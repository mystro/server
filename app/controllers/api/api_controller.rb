class Api::ApiController < ApplicationController
  respond_to :json, :xml

  before_filter :api_org

  def api_org
    id = params[:organization_id] || params[:id]
    @organization = Organization.named(id) rescue nil
    respond_with({error: "must set org. '#{id}' not found or invalid"}) unless @organization
  end

end