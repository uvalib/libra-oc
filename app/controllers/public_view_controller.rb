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
    if @work.present?
      author_names = @work.authors.map {|a| a.to_display(email: false) }
      contributor_names = @work.contributors.map {|a| a.to_display(email: false) }
      title = @work.title.first.to_s
      set_meta_tags(
        title: title,
        description: "Libra Open Content: #{title} | Authors: #{author_names.join(', ')} #{@work.abstract}",
        keywords: "UVA Libra Open #{author_names.join(' ')} #{@work.keyword.join(' ')}",

        #for google scholar
        "DC.title": title,
        "DC.creator": author_names.join('; '),
        "DC.contributor": contributor_names.join('; '),
        "DC.subject": @work.keyword.join("; "),
        "DC.type": @work.resource_type,
        "DC.identifier": @work.identifier,
        "DC.rights": @work.license,
        "DC.issued": @work.published_date,
        citation_online_date: (Date.parse(@work.date_created).try(:strftime, "%Y/%-m/%-d") if @work.date_created.present?),
        "DC.language": @work.language,
        "DC.publisher":@work.publisher,
      )
    end
  end

end
