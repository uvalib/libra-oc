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

  def display_authors( authors )
    return '' if authors.none?
    authors.each do |author|
      orcid_data = construct_author( author )
      orcid_data = content_tag(:span, raw( " #{orcid_data}" ), { style: 'font-weight:normal' }) unless orcid_data.blank?
      header = raw( "Author:" + orcid_data )
      concat CurationConcerns::Renderers::CustomPublicAttributeRenderer.new( header, author ).render
    end
  end

  def construct_author( author )
    return '' if author.nil?
    return "#{author.last_name}, #{author.first_name}, #{author.department}, #{author.institution}"
  end

  def construct_author_orcid( author )
    return '' if author.nil?

    orcid = get_author_orcid( author )
    return '' if orcid.blank?

    return "#{image_tag 'orcid.png', alt: t('sufia.user_profile.orcid.alt')} #{link_to extract_orcid_for_display( orcid ), orcid, { target: '_blank' }}".html_safe
  end

  def extract_orcid_for_display( orcid )
    return '' if orcid.blank?
    return orcid.gsub( 'http://orcid.org/', '' )
  end

  def display_contributors(contributors)
    # special case, we want to show the advisor field as blank
    return( CurationConcerns::Renderers::CustomPublicAttributeRenderer.new("Contributors:", '').render ) if contributors.none?

    # advisers are tagged with a numeric index so sorting them ensures they are presented in the correct order
#   contributors = work.contributors

#   contributors.each { |contributor|
#     arr = contributor.split("\n")
#     arr.push('') if arr.length == 4 # if the last item is empty, the split command will miss it.
#     arr.push('') if arr.length == 5 # if the last item is empty, the split command will miss it.
#     # arr should be an array of [ index, computing_id, first_name, last_name, department, institution ]
#     if arr.length == 6
#       advisors.push( construct_advisor_line( arr ) )
#     else
#       advisors.push(contributor) # this shouldn't happen, but perhaps it will if old data gets in there.
#     end
#   }
    concat CurationConcerns::Renderers::CustomPublicAttributeRenderer.new("Contributors:", raw( contributors.join( '<br>' ) ) ).render
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
    return( CurationConcerns::Renderers::CustomPublicAttributeRenderer.new("Sponsoring Agency:", sa ).render )
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
    doi = "Persistent link will appear here after submission." if work.is_draft?
    doi = work.permanent_url unless work.is_draft?
    return( CurationConcerns::Renderers::CustomPublicAttributeRenderer.new("Persistent Link:", doi ).render )
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

  def display_publication_date( date )
    return '' if date.blank?
    return( CurationConcerns::Renderers::CustomPublicAttributeRenderer.new("Issued Date:", date.gsub( '-', '/' ) ).render )
  end

  def display_array(value)
    if value.kind_of?(Array)
      value = value.join(", ")
    end
    return value
  end

  def construct_advisor_line( arr )
    res = ""
    res = field_append( res, arr[3].strip )
    res = field_append( res, arr[2].strip )
    res = field_append( res, arr[4].strip )
    res = field_append( res, arr[5].strip )
    return( res )
  end

  def field_append( current, field )
    res = current
    if field.blank? == false
      res += ", " if res.blank? == false
      res += field
    end
    return res
  end
end
