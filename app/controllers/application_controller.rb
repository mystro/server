class ApplicationController < ActionController::Base
  include ApplicationHelper

  protect_from_forgery

  before_filter :set_locale #http://guides.rubyonrails.org/i18n.html
  before_filter :authenticate_user!
  before_filter :set_time_zone
  #before_filter :mystro_selected

  #before_filter :job_errors
  #before_filter :resque_workers

  protected

  def resque_workers
    flash.now[:error] = "Resque workers are not running" if Resque.workers.count == 0
  end

  def job_errors
    flash.now[:error] = "There are jobs with errors" if Job.errors?
  end

  def filters(model, options={})
    q = model.scoped

    if options[:account]
      a = options.delete(:account)
      unless a == "everything"
        q = q.where(account_id: Account.named(a).id)
      end
    end

    options.each do |k, v|
      q = q.where(k => v)
    end

    q
  end

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

  def set_time_zone
    Time.zone = current_user.time_zone if current_user
  end

  def mystro_selected
    ( current_user ? current_user.account : nil ) || Mystro::Account.selected
  end

  def mystro_account
    Mystro::Account.list[mystro_selected]
  end

  def mystro_account_id
    account = Account.where(name: mystro_selected).first
    account.id if account
  end

  def enqueue(object, action, options={})
    o = {"user" => current_user, "account" => current_user.account}.merge(options)
    object.enqueue(action, o)
  end

  def raise_404
    raise ActionController::RoutingError.new('Not Found')
  end
end
