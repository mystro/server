namespace :mystro do
  namespace :files do
    desc "load mystro configuration files to database"
    task :load => :environment do
      Rake::Task["rigserver:files:templates"].invoke
    end
  end
  task :templates => :environment do
    puts ".. loading templates..."
    files = Dir["config/mystro/templates/*"]
    files.each do |file|
      name = File.basename(file).gsub(/\.rb/, "")
      t = Template.create(:name => name, :file => file)
      d = JSON.parse(t.load.to_json)
      t.data = d
      t.save
      puts ".. create #{name} #{file}"
    end
  end
end