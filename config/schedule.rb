# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

app = "mystroserver"
dir = "/srv/apps/#{app}"

set :output, "#{dir}/shared/log/cron.log"

job_type :rake, "cd :path && RAILS_ENV=:environment bundle exec rake :task --silent :output"

# log rotation
every 1.day, :at => "12:05 am" do
  command "sudo /usr/sbin/logrotate -s #{dir}/shared/log/logs.state #{dir}/current/config/logrotate.cfg"
end
