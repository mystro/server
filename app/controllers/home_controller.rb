class HomeController < ApplicationController
  def index
    @computes = Rig::Model::Instance.all || []
  rescue => e
    logger.error "ERROR: #{e.message}"
    e.backtrace.each {|b| logger.error b}
  end
end
