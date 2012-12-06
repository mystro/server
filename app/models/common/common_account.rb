module CommonAccount
  extend ActiveSupport::Concern

  included do
    field :deleting, type: Boolean, default: false
    #default_scope where(deleting: false)

    scope :with_account, ->(name){ where(account_id: Account.named(name).first) }

    extend ClassMethods
  end

  module ClassMethods

  end
end