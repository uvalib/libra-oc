#require_dependency 'libraoc/helpers/statistics_helper'

class PublicViewController < ApplicationController

  include WorkHelper
  include StatisticsHelper

  layout 'public_view'

  def show

    @id = params[:id]
    @work = get_work_item( @id )
    setup_meta_tags if @work.present?

    @can_view = false
    @can_view = helpers.can_view_work?( @work ) if @work.present?

    if @can_view

      # save work view statistics
      record_work_view_event( @work.id )

      # handle any debugging support necessary
      set_debugging_override( )
    else
      render404public( )
    end

  end

  private

  def setup_meta_tags
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
