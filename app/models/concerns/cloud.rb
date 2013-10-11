module Cloud
  extend ActiveSupport::Concern
  extend ClassMethods

  included do
    field :rid, type: String
    field :managed, type: Boolean, default: false
    field :synced_at, type: DateTime, default: nil

    index({rid: 1})

    def old?
      (Time.now.to_i - synced_at.to_i) > 60.minutes
    end
  end

  module ClassMethods
    def remote(id)
      where(:rid => id).first
    end

    def cloud(options={}, &block)
      self.class_eval &block
    end

    def provides(name, type, options={})
      if type == :symbolize
        symbolize name, options
      else
        o = options.merge(type: type)
        field name, o
      end
    end
  end
end
