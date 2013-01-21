class Api::EnvironmentsController < Api::ApiController

  # GET /api/accounts/:account_id/environments
  def index
    list = filters(Environment, { account_id: @account.id }).includes(:computes, :balancers).all
    out  = list.map(&:to_api)
    respond_with(out)
  end

  # GET /api/accounts/:account_id/environments/:id
  def show
    # use where(:id => ?) instead of find, because it throws an exception
    @environment = Environment.where(id: params[:id], account_id: @account.id).first ||
        Environment.where(name: params[:id], account_id: @account.id).first ||
        raise_404
    respond_with(@environment.to_api)
  end

  # POST /api/accounts/:account_id/environments
  def create
    @environment         = Environment.new(name: params[:name])
    @environment.account = @account
    @environment.template = Template.where(name: params[:template]).first || nil rescue nil
    @environment.protected = params[:protected]

    saved = @environment.save

    if saved
      @environment.enqueue(:create)
      render json: @environment, status: :created, location: @environment
    else
      render json: @environment.errors, status: :unprocessable_entity
    end
  end

  # PUT /api/accounts/:account_id/environments/:id
  def update

  end

  # DELETE /api/accounts/:account_id/environments/:id
  def destroy
    @environment = Environment.unscoped.where(:id => params[:id]).first ||
        Environment.where(:name => params[:id]).first ||
        raise_404

    raise "cannot destroy protected environment" if @environment.protected

    @environment.account ||= mystro_account_id
    @environment.deleting = true
    @environment.save
    #@environment.enqueue(:destroy)
    head :no_content
  end
end