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
  # NO_DOI       - Dont assign a DOI to the created items
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
    ingests.each_with_index do | dirname, ix |
      next if ix < start_ix
      ok = ingest_legacy_metadata( defaults, user, File.join( ingest_dir, dirname ) )
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
  def ingest_legacy_metadata( defaults, depositor, dirname )

     solr_doc, fedora_doc = IngestHelpers.load_legacy_ingest_content(dirname )
     id = solr_doc['id']

     puts "Ingesting #{File.basename( dirname )} (#{id})..."

     # create a payload from the document
     payload = create_legacy_ingest_payload( solr_doc, fedora_doc )

     # merge in any default attributes
     payload = apply_defaults_for_legacy_item( defaults, payload )

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
       puts "New work created; id #{work.id} (#{work.identifier || 'none'})"
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
  def create_legacy_ingest_payload( solr_doc, fedora_doc )


     payload = {}

     #
     # add all the required fields
     #

     # date and time attributes
     create_date = solr_doc.at_path( 'system_create_dt' )
     payload[ :create_date ] = IngestHelpers.extract_date( create_date ) if create_date.present?
     modified_date = solr_doc.at_path( 'system_modified_dt' )
     payload[ :modified_date ] = modified_date if modified_date.present?

     # document title
     title = solr_doc.at_path( 'mods_title_info_t[0]')
     payload[ :title ] = title if title.present?

     # document abstract (use the XML variant as it reflects the formatting better)
     # this was used for the 4th year theses
     #ab_node = fedora_doc.css( 'mods abstract' ).last
     # this was used for the subsequent items
     ab_node = fedora_doc.css( 'mods abstract' ).first
     abstract = ab_node.text if ab_node
     payload[ :abstract ] = abstract if IngestHelpers.field_supplied( abstract )

     # document author
     if solr_doc.at_path( 'mods_0_name_0_role_0_text_t[0]' ) == 'author'
       dept = solr_doc.at_path( 'mods_0_name_0_description_t[0]' )
       cid = solr_doc.at_path( 'mods_0_name_0_computing_id_t[0]' )
       fn = solr_doc.at_path( 'mods_0_name_0_first_name_t[0]' )
       ln = solr_doc.at_path( 'mods_0_name_0_last_name_t[0]' )
       payload[ :author_computing_id ] = cid if IngestHelpers.field_supplied( cid )
       payload[ :author_first_name ] = fn if IngestHelpers.field_supplied( fn )
       payload[ :author_last_name ] = ln if IngestHelpers.field_supplied( ln )
       payload[ :department ] = IngestHelpers.department_lookup( dept ) if IngestHelpers.field_supplied( dept )
     end

     # document advisor
     payload[ :advisors ] = []
     advisor_number = 1
     while true
        added, payload[ :advisors ] = add_advisor( solr_doc, advisor_number, payload[ :advisors ] )
        break unless added
        advisor_number += 1
     end

     # issue date
     issued_date = solr_doc.at_path( 'origin_info_date_issued_t[0]' )
     payload[ :issued ] = issued_date if issued_date.present?

     # embargo attributes
     embargo_type = solr_doc.at_path( 'release_to_t[0]' )
     payload[ :embargo_type ] = embargo_type if embargo_type.present?
     release_date = solr_doc.at_path( 'embargo_embargo_release_date_t[0]' )
     payload[ :embargo_release_date ] = release_date if release_date.present?
     payload[ :embargo_period ] =
         IngestHelpers.estimate_embargo_period( issued_date, release_date ) if issued_date.present? && release_date.present?

     # document source
     payload[ :source ] = solr_doc.at_path( 'id' )

     #
     # handle optional fields
     #

     # degree program
     degree = solr_doc.at_path( 'mods_extension_degree_level_t[0]' )
     payload[ :degree ] = degree if degree.present?

     # keywords
     keywords = solr_doc.at_path( 'subject_topic_t' )
     payload[ :keywords ] = keywords if keywords.present?

     # language
     language = solr_doc.at_path( 'language_lang_code_t[0]' )
     payload[ :language ] = IngestHelpers.language_code_lookup( language ) if language.present?

     # notes
     notes = solr_doc.at_path( 'note_t[0]' )
     payload[ :notes ] = notes if notes.present?

     return payload
  end

  #
  # adds another advisor if we can locate one
  #
  def add_advisor( solr_doc, advisor_number, advisors )

    if solr_doc.at_path( "mods_0_person_#{advisor_number}_role_0_text_t[0]" ) == 'advisor'
      cid = solr_doc.at_path( "mods_0_person_#{advisor_number}_computing_id_t[0]" )
      fn = solr_doc.at_path( "mods_0_person_#{advisor_number}_first_name_t[0]" )
      ln = solr_doc.at_path( "mods_0_person_#{advisor_number}_last_name_t[0]" )
      dept = solr_doc.at_path( "mods_0_person_#{advisor_number}_description_t[0]" )
      ins = solr_doc.at_path( "mods_0_person_#{advisor_number}_institution_t[0]" )

      advisor_computing_id = IngestHelpers.field_supplied( cid ) ? cid : ''
      advisor_first_name = IngestHelpers.field_supplied( fn ) ? fn : ''
      advisor_last_name = IngestHelpers.field_supplied( ln ) ? ln : ''
      advisor_department = IngestHelpers.field_supplied( dept ) ? IngestHelpers.department_lookup( dept ) : ''
      advisor_institution = IngestHelpers.field_supplied( ins ) ? ins : ''

      if advisor_computing_id.blank? == false ||
         advisor_first_name.blank? == false ||
         advisor_last_name.blank? == false ||
         advisor_department.blank? == false ||
         advisor_institution.blank? == false
         adv = TaskHelpers.contributor_fields( advisor_number - 1,
                                               advisor_computing_id,
                                               advisor_first_name,
                                               advisor_last_name,
                                               advisor_department,
                                               advisor_institution )

         return true, advisors << adv
      end
    end

    # could not find the next advisor, we are done
    return false, advisors
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

        when :force_embargo_period
          payload[ :embargo_period ] = v
          if payload[ :issued ]
             payload[ :embargo_release_date ] = IngestHelpers.calculate_embargo_release_date( payload[ :issued ], v )
          else
             #payload[ :embargo_release_date ] = IngestHelpers.calculate_embargo_release_date( v )
          end

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
