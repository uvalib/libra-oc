class PublicViewController < ApplicationController
  layout 'public_view'

  def show
    @work = LibraWork.find params[:id]

  end

end
