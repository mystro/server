class Zone
  include Mongoid::Document
  include Mongoid::Timestamps

  include CommonRemote

  has_many :records

  field :domain, type: String

  class << self
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