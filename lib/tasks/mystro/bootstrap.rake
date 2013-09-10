namespace :mystro do
  namespace :bootstrap do
    desc 'check mystro compute configuration'
    task :config => :environment do
      puts 'checking mystro and cloud configuration...'
      begin
        compute = Mystro.compute
        compute.running
        puts '.. compute'
      rescue => e
        raise "failed to talk to compute service, error was: #{e.message} at #{e.backtrace.first}"
      end

      begin
        dns = Mystro.dns
        dns.all
        puts '.. dns'
      rescue => e
        raise "failed to talk to DNS service, error was: #{e.message} at #{e.backtrace.first}"
      end

      puts 'done'
    end

    def question(s, d)
      ask(s) { |q| q.default = d }
    end

    def defaults(aname)
      {
          image: (Mystro.config.compute!.image || Mystro::Organization.get(aname).compute.image rescue nil),
          flavor: (Mystro.config.compute!.flavor || Mystro::Organization.get(aname).compute.flavor rescue nil),
          groups: (Mystro.config.compute!.groups || Mystro::Organization.get(aname).compute.groups rescue []).join(','),
          keypair: (Mystro.config.compute!.keypair || Mystro::Organization.get(aname).compute.keypair rescue nil),
      }
    end

    def build_server(name, userdata)
      puts
      aname = question('Organization name: ', 'ops')
      ename = question('Environment name: ', 'dev')
      sname = question('Server name: ', name)
      puts
      defs = defaults(aname)
      image = question('Image (AMI): ', defs[:image])
      flavor = question('Flavor (size): ', defs[:flavor])
      groups = question('Groups (comma separated): ', defs[:groups])
      groups = groups.split(',')
      keypair = question('Key pair name: ', defs[:keypair])
      userdata = question('Userdata package name: ', userdata)

      organization = Organization.where(name: aname).first || Organization.create(name: aname)
      #puts ".. using org: #{organization.name}"
      environment =
          Environment.where(name: ename).first ||
              Environment.create(name: ename, organization: organization, template: Template.named('empty'), protected: true)
      #puts ".. using environment: #{environment.name}"
      role = Role.where(name: "mystroserver").first || Role.create(name: "mystroserver", description: "created by mystro:boostrap", internal: true)
      compute = Compute.new(name: sname)
      compute.set_defaults(organization)
      compute.environment = environment
      compute.keypair = keypair
      compute.image = image
      compute.flavor = flavor
      compute.groups = groups
      compute.userdata = Userdata.named(userdata)
      compute.roles << role
      #puts ".. creating compute: #{compute.inspect}"
      #puts ".. options: #{compute.fog_options}"

      if agree('ready to create compute? ')
        compute.save!

        jcc = Jobs::Compute::Create.create(data: {model: {id: compute.id.to_s, class: compute.class.name}})
        puts "#{Time.now} creating compute..."
        # race condition, takes a sec for persistence engine
        # sleep
        sleep 3
        jcc = jcc.reload
        r = jcc.run
        raise "something went wrong" unless r

        #jcu = Jobs::Cloud::Update.create
        #puts "#{Time.now} updating cloud resources..."
        #sleep 3
        #jcu = jcu.reload
        #ru = jcu.run
        #raise "something went wrong" unless ru

        compute.reload
      end
    end

    desc 'use mystro configuration to bootstrap server'
    task :server => [:environment, :config] do
      compute = build_server('mystro', 'mystroserver')
      puts "#{compute.public_dns} (#{compute.public_ip})" if compute
    end

    desc 'use mystro configuration to bootstrap chef server'
    task :chef => [:environment, :config] do
      compute = build_server('chef', 'chefserver')
      puts "#{Time.now} compute created. connect to:"
      puts "#{compute.public_dns} (#{compute.public_ip})" if compute
    end
  end
end
