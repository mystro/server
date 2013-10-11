require 'highline/import'

namespace :mystro do

  def create_user
    user     = ask "Administrator name:  "
    email    = ask "Administrator email: "
    password = ask("password:            ") { |q| q.echo = "*" }
    confirm  = ask("confirm:             ") { |q| q.echo = "*" }
    opts     = {
        :name                  => user,
        :email                 => email,
        :password              => password,
        :password_confirmation => confirm
    }
    puts "creating user: #{user} <#{email}>"
    User.create(opts)
  rescue => e
    puts "error: #{e.message} at #{e.backtrace.first}"
  end

  namespace :user do
    desc "create a new user in the database"
    task :create => :environment do
      puts ".. creating user"
      create_user
    end
    task :admin => :environment do
      name = "Admin"
      email = "admin@localhost.com"
      pass = "t0wn3end"
      puts "creating user admin: #{email} / #{pass}"
      User.create(name: name, email: email, password: pass, password_confirmation: pass)
    end
  end
end
