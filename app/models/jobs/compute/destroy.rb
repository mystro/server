class Jobs::Compute::Destroy < Job
  def work
    mystro.compute.destroy(model.to_cloud) if model.rid
    model.records.each { |r| r.enqueue(:destroy) }
  ensure
    model.destroy
  end
end
