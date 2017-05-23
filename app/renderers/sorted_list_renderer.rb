class SortedListRenderer < CurationConcerns::Renderers::AttributeRenderer
  def initialize(field, values, options = {})
    values.sort! if values.respond_to? 'sort!'
    super
  end
end
