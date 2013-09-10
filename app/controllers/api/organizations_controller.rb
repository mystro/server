class Api::OrganizationsController < Api::ApiController
  def index
    list = filters(Organization, :file.ne => nil).all
    respond_with(list.map(&:to_api))
  end

  def show

  end
end