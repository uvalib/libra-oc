#require_dependency 'libraoc/helpers/statistics_helper'

class PublicViewController < ApplicationController

  include StatisticsHelper

  layout 'public_view'

  def show
    @id = params[:id]
    @work = get_work_item
    setup_meta_tags

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

  def setup_meta_tags
    set_meta_tags(
      description: "TODO",
      keywords: @work.keyword,

      #for google scholar
      "DC.title": :title,
      "DC.creator": @work.authors.map(&:to_display),
      "DC.contributor": @work.contributors.map(&:to_display),
      "DC.subject": @work.subject.join("; "),
      "DC.type": @work.resource_type,
      "DC.identifier": @work.identifier,
      "DC.rights": @work.license,
      "DC.issued": (Date.parse(@work.published_date).try(:strftime, "%Y/%-m/%-d") if @work.published_date.present?),
      citation_online_date: (Date.parse(@work.date_created).try(:strftime, "%Y/%-m/%-d") if @work.date_created.present?),
      "DC.identifier": @work.identifier,
      "DC.language": @work.language,
      "DC.publisher":@work.publisher,
    )
  end

end
