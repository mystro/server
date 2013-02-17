class Jobs::Record::Destroy < Job
  def work
    mystro.dns.destroy(model)
  ensure
    model.destroy
  end
end