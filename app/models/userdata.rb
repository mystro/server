class Userdata
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :data, type: Hash
  field :script, type: String
  field :files, type: Array
  field :enabled, type: Boolean, default: false

  index({ name: 1 }, { unique: true})
  scope :active, ->{ where(enabled: true) }

  class << self
    def named(name)
      where(name: name).first
    end
  end
end
