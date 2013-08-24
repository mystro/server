require 'qujo/queue/resque'
require 'qujo/database/mongoid'

Qujo.configure do |config|
  config.logger = Yell.new do |l|
    l.level = [:info, :warn, :error, :fatal]
    #if Rails.env.development?
    #  l.adapter STDOUT
    #end
    l.adapter :file, File.join(Rails.root, "log", "qujo.log")
  end
end
