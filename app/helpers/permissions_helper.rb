module PermissionsHelper

  include ActionView::Helpers::TagHelper
  include ActionView::Context

  #
  # make a nice label for the presenter classes
  #
  def permission_label( document )
    visibility = document.visibility_with_embargo

    title, klass = get_title_and_class( visibility )
    content_tag(:span, title, title: title, class: "label #{klass}")
  end

  def label_for_visibility(visibility)
    visibility = visibility.first if visibility.is_a? Array
    title, klass = get_title_and_class( visibility )
    content_tag(:span, title, title: title, class: "label #{klass}")
  end


  # Displays the button to select/deselect items for your batch.  Call this in the index partial that's rendered for each search result.
  # @param [Hash] document the Hash (aka Solr hit) for one Solr document
  def button_for_add_to_batch(document)
    render partial: '/batch_select/add_button', locals: { document: document }
  end

  private

  def get_title_and_class( visibility )
    if open_access?( visibility )
      return 'Visible Worldwide', 'label-success'
    elsif registered?( visibility )
      return I18n.translate('curation_concerns.institution_name'), 'label-warning'
    elsif embargo?(visibility)
      return 'Embargo', 'label-info'
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

  def embargo?( visibility )
    return visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO
  end

end
