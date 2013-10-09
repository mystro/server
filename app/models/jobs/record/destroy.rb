class Jobs::Record::Destroy < Job
  def work
    mystro.record.destroy(model.to_cloud) if model.rid
  ensure
    model.destroy
  end
end
