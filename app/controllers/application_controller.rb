class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :set_locale #http://guides.rubyonrails.org/i18n.html
  before_filter :authenticate_user!
  before_filter :set_time_zone

  protected

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

  def set_time_zone
    Time.zone = current_user.time_zone if current_user
  end

  def raise_404
    raise ActionController::RoutingError.new('Not Found')
  end
end
