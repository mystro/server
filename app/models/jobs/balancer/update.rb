class Jobs::Balancer::Create < Job
  def work
    raise "model is not set" unless model

    wait_for(model.computes)

    mystro.balancer.register_instances(model.computes.collect {|e| e.rid})
  end
end
