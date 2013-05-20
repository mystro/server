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

#log_path = File.join Rails.root, 'log'
#config = {
#    folder:     log_path,                 # destination folder
#    class_name: Logger,                   # logger class name
#    class_args: [ 'daily' ],  # logger additional parameters
#    level:      Logger::INFO,             # optional
#    formatter:  Logger::Formatter.new,    # optional
#}
#Resque.logger = config

#Resque.logger = Logger.new(File.join(Rails.root, "log", "resque"))
Resque.logger = Yell.new :datefile, File.join(Rails.root, "log", "workers.log")

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


