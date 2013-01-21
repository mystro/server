class Account
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :file, type: String
  field :data, type: Hash
  field :enabled, type: Boolean

  has_many :environments
  has_many :computes
  has_many :balancers
  has_many :records

  index({ name: 1 }, { unique: true })

  scope :named, ->(name){ where(name: name) }

  def to_api
    {
        name: name,
        file: file,
        enabled: enabled,
    }
  end

  class << self
    def mystro(a)
      if a.is_a?(Mystro::Account)
        where(name: a.name).first
      end
    end
  end

  def mystro
    a = Mystro::Account.list[name]
    a.data if a
  end

  def load
    #puts "account#load #{name} #{file}"
    #puts "#{Mystro::Account.list.inspect}"
    d = Mystro::Account.list[name]
    #puts "account#load d: #{d}"
    d.data.to_hash if d
  end
end
