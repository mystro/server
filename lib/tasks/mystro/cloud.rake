namespace :mystro do
  def cloud_pull
    MystroWorker.perform
  rescue => e
    puts "error: #{e.message} at #{e.backtrace.first}"
  end

  namespace :cloud do
    desc "updates resources from cloud into the database"
    task :update => :environment do
      puts ".. loading cloud resources"
      cloud_pull
    end
  end
end
