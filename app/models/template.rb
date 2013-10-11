class Template
  include Mongoid::Document
  include Mongoid::Timestamps

  include Org

  has_many :environments
  belongs_to :organization

  field :name, type: String
  field :file, type: String
  field :data, type: Hash
  field :enabled, type: Boolean, default: true

  index({ name: 1 })
  index({ file: 1 }, { unique: true})

  scope :active, ->{where(enabled: true)}
  scope :for_org, ->(org){where(:organization.in => [nil, Organization.named(org)])}

  class << self
    def named(name)
      where(name: name).first
    end
  end

  def to_str
    "#{organization ? "#{organization.name}/" : nil}#{name}"
  end

  def load
    Mystro::Dsl.load(file)
  end

  def server_attrs(name)
    if data["servers"]
      ts = data["servers"].select {|e| e["name"] == name}.first
      if ts && ts["attrs"]
        return ts["attrs"]
      end
    end
    nil
  end

  def to_api
    {
        name: name,
        file: file,
        enabled: enabled,
    }
  end
end
