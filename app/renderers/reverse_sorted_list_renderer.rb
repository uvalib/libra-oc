class ReverseSortedListRenderer < CurationConcerns::Renderers::AttributeRenderer
  def initialize(field, values, options = {})

    # if this is sortable
    if values.respond_to? 'sort!'
      values.sort!
      values.reverse!
    end

    super
  end

end
