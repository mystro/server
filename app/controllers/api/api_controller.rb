class Api::ApiController < ApplicationController
  respond_to :json, :xml

  before_filter :api_account

  def api_account
    id = params[:account_id] || params[:id]
    @account = Account.named(id) rescue nil
    respond_with({error: "must set account. '#{id}' not found or invalid"}) unless @account
  end

end