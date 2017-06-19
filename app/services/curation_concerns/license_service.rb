module CurationConcerns
  class LicenseService < QaSelectService

    def initialize
      super('licenses')
    end

    def include_current_value(value, _index, render_options, html_options)
      unless value.blank? || active?(value)
        html_options[:class] << ' force-select'
        render_options += [[label(value), value]]
      end
      [render_options, html_options]
    end


    def label(id)
      authority.find(id).fetch('term')
    end

    def url(id)
      authority.find(id).fetch('url')
    end

  end
end
