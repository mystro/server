class HomeController < ApplicationController
  include ApplicationHelper
  include ActionView::Helpers::DateHelper

  def index
    @environments = Environment.for_account(current_user.account).asc(:name)
  rescue => e
    logger.error "ERROR: #{e.message}"
    e.backtrace.each {|b| logger.error b}
    flash.now[:error] = "problem with getting computes: #{e.message}"
    @computes = []
  end

  def widget
    @environment = Environment.named(params[:environment])
    render "widget", layout: false
  end

  def raw
    #logger.info "MYSTRO: #{mystro_selected} #{mystro_account.data.inspect}"
    @computes = mystro_account.compute.all || []
  end
end
