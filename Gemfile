source 'https://rubygems.org'

# server
gem 'rake', '10.1.1'
gem 'rails', '3.2.14'
gem 'unicorn', '>= 4.3.1', :group => :production
gem 'thin', '>= 1.5.0'

gem 'devise', '>= 2.1.2'
#gem 'cancan', '>= 1.6.8'
#gem 'rolify', '>= 3.2.0'

gem 'foreman'
gem 'json', '~> 1.7.7'
gem 'ipaddress'
gem "settingslogic"

# jobs
gem 'resque'
gem 'resque-scheduler', :require => 'resque_scheduler'
# and qujo

gem 'mystro-client', github: 'mystro/client', branch: 'develop'
gem 'mystro-common', github: 'mystro/common', branch: 'develop'
gem 'qujo', github: 'shawncatz/qujo', branch: 'develop'
gem 'damsel', github: 'shawncatz/damsel', branch: 'develop'

# data
gem 'mongoid', '>= 3.0.9'
gem 'bson'
gem 'bson_ext'
gem 'symbolize', :require => 'symbolize/mongoid'


# misc
gem 'highline'
gem 'yell'

gem 'scout_api'
gem 'mongo'

# ui
gem 'jquery-rails'
gem 'client_side_validations'
gem 'client_side_validations-simple_form'
group :assets do
  gem 'bootstrap-sass', '>= 2.3.0.0'
  gem 'simple_form', '>= 2.0.4'
  gem 'sass-rails', '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier', '>= 1.0.3'
  gem 'therubyracer', '>= 0.10.2', :platform => :ruby
end

group :test do
  gem 'rspec-rails', '>= 2.11.0'
  gem 'capybara', '>= 1.1.2'
  gem 'database_cleaner', '>= 0.9.1'
  gem 'mongoid-rspec', '>= 1.4.6'
  gem 'email_spec', '>= 1.2.1'
  gem 'cucumber-rails', '>= 1.3.0', :require => false
  gem 'launchy', '>= 2.1.2'
  gem 'factory_girl_rails', '>= 4.1.0'

end

group :development do
  gem 'rspec-rails', '>= 2.11.0'
  gem 'factory_girl_rails', '>= 4.1.0'
  gem 'quiet_assets', '>= 1.0.1'
  gem 'capistrano'
  gem 'capistrano-webserver'
  #gem 'capistrano-unicorn'
  gem 'awesome_print'
  gem 'cape'
  gem 'sextant'

  gem 'better_errors'
  gem 'binding_of_caller'
end
gem 'whenever'
gem 'awesome_print'

if File.exists?('config/mystro/Gemfile') then
  eval File.read('config/mystro/Gemfile'), nil, 'Gemfile.devel'
end
