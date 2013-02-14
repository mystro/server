# ------------------------------------------------------------------------------
# Sample rails 3 config
# Shoule bd placed in config/unicorn/
# ------------------------------------------------------------------------------

# Set your full path to application.
app      = "mystro"
app_path = "/srv/apps/#{app}/current"

# Set unicorn options
worker_processes 1
preload_app true
timeout 60
listen "/tmp/#{app}.unicorn.sock", :backlog => 64
listen 6000, :tcp_nopush => true


# Spawn unicorn master worker for user apps (group: apps)
#user 'deploy', 'users'

# Fill path to your app
working_directory app_path

# Should be 'production' by default, otherwise use other env
rails_env = ENV['RAILS_ENV'] || 'production'

# Log everything to one file
stderr_path "log/unicorn.log"
stdout_path "log/unicorn.log"

# combine Ruby 2.0.0dev or REE with "preload_app true" for memory savings
# http://rubyenterpriseedition.com/faq.html#adapt_apps_for_cow
preload_app true
GC.respond_to?(:copy_on_write_friendly=) and GC.copy_on_write_friendly = true

# Set master PID location
pid "#{app_path}/tmp/pids/unicorn.pid"

before_fork do |server, worker|
  ActiveRecord::Base.connection.disconnect!

  old_pid = "#{server.config[:pid]}.oldbin"
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
end

after_fork do |server, worker|
  ActiveRecord::Base.establish_connection
end