set :rails_env, "production"
set :server_name, "rig.ops.env.inqlabs.com"

role :web, server_name
role :app, server_name
role :db,  server_name, :primary => true
