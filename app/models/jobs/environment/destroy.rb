class Jobs::Environment::Destroy < Job
  def work
    model.computes.each do |c|
      c.enqueue(:destroy)
    end
    model.balancers.each do |b|
      b.enqueue(:destroy)
    end
  ensure
    Mystro::Plugin.run "environment:destroy", model
    model.destroy
  end
end