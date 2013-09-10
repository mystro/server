class Provider
  include Mongoid::Document
  include Mongoid::Timestamps

  include Named

  field :name, type: String
  field :file, type: String
  field :data, type: Hash, default: {}
end
