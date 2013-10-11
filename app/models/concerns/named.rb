module Named
  extend ActiveSupport::Concern

  included do
    extend ClassMethods
  end

  module ClassMethods
    def named(name)
      where(name: name).first
    end
  end

end
