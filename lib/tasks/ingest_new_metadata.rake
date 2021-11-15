#
# Tasks to manage ingest of legacy Libra metadata
#

# pull in the helpers
require_dependency 'tasks/ingest_helpers'
include IngestHelpers


require_dependency 'app/helpers/public_view_helper'
include PublicViewHelper

#require_dependency 'app/servivces/resource_types_service'
#include ResourceTypesService

namespace :libraoc do

  namespace :ingest do

  #
  # a list of the valid work resource types. We will populate this later using the resource_type authority
  # configured in config/authorities/resource_types.yml
  #
  @valid_resource_types = []

  #
  # it is possible to 'override' the resource type because the possible list in libra-oc is more comprehensive
  # than that of libra1
  #
  @resource_type_override = {}

  #
  # possible environment settings that affect the ingest behavior
  #
  # MAX_COUNT    - Maximum number of items to process
  # DUMP_PAYLOAD - Output the entire document metadata before saving
  # DRY_RUN      - Dont actually create the items
  #

  # number of author columns in the csv
  MAX_AUTHORS = 14

  #
  # ingest metadata
  #
  desc "Ingest New Libra data; must provide the ingest directory; optionally provide restource type override file, a defaults file and start index"
  task new_metadata: :environment do |t, args|

    ingest_file = ARGV[ 1 ]
    if ingest_file.nil? && !File.exist?(ingest_file)
      puts "ERROR: no ingest directory specified or file does not exist, aborting"
      next
    end
    task ingest_file.to_sym do ; end

    depositor_arg = ARGV[2]
    if depositor_arg.empty?
      puts "No Depositor provided, Using the default: #{TaskHelpers::DEFAULT_USER}"
      # load default depositor information
      depositor = TaskHelpers.lookup_and_create_account( TaskHelpers::DEFAULT_USER )
      if depositor.nil?
        puts "ERROR: Cannot lookup or create default depositor account (#{TaskHelpers::DEFAULT_USER})"
        next
      end
    else
      depositor = TaskHelpers.lookup_and_create_account( depositor_arg )
      if depositor.nil?
        puts "ERROR: Cannot lookup or create depositor account (#{depositor_arg})"
        next
      end
    end
    task depositor_arg.to_sym do ; end

    start = ARGV[ 3 ]
    if start.nil?
      start = "0"
    end
    task start.to_sym do ; end

    start_ix = start.to_i
    start_ix = 0 if start_ix.to_s != start

    # get the list of items to be ingested
    ingests = CSV.read(ingest_file, headers: true, col_sep: "\t")


    # disable the workflow callbacks
    TaskHelpers.disable_workflow_callbacks

    success_count = 0
    error_count = 0
    total = ingests.length

    ingests.each_with_index do | row, ix |


      break if ENV[ 'MAX_COUNT' ] && ENV[ 'MAX_COUNT' ].to_i == ( success_count + error_count )
      next if ix < start_ix


      begin
        w = LibraWork.where(depositor: depositor.email, title: row['Title'])
        # Check for presence but also that the title matches to skip
        # where() returns partial title matches
        if w.present? && w.first.title == [row['Title']]
          w = w.first
          if w.doi.nil?
            if w.sponsoring_agency == [""]
              puts "Fixing Sponsoring Agency for #{w.id}"
              w.sponsoring_agency = nil
            end
            # Assign a DOI
            w.send(:allocate_doi)

          end
          puts "Row #{ix} - Skipping existing title: #{row["Title"]}"

          success_count += 1
          next
        end
      rescue ActiveFedora::ObjectNotFoundError => e
        puts e
        puts "Row #{ix} - Record doesn't exist, skipping...\nThis shouldn't happen, the Fedora reference is missing and is in a partially deleted state."
        success_count += 1
        next
      end

      # Create from row
      if ingest_new_metadata( depositor, row, ix, total )
        success_count += 1
      else
        error_count += 1
      end

      if ix % 10 == 0
        # sleep more every 10 records
        sleep(30)
      else
        sleep(5)
      end

    end
    puts "#{success_count} item(s) processed successfully, #{error_count} error(s) encountered"

  end

  #
  # helpers
  #

  #
  # convert a set of Libra extract assets into a new Libra metadata record
  #
  def ingest_new_metadata( depositor, row, current, total )

    puts "Ingesting #{current} of #{total}: #{row['Title']}"

    # create a payload from the document
    payload = create_csv_ingest_payload(row)

    # remove empty fields
    payload.compact!

    # dump the fields as necessary...
    IngestHelpers.dump_ingest_payload( payload ) if ENV[ 'DUMP_PAYLOAD' ]

    # validate the payload
    errors, warnings = IngestHelpers.validate_ingest_payload( payload )

    if errors.empty? == false
      puts " ERROR(S) identified for row #{current }: #{row['Title']}"
      puts " ==> #{errors.join( "\n ==> " )}"
      return false
    end

    #if warnings.empty? == false
    #  puts " WARNING(S) identified for row #{current - 1 }: #{row['Title']}, continuing anyway"
    #  puts " ==> #{warnings.join( "\n ==> " )}"
    #end

    # handle dry running
    return true if ENV[ 'DRY_RUN' ]

    # create the work
    ok, work = IngestHelpers.create_new_item( depositor, payload )
    if ok == true
      # Work created, create DOI
      if !work.doi.present? && !work.send(:allocate_doi)
        puts "Unable to allocate DOI"
      end

      puts "New work created; id: #{work.id} (#{work.doi || 'No DOI'})"
    else
      #puts " ERROR: creating new generic work for #{File.basename( dirname )} (#{id})"
      #return false
      puts " WARNING: while creating generic work for row #{current}: #{row['Title']}"
    end

    return ok
  end

  #
  # create a ingest payload from the Libra document
  #
  def create_csv_ingest_payload( row )


    payload = {}

    #
    # add all the required fields
    #

    # date and time attributes


    # resource type
    rt = row['Resource type']
    payload[ :resource_type ] = rt if rt.present?

    # title
    title = row['Title']
    payload[ :title ] = title if title.present?

    # abstract
    abstract = row['Abstract']
    payload[ :abstract ] = abstract if abstract.present?

    # author
    payload[ :authors ] = []
    author_number = 1

    while author_number < MAX_AUTHORS
      last_name = row["Author#{author_number}_LastName"]
      first_name = row["Author#{author_number}_FirstName"]

      break if first_name.blank? && last_name.blank?

      # remove extra whitespace
      first_name.strip!
      last_name.strip!

      # add a space when Anonymous
      first_name = " " if last_name == "Anonymous"

      author = {
        index: author_number - 1,
        first_name: first_name,
        last_name:  last_name
      }
      payload[:authors] << author
      author_number += 1
     end

    # document contributor
    # This assumes only one contributor
    payload[ :contributors ] = []
    if row['Contributor_LastName'].present? && row['Contributor_FirstName'].present?
      payload[:contributors] << {
        index: 0,
        first_name: row['Contributor_FirstName'],
        last_name: row['Contributor_LastName']
      }
     end


    # document work source
    #payload[ :work_source ] = ""

    # related URL's
    payload[ :related_url ] = [row['Related url']] if row['Related url'].present?

    # sponsoring agency
    payload[:sponsoring_agency] = [row['Sponsoring Agency']] if row['Sponsoring Agency'].present?


    # keywords
    keywords = row['Keyword']
    payload[ :keywords ] = keywords.split('|') if keywords.present?

    # language
    #languages = IngestHelpers.solr_all_field_extract(solr_doc, 'language_lang_code_t' )
    #languages = languages.map { |l| IngestHelpers.language_code_lookup( l ) } if languages.present?
    #payload[ :language ] = languages if languages.present?

    # notes
    payload[ :notes ] = row['Notes']

    # publisher attributes
    pd = row['Published Date']
    payload[:publish_date] = pd

    payload[:publisher] = row['Publisher']

    payload[:rights] = row['Rights']

    # All OEC records are public
    payload[:visibility] = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC

    return payload
  end


  end   # namespace ingest

end   # namespace libraoc

#
# end of file
#
