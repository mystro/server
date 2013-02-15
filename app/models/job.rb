class Job
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Symbolize

  field :data, type: Hash
  symbolize :status, in: [:new, :working, :waiting, :complete, :error, :cancelled], default: "new"
  field :message, type: String
  field :log, type: Array, default: []
  field :trace, type: Array, default: []
  field :accepted_at, type: DateTime

  default_scope where(accepted_at: nil)

  def accept
    self.accepted_at = Time.now
    self.save
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