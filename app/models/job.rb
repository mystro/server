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
  scope :active, ->{ where(:status.in => [:new, :working, :waiting, :retry, :error], accepted_at: nil)}
  scope :errors, ->{ where(:status.in => [:error])}

  def accept
    self.accepted_at = Time.now
    self.save!
  end

  def cancel
    self.status = :cancelled
    self.save!
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
    while ((count * interval) < maximum) && yield do
      sleep interval
      count += 1
    end
    raise "wait timeout count=#{count} interval=#{interval} maximum=#{maximum}" if ((count * interval) >= maximum)
  end

  def model
    @model ||= begin
      if data && data["id"] && data["class"]
        c = data["class"].constantize
        begin
        c.find(data["id"])# rescue nil #TODO: make this smarter
        rescue Mongoid::Errors::DocumentNotFound => e
          logger.error "document not found"
          nil
        end
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

  def enqueue
    Resque.enqueue(JobWorker, {id: self.id.to_s})
  end

  def run
    begin
      self.status = :working
      self.save!

      self.work
      self.status = :complete
      self.save!

      self.accept
    rescue => e
      logger.error "JOB#RUN: error running job, attempting to save"
      logger.error "  #{e.message} at #{e.backtrace.first}"
      self.status = :error
      self.message = e.message
      self.trace = e.backtrace
      self.save!
    end
  end

  def logger
    @logger ||= Rails.logger
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