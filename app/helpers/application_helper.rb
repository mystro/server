module ApplicationHelper
  def server_version
    @server_version ||= File.read("#{Rails.root}/VERSION").lines.first.chomp
  end

  def current_account_name
    @current_account_name ||= current_user.account
  end

  def current_account
    @current_account ||= Account.named(current_user.account)
  end
end
