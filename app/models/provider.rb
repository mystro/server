class Provider
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Symbolize

  belongs_to :user

  symbolize :cloud, :in => [:AWS], :scopes => true
  field :key, type: String
  field :secret, type: String
end
