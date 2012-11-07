class RecordWorker < BaseWorker
  @queue = :default

  class << self
    def perform_create(options)
      #id = options["id"]
      #record = Record.find(id)
      #raise "could not find record #{id}" unless record
      #
      #Rig::Model::Dns.create(record.name, record.values.first, :ttl => record.ttl)
      #record.rid = record.name
      #record.synced_at = Time.now
      #record.save
    end

    def perform_destroy(options)
      #id = options["id"]
      #record = Record.unscoped.find(id)
      #raise "could not find record #{id}" unless record
      #
      #Rig::Model::Dns.destroy(record.name)
      #record.destroy
    end
  end
end