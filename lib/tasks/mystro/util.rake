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
    task :compute => :environment do
      begin
        org = Organization.named('ops')
        env = org.environments.named('blarg')
        mystro = Mystro::Organization.get('ops')
        type = :vol
        num = env.get_next_number(@type)
        cloud = env.template.load.compute(type)
        compute = Compute.new(name: type, num: num)
        compute.set_defaults(org)
        compute.from_cloud(cloud)
        compute.num = num
        compute.environment = env
        compute.save

        puts "compute:"
        #puts "#{compute.inspect}"
        #puts "#{compute.volumes.inspect}"
        cloud = compute.to_cloud
        #puts "cloud:"
        #puts "#{cloud.inspect}"
        #puts "encode:"
        #encode = mystro.compute.encode(cloud)
        #puts encode.inspect
        puts "create:"
        remote = mystro.compute.create(cloud)
        puts "remote: #{remote.inspect}"
        compute.from_cloud(remote)
        compute.synced_at = Time.now
        compute.save
      rescue => e
        puts "exception: #{e.message}"
        #ensure
        #  mystro.compute.destroy(remote.id) if remote
        #  compute.destroy if compute
        #  puts "done"
      end
    end
  end
end
