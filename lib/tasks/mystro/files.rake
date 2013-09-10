namespace :mystro do
  namespace :files do
    desc "load mystro configuration files to database"
    task :load => :environment do
      Rake::Task["mystro:files:providers"].invoke
      Rake::Task["mystro:files:organizations"].invoke
      Rake::Task["mystro:files:userdata"].invoke
      Rake::Task["mystro:files:templates"].invoke
    end
    task :organizations => :environment do
      puts ".. loading organizations ..."
      Organization.update_all(enabled: false)
      files = Dir["config/mystro/organizations/*"]
      files.each do |file|
        name = File.basename(file).gsub(/\.yml/, "")
        a = Organization.find_or_create_by(:name => name, :file => file)
        a.enabled = true
        d = a.load
        a.data = d
        a.save
        puts ".. .. create #{name} #{file}"
        if d["dns"] && d["dns"]["zone"]
          z = d["dns"]["zone"]
          puts ".. .. .. create zone: #{z}"
          Zone.create(domain: z)
        end
      end
    end
    task :providers => :environment do
      puts ".. loading providers ..."
      #Provider.update_all(enabled: false)
      files = Dir["config/mystro/providers/*"]
      files.each do |file|
        name = File.basename(file).gsub(/\.yml/, "")
        p = Provider.find_or_create_by(:name => name, :file => file)
        d = p.load
        p.data = d
        p.save
        puts ".. .. create #{name} #{file}"
      end
    end
    task :userdata => :environment do
      puts ".. loading userdata packages ..."
      Userdata.update_all(enabled: false)
      base = "config/mystro/userdata"
      dirs = Dir["#{base}/*"].map {|e| e.gsub("#{base}/", "")}
      dirs.each do |name|
        userdata = Userdata.find_or_create_by(name: name)
        puts ".. create #{name}"

        files = Dir["#{base}/#{name}/*"]

        if File.exists?("#{base}/#{name}/userdata.sh.erb")
          puts ".. .. #{base}/#{name}/userdata.sh.erb"
          files.delete("#{base}/#{name}/userdata.sh.erb")
          userdata.script = File.read("#{base}/#{name}/userdata.sh.erb")
        end

        if File.exists?("#{base}/#{name}/userdata.yml")
          puts ".. .. #{base}/#{name}/userdata.yml"
          files.delete("#{base}/#{name}/userdata.yml")
          userdata.data = YAML.load_file("#{base}/#{name}/userdata.yml")
        end

        userdata.files = []

        files.each do |file|
          puts ".. .. #{file}"
          userdata.files << file
        end

        userdata.enabled = true
        userdata.save!
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
        t.organization = Organization.named(an) if an
        d = JSON.parse(t.load.to_json)
        t.data = d
        t.save
        puts ".. create #{name} #{file}"
      end
    end
  end
end
