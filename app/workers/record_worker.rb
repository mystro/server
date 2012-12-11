class RecordWorker < BaseWorker
  @queue = :default

  class << self
    def perform_create(record, mystro)
      mystro.dns.create(record)
      record.rid = record.name
      record.synced_at = Time.now
      record.save
    end

    def perform_update(record, mystro)
      return perform_create(record, mystro) unless record.synced_at

      #r = mystro.dns.find(record.rid)
    end

    def perform_destroy(record, mystro)
      mystro.dns.destroy(record)
    ensure
      record.destroy
    end
  end
end