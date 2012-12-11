set :default_stage, "production"
set :stages, %w(production staging)
set :application, "mystroserver"
set :user, "ubuntu"
set :ssh_options, { :forward_agent => true }

set :scm, :git
# Or: `accurev`, `bzr`, `cvs`, `darcs`, `git`, `mercurial`, `perforce`, `subversion` or `none`
set :repository,  "git@github.com:mystro/server.git"

set :deploy_to, "/srv/apps/#{application}"
set :deploy_via, :remote_cache

require 'capistrano/ext/multistage'
require 'bundler/capistrano'
set :bundle_flags,    "--quiet"

set :whenever_command, "bundle exec whenever"
require 'whenever/capistrano'

require 'webserver/apache'
set :webserver_dir, "/srv/sites"

## RVM specific
#set :rvm_ruby_string, ENV['GEM_HOME'].gsub(/.*\//,"")
#set :rvm_type, :user
#require "rvm/capistrano"

default_run_options[:pty] = true
set :use_sudo, false
set :keep_releases, 3

# if you want to clean up old releases on each deploy uncomment this:
after "deploy:restart", "deploy:cleanup"
after "deploy:restart", "foreman:restart"

after "deploy:update_code", "mystro:config:push"
after "deploy:create_symlink", "mystro:config:symlink"
after "deploy:restart", "mystro:files"
after "deploy:setup", "mystro:setup"

# uncomment below to map specified rake tasks to cap tasks
require 'cape'
# Configure Cape to execute Rake via Bundler, both locally and remotely.
Cape.local_rake_executable = '/usr/bin/env bundle exec rake'
Cape.remote_rake_executable = '/usr/bin/env bundle exec rake'

Cape do |cape|
  # Create Capistrano recipes for all Rake tasks.
  tasks = %w{mystro:reset mystro:setup mystro:cloud:update mystro:chef:roles}
  tasks.each do |task|
    cape.mirror_rake_tasks task, :roles => :app do |env|
      env['RAILS_ENV'] = rails_env
    end
  end
end

namespace :mystro do
  task :files do
    rake = fetch(:rake, "rake")
    task = "mystro:files:load"
    run "cd #{current_path} && #{rake} #{task} RAILS_ENV=#{rails_env}"
  end

  task :setup do
    run("mkdir -p #{shared_path}/config")
  end

  namespace :config do
    task :update do
      mystro.config.push
      mystro.config.symlink
    end

    desc "push mystro configuration"
    task :push do
      require "rails"
      dir = "config/mystro"
      file = "mystro-config-#{$$}-#{Time.now.to_i}.tgz"
      system("cd #{dir} && tar cfz /tmp/#{file} *")
      upload("/tmp/#{file}", "#{shared_path}/config/#{file}")
      run("cd #{shared_path}/config && tar xfz #{file}")
    end

    desc "symlink mystro configuration"
    task :symlink do
      run("ln -sf #{shared_path}/config #{current_path}/config/mystro")
    end
  end
end

namespace :foreman do
  desc "Start the application services"
  task :start, :roles => :app do
    sudo "start #{application}"
  end

  desc "Stop the application services"
  task :stop, :roles => :app do
    sudo "stop #{application}"
  end

  desc "Restart the application services"
  task :restart, :roles => :app do
    run "sudo start #{application} || sudo restart #{application}"
  end

  desc "Display logs for a certain process - arg example: PROCESS=web-1"
  task :logs, :roles => :app do
    run "cd #{current_path}/log && cat #{ENV["PROCESS"]}.log"
  end

  desc "Export the Procfile to upstart scripts"
  task :export, :roles => :app do
    webs       = 2
    workers    = 3
    schedulers = 1

    cmd = "cd #{current_path} && "
    cmd << "sudo bundle exec foreman export upstart /etc/init "
    cmd << "-a #{application} "
    cmd << "-u #{user} "
    cmd << "-l #{shared_path}/log "
    cmd << "-f #{current_path}/Procfile.production "
    cmd << "-c web=#{webs},worker=#{workers},scheduler=#{schedulers}"
    run "sudo rm -f /etc/init/#{application}*"
    run cmd
  end
end

# https://gist.github.com/1808418
# Use the config/mongoid/#{rails_env}.yml file for mongoid config
namespace :mongoid do
  desc "Copy mongoid config"
  task :copy do
    upload "config/mongoid/#{rails_env}.yml", "#{shared_path}/mongoid.yml", :via => :scp
  end

  desc "Link the mongoid config in the release_path"
  task :symlink do
    run "test -f #{release_path}/config/mongoid.yml || ln -s #{shared_path}/mongoid.yml #{release_path}/config/mongoid.yml"
  end

  desc "Create MongoDB indexes"
  task :index do
    run "cd #{current_path} && bundle exec rake db:mongoid:create_indexes RAILS_ENV=#{rails_env}", :once => true
  end
end
after "deploy:migrations", "mongoid:index"

# http://www.bencurtis.com/2011/12/skipping-asset-compilation-with-capistrano/
#namespace :deploy do
#  namespace :assets do
#    task :precompile, :roles => :web, :except => { :no_release => true } do
#      from = source.next_revision(current_revision)
#      if capture("cd #{latest_release} && #{source.local.log(from)} vendor/assets/ app/assets/ | wc -l").to_i > 0
#        run %Q{cd #{latest_release} && #{rake} RAILS_ENV=#{rails_env} #{asset_env} assets:precompile}
#      else
#        logger.info "Skipping asset pre-compilation because there were no asset changes"
#      end
#    end
#  end
#end
