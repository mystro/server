namespace :mystro do
  namespace :cloud do
    desc "updates resources from cloud into the database"
    task :update, [:now] => :environment do |_, args|
      now = args.now == "true"
      if now
        Jobs::Cloud::Update.create!.run
      else
        Jobs::Cloud::Update.create!.enqueue
      end
    end
  end
end
