class PersonAttributeRenderer < Hyrax::Renderers::AttributeRenderer
  def attribute_value_to_html person_json
    person = {}
    begin
      person = JSON.parse(person_json)
    rescue JSON::ParserError => e
      person = person_json
    end

    tags = ''
    %w(first_name last_name department institution).map do |key|
      tags << "#{key.titleize}: #{person[key]}<br/>"
    end
    tags + '<hr/>'
  end
end
