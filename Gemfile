source 'https://rubygems.org'

# server
gem 'rails', '3.2.8'
gem "unicorn", ">= 4.3.1", :group => :production

gem "devise", ">= 2.1.2"
#gem "cancan", ">= 1.6.8"
#gem "rolify", ">= 3.2.0"

gem "foreman"
gem "json", "1.6.1" # specified to solve depedency conflict with chef

# jobs
gem "resque"
gem 'resque-scheduler', :require => 'resque_scheduler'
gem 'resque-logger'

# data
gem "mongoid", ">= 3.0.9"
gem "bson"
gem "bson_ext"
gem "symbolize", :require => "symbolize/mongoid"

# ui
gem 'jquery-rails'
gem "bootstrap-sass", ">= 2.1.0.0"
gem "simple_form", ">= 2.0.4"

# misc
gem "highline"
gem "yell"

gem "rig", :require => false
#gem "rig", :path => "/Users/Shawn/catz/rig", :require => false
gem "chef", "~> 10.16.0"
gem "scout_api"
gem "mongo"

group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier', '>= 1.0.3'
  #gem "therubyracer", ">= 0.10.2", :platform => :ruby
end

group :test do
  gem "thin", ">= 1.5.0"
  gem "rspec-rails", ">= 2.11.0"
  gem "capybara", ">= 1.1.2"
  gem "database_cleaner", ">= 0.9.1"
  gem "mongoid-rspec", ">= 1.4.6"
  gem "email_spec", ">= 1.2.1"
  gem "cucumber-rails", ">= 1.3.0", :require => false
  gem "launchy", ">= 2.1.2"
  gem "factory_girl_rails", ">= 4.1.0"

end

group :development do
  gem "thin", ">= 1.5.0"
  gem "rspec-rails", ">= 2.11.0"
  gem "factory_girl_rails", ">= 4.1.0"
  gem 'quiet_assets', ">= 1.0.1"
  gem 'capistrano'
  gem 'capistrano-webserver'
  #gem 'capistrano-unicorn'
  gem "awesome_print"
end
gem 'whenever'