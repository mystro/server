class HomeController < ApplicationController
  include ApplicationHelper
  include ActionView::Helpers::DateHelper

  before_filter :current_org

  def index
    @environments = Environment.org(session[:org]).includes(:computes, :balancers).all
    render 'environments/index'
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
    #logger.info "MYSTRO: #{mystro_selected} #{mystro_organization.data.inspect}"
    @computes = mystro_organization.compute.all || []
  end
end
