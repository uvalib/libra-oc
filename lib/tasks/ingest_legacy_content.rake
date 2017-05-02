#
# Tasks to manage ingest of legacy Libra content
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
  # DRY_RUN      - Dont actually create the items
  #

  #
  # ingest content
  #
  desc "Ingest legacy Libra content; must provide the ingest directory; optionally provide the start index"
  task legacy_content: :environment do |t, args|

    ingest_dir = ARGV[ 1 ]
    if ingest_dir.nil?
      puts "ERROR: no ingest directory specified, aborting"
      next
    end
    task ingest_dir.to_sym do ; end

    start = ARGV[ 2 ]
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

    # disable the allocate DOI callback for the ingest
    LibraWork.skip_callback( :save, :after, :allocate_doi )

    success_count = 0
    error_count = 0
    total = ingests.size
    ingests.each_with_index do | dirname, ix |
      next if ix < start_ix
      ok = ingest_legacy_content( File.join( ingest_dir, dirname ), ix + 1, total )
      ok == true ? success_count += 1 : error_count += 1
      break if ENV[ 'MAX_COUNT' ] && ENV[ 'MAX_COUNT' ].to_i == ( success_count + error_count )
    end
    puts "#{success_count} item(s) processed successfully, #{error_count} error(s) encountered"

  end

  #
  # helpers
  #

  #
  # add legacy content to an existing metadata record
  #
  def ingest_legacy_content( dirname, current, total )

     assets = IngestHelpers.get_document_assets( dirname )
     puts "Ingesting #{current} of #{total}: #{File.basename( dirname )} (#{assets.length} assets)..."

     work_id = IngestHelpers.get_legacy_ingest_id(dirname )

     work = TaskHelpers.get_work_by_id( work_id )
     if work.nil?
       puts "ERROR: work #{work_id} does not exist, continuing anyway"
       return false
     end

     # determine the original depositor
     depositor = TaskHelpers.lookup_and_create_account( User.cid_from_email( work.depositor ) )
     if depositor.nil?
       puts "ERROR: Cannot lookup or create depositor account (#{work.depositor})"
       return false
     end

     # handle dry running
     return true if ENV[ 'DRY_RUN' ]

     # and upload each file
     assets.each do |asset|
       fileset = TaskHelpers.upload_file( depositor, work, File.join( dirname, asset[ :title ] ), asset[ :title ] )
       fileset.date_uploaded = DateTime.parse( asset[ :timestamp ] )
       fileset.save!
     end

     return true
  end

  end   # namespace ingest

end   # namespace libraoc

#
# end of file
#
