module PermissionsHelper

  include ActionView::Helpers::TagHelper
  include ActionView::Context

  #
  # make a nice label for the presenter classes
  #
  def permission_label( solr_doc )
    title, klass = get_title_and_class( solr_doc )
    content_tag(:span, title, title: title, class: "label #{klass}")
  end

  private

  def get_title_and_class( solr_doc )
    if open_access?( solr_doc )
      return 'Visible Worldwide', 'label-success'
    elsif registered?( solr_doc )
      return I18n.translate('curation_concerns.institution_name'), 'label-warning'
    else
      return 'Private', 'label-danger'
    end
  end

  def open_access?( solr_doc )
    return solr_doc.visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
  end

  def registered?( solr_doc )
    return solr_doc.visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
  end

end
