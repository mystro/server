class ComputesController < ApplicationController
  # GET /computes
  # GET /computes.json
  def index
    @computes = filters(Compute, {account: current_user.account}).includes(:environment, :balancer) #Compute.where(account_id: mystro_account_id).all
    # for form
    @environments = Environment.asc(:name).all
    @roles = Role.external.asc(:name).all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @computes }
    end
  end

  # GET /computes/1
  # GET /computes/1.json
  def show
    @compute = Compute.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @compute }
    end
  end

  # GET /computes/new
  # GET /computes/new.json
  def new
    @compute = Compute.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @compute }
    end
  end

  # GET /computes/1/edit
  def edit
    @compute = Compute.find(params[:id])
  end

  # POST /computes
  # POST /computes.json
  def create
    roles = params[:compute].delete(:roles)
    groups = params[:compute].delete(:groups)

    @compute = Compute.new(params[:compute])
    @compute.roles = roles =~ /,/ ? roles.split(",") : [roles].compact
    @compute.groups = groups =~ /,/ ? groups.split(",") : [groups].compact
    @compute.account = mystro_account_id

    saved = @compute.save

    respond_to do |format|
      if saved
        @compute.enqueue(:create)
        format.html { redirect_to @compute, notice: 'Compute was successfully created.' }
        format.json { render json: @compute, status: :created, location: @compute }
      else
        format.html { render action: "new" }
        format.json { render json: @compute.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /computes/1
  # PUT /computes/1.json
  def update
    @compute = Compute.find(params[:id])

    respond_to do |format|
      if @compute.update_attributes(params[:compute])
        format.html { redirect_to @compute, notice: 'Compute was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @compute.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /computes/1
  # DELETE /computes/1.json
  def destroy
    @compute = Compute.unscoped.find(params[:id])
    @compute.account ||= mystro_account_id
    @compute.deleting = true
    @compute.save
    @compute.enqueue(:destroy)

    respond_to do |format|
      format.html { redirect_to computes_url }
      format.json { head :no_content }
    end
  end
end
