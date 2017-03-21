#
# Tasks to manage ingest of legacy Libra metadata
#

# pull in the helpers
require_dependency 'tasks/ingest_helpers'
include IngestHelpers

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

  desc "Enumerate legacy Libra items"
  task legacy_list: :environment do |t, args|

    count = 0
    LibraWork.search_in_batches( {} ) do |group|
      group.each do |gw_solr|

        begin
           gw = LibraWork.find( gw_solr['id'] )
           if gw.is_legacy_thesis?
             puts "#{gw.work_source} #{gw.identifier || 'None'}"
             count += 1
           end
        rescue => e
        end

      end

      puts "Listed #{count} legacy work(s)"
    end

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

     puts "Ingesting #{File.basename( dirname )} (#{id})..."
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
       puts "New work created; id: #{work.id} (#{work.identifier[0] || 'none'})"
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

     # document source
     payload[ :source ] = solr_doc.at_path( 'id' )

     # resource type
     payload[ :resource_type ] = IngestHelpers.determine_resource_type( dirname )

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

     # construct the citation
     payload[ :citation ] = IngestHelpers.construct_citation( payload )

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

    # general approach
    abstract = IngestHelpers.solr_first_field_extract(solr_doc, 'mods_abstract_t' )
    return abstract if IngestHelpers.field_supplied( abstract )

    abstract = IngestHelpers.fedora_first_field_extract( fedora_doc, 'mods abstract' )
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

      return add_person( authors, cid, fn, ln, dept, ins )
    end

    # could not find the next author, we are done
    return false, authors
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
      return add_person( contributors, '', fn, ln, '', '' )
    end

    # could not find the next contributor, we are done
    return false, contributors
  end

  #
  # adds another person to the person list if we have one
  #
  def add_person( persons, cid, fn, ln, dept, ins )

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
       person = TaskHelpers.make_person( computing_id,
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
