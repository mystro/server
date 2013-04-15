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
  scope :for_account, ->(account){where(:account.in => [nil, Account.named(account)])}


  class << self
    def named(name)
      where(name: name).first
    end
  end

  def to_str
    "#{account ? "#{account.name}/" : nil}#{name}"
  end

  def load
    Mystro::DSL::Template.load(file)
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
