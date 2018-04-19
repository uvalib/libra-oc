class LibraRightsAttributeRenderer < CurationConcerns::Renderers::AttributeRenderer
  private
  def attribute_value_to_html(value)
    self.rights_attribute_to_html(value)
  end

  # Special treatment for license/rights.  A URL from the Sufia gem's config/sufia.rb is stored in the desctadata of the
  # curation_concern.  If that URL is valid in form, then it is used as a link.  If it is not validit is used as plain text.
  public
  def self.rights_attribute_to_html(value)
    authority = CurationConcerns.config.license_service_class.new.authority
    license = authority.find(value)
    license = {'term' => value} unless license.present?

    if license['url'].present?
      %(<a href=#{ERB::Util.h(license['url'])} target="_blank">#{license['term']}</a>)
    else
      license['term']
    end
  end
end
