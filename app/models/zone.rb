class Zone
  include Mongoid::Document
  include Mongoid::Timestamps
  include Qujo::Concerns::Model

  include Cloud
  include Deleting

  has_many :records

  cloud do
    provides :domain, String
  end

  def name
    domain
  end

  class << self
    def named(name)
      where(domain: name).first
    end
    def create_from_fog(obj)
      zone           = Zone.remote(obj.id) || Zone.create(:rid => obj.id)
      zone.domain    = obj.domain.gsub(/\.$/, "")
      zone.synced_at = Time.now

      list = obj.records || []
      list.each do |r|
        Record.create_from_fog(zone, r)
      end

      zone.save
      zone
    end
  end
end
