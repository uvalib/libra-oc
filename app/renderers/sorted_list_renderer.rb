class SortedListRenderer < CurationConcerns::Renderers::AttributeRenderer
  def initialize(field, values, options = {})
    values.sort!
    super
  end
end
