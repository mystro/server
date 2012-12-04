class Record
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Symbolize

  include CommonRemote
  include CommonWorker
  include CommonDeleting

  belongs_to :zone, index: true
  belongs_to :nameable, polymorphic: true
  belongs_to :account, index: true

  field :name, type: String
  symbolize :type, in: [:CNAME, :A], scopes: true, default: :CNAME
  field :ttl, type: Integer
  field :values, type: Array

  def long
    values.first
  end

  def short
    values.first.gsub(/\.#{zone.domain}$/, "")
  end

  def parts
    short.match(/^([^\d]+)(\d+)*\.(\w+)\./) do
      r = $1
      n = $2
      e = $3
      return [r, n, e]
    end
    nil
  end

  def fog_options
    if ::IPAddress.valid?(values.first)
      #A record
      {:name => name, :value => values.first, :type => 'A', :ttl => ttl || 86400}
    else
      #CNAME record
      {:name => name, :value => values.first, :type => 'CNAME', :ttl => ttl || 300}
    end
  end

  class << self
    def create_from_fog(zone, obj)
      n                = obj.name.gsub(/\.$/, "")
      record           = remote(n) || create(:zone => zone, :rid => n, :name => n)
      record.ttl       = obj.ttl
      record.type      = obj.type
      record.values    = [*obj.value].flatten
      record.synced_at = Time.now
      record.save
    end

    def find_by_record(record)
      r = Record.where(:name => record.long).first
      r ? r.nameable : nil
    end
  end
end
