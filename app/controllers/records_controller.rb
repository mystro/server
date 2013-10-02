class RecordsController < ApplicationController
  # GET /records
  # GET /records.json
  def index
    @records = Record.org(session[:org])

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @records }
    end
  end

  # GET /records/1
  # GET /records/1.json
  def show
    @record = Record.find(params[:id])
    @nameable = @record.nameable

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @record }
    end
  end

  # GET /records/new
  # GET /records/new.json
  def new
    @record = Record.new
    @record.organization = mystro_organization_id

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @record }
    end
  end

  # GET /records/1/edit
  def edit
    @record = Record.find(params[:id])
  end

  # POST /records
  # POST /records.json
  def create
    data = params[:record]
    values = data.delete(:values).split(",")
    @record = Record.new(data)
    @record.values = values
    if @record.zone
      @record.name = @record.name + ".#{@record.zone.domain}"
    else
      @record.name = @record.name + ".#{mystro_organization.data.dns.zone}"
    end
    @record.organization = mystro_organization_id

    respond_to do |format|
      if @record.save
        @record.enqueue(:create)
        format.html { redirect_to @record, notice: 'Record was successfully created.' }
        format.json { render json: @record, status: :created, location: @record }
      else
        format.html { render action: "new" }
        format.json { render json: @record.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /records/1
  # PUT /records/1.json
  def update
    @record = Record.find(params[:id])

    respond_to do |format|
      if @record.update_attributes(params[:record])
        @record.enqueue(:update)
        format.html { redirect_to @record, notice: 'Record was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @record.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /records/1
  # DELETE /records/1.json
  def destroy
    @record = Record.unscoped.find(params[:id])
    @record.organization ||= mystro_organization_id
    @record.deleting = true
    @record.save
    @record.enqueue(:destroy)

    respond_to do |format|
      format.html { redirect_to records_url }
      format.json { head :no_content }
    end
  end
end
