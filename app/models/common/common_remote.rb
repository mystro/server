module CommonRemote
  extend ActiveSupport::Concern

  included do
    field :rid, type: String
    index({ rid: 1 })

    field :managed, type: Boolean, default: false
    field :synced_at, type: DateTime, default: nil

    extend ClassMethods
  end

  module ClassMethods
    def remote(id)
      where(:rid => id).first
    end
  end
end