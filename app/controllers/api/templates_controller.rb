class Api::TemplatesController < Api::ApiController
  def index
    @templates = Template.all
    respond_with(@templates.map(&:to_api))
  end
end