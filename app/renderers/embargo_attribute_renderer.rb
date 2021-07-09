class EmbargoAttributeRenderer < CurationConcerns::Renderers::AttributeRenderer
  def attribute_value_to_html embargo_string
    return embargo_string
  end
end