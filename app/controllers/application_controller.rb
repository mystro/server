class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_filter :set_locale #http://guides.rubyonrails.org/i18n.html
  before_filter :authenticate_user!
  before_filter :set_time_zone

  before_filter :current_org

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

  def set_time_zone
    Time.zone = current_user.time_zone if current_user
  end

  def session_org
    session[:org] ||= "ops"
  end

  def current_org
    @organization ||= Organization.named(session_org)
  end

  #def set_organization
  #  @current_org = current_org
  #end

  def filters(model, options={})
    q = model.scoped

    if options[:organization]
      o = options.delete(:organization)
      if o
        q = q.where(organization: o)
      end
    end

    options.each do |k, v|
      q = q.where(k => v)
    end

    q
  end

  def raise_404
    raise ActionController::RoutingError.new('Not Found')
  end
end
