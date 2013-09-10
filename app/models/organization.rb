class Organization
  include Mongoid::Document
  include Mongoid::Timestamps
  include Qujo::Concerns::Model

  include Named

  has_many :environments
  has_many :computes
  has_many :balancers
  has_many :records
  has_many :templates

  field :name, type: String
  field :file, type: String
  field :data, type: Hash, default: {}
  field :enabled, type: Boolean, default: false

  index({ name: 1 }, { unique: true })

  class << self
    def named(name)
      where(name: name).first
    end

    def mystro(a)
      if a.is_a?(Mystro::Organization)
        where(name: a.name).first
      end
    end
  end

  def selectors
    @selectors ||= Hashie::Mash.new(self.data["selectors"])
  end

  def selectors_images
    @selectors_images ||= begin
      hash = selectors.images
      if hash
        hash.each do |k, v|
          v.map! { |e| [e["name"], e["id"]] }
        end
        hash
      else
        nil
      end
    end
  end

  def to_api
    {
        name:    name,
        file:    file,
        enabled: enabled,
    }
  end

  def mystro
    a = Mystro::Organization.get(name)
    a.data if a
  end

  def mystro_zone
    mystro.dns.zone || nil rescue nil
  end

  def load
    d = Mystro::Organization.get(name)
    #puts "organization#load d: #{d}"
    d.data.to_hash if d
  end
end
