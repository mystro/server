class Jobs::Compute::Destroy < Job
  def work
    info "compute:#{model.id}#destroy fog destroy"
    mystro.compute.destroy(model) if model.rid
    info "compute:#{model.id}#destroy queue record destroy"
    model.records.each { |r| r.enqueue(:destroy) }
  ensure
    info "compute:#{model.id}#destroy compute destroy"
    model.destroy
  end
end
