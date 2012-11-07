class Template
  include Mongoid::Document
  include Mongoid::Timestamps

  has_many :environments

  field :name, type: String
  field :file, type: String
  field :data, type: Hash
  field :enabled, type: Boolean, default: true

  index({ name: 1 }, { unique: true})

  def load
    Rig::Template.load(name)
  end
end
