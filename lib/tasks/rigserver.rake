require 'highline/import'

namespace :rigserver do
  desc "reset data (this will throw away database)"
  task :reset => :environment do
    Rake::Task["db:drop"].invoke
    Rake::Task["rigserver:setup"].invoke
  end

  desc "first time setup for Rig Server"
  task :setup => :environment do
    if User.count > 0
      puts "there already appears to be a user created."
      puts "if you wish to recreate the database, you should"
      puts "drop the existing one first."
      puts ""
      puts "rake db:drop"
    end

    # create database and set up indexes
    Rake::Task["db:mongoid:create_indexes"].invoke

    Rake::Task["rigserver:files:load"].invoke
    Rake::Task["rigserver:chef:roles"].invoke

    # create admin user
    create_user unless User.all.count > 0

    # load cloud resources
    cloud_pull unless Compute.all.count > 0
  end

  namespace :user do
    desc "create a new user in the database"
    task :create => :environment do
      puts ".. creating user"
      create_user
    end
  end

  namespace :cloud do
    desc "updates resources from cloud into the database"
    task :update => :environment do
      puts ".. loading cloud resources"
      cloud_pull
    end
  end

  namespace :files do
    desc "load rig configuration files to database"
    task :load => :environment do
      Rake::Task["rigserver:files:templates"].invoke
    end

    task :templates => :environment do
      puts ".. loading templates..."
      files = Dir["config/rig/templates/*"]
      files.each do |file|
        name = File.basename(file).gsub(/\.rb/, "")
        t = Template.create(:name => name, :file => file)
        d = JSON.parse(t.load.to_json)
        t.data = d
        t.save
        puts ".. create #{name} #{file}"
      end
    end
  end

  namespace :chef do
    desc "load roles from chef server"
    task :roles => :environment do
      puts ".. loading chef roles"
      if Rig.account[:plugins] && Rig.account[:plugins][:chef]
        ChefWorker.perform
      else
        puts "** chef is not configured, will not load roles"
      end
    end
  end

  namespace :test do
    task :create_environment => :environment do
      e = Environment.where(:name => "blarg").first
      e.enqueue(:create)
      puts "environment: #{e.id}"
    end
  end

  def cloud_pull
    RigWorker.perform
  rescue => e
    puts "error: #{e.message} at #{e.backtrace.first}"
  end

  def create_user
    user     = ask "Administrator name:  "
    email    = ask "Administrator email: "
    password = ask("password:            ") { |q| q.echo = "*" }
    confirm  = ask("confirm:             ") { |q| q.echo = "*" }
    opts     = {
        :name                  => user,
        :email                 => email,
        :password              => password,
        :password_confirmation => confirm
    }
    puts "creating user: #{user} <#{email}>"
    User.create(opts)
  rescue => e
    puts "error: #{e.message} at #{e.backtrace.first}"
  end
end