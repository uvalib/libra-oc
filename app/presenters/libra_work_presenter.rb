class LibraWorkPresenter < Sufia::WorkShowPresenter
  include ActionView::Helpers::TagHelper

  # add our custom fields to the presenter
  delegate :notes,
           :admin_notes,
           :sponsoring_agency,
           :license,
           :doi,
           :libra_id,
           :source_citation,
           :work_source,
           :abstract,
           :keywords,


     to: :solr_document

  def authors
    return people_sort( self.solr_document.authors )
  end
  def contributors
    return people_sort( self.solr_document.contributors )
  end

  def libra_permission_badge
    content_tag(:span, link_title, title: link_title, class: "label #{dom_label_class}")
  end

  private
  def dom_label_class
    if open_access_with_embargo?
      'label-warning'
    elsif open_access?
      'label-success'
    elsif registered?
      'label-warning'
    else
      'label-danger'
    end
  end

  def link_title
    if open_access_with_embargo?
      'Open Access with Embargo'
    elsif open_access?
      'Visible Worldwide'
    elsif registered?
      I18n.translate('curation_concerns.institution_name')
    else
      'Private'
    end
  end

  def open_access_with_embargo?
    if @open_access_with_embargo.nil?
      @open_access_with_embargo = open_access? && embargo?
    end
    @open_access_with_embargo
  end

  def open_access?
    @open_access = @solr_document.visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC if @open_access.nil?
    @open_access
  end

  def registered?
    @registered = @solr_document.visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED if @registered.nil?
    @registered
  end

  def embargo?
    @solr_document.embargo_release_date.present?
  end

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
