module ExportsHelper

  def format_persons( persons )
    return '' if persons.nil? || persons.empty?
    persons.map { |p| p.to_display }.join( ', ' )
  end

  def format_visibility( rec )
    return 'private' if rec.is_private?
    return 'UVa only' if rec.is_institution_visible?
    return 'public' if rec.is_publicly_visible?
    return 'unknown'
  end

  def format_array( array, delimiter )
    return '' if array.blank?
    return array.join( delimiter )
  end
end
