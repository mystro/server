namespace :mystro do
  namespace :account do
    task :unknown do
      Account.find_or_create_by(name: "unknown")
    end
  end
end