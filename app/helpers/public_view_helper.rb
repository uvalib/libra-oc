require_dependency 'libraoc/helpers/service_helpers'

module PublicViewHelper

  def file_date(date)
    return "Unknown" if date.nil?
    return date.strftime("%B %d, %Y")
  end

  def file_date_created(date)
    return "Unknown" if date.nil?
    date = date.join() if date.kind_of?(Array)
    return file_date(date) if date.kind_of?(DateTime)
    begin
      return file_date(DateTime.strptime(date, "%Y:%m:%d"))
    rescue
      begin
        return file_date(DateTime.strptime(date, "%m/%d/%Y"))
      rescue
        begin
          return file_date(DateTime.strptime(date, "%Y-%m-%d"))
        rescue
          return date
        end
      end
    end
  end

  def display_title(work)
    return 'Not Found' if work.nil?
    title = CGI.unescapeHTML( String.new work[:title][0].to_s )
    return raw( title )
  end

  def display_resource_type work
    if work.resource_type.present?
      work.resource_type.each do |type|
        concat content_tag :span, type, class: 'pull-right label label-default'
      end
    end
  end

  def display_authors( authors )
    return '' if authors.none?
    concat raw('<div class="document-row">')
    author_label = authors.one? ? "Author:" : "Authors:"
    concat content_tag(:span, author_label, class: 'document-label')
    authors.each do |author|
      
       author_string = construct_person_span( author, true )
       unless author_string.blank?
          concat content_tag(:span, author_string,
                             style: 'font-weight:normal', class:'document-value' )
       end
    end
    concat raw('</div>')
  end

  def construct_person_span(person, want_orcid = false )
    return '' if person.nil?
    first_line = concat_with_comma( '', person.last_name )
    first_line = concat_with_comma( first_line, person.first_name )
    first_line = concat_with_comma( first_line, person.department )
    results = content_tag(:span, first_line )
    orcid_tag = want_orcid ? construct_orcid_tag( person ) : ''

    if person.institution.present? || orcid_tag.present?
       results += content_tag(:span, raw( "#{person.institution} #{orcid_tag}" ) )
    end

    return results
  end

  def concat_with_comma( destination, field )
    if field.present?
      return destination.present? ? "#{destination}, #{field}" : field
    end

    return destination
  end

  def construct_orcid_tag( person )
    return '' if person.nil? || person.computing_id.blank?

    orcid = Helpers.lookup_orcid( person.computing_id )
    return '' if orcid.blank?

    return "#{image_tag 'orcid.png', alt: t('sufia.user_profile.orcid.alt')} #{link_to extract_orcid_for_display( orcid ), orcid, { target: '_blank' }}".html_safe
  end

  def extract_orcid_for_display( orcid )
    return '' if orcid.blank?
    return orcid.gsub( 'http://orcid.org/', '' )
  end

  def display_contributors(contributors)
    return '' if contributors.none?
    concat raw('<div class="document-row">')
    contributor_label = contributors.one? ? "Contributor:" : "Contributors:"
    concat content_tag(:span, contributor_label, class: 'document-label')
    contributors.each do |contributor|
      contributor_string = construct_person_span(contributor, false )
      unless contributor_string.blank?
        concat content_tag(:span, contributor_string,
                           style: 'font-weight:normal', class:'document-value' )
      end
    end
    concat raw('</div>')
  end

  def display_description( description )
    return '' if description.blank?
    description = simple_format( description )
    description = CGI.unescapeHTML( String.new description.to_s )
    return( CurationConcerns::Renderers::CustomPublicAttributeRenderer.new("Abstract:", raw( description ) ).render )
  end

  def display_degree( degree )
    return '' if degree.blank?
    return( CurationConcerns::Renderers::CustomPublicAttributeRenderer.new("Degree:", degree ).render )
  end

  def display_keywords( work )
    kw = construct_keywords( work )
    return '' if kw.blank?
    return( CurationConcerns::Renderers::CustomPublicAttributeRenderer.new("Keywords:", kw ).render )
  end

  def construct_keywords( work )
    return '' if work.nil?
    return work.keyword.join( ', ')
  end

  def display_sponsoring_agency( sponsoring_agency )
    return '' if sponsoring_agency.blank?
    sa = sponsoring_agency.join( ' ')
    CurationConcerns::Renderers::CustomPublicAttributeRenderer.new("Sponsoring Agency:", sa ).render
  end

  def display_related_links( links )
    return '' if links.blank?
    a = []
    links.each { |link|
      display = links.length > 1 ? raw("&bull; #{link}") : link
      a.push( display )
    }
    return( CurationConcerns::Renderers::CustomPublicAttributeRenderer.new("Related Links:", raw( a.join( '<br>' ) ) ).render )
  end

  def display_doi_link(work)
    if work.doi
      CurationConcerns::Renderers::CustomPublicAttributeRenderer.new("Persistent Link:", work.doi ).render
    end
  end

  def display_notes(notes)
    return '' if notes.blank?
    notes = simple_format( notes )
    return( CurationConcerns::Renderers::CustomPublicAttributeRenderer.new("Notes:", notes ).render )
  end

  def display_language( language )
    return '' if language.blank?
    return( CurationConcerns::Renderers::CustomPublicAttributeRenderer.new("Language:", language ).render )
  end

  def display_rights(rights)
    return '' if rights.blank?
    rights = rights.join(' ') if rights.kind_of?(Array)
    return( CurationConcerns::Renderers::CustomPublicAttributeRenderer.new("Rights:", rights ).render )
  end

  def display_rights(rights)
    return '' if rights.blank?
    rights = rights.join(' ') if rights.kind_of?(Array)
    return( CurationConcerns::Renderers::CustomPublicAttributeRenderer.new("Rights:", rights ).render )
  end

  def display_generic_date(name, date)
    return '' if date.blank? || date.kind_of?(Date)
    CurationConcerns::Renderers::CustomPublicAttributeRenderer.new("#{name}:", date.gsub( '-', '/' ) ).render
  end

  def display_generic(name, field)
    return '' if field.blank?
    field = field.join(' ') if field.kind_of?(Array)
    CurationConcerns::Renderers::CustomPublicAttributeRenderer.new("#{name}:", field ).render
  end


end
