class Jobs::Record::Create < Job
  def work
    mystro.dns.create(model)
    model.rid = model.name
    model.synced_at = Time.now
    model.save!
  end
end