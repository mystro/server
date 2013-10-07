class Api::ComputesController < Api::ApiController
  # GET /api/organizations/:organization_id/computes
  def index
    list = filters(Compute, { organization_id: @organization.id }).includes(:environment, :balancer).all
    out  = list.map(&:to_api)
    respond_with(out)
  end

  # GET /api/organizations/:organization_id/computes/:id
  def show
    @compute = Compute.find(params[:id])
    respond_with(@compute)
  end

  def search
    patterns = (params[:pattern]||"").split(",")
    data = Compute.asc(:organization_id, :environment_id).all
    #data = list.map {|e| {id: e.id, name: e.display}}
    patterns.each do |pattern|
      p = Regexp.escape(pattern)
      data = data.reject do |e|
        #logger.info "PATTERN: #{e.display} !~ /#{p}/"
        e.short !~ /#{p}/
      end
    end
    out = data.map(&:to_api)
    respond_with(out)
  end
end
