class ChefWorker < BaseWorker
  @queue = :low

  class << self
    def perform
      list = Mystro::Plugin::Chef.role_list
      logger.info "#{self.name} found #{list.count} roles"
      list.each do |e|
        name = e["name"]
        d = {
            description: e["description"],
            internal: ! e["description"].match(/^internal/i).nil?
        }
        r = Role.where(name: name).first || Role.create(name: name)
        r.update_attributes(d)
        r
      end
      logger.info "#{self.name} complete"
    end
  end
end