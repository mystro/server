class ComputesController < ApplicationController
  # GET /computes
  # GET /computes.json
  def index
    @computes = filters(Compute, {account_id: mystro_account_id}).includes(:environment, :balancer) #Compute.where(account_id: mystro_account_id).all
    # for form
    @environments = Environment.all
    @roles = Role.external.all.sort(name: 1)

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

  def search
    patterns = (params[:pattern]||"").split(",")
    data = Compute.asc(:account_id, :environment_id).all
    #data = list.map {|e| {id: e.id, name: e.display}}
    patterns.each do |pattern|
      p = Regexp.escape(pattern)
      data = data.reject do |e|
        logger.info "PATTERN: #{e.display} !~ /#{p}/"
        e.display !~ /#{p}/
      end
    end
    out = data.map do |e|
      {
          id: e.id,
          name: e.display,
          long: (e.long rescue nil),
          dns: e.public_dns,
          ip: e.public_ip,
          environment: e.environment ? e.environment.name : nil,
          account: e.account ? e.account.name : nil,
          roles: e.roles_string
      }
    end
    render json: out, status: :ok
  end
end
