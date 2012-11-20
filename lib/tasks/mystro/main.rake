namespace :mystro do
  desc "reset data (this will throw away database)"
  task :reset => :environment do
    Rake::Task["db:drop"].invoke
    Rake::Task["mystro:setup"].invoke
  end

  desc "first time setup for Mystro Server"
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

    Rake::Task["mystro:files:load"].invoke
    Rake::Task["mystro:chef:roles"].invoke

    # create admin user
    create_user unless User.all.count > 0

    # load cloud resources
    cloud_pull unless Compute.all.count > 0
  end

  namespace :chef do
    desc "load roles from chef server"
    task :roles => :environment do
      puts ".. loading chef roles"
      if Mystro.account[:plugins] && Mystro.account[:plugins][:chef]
        ChefWorker.perform
      else
        puts "** chef is not configured, will not load roles"
      end
    end
  end

  namespace :test do
    task :config => :environment do
      puts "DIR: #{Mystro.directory}"
      puts Mystro.account.to_hash.to_yaml
    end
    task :create_environment => :environment do
      e = Environment.where(:name => "blarg").first
      unless e
        t = Template.where(:name => "duo").first
        e = Environment.create(name: "blarg", template: t, protected: false)
      end
      e.enqueue(:create)
      puts "created: #{e.id}"
      puts "url: http://localhost:3000/environments/#{e.id}"
      puts "url: http://localhost:3000/environments/#{e.name}"
    end
    task :create_dns => :environment do
      r = Record.create(name: "app1.blarg.env.inqlabs.com", values: ["127.0.0.1"])
      r.enqueue(:create)
    end
  end
end