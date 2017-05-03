module ExportsHelper

  def format_persons( persons )
    return '' if persons.nil? || persons.empty?
    persons.map { |p| p.to_display }.join( ', ' )
  end

end
