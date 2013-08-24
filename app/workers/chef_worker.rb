class ChefWorker < Qujo::Queue::Resque::ScheduleWorker
  @queue = :default
  @job = "Jobs::Chef::Roles"
end
