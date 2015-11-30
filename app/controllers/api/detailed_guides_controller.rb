class Api::DetailedGuidesController < PublicFacingController
  skip_before_filter :restrict_request_formats
  respond_to :json

  self.responder = Api::Responder

  def show
    @guide = DetailedGuide.published_as(params[:id])
    if @guide
      respond_with Api::DetailedGuidePresenter.new(@guide, view_context)
    else
      respond_with_not_found
    end
  end

  def index
    respond_with Api::DetailedGuidePresenter.paginate(
      DetailedGuide.published.alphabetical,
      view_context
    )
  end

  private

  def respond_with_not_found
    respond_with Hash.new, status: :not_found
  end
end
