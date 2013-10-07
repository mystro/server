class Jobs::Record::Destroy < Job
  def work
    mystro.record.destroy(model.rid) if model.rid
  ensure
    model.destroy
  end
end
