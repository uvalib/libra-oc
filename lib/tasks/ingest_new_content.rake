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
  desc "Ingest new Libra content; must provide the ingest directory; optionally provide the start index"
  task new_content: :environment do |t, args|



    asset_dir = ARGV[ 1 ]
    if asset_dir.nil?
      puts "ERROR: no ingest directory specified, aborting"
      next
    end
    task asset_dir.to_sym do ; end

    ingest_csv = ARGV[ 2 ]
    if ingest_csv.nil? && !File.exist?(ingest_csv)
      puts "ERROR: no ingest csv specified, aborting"
      next
    end
    task ingest_csv.to_sym do ; end

    depositor_arg = ARGV[3]
    if depositor_arg.empty?
      puts "No Depositor provided, Using the default: #{TaskHelpers::DEFAULT_USER}"
      sleep 10
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

    start = ARGV[ 4]
    if start.nil?
      start = "0"
    end
    task start.to_sym do ; end

    start_ix = start.to_i
    start_ix = 0 if start_ix.to_s != start


    # get the list of items to be ingested
    ingests = CSV.read(ingest_csv, headers: true, col_sep: "\t")
    if ingests.empty?
      puts "ERROR: ingest csv does not contain contains any items, aborting"
      next
    end

    # disable the workflow callbacks
    TaskHelpers.disable_workflow_callbacks


    success_count = 0
    error_count = 0
    total = ingests.length
    ingests.each_with_index do | row, ix |
      break if ENV[ 'MAX_COUNT' ] && ENV[ 'MAX_COUNT' ].to_i == ( success_count + error_count )
      next if ix < start_ix

      work = nil
      begin
        # Look up the work by title
        workSearch = LibraWork.where(depositor: depositor.email, title: row['Title'])
        case workSearch.length
        when 0
          puts "ERROR: Libra Work not found for title: #{row['Title']}\nSkipping..."
          error_count += 1
          next
        when 1
          # continue attaching files
          work = workSearch.first
        else
          # where() also finds partial name matches. Select an exact match here.
          dupeCheck = workSearch.select{|work| work.title == [row['Title']]}
          if dupeCheck.one?
            work = dupeCheck.first
          else
            # Titles really match, this is a problem
            puts "ERROR: More than one work found for the title: #{row['Title']}\nSkipping..."
            error_count += 1
            next
          end
        end
      rescue ActiveFedora::ObjectNotFoundError => e
        puts e
        puts "ERROR: Record doesn't exist, skipping...\nThis shouldn't happen, the Fedora reference is missing and is in a partially deleted state."
        error_count += 1
        next
      end

      # upload files from row
      if ingest_new_content( depositor, work, row['Files'], asset_dir, ix, total )
        success_count += 1
      else
        error_count += 1
      end

    end
    puts "#{success_count} item(s) processed successfully, #{error_count} error(s) encountered"

  end

  #
  # helpers
  #

  #
  # add legacy content to an existing metadata record
  #
  def ingest_new_content( depositor, work, file_str, asset_dir, current, total )
    file_names = file_str.split('|')

    puts "Ingesting row #{current} of #{total}: #{work.title.join} (#{file_names.length} assets)..."

    # handle dry running
    return true if ENV[ 'DRY_RUN' ]

    # and upload each file
    file_names.each do |file_name|

      # Clamav can't handle file names with space, (, or )
      # Assume they have been removed, but keep them in the label
      adjusted_file_name = file_name.gsub(/[() ]/, '_')
      file_path = File.join( asset_dir, adjusted_file_name )

      # remove spaces in filename
      #file_no_spaces = file_path.gsub(' ', '_')
      #File.rename(file_path, file_no_spaces)
      #file_path = file_no_spaces

      # Check for existing asset
      if work.file_sets.any? {|fs| fs.title.first == file_name }
        puts "Skipping existing file: #{file_name}"
        next
      end

      if File.exist?(file_path)
        fileset = TaskHelpers.upload_file( depositor, work, file_path, file_name, work.visibility )
      else
        puts "File does not exist: #{file_path}"
      end
      # Upload very slowly...
      sleep(30)

    end

    return true
  end

  end   # namespace ingest

end   # namespace libraoc

#
# end of file
#
