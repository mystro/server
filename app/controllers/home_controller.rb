class HomeController < ApplicationController
  def index
    logger.info "MYSTRO: #{mystro_selected} #{mystro_account.data.inspect}"
    @computes = mystro_account.compute.all || []
  rescue => e
    logger.error "ERROR: #{e.message}"
    e.backtrace.each {|b| logger.error b}
    flash.now[:error] = "problem with getting computes: #{e.message}"
    @computes = []
  end
end
