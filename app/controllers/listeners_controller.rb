class ListenersController < ApplicationController
  # GET /listeners
  # GET /listeners.json
  def index
    @listeners = Listener.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @listeners }
    end
  end

  # GET /listeners/1
  # GET /listeners/1.json
  def show
    @listener = Listener.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @listener }
    end
  end

  # GET /listeners/new
  # GET /listeners/new.json
  def new
    @listener = Listener.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @listener }
    end
  end

  # GET /listeners/1/edit
  def edit
    @listener = Listener.find(params[:id])
  end

  # POST /listeners
  # POST /listeners.json
  def create
    @listener = Listener.new(params[:listener])

    respond_to do |format|
      if @listener.save
        format.html { redirect_to @listener, notice: 'Listener was successfully created.' }
        format.json { render json: @listener, status: :created, location: @listener }
      else
        format.html { render action: "new" }
        format.json { render json: @listener.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /listeners/1
  # PUT /listeners/1.json
  def update
    @listener = Listener.find(params[:id])

    respond_to do |format|
      if @listener.update_attributes(params[:listener])
        format.html { redirect_to @listener, notice: 'Listener was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @listener.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /listeners/1
  # DELETE /listeners/1.json
  def destroy
    @listener = Listener.find(params[:id])
    @listener.destroy

    respond_to do |format|
      format.html { redirect_to listeners_url }
      format.json { head :no_content }
    end
  end
end
