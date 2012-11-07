class BalancersController < ApplicationController
  # GET /balancers
  # GET /balancers.json
  def index
    @balancers = Balancer.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @balancers }
    end
  end

  # GET /balancers/1
  # GET /balancers/1.json
  def show
    @balancer = Balancer.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @balancer }
    end
  end

  # GET /balancers/new
  # GET /balancers/new.json
  def new
    @balancer = Balancer.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @balancer }
    end
  end

  # GET /balancers/1/edit
  def edit
    @balancer = Balancer.find(params[:id])
  end

  # POST /balancers
  # POST /balancers.json
  def create
    @balancer = Balancer.new(params[:balancer])

    respond_to do |format|
      if @balancer.save
        format.html { redirect_to @balancer, notice: 'Balancer was successfully created.' }
        format.json { render json: @balancer, status: :created, location: @balancer }
      else
        format.html { render action: "new" }
        format.json { render json: @balancer.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /balancers/1
  # PUT /balancers/1.json
  def update
    @balancer = Balancer.find(params[:id])

    respond_to do |format|
      if @balancer.update_attributes(params[:balancer])
        format.html { redirect_to @balancer, notice: 'Balancer was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @balancer.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /balancers/1
  # DELETE /balancers/1.json
  def destroy
    @balancer = Balancer.find(params[:id])
    @balancer.deleting = true
    @balancer.save
    @balancer.enqueue(:destroy)

    respond_to do |format|
      format.html { redirect_to balancers_url }
      format.json { head :no_content }
    end
  end
end
