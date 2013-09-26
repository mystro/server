class Job
  include Qujo::Database::Mongoid

  include Qujo::Queue::Resque

  include Qujo::Concerns::Common
  include Qujo::Concerns::Logging
  include Qujo::Concerns::Status

  def mystro
    @mystro ||= begin
      raise 'model or organization not set' unless model && model.organization
      a = model.organization
      o = Mystro::Organization.get(a.name)
      raise 'organization not found' unless o
      o
    end
  end

  # wait for objects be synced (set synced_at value)
  def wait_for(list=nil)
    return unless list && list.count
    classes = list.map { |e| e.class }.uniq
    logger.info "#{self.class.name}##{self.id} waiting for list of #{classes.join(",")}"
    wait do
      list.each { |e| e.reload }
      unsynced = list.select { |e| e.synced_at.nil? }
      unsynced.count > 0
    end
  end

end
