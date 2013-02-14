class Template
  include Mongoid::Document
  include Mongoid::Timestamps

  has_many :environments
  belongs_to :account

  field :name, type: String
  field :file, type: String
  field :data, type: Hash
  field :enabled, type: Boolean, default: true

  index({ file: 1 }, { unique: true})

  scope :active, ->{where(enabled: true)}

  def to_str
    "#{account ? "#{account.name}/" : nil}#{name}"
  end

  def load
    Mystro::DSL::Template.load(file)
  end

  def to_api
    {
        name: name,
        file: file,
        enabled: enabled,
    }
  end
end
