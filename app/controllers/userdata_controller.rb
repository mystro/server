class UserdataController < ApplicationController
  # GET /userdata
  # GET /userdata.json
  def index
    @userdatas = Userdata.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @userdata }
    end
  end

  # GET /userdata/1
  # GET /userdata/1.json
  def show
    @userdata = Userdata.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @userdata }
    end
  end

  # GET /userdata/new
  # GET /userdata/new.json
  def new
    @userdata = Userdata.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @userdata }
    end
  end

  # GET /userdata/1/edit
  def edit
    @userdata = Userdata.find(params[:id])
  end

  # POST /userdata
  # POST /userdata.json
  def create
    @userdata = Userdata.new(params[:userdata])

    respond_to do |format|
      if @userdata.save
        format.html { redirect_to @userdata, notice: 'Userdata was successfully created.' }
        format.json { render json: @userdata, status: :created, location: @userdata }
      else
        format.html { render action: "new" }
        format.json { render json: @userdata.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /userdata/1
  # PUT /userdata/1.json
  def update
    @userdata = Userdata.find(params[:id])

    respond_to do |format|
      if @userdata.update_attributes(params[:userdata])
        format.html { redirect_to @userdata, notice: 'Userdata was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @userdata.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /userdata/1
  # DELETE /userdata/1.json
  def destroy
    @userdata = Userdata.find(params[:id])
    @userdata.destroy

    respond_to do |format|
      format.html { redirect_to userdata_index_url }
      format.json { head :no_content }
    end
  end
end
