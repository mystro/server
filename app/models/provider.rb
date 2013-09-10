class Provider
  include Mongoid::Document
  include Mongoid::Timestamps

  include Named

  field :name, type: String
  field :file, type: String
  field :data, type: Hash, default: {}

  def load
    d = Mystro::Organization.get(name)
    #puts "organization#load d: #{d}"
    d.data.to_hash if d
  end
end
