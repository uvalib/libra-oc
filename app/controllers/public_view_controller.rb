require_dependency 'libraoc/helpers/statistics_helper'

class PublicViewController < ApplicationController

  include StatisticsHelper

  layout 'public_view'

  def show
    @id = params[:id]
    @work = get_work_item

    @can_view = helpers.can_view_work?( @work )
    if @can_view

      # save work view statistics
      work_view_event( @work.id, current_user )

      # handle any debugging support necessary
      set_debugging_override( )
    else
      render404public( )
    end

  end

  private

  def get_work_item
    id = params[:id]
    work = LibraWork.where( { id: id } )
    if work.length > 0
      return work[ 0 ]
    end
    return nil
  end

end
