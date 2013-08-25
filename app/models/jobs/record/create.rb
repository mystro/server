class Jobs::Record::Create < Job
  def work
    r = model
    mystro.dns.create(r)
    r.rid = model.name
    r.synced_at = Time.now
    r.save!
  end
end
