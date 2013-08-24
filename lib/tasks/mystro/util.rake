namespace :mystro do
  namespace :util do
    task :update_balancers => :environment do
      oldid = "arn:aws:iam::169133138302:server-certificate/inqlabs.com"
      fog   = Mystro.balancer.fog
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
      %w{inqcloud reader}.each do |account|
        puts ".. #{account}"
        mystro = Mystro::Account.get(account)
        fog    = mystro.compute.fog
        if mystro
          computes = mystro.compute.all
          computes.each do |compute|
            t = { "Account" => account }.merge(compute.tags)
            puts ".. .. [#{t["Account"] || "no"}] #{t["Name"]}/#{t["Environment"]}"
            fog.create_tags([compute.id], t)
          end
        end
      end
    end
  end
end
