class PersonAttributeRenderer < CurationConcerns::Renderers::AttributeRenderer
  def attribute_value_to_html person_json
    person = JSON.parse(person_json)
    tags = ''
    %w(first_name last_name department institution).map do |key|
      tags << "#{key.titleize}: #{person[key]}<br/>"
    end
    tags
  end
end
