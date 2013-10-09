class ComputesController < ApplicationController
  # GET /computes
  # GET /computes.json
  def index
    @computes = Compute.org(session[:org]).includes(:environment, :balancer)

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
    groups = params[:compute].delete(:groups)

    logger.info "groups: #{groups.class} #{groups.inspect}"

    @compute         = Compute.new(params[:compute])
    @compute.groups  = case groups
                         when String
                           groups.split(",")
                         when Array
                           [groups].compact.flatten.reject(&:empty?)
                         else
                           raise "don't know class type"
                       end
    @compute.organization = Organization.named(session[:org])

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

    changed = nil
    if @compute.balancer && params[:compute]["balancer_id"] == ""
      @compute.balancer.enqueue(:remove, { rid: @compute.rid })
    elsif !@compute.balancer && params[:compute]["balancer_id"] && !params[:compute]["balancer_id"].blank?
      changed = :add
    end

    respond_to do |format|
      if @compute.update_attributes(params[:compute])
        if changed
          @compute.balancer.enqueue(changed, { rid: @compute.rid })
        end

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
    @compute          = Compute.unscoped.find(params[:id])
    @compute.organization  ||= Organization.named(session[:org])
    @compute.deleting = true
    @compute.save
    @compute.enqueue(:destroy)

    respond_to do |format|
      format.html { redirect_to computes_url }
      format.json { head :no_content }
    end
  end

  def dialog
    @type = params[:type]
    @org = Organization.named(session[:org])
    @env = params[:environment] ? Environment.named(params[:environment]) : nil

    if @type == "general"
      @compute = Compute.new
      @compute.set_defaults(@org)
    else
      num = @env.get_next_number(@type)
      cloud = @env.template.load.compute(@type)
      @compute = Compute.new(name: @type, num: num)
      @compute.set_defaults(@org)
      logger.info "CLOUD: #{cloud.to_yaml}"
      @compute.from_cloud(cloud)
      @compute.num = num
      logger.info "compute: #{@compute.display} : #{@compute.to_yaml}"
    end

    @compute.environment = @env if @env
    @selectors = {
        regions: @org.selectors.regions,
        flavors: @org.selectors.flavors,
        images: @org.selectors_images,
        groups: @org.selectors.groups,
        keypairs: @org.selectors.keypairs,
    }
    @environments = Environment.for_org(session[:org]).asc(:name).all
    @balancers = Balancer.for_org(session[:org]).asc(:name).all
    @roles = Role.external.asc(:name).all
    @userdata = Userdata.all
    render 'dialog', layout: false
  end
end
