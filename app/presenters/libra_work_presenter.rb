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

  def embargo
    doc = self.solr_document
    if doc.has_embargo?
      release_date = Date.parse(doc.embargo_release_date).to_s
      visibility_after = label_for_visibility(self.solr_document['visibility_after_embargo_ssim'])
      visibility_before = label_for_visibility(self.solr_document['visibility_during_embargo_ssim'])
      return "Files are #{visibility_before} until #{release_date} and then #{visibility_after}"
    else
      return nil
    end
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
