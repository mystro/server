class Environment
  include Mongoid::Document
  include Mongoid::Timestamps

  include CommonAccount
  include CommonWorker
  include CommonDeleting

  has_many :computes
  has_many :balancers
  belongs_to :template, index: true
  belongs_to :account, index: true

  field :name, type: String
  field :protected, type: Boolean, default: false

  index({ name: 1, account: 1 }, { unique: true})

  scope :for_account, ->(account){ where(:account.in => [nil, Account.named(account).first]) }

  validates_presence_of(:name)
  validates_presence_of(:template)

  def get_next_number(name)
    (computes.where(:name => name).max(:num).to_i || 0) + 1
  end

  def old?
    a = age
    a < 0 || a > 60.minutes
  end

  def age
    @age ||= begin
      list = computes.map(&:synced_at) + balancers.map(&:synced_at)
      return -1 if list.include?(nil) || list.count == 0
      Time.now - list.min
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
        account: account ? account.name : nil,
        deleting: deleting,
        protected: protected,
        created: created_at,
        updated: updated_at,
    }
  end

  class << self
    def create_from_fog(tags)
      # since environments don't actually exist in the cloud, except as meta data,
      # this is here for convenience
      if tags.is_a?(String)
        name = tags
        account = "unknown"
      else
        name = tags["Environment"]
        account = tags["Account"] || "unknown"
      end
      a = Account.named(account).first
      e = Environment.where(name: name, account: a).first ||
          Environment.where(:name => name).first ||
          Environment.create(name: name, account: account)
      unless e.account
        e.account = a
        e.save
      end
      e
    end
  end
end
