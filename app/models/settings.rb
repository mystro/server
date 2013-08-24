class Settings < Settingslogic
  source "#{Rails.root}/config/application.yml"
  namespace Rails.env
  load!
end
Settings.reload! if Rails.env.development?
