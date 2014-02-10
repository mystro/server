namespace :mystro do
  task :deploy => :environment do
    Settings.deploy.update.each do |name|
      sh "bundle update #{name}"
    end
    sh "git add ."
    sh "git commit -am 'deploy'"
    sh "cap deploy"
  end
end