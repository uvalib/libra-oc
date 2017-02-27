class PersonAttributeRenderer < CurationConcerns::Renderers::AttributeRenderer
  def attribute_value_to_html value
    content_tag(:p, value)
  end
end
