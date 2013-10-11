class Userdata
  include Mongoid::Document
  include Mongoid::Timestamps

  include Named

  field :name, type: String
  field :data, type: Hash
  field :script, type: String
  field :files, type: Array
  field :enabled, type: Boolean, default: false

  index({ name: 1 }, { unique: true})
  scope :active, ->{ where(enabled: true) }
end
