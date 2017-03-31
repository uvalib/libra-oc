#
# Helpers for the ingest process
#

module CitationHelpers

  # basic template tokens
  AUTHOR_FIRST_NAME_TOKEN = '<AuthorFirstName>'
  AUTHOR_LAST_NAME_TOKEN = '<AuthorLastName>'
  OTHER_AUTHORS_TOKEN = '<OtherAuthors>'
  TITLE_TOKEN = '<Title>'
  PUB_LOCATION_TOKEN = '<PublisherLocation>'
  PUBLISHER_TOKEN = '<Publisher>'
  PUB_YEAR_TOKEN = '<PublicationYear>'
  AVAILABLE_PLACEHOLDER = 'Available:'
  ISBN_PLACEHOLDER = 'ISBN:'
  ISBN_TOKEN = '<ISBN>'
  PUB_URL_TOKEN = '<PublicationUrl>'
  ISSN_PLACEHOLDER = 'ISSN:'
  ISSN_TOKEN = '<ISSN>'
  EDITOR_PLACEHOLDER = 'Ed. '
  BOOK_TITLE_TOKEN = '<BookTitle>'
  EDITOR_FIRST_NAME_TOKEN = '<EditorFirstName>'
  EDITOR_LAST_NAME_TOKEN = '<EditorLastName>'
  START_PAGE_TOKEN = '<StartPage>'
  END_PAGE_TOKEN = '<EndPage>'
  JOURNAL_TITLE_TOKEN = '<JournalTitle>'
  JOURNAL_VOLUME_TOKEN = '<JournalVolume>'
  JOURNAL_ISSUE_TOKEN = '<JournalIssue>'
  JOURNAL_PUB_YEAR_TOKEN = '<JournalPublicationYear>'
  CONFERENCE_TITLE_TOKEN = '<ConferenceTitle>'
  CONFERENCE_LOCATION_TOKEN = '<ConferenceLocation>'

  # book citation template
  BOOK_CITATION_TEMPLATE =
      "#{AUTHOR_LAST_NAME_TOKEN}, #{AUTHOR_FIRST_NAME_TOKEN}, #{OTHER_AUTHORS_TOKEN}. #{TITLE_TOKEN}. " +
      "#{PUB_LOCATION_TOKEN}: #{PUBLISHER_TOKEN}, #{PUB_YEAR_TOKEN}. " +
      "#{AVAILABLE_PLACEHOLDER} #{ISBN_PLACEHOLDER}#{ISBN_TOKEN}, #{PUB_URL_TOKEN}"

  EDITED_BOOK_CITATION_TEMPLATE =
      "#{AUTHOR_LAST_NAME_TOKEN}, #{AUTHOR_FIRST_NAME_TOKEN}, #{OTHER_AUTHORS_TOKEN}. " +
      "\"#{TITLE_TOKEN}\". #{EDITOR_PLACEHOLDER} #{EDITOR_FIRST_NAME_TOKEN} #{EDITOR_LAST_NAME_TOKEN}. " +
      "#{BOOK_TITLE_TOKEN}. #{PUB_LOCATION_TOKEN}: #{PUBLISHER_TOKEN}, #{PUB_YEAR_TOKEN}. " +
      "#{START_PAGE_TOKEN} - #{END_PAGE_TOKEN}. " +
      "#{AVAILABLE_PLACEHOLDER} #{ISBN_PLACEHOLDER}#{ISBN_TOKEN}, #{PUB_URL_TOKEN}"

  # article citation template
  ARTICLE_CITATION_TEMPLATE =
      "#{AUTHOR_LAST_NAME_TOKEN}, #{AUTHOR_FIRST_NAME_TOKEN}, #{OTHER_AUTHORS_TOKEN}. " +
      "\"#{TITLE_TOKEN}\". #{JOURNAL_TITLE_TOKEN} #{JOURNAL_VOLUME_TOKEN}. " +
      "#{JOURNAL_ISSUE_TOKEN} (#{JOURNAL_PUB_YEAR_TOKEN}): " +
      "#{START_PAGE_TOKEN} - #{END_PAGE_TOKEN}. " +
      "#{AVAILABLE_PLACEHOLDER} #{ISSN_PLACEHOLDER}#{ISSN_TOKEN}, #{PUB_URL_TOKEN}"

  # conference citation template
  CONFERENCE_CITATION_TEMPLATE =
      "#{AUTHOR_LAST_NAME_TOKEN}, #{AUTHOR_FIRST_NAME_TOKEN}, #{OTHER_AUTHORS_TOKEN}. " +
      "\"#{TITLE_TOKEN}\". #{CONFERENCE_TITLE_TOKEN}, #{CONFERENCE_LOCATION_TOKEN}. " +
      "#{PUB_YEAR_TOKEN}."

  #
  # construct a citation field based on the information captured
  #
  def render( payload )

    # no citation if the work is not one of a known set of resources
    return nil if ['article', 'article_reprint', 'book', 'book_part', 'conference_paper' ].include?( payload[ :resource_type ] ) == false

    #citation = ''
    case payload[ :resource_type ]
      when 'article', 'article_reprint'
        citation = render_template( payload, ARTICLE_CITATION_TEMPLATE )
      when 'book'
        citation = render_template( payload, BOOK_CITATION_TEMPLATE )
      when 'book_part'
        citation = render_template( payload, EDITED_BOOK_CITATION_TEMPLATE )
      when 'conference_paper'
        citation = render_template( payload, CONFERENCE_CITATION_TEMPLATE )
      else
        return nil
    end

    #puts "==> CITATION (before) [#{citation}]"
    citation = cleanup( citation )

    puts "==> CITATION [#{citation}]"
    return citation
  end

  private

  def render_template( payload, template )

    citation = template
    citation = substitute_token( citation, AUTHOR_LAST_NAME_TOKEN, payload[:authors ][0][:last_name] )
    citation = substitute_token( citation, AUTHOR_FIRST_NAME_TOKEN, payload[:authors ][0][:first_name] )
    citation = substitute_token( citation, TITLE_TOKEN, payload[:title ] )
    citation = substitute_token( citation, PUBLISHER_TOKEN, payload[:publisher ] )
    citation = substitute_token( citation, PUB_LOCATION_TOKEN, payload[:publish_location ] )
    citation = substitute_token( citation, PUB_YEAR_TOKEN, payload[:publish_date ] )
    citation = substitute_token( citation, ISBN_TOKEN, payload[:isbn ] )
    citation = substitute_token( citation, ISSN_TOKEN, payload[:issn ] )
    citation = substitute_token( citation, START_PAGE_TOKEN, payload[:start_page ] )
    citation = substitute_token( citation, END_PAGE_TOKEN, payload[:end_page ] )
    citation = substitute_token( citation, CONFERENCE_TITLE_TOKEN, payload[:conference_title ] )
    citation = substitute_token( citation, CONFERENCE_LOCATION_TOKEN, payload[:conference_location ] )
    citation = substitute_token( citation, PUB_URL_TOKEN, payload[:related_url ] )
    citation = substitute_token( citation, JOURNAL_TITLE_TOKEN, payload[ :journal_title ] )
    citation = substitute_token( citation, JOURNAL_VOLUME_TOKEN, payload[ :journal_volume ] )
    citation = substitute_token( citation, JOURNAL_ISSUE_TOKEN, payload[ :journal_issue ] )
    citation = substitute_token( citation, JOURNAL_PUB_YEAR_TOKEN, payload[ :journal_publication_year ] )

    citation = substitute_token( citation, EDITOR_FIRST_NAME_TOKEN, payload[ :editor_first_name ] )
    citation = substitute_token( citation, EDITOR_LAST_NAME_TOKEN, payload[ :editor_last_name ] )
    citation = substitute_token( citation, BOOK_TITLE_TOKEN, payload[ :journal_title ] )

    # deal with some special cases
    other_authors = construct_other_authors( payload[ :authors ] )
    citation = substitute_token(citation, OTHER_AUTHORS_TOKEN, other_authors )

    # remove placeholder labels if their corresponding fields do not exist
    if payload[ :isbn ].blank?
      citation = delete_token(citation, ISBN_PLACEHOLDER )
    end
    if payload[ :issn ].blank?
      citation = delete_token(citation, ISSN_PLACEHOLDER )
    end

    if payload[ :isbn ].blank? && payload[ :issn ].blank? && payload[:related_url ].blank?
      citation = delete_token(citation, AVAILABLE_PLACEHOLDER )
    end

    return citation
  end

  def cleanup( citation )
    cleaned = cleanup_pass( citation )
    while true
      again = cleanup_pass( cleaned )
      return cleaned if cleaned == again
      cleaned = again
    end
  end

  def cleanup_pass( citation )
     res = citation
     res = res.gsub( ' :', ' ' )
     res = res.gsub( ' , ', ' ' )
     res = res.gsub( ', .', '.' )
     res = res.gsub( ',,', ',' )
     res = res.gsub( ' - .', '' )
     res = res.gsub( '. . .', '.' )
     res = res.gsub( '. .', '.' )
     res = res.gsub( '..', '.' )
     res = res.gsub( '()', '' )
     res = res.gsub( ' . ', '. ' )
     res = res.gsub( /:$/, '' )
     res = res.gsub( /,$/, '' )

     # finally remove all duplicate spaces and strip trailing spaces
     return res.gsub( '  ', ' ' ).rstrip
  end

  #
  # add subsequent (non primary) authors to the citation
  #
  def construct_other_authors( authors )

    oo = ''
    return oo if authors.empty? || authors.length == 1

    authors.each_with_index do|a, ix|
      next if ix == 0
      if a[:first_name].present? && a[:last_name].present?
         oo += " and" if ix > 1
         oo += " #{a[:first_name]} #{a[:last_name]}"
      end
    end
    oo += '.'
    return oo
  end

  #
  # delete the specified token
  #
  def delete_token( source, what )
    return source.gsub( what, '' )
  end

  #
  # make a substitution in the source from what to with
  #
  def substitute_token( source, what, with )
    with = '' if with.nil?
    return source.gsub( what, with )
  end

end

#
# end of file
#