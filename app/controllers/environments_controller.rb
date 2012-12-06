class EnvironmentsController < ApplicationController
  # GET /environments
  # GET /environments.json
  def index
    @environments = filters(Environment, {account_id: mystro_account_id}).all
    @templates = Template.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @environments }
    end
  end

  # GET /environments/1
  # GET /environments/1.json
  def show
    # use where(:id => ?) instead of find, because it throws an exception
    @environment = Environment.where(:id => params[:id]).first ||
        Environment.where(:name => params[:id]).first ||
        raise_404

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @environment }
    end
  end

  # GET /environments/new
  # GET /environments/new.json
  def new
    @environment = Environment.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @environment }
    end
  end

  # GET /environments/1/edit
  def edit
    @environment = Environment.find(params[:id])
  end

  # POST /environments
  # POST /environments.json
  def create
    @environment = Environment.new(params[:environment])
    @environment.account = mystro_account_id
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
    @environment.account_id ||= mystro_account_id

    respond_to do |format|
      if @environment.update_attributes(params[:environment])
        @environment.enqueue(:create)
        format.html { redirect_to @environment, notice: 'Environment was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @environment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /environments/1
  # DELETE /environments/1.json
  def destroy
    @environment = Environment.unscoped.where(:id => params[:id]).first ||
        Environment.where(:name => params[:id]).first ||
        raise_404

    raise "cannot destroy protected environment" if @environment.protected

    @environment.account ||= mystro_account_id
    @environment.deleting = true
    @environment.save
    @environment.enqueue(:destroy)

    respond_to do |format|
      format.html { redirect_to environments_url }
      format.json { head :no_content }
    end
  end
end
