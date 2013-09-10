namespace :mystro do
  namespace :organization do
    task :unknown do
      Organization.find_or_create_by(name: "unknown")
    end
  end
end