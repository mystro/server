class EnvironmentsController < ApplicationController
  respond_to :json

  # GET /environments
  # GET /environments.json
  def index
    @environments = Environment.org(@current_org).includes(:computes, :balancers).all
  end

  # GET /environments/1
  # GET /environments/1.json
  def show
    @environment = Environment.where(:id => params[:id]).first ||
        Environment.where(:name => params[:id]).first ||
        raise_404
  end

  ## GET /environments/new
  ## GET /environments/new.json
  #def new
  #  @environment = Environment.new
  #  @templates = Template.active.org(@current_org).asc(:organization, :name).all
  #  @organizations = Organization.all
  #
  #  respond_to do |format|
  #    format.html # new.html.erb
  #    format.json { render json: @environment }
  #  end
  #end

  # GET /environments/1/edit
  def edit
    @environment = Environment.find(params[:id])
    @templates = Template.active.org(@current_org).asc(:organization, :name).all
    @organizations = Organization.all
  end

  # POST /environments
  # POST /environments.json
  def create
    @environment = Environment.new(params[:environment])
    @environment.organization = @current_org
    saved = @environment.save

    respond_to do |format|
      if saved
        @environment.enqueue(:create)
        format.html { redirect_to @environment, notice: 'Environment was successfully created.' }
        format.json { render json: @environment, status: :created, location: @environment }
      else
        format.html { render action: "new" }
        format.json { render json: @environment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /environments/1
  # PUT /environments/1.json
  def update
    @environment = Environment.find(params[:id])
    @environment.organization ||= @current_org
    #@templates = Template.active.org(@current_org).asc(:organization, :name).all
    #@organizations = Organization.all

    respond_to do |format|
      if @environment.update_attributes(params[:environment])
        #@environment.enqueue(:create)
        format.html { redirect_to @environment, notice: 'Environment was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @environment.errors, status: :unprocessable_entity }
      end
    end
  end

  def refresh
    @environment = Environment.find(params[:id])
    @environment.enqueue(:create)
    render json: {queued: true}
  rescue => e
    render status: :unprocessable_entity, json: {queued: false, error: e.message}
  end

  def dialog
    @environment = Environment.new
    @templates = Template.active.org(session_org).asc(:organization, :name).all
    render 'environments/dialog', layout: false
  end

  # DELETE /environments/1
  # DELETE /environments/1.json
  def destroy
    @environment = Environment.unscoped.where(:id => params[:id]).first ||
        Environment.where(:name => params[:id]).first ||
        raise_404

    raise "cannot destroy protected environment" if @environment.protected

    @environment.organization ||= @current_org
    @environment.deleting = true
    @environment.save
    @environment.enqueue(:destroy)

    respond_to do |format|
      format.html { redirect_to environments_url }
      format.json { head :no_content }
    end
  end
end
