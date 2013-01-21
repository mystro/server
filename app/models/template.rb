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
    Mystro::DSL::Template.load(name)
  end

  def to_api
    {
        name: name,
        file: file,
        enabled: enabled,
    }
  end
end
