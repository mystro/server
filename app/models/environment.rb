class Environment
  include Mongoid::Document
  include Mongoid::Timestamps
  include Qujo::Concerns::Model

  include Org
  include Named
  include Deleting

  has_many :computes
  has_many :balancers
  belongs_to :template, index: true
  belongs_to :organization, index: true

  field :name, type: String
  field :protected, type: Boolean, default: false

  validates_presence_of(:name)
  validates_presence_of(:template)

  index({ name: 1 })
  index({ name: 1, organization: 1 }, { unique: true})

  scope :for_org, ->(org) {where(:organization.in =>  [nil, Organization.named(org)])}

  def display
    name
  end

  def get_next_number(name)
    (computes.where(:name => name).max(:num).to_i || 0) + 1
  end

  def old?
    a = age
    a < 0 || a > 8.hours # TODO: make this (and schedule) configurable.
  end

  def age
    @age ||= begin
      list = computes.map(&:synced_at) + balancers.map(&:synced_at)
      return -1 if list.include?(nil) || list.count == 0
      Time.now - list.min
    end
  end

  def records
    @records ||= [computes.map(&:records) + balancers.map(&:records)].flatten
  end

  def records_count
    @records_count ||= records.count
  end

  def versions
    @versions ||= begin
      out = []
      computes.each do |c|
        out += c.versions
      end
      out.flatten.uniq
    end
  end

  def as_json(options={})
    j = super(:include => [:computes, :balancers])
    j[:age] = age
    j
  end

  def to_api
    {
        id: id,
        age: age,
        name: name,
        template: template ? template.name : nil,
        computes: computes.count,
        balancers: balancers.count,
        organization: organization ? organization.name : nil,
        deleting: deleting,
        protected: protected,
        created: created_at,
        updated: updated_at,
    }
  end

  class << self
    def named(name)
      where(name: name).first
    end
    def create_from_cloud(tags)
      # since environments don't actually exist in the cloud, except as meta data,
      # this is here for convenience
      if tags.is_a?(String)
        name = tags
        organization = 'unknown'
      else
        name = tags['Environment'] || 'unknown'
        organization = tags['Organization'] || tags['Account'] || 'unknown'
      end
      return nil unless name
      a = Organization.named(organization)
      e = Environment.where(name: name, organization: a).first ||
          Environment.create!(name: name, organization: a, template: Template.named('empty'))
      unless e.organization
        e.organization = a
        e.save
      end
      e
    end
  end
end
