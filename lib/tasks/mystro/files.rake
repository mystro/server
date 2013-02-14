namespace :mystro do
  namespace :files do
    desc "load mystro configuration files to database"
    task :load => :environment do
      Rake::Task["mystro:files:accounts"].invoke
      Rake::Task["mystro:files:templates"].invoke
    end
    task :accounts => :environment do
      puts ".. loading accounts ..."
      Account.update_all(enabled: false)
      files = Dir["config/mystro/accounts/*"]
      files.each do |file|
        name = File.basename(file).gsub(/\.yml/, "")
        a = Account.find_or_create_by(:name => name, :file => file)
        a.enabled = true
        d = a.load
        a.data = d
        a.save
        puts ".. create #{name} #{file}"
      end
    end
    task :templates => :environment do
      puts ".. loading templates..."
      Template.update_all(enabled: false)
      dir = "config/mystro/templates"
      files = Dir["#{dir}/**/*"].select {|e| File.file?(e)}.map {|e| e.gsub("#{dir}/", "")}
      files.each do |file|
        name = File.basename(file).gsub(/\.rb/, "")
        f = "#{dir}/#{file}"
        an = file =~ /\// ? file.split("/").first : nil
        t = Template.find_or_create_by(:name => name, :file => f)
        t.enabled = true
        t.account = Account.named(an).first if an
        d = JSON.parse(t.load.to_json)
        t.data = d
        t.save
        puts ".. create #{name} #{file}"
      end
    end
  end
end