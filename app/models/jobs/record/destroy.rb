class Jobs::Record::Destroy < Job
  def work
    info "record destroy: #{model.rid} #{model.name}"
    mystro.record.destroy(model.to_cloud)
  ensure
    model.destroy
  end
end
