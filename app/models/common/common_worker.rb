module CommonWorker
  extend ActiveSupport::Concern

  included do
    include Qujo::Concerns::Model
  end

  #included do
  #  #def enqueue(action, options={})
  #  #  w = "#{self.class.name}Worker".constantize
  #  #  o = {"id" => self.id.to_s}.merge(options)
  #  #  if Mystro.config.workers
  #  #    logger.info "  ENQUEUE: #{w} #{action}"
  #  #    Resque.enqueue(w, action, o) unless Rails.env.test?
  #  #  else
  #  #    logger.info "  RUNNING: #{w} #{action}"
  #  #    w.perform(action, o)
  #  #  end
  #  #end
  #
  #  def enqueue(action, options={})
  #    n = "Jobs::#{self.class.name.capitalize}::#{action.capitalize}"
  #    c = n.constantize
  #    d = {id: self.id.to_s, class: self.class.name}.merge(options)
  #    j = c.create(data: d)
  #    if Mystro.config.workers
  #      logger.info "** ENQUEUE: JOB=#{j.id} NAME=#{n} DATA=#{d}"
  #      j.enqueue
  #    else
  #      logger.info "** RUNNING: JOB=#{j.id} NAME=#{n} DATA=#{d}"
  #      j.work
  #    end
  #    j.id
  #  end
  #
  #  extend ClassMethods
  #end
  #
  #module ClassMethods
  #
  #end
end
