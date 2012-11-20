module CommonWorker
  extend ActiveSupport::Concern

  included do
    def enqueue(action, options={})
      w = "#{self.class.name}Worker".constantize
      o = {"id" => self.id.to_s}.merge(options)
      if Mystro.config.workers
        logger.info "  ENQUEUE: #{w} #{action}"
        Resque.enqueue(w, action, o) unless Rails.env.test?
      else
        logger.info "  RUNNING: #{w} #{action}"
        w.perform(action, o)
      end
    end

    extend ClassMethods
  end

  module ClassMethods

  end
end