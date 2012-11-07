module CommonWorker
  extend ActiveSupport::Concern

  included do
    def enqueue(action, options={})
      w = "#{self.class.name}Worker".constantize
      logger.info "  ENQUEUE: #{w} #{action}"
      Resque.enqueue(w, action, {:id => self.id.to_s}.merge(options)) unless Rails.env.test?
    end

    extend ClassMethods
  end

  module ClassMethods

  end
end