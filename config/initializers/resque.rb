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

log_path = File.join Rails.root, 'log'
config = {
    folder:     log_path,                 # destination folder
    class_name: Yell,                     # logger class name
    class_args: [],              # logger additional parameters
}
Resque.logger = config

# reload worker code
# https://github.com/defunkt/resque/issues/447
unless Rails.application.config.cache_classes
  Resque.after_fork do |job|
    ActionDispatch::Reloader.cleanup!
    ActionDispatch::Reloader.prepare!
  end
end

Resque::Server.use Authentication