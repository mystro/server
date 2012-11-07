class Environment
  include Mongoid::Document
  include Mongoid::Timestamps

  include CommonWorker
  include CommonDeleting

  has_many :computes
  has_many :balancers
  belongs_to :template, index: true

  field :name, type: String
  field :protected, type: Boolean

  index({ name: 1 }, { unique: true})

  def get_next_number(name)
    (computes.where(:name => name).max(:num).to_i || 0) + 1
  end

  class << self
    def create_from_fog(name)
      # since environments don't actually exist in the cloud, except as meta data,
      # this is here for convenience
      Environment.where(:name => name).first || Environment.create(:name => name)
    end
  end
end
