class Jobs::Environment::Destroy < Job
  def work
    model.computes.each do |c|
      c.enqueue(:destroy)
    end

    model.balancers.each do |b|
      b.enqueue(:destroy)
    end

    wait interval: 5 do
      model.computes.count > 0 && model.balancers.count > 0
    end

    model.destroy
  rescue => e
    Mystro::Log.error "failed to destroy environment: #{e.message} at #{e.backtrace.first}"
    raise
  ensure
    Mystro::Plugin.run "environment:destroy", model
  end
end