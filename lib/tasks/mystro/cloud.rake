namespace :mystro do
  namespace :cloud do
    desc "updates resources from cloud into the database, set arg true to run immediately"
    task :update, [:now] => :environment do |_, args|
      now = args.now == "true"
      Qujo.configure {|config| config.console = true}
      if now
        Jobs::Cloud::Update.create!.run
      else
        Jobs::Cloud::Update.create!.enqueue
      end
    end
  end
end
