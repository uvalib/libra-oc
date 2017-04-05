class LanguageService
  attr_accessor :authority

  def initialize
    @authority = Qa::Authorities::Local.subauthority_for('languages')
  end

  def select_active_options
    active_elements.map { |e| [e[:label], e[:id]] }
  end

  def label(id)
    authority.find(id).fetch('term')
  end

  def active_elements
    authority.all.select { |e| authority.find(e[:id])[:active] }
  end

  def active?(id)
    authority.find(id).fetch('active')
  end

  def include_current_value(value, _index, render_options, html_options)
    unless value.blank? || active?(value)
      html_options[:class] << ' force-select'
      render_options += [[label(value), value]]
    end
    [render_options, html_options]
  end

end
