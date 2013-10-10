namespace :mystro do
  namespace :util do
    task :update_balancers => :environment do
      oldid = "arn:aws:iam::169133138302:server-certificate/inqlabs.com"
      fog = Mystro.balancer.fog
      puts "fog: #{fog}"
      balancers = Mystro.balancer.all
      balancers.each do |b|
        listeners = b.listeners
        listeners.each do |l|
          #puts "#{l.inspect}"
          #puts "#{l.ssl_id}"
          if l.ssl_id == oldid && l.lb_port == 443
            puts "#{l.lb_port} #{l.ssl_id}"
            b.set_listener_ssl_certificate(443, "arn:aws:iam::169133138302:server-certificate/2013inqlabs.com")
          end
        end
      end
    end
    task :fix_tags => :environment do
      puts "fixing tags:"
      %w{inqcloud reader}.each do |organization|
        puts ".. #{organization}"
        mystro = Mystro::Organization.get(organization)
        fog = mystro.compute.fog
        if mystro
          computes = mystro.compute.all
          computes.each do |compute|
            t = {"Organization" => organization}.merge(compute.tags)
            puts ".. .. [#{t["Organization"] || "no"}] #{t["Name"]}/#{t["Environment"]}"
            fog.create_tags([compute.id], t)
          end
        end
      end
    end
    namespace :env do
      task :create => :environment do
        org = Organization.named('ops')
        temp = Template.named('duo')
        env = org.environments.create(name: 'blarg', template: temp, protected: false)
        puts "ENV: #{env.inspect}"
        puts "TEMP: #{temp.inspect}"
        if env
          job = Jobs::Environment::Create.create(data: {'model' => {'id' => env.id.to_s, 'class' => env.class.name}})
          puts "running job: #{job.id}: #{job.inspect}"
          job.run
          job.accept
        end
      end
      task :destroy => :environment do
        env = Environment.where(name: 'blarg').first
        puts "ENV: #{env.inspect}"
        if env
          job = Jobs::Environment::Destroy.create(data: {'model' => {'id' => env.id.to_s, 'class' => env.class.name}})
          puts "running job: #{job.id}: #{job.inspect}"
          job.run
          job.accept
        end
      end
    end
    task :compute => :environment do
      begin
        org = Organization.named('hdp')
        env = org.environments.named('live')
        mystro = Mystro::Organization.get('hdp')
        type = :data
        num = env.get_next_number(type)
        cloud = env.template.load.compute(type)
        compute = Compute.new(name: type, num: num)
        compute.set_defaults(org)
        compute.from_cloud(cloud)
        compute.num = num
        compute.environment = env
        compute.save

        #puts "compute:"
        #puts "#{compute.inspect}"
        #puts "#{compute.volumes.inspect}"
        cloud = compute.to_cloud
        #puts "cloud:"
        #puts "#{cloud.inspect}"
        puts "encode:"
        encode = mystro.compute.encode(cloud)
        puts encode.inspect
        puts "create:"
        remote = mystro.compute.create(cloud)
        puts "remote: #{remote.inspect}"
        compute.from_cloud(remote)
        compute.synced_at = Time.now
        compute.save
      rescue => e
        puts "exception: #{e.message}"
        puts e.backtrace.join("\n")
        #ensure
        #  mystro.compute.destroy(remote.id) if remote
        #  compute.destroy if compute
        #  puts "done"
      end
    end
    task :fog do
      require 'fog'
      key = ENV['AWS_ACCESS_KEY_ID']
      secret = ENV['AWS_SECRET_ACCESS_KEY']
      aws = Fog::Compute.new(provider: 'AWS', aws_access_key_id: key, aws_secret_access_key: secret)
      count = aws.servers.all.count
      puts "verify that the connection is working: #{count}"
      withvol = {
          :image_id => 'ami-0145d268',
          :flavor_id => 'm1.large',
          :key_name => 'mystro',
          :groups => ['default'],
          :region => 'us-east-1',
          :tags => {
              'Name' => 'fog-test-with',
          },
          :block_device_mapping => [
              {
                  'DeviceName' => '/dev/sda1',
                  'Ebs.SnapshotId' => 'snap-945db7d4',
                  'Ebs.VolumeSize' => '16',
                  'Ebs.DeleteOnTermination' => 'true'
              },
              {
                  'DeviceName' => '/dev/sdb',
                  'VirtualName' => 'ephemeral0'
              }
          ],
      }

      withoutvol = {
          :image_id => 'ami-0145d268',
          :flavor_id => 'm1.large',
          :key_name => 'mystro',
          :groups => ['default'],
          :region => 'us-east-1',
          :tags => {
              'Name' => 'fog-test-without',
          }
      }

      begin
        puts 'attempt to create without volume information:'
        puts "options: #{withoutvol.inspect}"
        without = aws.servers.create(withoutvol)
        puts "success: #{without.id}"
      rescue => e
        puts "exception: #{e.message}"
          #puts e.backtrace.join("\n")
      ensure
        without.destroy if without
      end

      begin
        puts 'attempt to create with volume information:'
        puts "options: #{withvol.inspect}"
        with = aws.servers.create(withvol)
        puts "success: #{with.id}"
      rescue => e
        puts "exception: #{e.message}"
          #puts e.backtrace.join("\n")
      ensure
        with.destroy if with
      end
    end
  end
end
