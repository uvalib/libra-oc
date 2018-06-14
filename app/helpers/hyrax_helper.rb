module HyraxHelper
  include ::BlacklightHelper
  include Hyrax::BlacklightOverride
  include Hyrax::HyraxHelperBehavior

  def render_libra_visibility_link(document)
    # Anchor must match with a tab in
    # https://github.com/projecthydra/hyrax/blob/master/app/views/curation_concerns/base/_guts4form.html.erb#L2
    link_to render_visibility_label(document),
      edit_polymorphic_path([main_app, document], anchor: "share"),
      id: "permission_" + document.id, class: "visibility-link"
  end

  # A Blacklight index field helper_method
  # @param [Hash] options from blacklight helper_method invocation. Maps rights URIs to links with labels.
  # @return [ActiveSupport::SafeBuffer] rights statement links, html_safe
  def license_links(options)
    service = Hyrax::LicenseService.new
    options[:url].map { |right| link_to service.label(right), right }.to_sentence.html_safe
  end

  private

  def render_visibility_label(document)
    if document.registered?
      content_tag :span, t('curation_concerns.visibility.authenticated.label_html'),
        class: "label label-warning", title: institution_name
    elsif document.public?
      content_tag :span, t('hyrax.visibility.open.text'), class: "label label-success",
        title: t('hyrax.visibility.open.note')
    else
      content_tag :span, t('hyrax.visibility.private.text'), class: "label label-danger",
        title: t('hyrax.visibility.private.note')
    end
  end
end
