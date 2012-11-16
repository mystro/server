class EnvironmentWorker < BaseWorker
  @queue = :default

  class << self
    def perform_create(options)
      id = options["id"]
      e  = Environment.find(id)
      raise "could not find environment #{id}" unless e
      t = e.template
      raise "could not find template" unless t
      d = e.template.data || e.template.load

      balancers = {}

      d["balancers"].each do |x|
        n = "#{e.name}-#{x["name"]}"
        b = e.balancers.find_or_create_by(:name => n)
        b.update_attributes(
            :rid => n,
            :primary => x["primary"],
            :sticky => true,
            :sticky_type => x["sticky_type"],
            :sticky_arg => x["sticky_arg"],
            :managed => true,
        )
        b.save

        x["listeners"].each do |xl|
          l = b.listeners.find_or_create_by(:from => "#{xl["from_proto"]}:#{xl["from_port"]}")
          l.update_attributes(
              :cert => xl["cert"],
              :to => "#{xl["to_proto"]}:#{xl["to_port"]}",
          )
          l.save
        end

        b.save
        balancers[x["name"]] = b
      end

      d["servers"].each do |x|
        s = x["attrs"]
        1.upto(s["count"]) do |i|
          o = {
              :roles   => Role.create_from_fog(s["roles"]),
              :groups  => s["groups"],
              :image   => s["image"],
              :flavor  => s["flavor"],
              :keypair => s["keypair"],
              :managed => true,
              :userdata => s["userdata"],
          }.delete_if {|k, v| v.nil?}

          name = s["name"]

          c = e.computes.find_or_create_by(:name => name, :num => i)
          c.update_attributes(o)
          if s["balancer"]
            if balancers[s["balancer"]]
              c.balancer = balancers[s["balancer"]]
            else
              raise "balancer #{s["balancer"]} does not exist"
            end
          end
          c.save
        end
      end

      e.computes.each do |c|
        logger.info "compute: #{c.inspect}"
        unless c.synced_at
          logger.info "compute enqueue: #{c.enqueue(:create)}"
        end
      end

      e.balancers.each do |b|
        logger.info "balancer: #{b.inspect}"
        unless b.synced_at
          logger.info "balancer enqueue: #{b.enqueue(:create)}"
        end
      end

      Mystro::Plugin.run "environment:create", e
    end

    def perform_destroy(options)
      id = options["id"]
      e = Environment.unscoped.find(id)
      raise "could not find environment #{id}" unless e

      e.computes.each do |c|
        c.enqueue(:destroy)
      end
      e.balancers.each do |b|
        b.enqueue(:destroy)
      end

      Mystro::Plugin.run "environment:destroy", e
      e.destroy
    end

    def perform_add(options)

    end

    def perform_remove(options)

    end
  end
end