require 'resque/server'

class Authentication
  def initialize(app)
    @app = app
  end

  def call(env)
    env['warden'].authenticate!(:database_authenticatable, :rememberable, :scope => :user)
    @app.call(env)
  end
end

Resque.logger = Yell.new do |l|
  #:datefile, File.join(Rails.root, "log", "workers.log"), level: [:info, :warn, :error, :fatal]
  l.level = [:info, :warn, :error, :fatal]
  l.adapter :datefile, File.join(Rails.root, "log", "workers.log"), level: [:info, :warn, :error, :fatal]
end

# reload worker code
# https://github.com/defunkt/resque/issues/447
unless Rails.application.config.cache_classes
  Resque.after_fork do |job|
    ActionDispatch::Reloader.cleanup!
    ActionDispatch::Reloader.prepare!
  end
end

Resque::Server.use Authentication
Resque.redis.namespace = "resque:Mystro"


