class Jobs::Record::Create < Job
  def work
    record = model
    remote = mystro.record.create(record.to_cloud)
    record.from_cloud(remote)
    record.rid = remote.identity
    record.synced_at = Time.now
    record.save!
  end
end
