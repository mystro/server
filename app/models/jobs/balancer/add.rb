class Jobs::Balancer::Add < Job
  def work
    raise "model is not set" unless model
    rid = data["rid"]
    info "add rid: #{rid}"

    elb = model.to_fog
    list = elb.instance_health.map {|e| e["InstanceId"]}

    info "old list: #{list.inspect}"
    unless list.include?(rid)
      list << rid
      elb.register_instances(list)
    end

    info "new list: #{list.inspect}"
  end
end