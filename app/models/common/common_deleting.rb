module CommonDeleting
  extend ActiveSupport::Concern

  included do
    field :deleting, type: Boolean, default: false
    #default_scope where(deleting: false)

    extend ClassMethods
  end

  module ClassMethods

  end
end