class Jobs::Balancer::Remove < Job
  def work
    raise "model is not set" unless model
    rid = data["rid"]
    info "remove rid: #{rid}"

    elb = model.to_fog
    list = elb.instance_health.map {|e| e["InstanceId"]}
    count = list.count

    if list.include?(rid)
      elb.deregister_instances([rid])
    end

    info "waiting for remove"
    wait do
      # wait while block is TRUE
      b = model.to_fog
      c = b.instance_health.count
      info "instance count: #{c}"
      c != (count - 1) # true until original list is shorter by one
    end
  end
end