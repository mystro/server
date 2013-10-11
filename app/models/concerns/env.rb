module Env
  extend ActiveSupport::Concern

  included do
    belongs_to :environment, index: true

  end
end
