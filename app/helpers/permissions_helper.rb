module PermissionsHelper

  include ActionView::Helpers::TagHelper
  include ActionView::Context

  #
  # make a nice label for the presenter classes
  #
  def permission_label( visibility )
    visibility = visibility.first if visibility.is_a? Array
    title, klass = get_title_and_class( visibility )
    content_tag(:span, title, title: title, class: "label #{klass}")
  end

  private

  def get_title_and_class( visibility )
    if open_access?( visibility )
      return 'Visible Worldwide', 'label-success'
    elsif registered?( visibility )
      return I18n.translate('curation_concerns.institution_name'), 'label-warning'
    else
      return 'Private', 'label-danger'
    end
  end

  def open_access?( visibility )
    return visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
  end

  def registered?( visibility )
    return visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
  end

end
