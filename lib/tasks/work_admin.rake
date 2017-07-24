#
# Some helper tasks to create and delete works
#

# pull in the helpers
require_dependency 'tasks/task_helpers'
include TaskHelpers

namespace :libraoc do

namespace :work do

  desc "List all works"
  task list_all: :environment do |t, args|

    count = 0
    LibraWork.search_in_batches( {} ) do |group|
      TaskHelpers.batched_process_solr_works( group, &method( :show_libra_work_callback ) )
      count += group.size
    end

    puts "Listed #{count} work(s)"
  end

  desc "List my works; optionally provide depositor email"
  task list_my: :environment do |t, args|

    who = ARGV[ 1 ]
    who = TaskHelpers.default_user_email if who.nil?
    task who.to_sym do ; end

    count = 0
    LibraWork.search_in_batches( { depositor: who } ) do |group|
      TaskHelpers.batched_process_solr_works( group, &method( :show_libra_work_callback ) )
      count += group.size
    end

    puts "Listed #{count} work(s)"
  end

  desc "List work by id; must provide the work id"
  task list_by_id: :environment do |t, args|

    work_id = ARGV[ 1 ]
    if work_id.nil?
      puts "ERROR: no work id specified, aborting"
      next
    end

    task work_id.to_sym do ; end

    work = TaskHelpers.get_work_by_id( work_id )
    if work.nil?
      puts "ERROR: work #{work_id} does not exist, aborting"
      next
    end

    TaskHelpers.show_libra_work(work )
  end

  desc "Work counts by depositor"
  task count_by_depositor: :environment do |t, args|

    depositors = {}
    count = 0
    LibraWork.search_in_batches( {} ) do |group|
      group.each do |gw_solr|
        begin
          gw = LibraWork.find( gw_solr['id'] )
          if depositors[ gw.depositor ].nil?
            depositors[ gw.depositor ] = 1
          else
            depositors[ gw.depositor ] = depositors[ gw.depositor ] + 1
          end
        rescue => e
          puts e
        end
      end

      count += group.size
    end

    # output a summary...
    depositors.keys.sort.each do |k|
      puts " #{k} => #{depositors[k]} work(s)"
    end

    puts "Summerized #{count} work(s)"
  end

  desc "Delete all works"
  task del_all: :environment do |t, args|

    count = 0
    LibraWork.search_in_batches( {} ) do |group|
      TaskHelpers.batched_process_solr_works( group, &method( :delete_libra_work_callback ) )
      count += group.size
    end

    puts "done" unless count == 0
    puts "Deleted #{count} work(s)"

  end

  desc "Delete my works; optionally provide depositor email"
  task del_my: :environment do |t, args|

     who = ARGV[ 1 ]
     who = TaskHelpers.default_user_email if who.nil?
     task who.to_sym do ; end

     count = 0
     LibraWork.search_in_batches( { depositor: who } ) do |group|
       TaskHelpers.batched_process_solr_works( group, &method( :delete_libra_work_callback ) )
       count += group.size
     end

     puts "done" unless count == 0
     puts "Deleted #{count} work(s)"

  end

  desc "Delete work by id; must provide the work id"
  task del_by_id: :environment do |t, args|

    work_id = ARGV[ 1 ]
    if work_id.nil?
      puts "ERROR: no work id specified, aborting"
      next
    end

    task work_id.to_sym do ; end

    work = TaskHelpers.get_work_by_id( work_id )
    if work.nil?
      puts "ERROR: work #{work_id} does not exist, aborting"
      next
    end

    delete_libra_work_callback( work )
    puts "Work deleted"
  end

  desc "Create new libra work; optionally provide depositor email"
  task create: :environment do |t, args|

    who = ARGV[ 1 ]
    who = TaskHelpers.default_user_email if who.nil?
    task who.to_sym do ; end

    # lookup user and exit if error
    user = User.find_by_email( who )
    if user.nil?
      puts "ERROR: locating user #{who}, aborting"
      next
    end

    id = Time.now.to_i
    title = "Example libra work title (#{id})"
    description = "Example libra work description (#{id})"

    work = create_libra_work( user, title, description )

    #filename = TaskHelpers.get_random_image( )
    #TaskHelpers.upload_file( user, work, filename, File.basename( filename ), work.visibility )

    TaskHelpers.show_libra_work work

  end

  desc "Transfer ownership of work by id; must provide the work id and new depositor email"
  task transfer_id: :environment do |t, args|

    work_id = ARGV[ 1 ]
    if work_id.nil?
      puts "ERROR: no work id specified, aborting"
      next
    end

    task work_id.to_sym do ; end

    work = TaskHelpers.get_work_by_id( work_id )
    if work.nil?
      puts "ERROR: work #{work_id} does not exist, aborting"
      next
    end

    who = ARGV[ 2 ]
    if who.nil?
      puts "ERROR: no depositor email specified, aborting"
      next
    end

    task who.to_sym do ; end

    # lookup user and exit if error
    user = User.find_by_email( who )
    if user.nil?
      puts "ERROR: locating user #{who}, aborting"
      next
    end

    if work.depositor == who
      puts "ERROR: work is already owned by #{who}, aborting"
      next
    end

#    ContentDepositorChangeEventJob.perform_now( work, who )
    work.depositor = who
    work.file_sets.each do |f|
      f.apply_depositor_metadata( user )
      f.save!
    end
    work.save!

    puts "Work transfered to #{who}"
  end

  desc "Show work id and DOI of all deposited works"
  task summerize_deposits: :environment do |t, args|

    count = 0
    LibraWork.search_in_batches( { } ) do |group|
      group.each do |solr_rec|
        ws = work_source_from_solr_doc( solr_rec )
        if ws.blank?
          puts "id:#{id_from_solr_doc( solr_rec )} #{doi_from_solr_doc( solr_rec )}"
          count += 1
        end

      end
    end

    puts "Listed #{count} work(s)"
  end

  desc "Show work id, source id and DOI of all migrated works"
  task summerize_migrated: :environment do |t, args|

    count = 0
    LibraWork.search_in_batches( { } ) do |group|
      group.each do |solr_rec|
        ws = work_source_from_solr_doc( solr_rec )
        if ws.present?
           puts "id:#{id_from_solr_doc( solr_rec )} ws:#{ws} #{doi_from_solr_doc( solr_rec )}"
           count += 1
        end

      end
    end

    puts "Listed #{count} work(s)"

  end

  #
  # helpers
  #

  def show_libra_work_callback( work )
    TaskHelpers.show_libra_work( work )
  end

  def delete_libra_work_callback( work )
    print "."
    # if the work is draft, we can remove the DOI, otherwise, we must revoke it
    #if work.is_draft? == true
    #  remove_doi( work )
    #else
    #  revoke_doi( work )
    #end
    work.destroy
  end

  def create_libra_work( user, title, description )

    work = LibraWork.create!(title: [ title ] ) do |w|

      # generic work attributes
      w.apply_depositor_metadata(user)
      w.creator = [ user.email ]

      w.authors = []
      w.authors << TaskHelpers.make_author( User.cid_from_email( user.email ), 0 )
      w.authors << TaskHelpers.make_author( 'naw4t', 1 )

      w.contributors = []
      w.contributors << TaskHelpers.make_contributor( 'ecr2c', 0 )
      w.contributors << TaskHelpers.make_contributor( 'sah', 1 )
      w.contributors << TaskHelpers.make_contributor( 'rwl', 2 )

      w.date_uploaded = CurationConcerns::TimeService.time_in_utc.to_s
      #w.date_created = CurationConcerns::TimeService.time_in_utc.to_s
      #w.published_date = CurationConcerns::TimeService.time_in_utc.to_s

      w.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC

      w.abstract = description

      w.publisher = LibraWork::DEFAULT_PUBLISHER
      w.notes = 'Placeholder notes'
      w.admin_notes << 'Placeholder admin notes'
      w.language = [ 'English', 'German', 'French' ]

      w.rights << LibraWork::DEFAULT_RIGHTS
      w.resource_type = 'Article'
    end

    return work
  end

  def work_source_from_solr_doc( solr_doc )
    fname = Solrizer.solr_name('work_source')
    return '' unless solr_doc[ fname ]
    return solr_doc[ fname ][ 0 ] if solr_doc[ fname ][ 0 ].start_with?( LibraWork::SOURCE_LEGACY )
    return ''
  end

  def id_from_solr_doc( solr_doc )
    fname = 'id'
    return '' unless solr_doc[ fname ]
    return solr_doc[ fname ]
  end

  def doi_from_solr_doc( solr_doc )
    fname = Solrizer.solr_name('doi')
    return 'None' unless solr_doc[ fname ] && solr_doc[ fname ][ 0 ]
    return solr_doc[ fname ][ 0 ]
  end

end   # namespace work

end   # namespace libraoc

#
# end of file
#
