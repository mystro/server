class Jobs::Balancer::Destroy < Job
  def work
    mystro.balancer.destroy(model.rid) if model.synced_at && model.rid
    model.records.each { |r| r.enqueue(:destroy) }
  ensure
    model.destroy
  end
end