require_dependency 'app/helpers/permissions_helper'

class LibraWorkPresenter < Sufia::WorkShowPresenter
  include ActionView::Helpers::TagHelper
  include PermissionsHelper

  # add our custom fields to the presenter
  delegate :notes,
           :admin_notes,
           :depositor,
           :sponsoring_agency,
           :license,
           :doi,
           :libra_id,
           :source_citation,
           :work_source,
           :abstract,
           :keywords,
           :audit_history,

     to: :solr_document

  def authors
    return people_sort( self.solr_document.authors )
  end

  def contributors
    return people_sort( self.solr_document.contributors )
  end

  def libra_permission_badge
    permission_label( self.solr_document )
  end

  private

  def people_sort( people )

    return people if people.nil?
    return people if people.empty?

    # convert to JSON
    sorted_people = []
    people.each do |p|
       sorted_people << JSON.parse( p )
    end

    # sort them
    sorted_people.sort! {|a,b| a['index'] <=> b['index']}

    # reconstruct the map correctly
    return sorted_people.map {|p| JSON.generate( p )}
  end
end
