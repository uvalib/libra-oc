#
# Tasks to manage ingest of legacy Libra content
#

# pull in the helpers
require_dependency 'tasks/ingest_helpers'
include IngestHelpers

namespace :libraoc do

  namespace :ingest do

  desc "Purge legacy ingest ids; must provide the ingest directory"
  task purge_legacy_ingest_id: :environment do |t, args|

    ingest_dir = ARGV[ 1 ]
    if ingest_dir.nil?
      puts "ERROR: no ingest directory specified, aborting"
      next
    end
    task ingest_dir.to_sym do ; end

    # get the list of items to be ingested
    ingests = IngestHelpers.get_legacy_ingest_list(ingest_dir )
    if ingests.empty?
      puts "ERROR: ingest directory does not contain contains any items, aborting"
      next
    end

    ingests.each_with_index do | dirname, ix |
      IngestHelpers.clear_legacy_ingest_id(File.join(ingest_dir, dirname ) )
    end

    puts "done"
  end

  desc "Enumerate legacy Libra items"
  task legacy_list: :environment do |t, args|

    count = 0
    LibraWork.search_in_batches( {} ) do |group|
      group.each do |gw_solr|

        begin
          gw = LibraWork.find( gw_solr['id'] )
          if gw.is_legacy_content?
            puts "#{gw.work_source} #{gw.doi || 'None'}"
            count += 1
          end
        rescue => e
        end

      end

      puts "Listed #{count} legacy work(s)"
    end

  end

  desc "Finalize legacy ingest works; must provide the ingest directory"
  task finalize_legacy_ingests: :environment do |t, args|

    ingest_dir = ARGV[ 1 ]
    if ingest_dir.nil?
      puts "ERROR: no ingest directory specified, aborting"
      next
    end
    task ingest_dir.to_sym do ; end

    # get the list of items to be ingested
    ingests = IngestHelpers.get_legacy_ingest_list( ingest_dir )
    if ingests.empty?
      puts "ERROR: ingest directory does not contain contains any items, aborting"
      next
    end

    count = 0
    errors = 0
    ingests.each_with_index do | dirname, ix |
      work_id = IngestHelpers.get_legacy_ingest_id( File.join( ingest_dir, dirname ) )

      if work_id.blank?
        puts "ERROR: no work id for #{filename}, continuing anyway"
        errors += 1
        next
      end

      work = TaskHelpers.get_work_by_id( work_id )
      if work.nil?
        puts "ERROR: work #{work_id} does not exist, continuing anyway"
        errors += 1
        next
      end

      # only finalize items without DOI's...
      if work.doi.blank?
        puts "Finalizing #{ix + 1} of #{ingests.length} (#{work_id})..."

        if update_work_unassigned_doi( work ) == true
          count += 1
        else
          errors += 1
        end

      else
        puts "Work #{ix + 1} of #{ingests.length} (#{work_id}) already has a DOI, ignoring"
      end

    end

    puts "Finalized #{count} of #{ingests.length} ingest work(s). #{errors} error(s) encountered."
  end

  desc "Delete legacy ingest works; must provide the ingest directory"
  task delete_legacy_ingests: :environment do |t, args|

    ingest_dir = ARGV[ 1 ]
    if ingest_dir.nil?
      puts "ERROR: no ingest directory specified, aborting"
      next
    end
    task ingest_dir.to_sym do ; end

    # get the list of items to be ingested
    ingests = IngestHelpers.get_legacy_ingest_list( ingest_dir )
    if ingests.empty?
      puts "ERROR: ingest directory does not contain contains any items, aborting"
      next
    end

    count = 0
    ingests.each_with_index do | dirname, ix |
      work_id = IngestHelpers.get_legacy_ingest_id( File.join( ingest_dir, dirname ) )

      if work_id.blank?
        puts "ERROR: no work id for #{filename}, continuing anyway"
        next
      end

      work = TaskHelpers.get_work_by_id( work_id )
      if work.nil?
        puts "ERROR: work #{work_id} does not exist, continuing anyway"
        next
      end

      delete_libra_work_callback( work )
      count += 1

    end

    puts "Deleted #{count} of #{ingests.length} ingest work(s)"
  end

  desc "Build reference works; must provide the reference list file, ingest data directory and the target directory"
  task build_reference_works: :environment do |t, args|

    reference_works = ARGV[ 1 ]
    if reference_works.nil?
      puts "ERROR: no reference works file specified, aborting"
      next
    end
    task reference_works.to_sym do ; end

    ingest_dir = ARGV[ 2 ]
    if ingest_dir.nil?
      puts "ERROR: no ingest directory specified, aborting"
      next
    end
    task ingest_dir.to_sym do ; end

    target_dir = ARGV[ 3 ]
    if target_dir.nil?
      puts "ERROR: no target directory specified, aborting"
      next
    end
    task target_dir.to_sym do ; end

    if File.exists?( reference_works ) == false
      puts "ERROR: reference works file (#{reference_works}) does not exist, aborting"
      next
    end

    if Dir.exists?( ingest_dir ) == false
      puts "ERROR: ingest directory (#{ingest_dir}) does not exist, aborting"
      next
    end

    if Dir.exists?( target_dir ) == true
      puts "ERROR: target directory (#{target_dir}) already exists, aborting"
      next
    end

    reference_list = IngestHelpers.load_reference_works( reference_works )
    if reference_list.empty? == true
      puts "ERROR: reference works file is empty, aborting"
      next
    end
    puts "Loaded #{reference_list.length} reference work(s)..."

    # get all the available works
    ok, articles, article_reprints, books, book_parts, conference_papers = load_all_ingest_data( ingest_dir )
    next if ok == false

    errors = 0
    count = 0

    reference_list.each_with_index do |w, ix|

      work_type = File.dirname( w )
      work_ref = File.basename( w )

      puts "Extracting #{ix + 1} of #{reference_list.length} (#{work_ref})..."

      case work_type
        when 'article'
           work_item = locate_work_item( File.join( ingest_dir, work_type ), work_ref, articles )
        when 'article_reprint'
          work_item = locate_work_item( File.join( ingest_dir, work_type ), work_ref, article_reprints )
        when 'book'
          work_item = locate_work_item( File.join( ingest_dir, work_type ), work_ref, books )
        when 'book_part'
          work_item = locate_work_item( File.join( ingest_dir, work_type ), work_ref, book_parts )
        when 'conference_paper'
          work_item = locate_work_item( File.join( ingest_dir, work_type ), work_ref, conference_papers )
        else
          puts "ERROR: unknown work type #{work_type}, skipping..."
          errors += 1
          next
      end

      if work_item.nil?
        puts "ERROR: cannot locate work item #{w}, skipping..."
        errors += 1
        next
      end

      # copy the work item we located
      ok = copy_work_item( target_dir, File.join( ingest_dir, work_type, work_item ), count + 1 )
      ok ? count += 1 : errors += 1

    end

    puts "#{count} work(s) copied, #{errors} error(s) encountered"
  end

  desc "Rename reference works; must provide the reference list file and the ingest data directory"
  task rename_reference_works: :environment do |t, args|

    reference_works = ARGV[ 1 ]
    if reference_works.nil?
      puts "ERROR: no reference works file specified, aborting"
      next
    end
    task reference_works.to_sym do ; end

    ingest_dir = ARGV[ 2 ]
    if ingest_dir.nil?
      puts "ERROR: no ingest directory specified, aborting"
      next
    end
    task ingest_dir.to_sym do ; end

    if File.exists?( reference_works ) == false
      puts "ERROR: reference works file (#{reference_works}) does not exist, aborting"
      next
    end

    if Dir.exists?( ingest_dir ) == false
      puts "ERROR: ingest directory (#{ingest_dir}) does not exist, aborting"
      next
    end

    reference_list = IngestHelpers.load_reference_works( reference_works )
    if reference_list.empty? == true
      puts "ERROR: reference works file is empty, aborting"
      next
    end
    puts "Loaded #{reference_list.length} reference work(s)..."

    # get all the available works
    ok, articles, article_reprints, books, book_parts, conference_papers = load_all_ingest_data( ingest_dir )
    next if ok == false


  end

  #
  # helpers
  #

  #
  # load all ingestable data in the specified directory
  #
  def load_all_ingest_data( ingest_root )

    # get all the available works
    puts "Loading all ingestable works from #{ingest_root}..."

    articles = IngestHelpers.get_legacy_ingest_list( File.join( ingest_root, 'article' ) )
    article_reprints = IngestHelpers.get_legacy_ingest_list( File.join( ingest_root, 'article_reprint' ) )
    books = IngestHelpers.get_legacy_ingest_list( File.join( ingest_root, 'book' ) )
    book_parts = IngestHelpers.get_legacy_ingest_list( File.join( ingest_root, 'book_part' ) )
    conference_papers = IngestHelpers.get_legacy_ingest_list( File.join( ingest_root, 'conference_paper' ) )

    load_count = 0
    if articles.empty?
      puts "ERROR: article list is empty, aborting"
      return false, nil, nil, nil, nil, nil
    else
      load_count += articles.length
    end

    if article_reprints.empty?
      puts "ERROR: article_reprint list is empty, aborting"
      return false, nil, nil, nil, nil, nil
    else
      load_count += article_reprints.length
    end
    if books.empty?
      puts "ERROR: book list is empty, aborting"
      return false, nil, nil, nil, nil, nil
    else
      load_count += books.length
    end
    if book_parts.empty?
      puts "ERROR: book_part list is empty, aborting"
      return false, nil, nil, nil, nil, nil
    else
      load_count += book_parts.length
    end
    if conference_papers.empty?
      puts "ERROR: conference_paper list is empty, aborting"
      return false, nil, nil, nil, nil, nil
    else
      load_count += conference_papers.length
    end

    puts "#{load_count} work(s) loaded"

    return true, articles, article_reprints, books, book_parts, conference_papers

  end

  #
  # locate the specified work item from the specified list
  #
  def locate_work_item( base_dir, work_ref, work_list )

    work_list.each do |w|
      json_doc = TaskHelpers.load_json_doc( File.join( base_dir, w, TaskHelpers::DOCUMENT_JSON_FILE ) )
      next if json_doc.nil?
      if json_doc['id'] == work_ref
        return w
      end
    end

    # could not locate it
    return nil
  end

  #
  # copy a work item to the target directory
  #
  def copy_work_item( base_target_dir, work_item, item_number )

    puts "copying #{work_item}..."

    target_dir = File.join( base_target_dir, "extract.#{item_number}" )
    begin
       FileUtils.mkdir_p( target_dir )
       contents = TaskHelpers.get_directory_list( work_item, /^.*$/ )
       contents.each do |f|
         next if f == '.' || f == '..'

         puts "  copying #{File.join( work_item, f )} -> #{target_dir}"
         FileUtils.cp( File.join( work_item, f ), target_dir )
       end

       #puts "  deleting #{work_item}..."
       #FileUtils.rm_rf( work_item )
       return true
    rescue => ex
       puts "ERROR: #{ex}"
       return false
    end
  end

  end   # namespace ingest

end   # namespace libraoc

#
# end of file
#
