#
# Helpers for the ingest process
#

module CitationHelpers

  #
  # construct a citation field based on the information captured
  #
  def construct( payload )

    # no citation if the work is not one of a known set of resources
    return nil if ['article', 'article_reprint', 'book', 'book_part', 'conference_paper' ].include?( payload[ :resource_type ] ) == false

    #citation = ''
    case payload[ :resource_type ]
      when 'article', 'article_reprint'
        citation = render_template( payload, 'article' )
      when 'book'
        citation = render_template( payload, 'book' )
      when 'book_part'
        citation = render_template( payload, 'book_part' )
      when 'conference_paper'
        citation = render_template( payload, 'conference_paper' )
    end

    puts "==> CITATION [#{citation}]"
    return citation
  end

  private

  def render_template( payload, template )

    # setup the variables for the render process
    vars = {
     # common attributes
     :author                   => comma_separate( payload[:authors ][0][:last_name], payload[:authors ][0][:first_name] ),
     :other_authors            => construct_other_authors( payload[ :authors ] ),
     :title                    => payload[:title],
     :publication_year         => payload[:publish_date],
     :publication_url          => payload[:related_url],
     :publisher                => payload[:publisher],
     :isbn                     => payload[:isbn],
     :start_page               => payload[:start_page],
     :end_page                 => payload[:end_page],

    # book attributes
     :book_title               => payload[:journal_title],
     :publish_location         => payload[:publish_location],
     :editors                  => construct_editors( payload[ :editors ] ),

     # article attributes
     :journal_title            => payload[:journal_title],
     :journal_volume           => payload[:journal_volume],
     :journal_issue            => payload[:journal_issue],
     :journal_publication_year => payload[:journal_publication_year],
     :issn                     => payload[:issn],

     # conference attributes
     :conference_details       => comma_separate( payload[:conference_title], payload[:conference_location] ),
     :conference_date          => payload[:conference_date]
    }

    # remove any blank attributes
    vars = remove_blank_attributes( vars )

    erb_file = "lib/citation_templates/#{template}.erb"
    str = ERB.new( IO.read( File.join( Rails.root, erb_file ) ) ).result( binding )

    # remove carriage returns
    str = str.gsub( /\n/, '' )

    # squish remaining spaces
    str = str.squish

    # remove leading spaces following punctuation
    str = str.gsub( ' ,', ',' )
    str = str.gsub( ' .', '.' )
    str = str.gsub( ' :', ':' )

    return( str )

  end

  #
  # add subsequent (non primary) authors to the citation
  #
  def construct_other_authors( authors )

    return nil if authors.empty? || authors.length == 1

    oo = ''
    authors.each_with_index do|a, ix|
      next if ix == 0
      if a[:first_name].present? && a[:last_name].present?
         oo += ", " if ix > 1
         oo += " and " if ix == authors.length - 1
         oo += "#{a[:first_name]} #{a[:last_name]}"
      end
    end
    return oo
  end

  #
  # add editors to the citation
  #
  def construct_editors( editors )

    return nil if editors.empty?

    ed = ''
    editors.each_with_index do|e, ix|
      if e[:first_name].present? && e[:last_name].present?
        ed += ", " if ix > 0
        ed += " and " if ix > 0 && ix == editors.length - 1
        ed += "#{e[:first_name]} #{e[:last_name]}"
      end
    end
    return ed
  end

  #
  # remove blank attributes from a hash
  #
  def remove_blank_attributes( vars )
    res = {}
    vars.keys.each do |k|
      if vars[ k ].present?
        res[ k ] = vars[ k ]
      end
    end
    return( res )
  end

  def comma_separate( this, that )
    return separate_with( this, that, ', ' )
  end

  def space_separate( this, that )
    return separate_with( this, that, ' ' )
  end

  def separate_with( this, that, separator )
    return "#{this}#{separator}#{that}" if this.present? && that.present?
    return this if this.present?
    return that if that.present?
    return ''
  end

end

#
# end of file
#