module ApplicationHelper
  def server_version
    @server_version ||= File.read("#{Rails.root}/VERSION").lines.first.chomp
  end

  def current_account
    @current_account ||= current_user.account
  end

  def current_account_load
    @current_account_load ||= Account.named(current_account).first
  end
end
