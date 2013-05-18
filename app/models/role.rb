class Role
  include Mongoid::Document
  include Mongoid::Timestamps

  has_and_belongs_to_many :computes

  field :name, type: String
  field :description, type: String
  field :internal, type: Boolean, default: true
  field :deployable, type: Boolean, default: false

  index({ name: 1 }, { unique: true, background: true })

  scope :external, where(internal: false)
  scope :internal, where(internal: true)
  scope :deployable, where(deployable: true)

  class << self
    def create_from_fog(roles)
      out   = []
      return out unless roles
      rlist =
          case roles.class.name
            when "String"
              (roles || "").split(",")
            when "Array"
              roles
            else
              raise "role: create_from_fog: unknown type for roles [#{roles.class}]: #{roles.inspect}"
          end
      rlist.each do |r|
        out << Role.where(name: r).first || Role.create(name: r)
      end
      out
    end
  end
end
