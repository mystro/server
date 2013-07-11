This application was generated with the "rails_apps_composer":https://github.com/RailsApps/rails_apps_composer gem provided by the "RailsApps Project":http://railsapps.github.com/.

h2. Diagnostics

This application was built with recipes that are known to work together.

This application was built with preferences that are NOT known to work together.

If the application doesn't work as expected, please "report an issue":https://github.com/RailsApps/rails_apps_composer/issues and include these diagnostics:

We'd also like to know if you've found combinations of recipes or preferences that do work together.

Recipes:
["controllers", "core", "email", "extras", "frontend", "gems", "git", "init", "models", "prelaunch", "railsapps", "readme", "routes", "setup", "testing", "views"]

Preferences:
{:git=>true, :railsapps=>"none", :dev_webserver=>"webrick", :prod_webserver=>"unicorn", :database=>"mongodb", :orm=>"mongoid", :templates=>"erb", :unit_test=>"rspec", :integration=>"cucumber", :fixtures=>"factory_girl", :frontend=>"bootstrap", :bootstrap=>"sass", :email=>"none", :authentication=>"devise", :devise_modules=>"default", :authorization=>"cancan", :form_builder=>"simple_form", :starter_app=>"home_app", :quiet_assets=>true, :ban_spiders=>true}

h2. Ruby on Rails

This application requires:

* Ruby version 1.9.3
* Rails version 3.2.8

Learn more about "Installing Rails":http://railsapps.github.com/installing-rails.html.

h2. Database

This application uses MongoDB with the Mongoid ORM.

h2. Development

* Template Engine: ERB
* Testing Framework: RSpec and Factory Girl and Cucumber
* Front-end Framework: Twitter Bootstrap (Sass)
* Form Builder: SimpleForm
* Authentication: Devise
* Authorization: CanCan