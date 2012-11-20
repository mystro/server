class RecordWorker < BaseWorker
  @queue = :default

  class << self
    def perform_create(options)
      id = options["id"]
      record = Record.find(id)
      raise "could not find record #{id}" unless record

      Mystro.dns.create(record)
      record.rid = record.name
      record.synced_at = Time.now
      record.save
    end

    def perform_destroy(options)
      id = options["id"]
      record = Record.unscoped.find(id)
      raise "could not find record #{id}" unless record

      Mystro.dns.destroy(record)
      record.destroy
    end
  end
end