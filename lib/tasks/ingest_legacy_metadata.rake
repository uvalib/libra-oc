#
# Tasks to manage ingest of legacy Libra metadata
#

# pull in the helpers
require_dependency 'tasks/ingest_helpers'
include IngestHelpers

require_dependency 'tasks/citation_helpers'
include CitationHelpers

require_dependency 'app/helpers/public_view_helper'
include PublicViewHelper

namespace :libraoc do

  namespace :ingest do

  #
  # possible environment settings that affect the ingest behavior
  #
  # MAX_COUNT    - Maximum number of items to process
  # DUMP_PAYLOAD - Output the entire document metadata before saving
  # DRY_RUN      - Dont actually create the items
  #

  #
  # ingest metadata
  #
  desc "Ingest legacy Libra data; must provide the ingest directory; optionally provide a defaults file and start index"
  task legacy_metadata: :environment do |t, args|

    ingest_dir = ARGV[ 1 ]
    if ingest_dir.nil?
      puts "ERROR: no ingest directory specified, aborting"
      next
    end
    task ingest_dir.to_sym do ; end

    defaults_file = ARGV[ 2 ]
    if defaults_file.nil?
      defaults_file = IngestHelpers::DEFAULT_DEFAULT_FILE
    end
    task defaults_file.to_sym do ; end

    start = ARGV[ 3 ]
    if start.nil?
      start = "0"
    end
    task start.to_sym do ; end

    start_ix = start.to_i
    start_ix = 0 if start_ix.to_s != start

    # get the list of items to be ingested
    ingests = IngestHelpers.get_legacy_ingest_list(ingest_dir )
    if ingests.empty?
      puts "ERROR: ingest directory does not contain contains any items, aborting"
      next
    end

    # load any default attributes
    defaults = IngestHelpers.load_config_file( defaults_file )

    # load depositor information
    depositor = Helpers.lookup_user( TaskHelpers::DEFAULT_USER )
    if depositor.nil?
      puts "ERROR: Cannot locate depositor info (#{TaskHelpers::DEFAULT_USER})"
      next
    end

    user = User.find_by_email( depositor.email )
    if user.nil?
      puts "ERROR: Cannot lookup depositor info (#{depositor.email})"
      next
    end

    # disable the allocate DOI callback for the ingest
    LibraWork.skip_callback( :save, :after, :allocate_doi )

    success_count = 0
    error_count = 0
    total = ingests.size
    ingests.each_with_index do | dirname, ix |
      next if ix < start_ix
      ok = ingest_legacy_metadata( defaults, user, File.join( ingest_dir, dirname ), ix + 1, total )
      ok == true ? success_count += 1 : error_count += 1
      break if ENV[ 'MAX_COUNT' ] && ENV[ 'MAX_COUNT' ].to_i == ( success_count + error_count )
    end
    puts "#{success_count} item(s) processed successfully, #{error_count} error(s) encountered"

  end

  #
  # helpers
  #

  #
  # convert a set of Libra extract assets into a new Libra metadata record
  #
  def ingest_legacy_metadata( defaults, depositor, dirname, current, total )

     solr_doc, fedora_doc = IngestHelpers.load_legacy_ingest_content(dirname )
     id = solr_doc['id']

     puts "Ingesting #{current} of #{total}: #{File.basename( dirname )} (#{id})..."

     # create a payload from the document
     payload = create_legacy_ingest_payload( dirname, solr_doc, fedora_doc )

     # merge in any default attributes
     payload = apply_defaults_for_legacy_item( defaults, payload )

     # calculate embargo release date
     payload = add_embargo_release_date( payload )

     # some fields with embedded quotes need to be escaped; handle this here
     payload = IngestHelpers.escape_fields( payload )

     # dump the fields as necessary...
     IngestHelpers.dump_ingest_payload( payload ) if ENV[ 'DUMP_PAYLOAD' ]

     # validate the payload
     errors, warnings = IngestHelpers.validate_ingest_payload( payload )

     if errors.empty? == false
       puts " ERROR(S) identified for #{File.basename( dirname )} (#{id})"
       puts " ==> #{errors.join( "\n ==> " )}"
       return false
     end

     if warnings.empty? == false
       puts " WARNING(S) identified for #{File.basename( dirname )} (#{id}), continuing anyway"
       puts " ==> #{warnings.join( "\n ==> " )}"
     end

     # handle dry running
     return true if ENV[ 'DRY_RUN' ]

     # create the work
     ok, work = IngestHelpers.create_new_item( depositor, payload )
     if ok == true
       puts "New work created; id: #{work.id} (#{work.doi || 'none'})"
     else
       #puts " ERROR: creating new generic work for #{File.basename( dirname )} (#{id})"
       #return false
       puts " WARNING: while creating generic work for #{File.basename( dirname )} (#{id})"
     end

     # create a record of the actual work id
     if work != nil
        IngestHelpers.set_legacy_ingest_id(dirname, work.id )
     end

     return ok
  end

  #
  # create a ingest payload from the Libra document
  #
  def create_legacy_ingest_payload( dirname, solr_doc, fedora_doc )


     payload = {}

     #
     # add all the required fields
     #

     # date and time attributes
     create_date = solr_doc.at_path( 'system_create_dt' )
     payload[ :create_date ] = create_date if create_date.present?
     modified_date = solr_doc.at_path( 'system_modified_dt' )
     payload[ :modified_date ] = modified_date if modified_date.present?

     # title
     title = extract_title( solr_doc, fedora_doc )
     payload[ :title ] = title if title.present?

     # abstract
     abstract = extract_abstract( solr_doc, fedora_doc )
     payload[ :abstract ] = abstract if abstract.present?

     # author
     payload[ :authors ] = []
     author_number = 0
     while true
       added, payload[ :authors ] = add_author( solr_doc, author_number, payload[ :authors ] )
       break unless added
       author_number += 1
     end

     # document contributor
     payload[ :contributors ] = []
     contributor_number = 0
     while true
        added, payload[ :contributors ] = add_contributor( solr_doc, contributor_number, payload[ :contributors ] )
        break unless added
        contributor_number += 1
     end

     # issue date
     issued_date = extract_issued_date( solr_doc, fedora_doc )
     payload[ :issued ] = issued_date if issued_date.present?

     # embargo attributes
     embargo_type = IngestHelpers.solr_first_field_extract(solr_doc, 'release_to_t' )
     payload[ :embargo_type ] = embargo_type if embargo_type.present?
     release_date = IngestHelpers.solr_first_field_extract(solr_doc, 'embargo_embargo_release_date_t' )
     payload[ :embargo_release_date ] = release_date if release_date.present?

     # document work source
     payload[ :work_source ] = solr_doc.at_path( 'id' )

     # related URL's
     payload[ :related_url ] = extract_related_url( solr_doc, fedora_doc )

     # sponsoring agency
     payload[:sponsoring_agency] = extract_sponsoring_agency( solr_doc, fedora_doc )

     # resource type
     payload[ :resource_type ] = determine_resource_type( solr_doc )

     #
     # handle optional fields
     #

     # degree program
     #degree = solr_doc.at_path( 'mods_extension_degree_level_t[0]' )
     #payload[ :degree ] = degree if degree.present?

     # keywords
     keywords = solr_doc.at_path( 'subject_topic_t' )
     payload[ :keywords ] = keywords if keywords.present?

     # language
     language = IngestHelpers.solr_first_field_extract(solr_doc, 'language_lang_code_t' )
     payload[ :language ] = IngestHelpers.language_code_lookup( language ) if language.present?

     # notes
     notes = IngestHelpers.solr_first_field_extract(solr_doc, 'note_t' )
     payload[ :notes ] = notes if notes.present?

     # publisher attributes
     publisher = extract_publisher( solr_doc, fedora_doc )
     payload[ :publisher ] = publisher if publisher.present?
     publish_location = extract_publish_location( solr_doc, fedora_doc )
     payload[ :publish_location ] = publish_location if publish_location.present?
     publish_date = extract_publish_date( solr_doc, fedora_doc )
     payload[ :publish_date ] = publish_date if publish_date.present?

     # ISBN & ISSN
     isbn = extract_isbn( solr_doc, fedora_doc )
     payload[ :isbn ] = isbn if isbn.present?
     issn = extract_issn( solr_doc, fedora_doc )
     payload[ :issn ] = issn if issn.present?

     # conference attributes
     conference_title = extract_conference_name( solr_doc, fedora_doc )
     payload[ :conference_title ] = conference_title if conference_title.present?
     conference_location = extract_conference_location( solr_doc, fedora_doc )
     payload[ :conference_location ] = conference_location if conference_location.present?
     conference_date = extract_conference_date( solr_doc, fedora_doc )
     payload[ :conference_date ] = conference_date if conference_date.present?

     # page attributes
     start_page = extract_start_page( solr_doc, fedora_doc )
     payload[ :start_page ] = start_page if start_page.present?
     end_page = extract_end_page( solr_doc, fedora_doc )
     payload[ :end_page ] = end_page if end_page.present?

     # journal attributes
     journal_title = extract_journal_name( solr_doc, fedora_doc )
     payload[ :journal_title ] = journal_title if journal_title.present?
     journal_volume = extract_journal_volume( solr_doc, fedora_doc )
     payload[ :journal_volume ] = journal_volume if journal_volume.present?
     journal_issue = extract_journal_issue( solr_doc, fedora_doc )
     payload[ :journal_issue ] = journal_issue if journal_issue.present?
     journal_year = extract_journal_year( solr_doc, fedora_doc )
     payload[ :journal_publication_year ] = journal_year if journal_year.present?

     # edited book attributes
     payload[ :editors ] = []
     editor_number = 0
     while true
       added, payload[ :editors ] = add_editor( solr_doc, editor_number, payload[ :editors ] )
       break unless added
       editor_number += 1
     end

     # construct the citation
     payload[ :citation ] = CitationHelpers.construct( payload )

     return payload
  end

  #
  # Attempt to extract the title
  #
  def extract_title( solr_doc, fedora_doc )

    # general approach
    title = IngestHelpers.solr_first_field_extract(solr_doc, 'mods_title_info_t')
    return title if title.present?

    return nil
  end

  #
  # Attempt to extract the abstract
  #
  def extract_abstract( solr_doc, fedora_doc )

    # document abstract (use the XML variant as it reflects the formatting better)
    abstract = IngestHelpers.fedora_first_field_extract( fedora_doc, 'mods abstract' )
    return abstract if IngestHelpers.field_supplied( abstract )

    # try the MODS record instead
    abstract = IngestHelpers.solr_first_field_extract(solr_doc, 'mods_abstract_t' )
    return abstract if IngestHelpers.field_supplied( abstract )

    return nil
  end

  #
  # Attempt to extract issue/publication date
  #
  def extract_issued_date( solr_doc, fedora_doc )

    # general approach
    issued_date = IngestHelpers.solr_first_field_extract(solr_doc, 'origin_info_date_issued_t' )
    return issued_date if issued_date.present?

    issued_date = IngestHelpers.fedora_first_field_extract( fedora_doc, 'mods dateIssued' )
    return issued_date if issued_date.present?

    # try for books
    issued_date = IngestHelpers.solr_first_field_extract(solr_doc, 'origin_info_year_issued_t' )
    return issued_date if issued_date.present?
    issued_date = IngestHelpers.solr_first_field_extract(solr_doc, 'book_origin_info_year_issued_t' )
    return issued_date if issued_date.present?

    # try for conference papers
    issued_date = IngestHelpers.solr_first_field_extract(solr_doc, 'conference_date_t' )
    return issued_date if issued_date.present?

    return nil
  end

  #
  # Attempt to extract the related URL
  #
  def extract_related_url( solr_doc, fedora_doc )

    # general approach
    related_url = IngestHelpers.solr_first_field_extract(solr_doc, 'other_version_location_t')
    return related_url if related_url.present?

    return nil
  end

  #
  # Attempt to extract the sponsoring agency
  #
  def extract_sponsoring_agency( solr_doc, fedora_doc )

    # general approach
    sponsor = IngestHelpers.solr_first_field_extract(solr_doc, 'mods_sponsor_sponsor_name_t')
    return sponsor if sponsor.present?

    return nil
  end

  #
  # Attempt to extract the start page
  #
  def extract_start_page( solr_doc, fedora_doc )

    # for books and articles
    start_page = IngestHelpers.fedora_first_field_extract( fedora_doc, 'mods relatedItem part extent start' )
    return start_page if start_page.present?
    return nil
  end

  #
  # Attempt to extract the end page
  #
  def extract_end_page( solr_doc, fedora_doc )

    # for books and articles
    start_page = IngestHelpers.fedora_first_field_extract( fedora_doc, 'mods relatedItem part extent end' )
    return start_page if start_page.present?
    return nil
  end

  #
  # Attempt to extract the publisher
  #
  def extract_publisher( solr_doc, fedora_doc )

     # for books
     publisher = IngestHelpers.fedora_first_field_extract( fedora_doc, 'mods originInfo publisher' )
     return publisher if publisher.present?
     return nil
  end

  #
  # Attempt to extract the publish location
  #
  def extract_publish_location( solr_doc, fedora_doc )

    # for books
    publish_location = IngestHelpers.fedora_first_field_extract( fedora_doc, 'mods originInfo place placeTerm' )
    return publish_location if publish_location.present?
    return nil
  end

  #
  # Attempt to extract the publish date
  #
  def extract_publish_date( solr_doc, fedora_doc )

    # for books
    publish_date = IngestHelpers.fedora_first_field_extract( fedora_doc, 'mods originInfo dateOther' )
    return publish_date if publish_date.present?
    return nil
  end

  #
  # Attempt to extract the ISBN
  #
  def extract_isbn( solr_doc, fedora_doc )

    # for books
    isbn = IngestHelpers.fedora_first_field_extract( fedora_doc, 'mods identifier', 'isbn' )
    return isbn if isbn.present?
    return nil
  end

  #
  # Attempt to extract the ISSN
  #
  def extract_issn( solr_doc, fedora_doc )

    # for articles
    issn = IngestHelpers.fedora_first_field_extract( fedora_doc, 'mods identifier', 'issn' )
    return issn if issn.present?
    return nil
  end

  #
  # Attempt to extract the conference name
  #
  def extract_conference_name( solr_doc, fedora_doc )

    # for conferences
    node = IngestHelpers.fedora_first_node_extract(fedora_doc, 'mods relatedItem name', 'conference' )
    return nil if node.nil?
    name = IngestHelpers.fedora_first_field_extract( node, 'namePart' )
    return name if name.present?
    return nil
  end

  #
  # Attempt to extract the conference location
  #
  def extract_conference_location( solr_doc, fedora_doc )

    # for conferences
    node = IngestHelpers.fedora_first_node_extract(fedora_doc, 'mods relatedItem name', 'conference' )
    return nil if node.nil?

    location = IngestHelpers.fedora_first_field_extract( node, 'affiliation' )
    return location if location.present?
    return nil
  end

  #
  # Attempt to extract the conference date
  #
  def extract_conference_date( solr_doc, fedora_doc )

    # for conferences
    node = IngestHelpers.fedora_first_node_extract(fedora_doc, 'mods relatedItem name', 'conference' )
    return nil if node.nil?

    date = IngestHelpers.fedora_last_field_extract( node, 'namePart', 'date' )
    return date if date.present?
    return nil
  end

  #
  # Attempt to extract the journal name
  #
  def extract_journal_name( solr_doc, fedora_doc )

    # for journals
    node = IngestHelpers.fedora_first_node_extract(fedora_doc, 'mods relatedItem', 'host' )
    return nil if node.nil?

    name = IngestHelpers.fedora_first_field_extract( node, 'titleInfo title' )
    return nil if name.present? == false
    return name
  end

  #
  # Attempt to extract the journal volume
  #
  def extract_journal_volume( solr_doc, fedora_doc )

    # for journals
    node = IngestHelpers.fedora_first_node_extract(fedora_doc, 'mods relatedItem', 'host' )
    return nil if node.nil?

    node = IngestHelpers.fedora_first_node_extract(node, 'part detail', 'volume' )
    return nil if node.nil?
    node = IngestHelpers.fedora_first_node_extract(node, 'number' )
    return nil if node.nil? || node.text.present? == false
    return node.text
  end

  #
  # Attempt to extract the journal issue
  #
  def extract_journal_issue( solr_doc, fedora_doc )

    # for journals
    node = IngestHelpers.fedora_first_node_extract(fedora_doc, 'mods relatedItem', 'host' )
    return nil if node.nil?

    node = IngestHelpers.fedora_first_node_extract(node, 'part detail', 'number' )
    return nil if node.nil?
    node = IngestHelpers.fedora_first_node_extract(node, 'number' )
    return nil if node.nil? || node.text.present? == false
    return node.text
  end

  #
  # Attempt to extract the journal year
  #
  def extract_journal_year( solr_doc, fedora_doc )

    # for journals
    node = IngestHelpers.fedora_first_node_extract(fedora_doc, 'mods relatedItem', 'host' )
    return nil if node.nil?

    node_list = IngestHelpers.fedora_node_list_extract( node, 'part date' )
    return nil if node_list.nil?
    node_list.each_with_index do |n, ix|
      if n.text.length == 4
        return n.text
      end
    end
    return nil
  end

  #
  # based on the directory we are ingesting from, take a guess at the resource type
  #
  def determine_resource_type( solr_doc )

    resource_type = solr_doc.at_path( 'object_type_facet[0]' )
    rt = nil
    case resource_type
      when 'Article'
        rt = 'article'
      when 'Article Preprint'
          rt = 'article_reprint'
      when 'Book'
        rt = 'book'
      when 'Part of Book'
        rt = 'book_part'
      when 'Chapter in an Edited Collection'
        rt = 'book_part'
      when 'Conference Proceeding', 'Conference Paper'
        rt = 'conference_paper'
      else
         puts "==> Unknown resource type: #{resource_type}"
    end
    return rt
  end


  #
  # adds another author if we can locate one
  #
  def add_author( solr_doc, author_number, authors )

    role = solr_doc.at_path( "mods_0_name_#{author_number}_role_0_text_t[0]" )
    if role && role.include?( 'author' )
      cid = solr_doc.at_path( "mods_0_name_#{author_number}_computing_id_t[0]" )
      fn = solr_doc.at_path( "mods_0_name_#{author_number}_first_name_t[0]" )
      ln = solr_doc.at_path( "mods_0_name_#{author_number}_last_name_t[0]" )
      dept = solr_doc.at_path( "mods_0_name_#{author_number}_description_t[0]" )
      ins = solr_doc.at_path( "mods_0_name_#{author_number}_institution_t[0]" )

      return add_person( authors, author_number, cid, fn, ln, dept, ins )
    end

    # could not find the next author, we are done
    return false, authors
  end

  #
  # adds another editor if we can locate one
  #
  def add_editor( solr_doc, editor_number, editors )

     fn = solr_doc.at_path( "book_0_editor_#{editor_number}_first_name_t[0]" )
     ln = solr_doc.at_path( "book_0_editor_#{editor_number}_last_name_t[0]" )

     return add_person( editors, editor_number, '', fn, ln, '', '' ) if fn.present? && ln.present?

     # could not find the next editor, we are done
     return false, editors
  end

  #
  # adds another contributor if we can locate one
  #
  def add_contributor( solr_doc, contributor_number, contributors )

    #
    # for libra open, the only contributors are book editors
    #

    fn = solr_doc.at_path( "mods_0_book_0_editor_#{contributor_number}_first_name_t[0]" )
    ln = solr_doc.at_path( "mods_0_book_0_editor_#{contributor_number}_last_name_t[0]" )

    if fn.blank? == false && ln.blank? == false
      return add_person( contributors, contributor_number, '', fn, ln, '', '' )
    end

    # could not find the next contributor, we are done
    return false, contributors
  end

  #
  # adds another person to the person list if we have one
  #
  def add_person( persons, index, cid, fn, ln, dept, ins )

    computing_id = IngestHelpers.field_supplied( cid ) ? cid : ''
    first_name = IngestHelpers.field_supplied( fn ) ? fn : ''
    last_name = IngestHelpers.field_supplied( ln ) ? ln : ''
    department = IngestHelpers.field_supplied( dept ) ? IngestHelpers.department_lookup( dept ) : ''
    institution = IngestHelpers.field_supplied( ins ) ? ins : ''

    if computing_id.blank? == false ||
       first_name.blank? == false ||
       last_name.blank? == false ||
       department.blank? == false ||
       institution.blank? == false
       person = TaskHelpers.make_person( index,
                                         computing_id,
                                         first_name,
                                         last_name,
                                         department,
                                         institution
                                       )

      return true, persons << person
    end
    return false, persons
  end

  #
  # calculate embargo release date
  #
  def add_embargo_release_date( payload )

    # handle embargo release date calculation
    if payload[ :embargo_type ] == 'uva'
       if payload[ :issued ]
          payload[ :embargo_release_date ] = IngestHelpers.calculate_embargo_release_date( payload[ :issued ] )
       elsif payload[ :create_date ]
          payload[ :embargo_release_date ] = IngestHelpers.calculate_embargo_release_date( payload[ :create_date ] )
       end
    end
    return payload
  end

  #
  # apply any default values and behavior to the standard payload
  #
  def apply_defaults_for_legacy_item( defaults, payload )

    # merge in defaults
    defaults.each { |k, v|

      case k

        when :notes
          next if v.blank?

          # create the admin notes for this item
          new_notes = payload[ :notes ] || ''
          new_notes += "\n\n" if new_notes.blank? == false

          original_create_date = payload[ :create_date ]
          dt = datetime_from_string( original_create_date )
          original_create_date = dt.strftime( "%Y-%m-%d %H:%M:%S" ) if dt.nil? == false
          time_now = CurationConcerns::TimeService.time_in_utc.strftime( "%Y-%m-%d %H:%M:%S" )
          new_notes += "#{v.gsub( 'LIBRA1_CREATE_DATE', original_create_date ).gsub( 'CURRENT_DATE', time_now )}"
          payload[ :notes ] = new_notes

       else if payload.key?( k ) == false
               payload[ k ] = v
            end
       end
    }

    return payload
  end

  end   # namespace ingest

end   # namespace libraoc

#
# end of file
#
