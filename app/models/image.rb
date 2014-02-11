class Image
  include Mongoid::Document
  include Mongoid::Timestamps

  include Cloud

  field :name, type: String
  field :user, type: String, default: 'ubuntu'

  scope :region, ->(name) { where(region: name) }

  class << self
    def named(name)
      where(name: name).first
    end
  end
end