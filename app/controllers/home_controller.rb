class HomeController < ApplicationController
  def index
    @computes = Mystro.compute.all || []
  rescue => e
    logger.error "ERROR: #{e.message}"
    e.backtrace.each {|b| logger.error b}
  end
end
