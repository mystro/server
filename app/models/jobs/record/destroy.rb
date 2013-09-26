class Jobs::Record::Destroy < Job
  def work
    mystro.dns.destroy(model.rid) if model.rid
  ensure
    model.destroy
  end
end