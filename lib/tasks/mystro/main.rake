namespace :mystro do
  desc 'reset data (this will throw away database)'
  task :reset => :environment do
    Rake::Task['db:drop'].invoke
    Rake::Task['mystro:setup'].invoke
  end

  desc 'first time setup for Mystro Server'
  task :setup => :environment do
    if User.count > 0
      puts 'there already appears to be a user created.'
      puts 'if you wish to recreate the database, you should'
      puts 'drop the existing one first.'
      puts ""
      puts 'rake db:drop'
    end

    # create database and set up indexes
    Rake::Task['db:mongoid:create_indexes'].invoke

    Rake::Task['mystro:files:load'].invoke
    Rake::Task['mystro:chef:roles'].invoke

    Rake::Task['mystro:organization:unknown'].invoke

    # load cloud resources
    Rake::Task['mystro:cloud:update'].invoke unless Compute.all.count > 0

    # create admin user
    Rake::Task['mystro:user:admin'].invoke
  end

  desc 'link config files into server/config directory'
  task :config, [:dir] => :environment do |_, args|
    arg = args.dir || '../config'
    dir = File.expand_path(arg)
    raise "'#{dir}' is not a directory" unless File.directory?(dir)
    cwd = Dir.pwd
    Dir.chdir(dir) do
      Dir.entries('.').each do |d|
        dest = "#{cwd}/config/#{d}"
        if !File.directory?(d)
          puts "   #{d} - skipped, not directory"
          next
        end
        if d =~ /^\./
          puts "   #{d} - skipped, starts with dot (.)"
          next
        end
        puts "   #{dest} -> #{dir}/#{d}"
        FileUtils.rm_rf(dest)
        FileUtils.symlink("#{dir}/#{d}", dest)
      end
    end
  end

  namespace :chef do
    desc 'load roles from chef server'
    task :roles => :environment do
      puts '.. loading chef roles'
      if Mystro.organization[:plugins] && Mystro.organization[:plugins][:chef]
        ChefWorker.perform
      else
        puts '** chef is not configured, will not load roles'
      end
    end
  end

  namespace :test do
    task :config => :environment do
      puts "DIR: #{Mystro.directory}"
      puts Mystro.organization.to_hash.to_yaml
    end
    task :create_environment => :environment do
      e = Environment.where(:name => 'blarg').first
      unless e
        t = Template.where(:name => 'duo').first
        e = Environment.create(name: 'blarg', template: t, protected: false)
      end
      e.enqueue(:create)
      puts "created: #{e.id}"
      puts "url: http://localhost:3000/environments/#{e.id}"
      puts "url: http://localhost:3000/environments/#{e.name}"
    end
    task :create_dns => :environment do
      r = Record.create(name: 'app1.blarg.env.inqlabs.com', values: ['127.0.0.1'])
      r.enqueue(:create)
    end
    task :create_compute => :environment do
      Mystro.config.workers = false
      # {'name'=>'test1', 'environment'=>'50aa84d128a702a854000006', 'role_ids'=>['50a6b63528a7027810000019', ""],
      #'region'=>'us-east-1', 'flavor'=>'m1.small', 'image'=>'ami-3c994355', 'groups'=>'app-server,db-inqcloud-dev',
      #'keypair'=>'inqcloud-dev'}
      puts 'destroying previous test1.ops computes'
      e    = Environment.where(name: 'ops').first
      list = Compute.where(name: 'test', num: '1', environment: e)
      list.each do |c|
        puts ".. destroy compute:#{c.id}"
        c.destroy
      end

      c = Compute.create(name:    'test', num: 1, environment: e, role_ids: [],
                         region:  Mystro.organization.compute.region,
                         flavor:  Mystro.organization.compute.flavor,
                         image:   Mystro.organization.compute.image,
                         groups:  Mystro.organization.compute.groups,
                         keypair: Mystro.organization.compute.keypair)
      puts 'queueing create action'
      c.enqueue(:create)
      10.times { |i| print '.'; sleep 1 }; puts
      puts 'queueing destroy action'
      c.enqueue(:destroy)
    end
    task :userdata => :environment do
      a = Account.where(name: 'ops').first
      m = a.mystro
      e = Environment.where(name: 'dev').first || Environment.create(name: "dev")
      r = Role.where(name: "test").first || Role.create(name: "test")
      c = Compute.new(name:    'test', num: 1, environment: e, role_ids: r.id)
      c.set_defaults(a)
      o = c.fog_options
      u = o[:user_data]
      puts u
    end
  end
end
