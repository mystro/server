class Api::AccountsController < Api::ApiController
  def index
    list = filters(Account, :file.ne => nil).all
    respond_with(list.map(&:to_api))
  end

  def show

  end
end