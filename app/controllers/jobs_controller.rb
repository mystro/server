class JobsController < ApplicationController
  # GET /jobs
  # GET /jobs.json
  def index
    #@jobs = Job.all
    q = Job.scoped
    q = q.unscoped
    @jobs = q.active.desc(:created_at).all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @jobs }
    end
  end

  # GET /jobs/errors
  # GET /jobs/errors.json
  def errors
    #@jobs = Job.all
    q = Job.scoped
    @jobs = q.errors.desc(:created_at).all

    respond_to do |format|
      format.html { render "index"} # index.html.erb
      format.json { render json: @jobs }
    end
  end

  # GET /jobs/all
  # GET /jobs/all.json
  def all
    #@jobs = Job.all
    q = Job.scoped
    q = q.unscoped
    @jobs = q.desc(:created_at).limit(50).all

    respond_to do |format|
      format.html { render "index"} # index.html.erb
      format.json { render json: @jobs }
    end
  end

  # GET /jobs/1
  # GET /jobs/1.json
  def show
    @job = Job.unscoped.find(params[:id])
    # sometimes things don't get updated (can't see trace on errors)
    # if identity map is enabled
    @job = @job.reload

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @job }
    end
  end

  # GET /jobs/new
  # GET /jobs/new.json
  def new
    @job = Job.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @job }
    end
  end

  ## GET /jobs/1/edit
  #def edit
  #  @job = Job.find(params[:id])
  #end

  # POST /jobs
  # POST /jobs.json
  def create
    p = params[:job]
    k = Job
    if p["_type"]
      t = p.delete("_type")
      begin
        k = t.constantize
      rescue => e
        logger.info "TYPE:#{k} failed"
      end
    end
    @job = k.new(p)

    respond_to do |format|
      if @job.save
        @job.enqueue
        format.html { redirect_to @job, notice: 'Job was successfully created.' }
        format.json { render json: @job, status: :created, location: @job }
      else
        format.html { render action: "new" }
        format.json { render json: @job.errors, status: :unprocessable_entity }
      end
    end
  end

  ## PUT /jobs/1
  ## PUT /jobs/1.json
  #def update
  #  @job = Job.find(params[:id])
  #
  #  respond_to do |format|
  #    if @job.update_attributes(params[:job])
  #      format.html { redirect_to @job, notice: 'Job was successfully updated.' }
  #      format.json { head :no_content }
  #    else
  #      format.html { render action: "edit" }
  #      format.json { render json: @job.errors, status: :unprocessable_entity }
  #    end
  #  end
  #end

  def refresh
    @job = Job.find(params[:id])
    @job.retry
    @job.enqueue

    head :no_content
  rescue => e
    render json: {message: e.message}
  end

  def accept
    @job = Job.find(params[:id])
    @job.accept

    head :no_content
  rescue => e
    render json: {message: e.message}
  end

  # DELETE /jobs/1
  # DELETE /jobs/1.json
  def destroy
    @job = Job.unscoped.find(params[:id])
    @job.cancel

    respond_to do |format|
      format.html { redirect_to jobs_url }
      format.json { head :no_content }
    end
  end
end
