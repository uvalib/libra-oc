module SufiaHelper
  include ::BlacklightHelper
  include Sufia::BlacklightOverride
  include Sufia::SufiaHelperBehavior

  def render_libra_visibility_link(document)
    # Anchor must match with a tab in
    # https://github.com/projecthydra/sufia/blob/master/app/views/curation_concerns/base/_guts4form.html.erb#L2
    link_to render_visibility_label(document),
      edit_polymorphic_path([main_app, document], anchor: "share"),
      id: "permission_" + document.id, class: "visibility-link"
  end

  # A Blacklight index field helper_method
  # @param [Hash] options from blacklight helper_method invocation. Maps rights URIs to links with labels.
  # @return [ActiveSupport::SafeBuffer] rights statement links, html_safe
  def license_links(options)
    service = CurationConcerns::LicenseService.new
    options[:url].map { |right| link_to service.label(right), right }.to_sentence.html_safe
  end

  private

  def render_visibility_label(document)
    if document.visibility_with_embargo == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO
      content_tag :span, t('curation_concerns.visibility.embargo.label_html'),
        class: "label label-info", title: 'Embargo'

    elsif document.registered?
      content_tag :span, t('curation_concerns.visibility.authenticated.label_html'),
        class: "label label-warning", title: institution_name
    elsif document.public?
      content_tag :span, t('sufia.visibility.open'), class: "label label-success",
        title: t('sufia.visibility.open_title_attr')
    else
      content_tag :span, t('sufia.visibility.private'), class: "label label-danger",
        title: t('sufia.visibility.private_title_attr')
    end
  end
end
