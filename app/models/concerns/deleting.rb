module Deleting
  extend ActiveSupport::Concern

  included do
    field :deleting, type: Boolean, default: false
  end
end
