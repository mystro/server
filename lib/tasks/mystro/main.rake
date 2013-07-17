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

    Rake::Task["mystro:account:unknown"].invoke

    # load cloud resources
    Rake::Task["mystro:cloud:update"].invoke unless Compute.all.count > 0

    # create admin user
    Rake::Task["mystro:user:admin"].invoke
  end

  desc "link config files into server/config directory"
  task :config, [:dir] => :environment do |_, args|
    arg = args.dir || "../config"
    dir = File.expand_path(arg)
    raise "'#{dir}' is not a directory" unless File.directory?(dir)
    cwd = Dir.pwd
    Dir.chdir(dir) do
      Dir.entries(".").each do |d|
        dest = "#{cwd}/config/#{d}"
        if !File.directory?(d)
          puts "   #{d} - skipped, not directory"
          next
        end
        if d =~ /^\./
          puts "   #{d} - skipped, starts with dot (.)"
          next
        end
        if File.exists?(dest)
          puts "   #{d} - skipped, destination exists (#{dest})"
          next
        end
        puts "   #{dest} -> #{dir}/#{d}"
        FileUtils.symlink("#{dir}/#{d}", dest)
      end
    end
  end

  desc "use mystro configuration to bootstrap server"
  task :bootstrap => :environment do
    #puts "checking mystro and cloud configuration..."
    #begin
    #  compute = Mystro.compute
    #  compute.running
    #  puts ".. compute"
    #rescue => e
    #  raise "failed to talk to compute service, error was: #{e.message} at #{e.backtrace.first}"
    #end
    #
    ##begin
    ##  dns = Mystro.dns
    ##  dns.all
    ##  puts ".. dns"
    ##rescue => e
    ##  raise "failed to talk to DNS service, error was: #{e.message} at #{e.backtrace.first}"
    ##end
    #
    #puts "done"

    puts
    aname = ask("Account name: ") { |q| q.default = 'ops' }
    ename = ask("Environment name: ") { |q| q.default = 'dev' }
    sname = ask("Server name: ") { |q| q.default = 'mystro' }
    puts
    image = Mystro.config.compute!.image || Mystro::Account.list[aname].compute.image rescue nil
    image = ask("Image (AMI): ") {|q| q.default = image}
    flavor = Mystro.config.compute!.flavor || Mystro::Account.list[aname].compute.flavor rescue nil
    flavor = ask("Flavor (size): ") {|q| q.default = flavor}
    groups = Mystro.config.compute!.groups || Mystro::Account.list[aname].compute.groups rescue nil
    groups = ask("Groups (comma separated): ") {|q| q.default = groups.join(",")}
    groups = groups.split(",")
    keypair = Mystro.config.compute!.keypair || Mystro::Account.list[aname].compute.keypair rescue nil
    keypair = ask("Key pair name: ") { |q| q.default = keypair }


    puts "creating compute..."
    account = Account.where(name: aname).first || Account.create(name: aname)
    #puts ".. using account: #{account.name}"
    environment =
        Environment.where(name: ename).first ||
        Environment.create(name: ename, account: account, template: Template.named('empty'), protected: true)
    #puts ".. using environment: #{environment.name}"
    compute = Compute.new(name: sname)
    compute.set_defaults(account)
    compute.environment = environment
    compute.keypair = keypair
    compute.image = image
    compute.flavor = flavor
    compute.groups = groups
    #puts ".. creating compute: #{compute.inspect}"
    #puts ".. options: #{compute.fog_options}"

    agree("ready to create compute? ")

    compute.save!

    puts ".. enqueue job"
    jid = compute.enqueue(:create, dns: false)

    if Resque.workers.count == 0
      puts ".. no workers, running job now"
      job = Job.find(jid)
      job.run
    end
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
    task :create_compute => :environment do
      Mystro.config.workers = false
      # {"name"=>"test1", "environment"=>"50aa84d128a702a854000006", "role_ids"=>["50a6b63528a7027810000019", ""],
      #"region"=>"us-east-1", "flavor"=>"m1.small", "image"=>"ami-3c994355", "groups"=>"app-server,db-inqcloud-dev",
      #"keypair"=>"inqcloud-dev"}
      puts "destroying previous test1.ops computes"
      e    = Environment.where(name: "ops").first
      list = Compute.where(name: "test", num: "1", environment: e)
      list.each do |c|
        puts ".. destroy compute:#{c.id}"
        c.destroy
      end

      c = Compute.create(name:    "test", num: 1, environment: e, role_ids: [],
                         region:  Mystro.account.compute.region,
                         flavor:  Mystro.account.compute.flavor,
                         image:   Mystro.account.compute.image,
                         groups:  Mystro.account.compute.groups,
                         keypair: Mystro.account.compute.keypair)
      puts "queueing create action"
      c.enqueue(:create)
      10.times { |i| print "."; sleep 1 }; puts
      puts "queueing destroy action"
      c.enqueue(:destroy)
    end
  end
end