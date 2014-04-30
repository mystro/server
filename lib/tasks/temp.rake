namespace :temp do
  task :keys do
    cfg = Mystro.config
    pro = Mystro::Provider.get('aws')
    iam = Fog::AWS::IAM.new(aws_access_key_id: pro.data['aws_access_key_id'], aws_secret_access_key: pro.data['aws_secret_access_key'])
    users = iam.users
    puts "users: #{users.count}"
    list = users.map {|e| {id: e.id, arn: e.arn, keys: e.access_keys.map {|e| e.id}.join("\n")}}
    puts Mystro::CLI.list(%w{id keys}, list)
  end
end