class Job
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Symbolize

  field :data, type: Hash
  symbolize :status, in: [:new, :working, :waiting, :complete, :error, :retry, :cancelled], default: "new"
  field :message, type: String
  field :log, type: Array, default: []
  field :trace, type: Array, default: []
  field :accepted_at, type: DateTime

  default_scope where(accepted_at: nil)

  def accept
    self.accepted_at = Time.now
    self.save
  end

  def retry
    self.accepted_at = nil
    self.status = :retry
    self.log << "--- retry ---"
    self.message = nil
    self.save
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

  # wait while return value from block is true
  def wait(options = { }, &block)
    return unless block_given?
    o = { interval: 3, maximum: 600 }.merge(options)
    interval = o[:interval]
    maximum = o[:maximum]
    count = 0
    while yield && ((count * interval) < maximum) do
      sleep interval
      count += 1
    end
    raise "wait timeout" if ((count * interval) < maximum)
  end

  def model
    @model ||= begin
      if data["id"] && data["class"]
        c = data["class"].constantize
        c.find(data["id"])
      end
    end
  end

  def mystro
    @mystro ||= begin
      if model && model.account
        a = model.account
        Mystro::Account.list[a.name]
      end
    end
  end

  def pushlog(sev, msg)
    self.log << {severity: sev, message: msg}
  end

  def debug(msg)
    pushlog(:debug, msg) if Rails.env.development? || Mystro.config.debug
  end

  def info(msg)
    pushlog(:info, msg)
  end

  def warn(msg)
    pushlog(:warn, msg)
  end

  def error(msg)
    pushlog(:error, msg)
  end

  def enqueue
    Resque.enqueue(JobWorker, {id: self.id.to_s})
  end

  def self.inherited(child)
    child.instance_eval do
      def model_name
        Job.model_name
      end
    end
    super
  end

  class << self
    def errors?
      Job.where(status: :error).count > 0
    end
  end
end