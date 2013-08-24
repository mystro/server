class MystroWorker < Qujo::Queue::Resque::ScheduleWorker
  @queue = :default
  @job = "Jobs::Cloud::Update"
end
