namespace :mystro do
  namespace :files do
    desc "load mystro configuration files to database"
    task :load => :environment do
      Rake::Task["mystro:files:accounts"].invoke
      Rake::Task["mystro:files:templates"].invoke
    end
    task :accounts => :environment do
      puts ".. loading accounts ..."
      files = Dir["config/mystro/accounts/*"]
      files.each do |file|
        name = File.basename(file).gsub(/\.yml/, "")
        a = Account.create(:name => name, :file => file)
        d = a.load
        a.data = d
        a.save
        puts ".. create #{name} #{file}"
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
end