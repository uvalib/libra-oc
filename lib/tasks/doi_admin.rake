#
# Some helper tasks to manage DOI submission
#

# pull in the helpers
require_dependency 'tasks/task_helpers'
include TaskHelpers

require_dependency 'libraoc/serviceclient/entity_id_client'

namespace :libraoc do

  namespace :doi do

  #
  # list DOIs for all works
  #
  desc "List DOI's for all works"
  task list_all: :environment do |t, args|

    count = 0
    LibraWork.search_in_batches( {} ) do |group|
      TaskHelpers.batched_process_solr_works( group, &method( :show_work_doi_callback ) )
      count += group.size
    end

    puts "Listed #{count} work(s)"
  end

  #
  # list DOIs for all works from the specified user
  #
  desc "List DOI's for all my works; optionally provide depositor email"
  task list_my: :environment do |t, args|

     who = ARGV[ 1 ]
     who = TaskHelpers.default_user_email if who.nil?
     task who.to_sym do ; end

     count = 0
     LibraWork.search_in_batches( {depositor: who} ) do |group|
       TaskHelpers.batched_process_solr_works( group, &method( :show_work_doi_callback ) )
       count += group.size
     end

     puts "Listed #{count} work(s)"
  end

  #
  # get the EZID service metadata for the specified work
  #
  desc "Get EZID metadata for the specified work; must provide the work id"
  task ezid_metadata_by_id: :environment do |t, args|

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

    status, r = ServiceClient::EntityIdClient.instance.metadataget( work.doi )
    if ServiceClient::EntityIdClient.instance.ok?( status )
      puts r
    else
      puts "ERROR: EZID service returns #{status}, aborting"
    end

  end

  #
  # get the EZID service metadata for the specified DOI
  #
  desc "Get EZID metadata for the specified DOI; must provide the DOI"
  task ezid_metadata_by_doi: :environment do |t, args|

    doi = ARGV[ 1 ]
    if doi.nil?
      puts "ERROR: no DOI specified, aborting"
      next
    end

    task doi.to_sym do ; end

    status, r = ServiceClient::EntityIdClient.instance.metadataget( doi )
    if ServiceClient::EntityIdClient.instance.ok?( status )
      puts r
    else
      puts "ERROR: EZID service returns #{status}, aborting"
    end

  end

  #
  # assign a new DOI for the specified work
  #
  desc "Assign a new DOI for the specified work; must provide the work id"
  task assign_doi_by_id: :environment do |t, args|

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

    if update_work_doi( work )
      puts "New DOI assigned to work #{work.id} (#{work.doi})"
    end

  end

  #
  # assign a new DOI for all my works
  #
  desc "Assign new DOI's for all my works; optionally provide depositor email"
  task assign_doi_my: :environment do |t, args|

    who = ARGV[ 1 ]
    who = TaskHelpers.default_user_email if who.nil?
    task who.to_sym do ; end

    count = 0
    LibraWork.search_in_batches( {} ) do |group|
      TaskHelpers.batched_process_solr_works( group, &method( :update_work_doi ) )
      count += group.size
    end

    puts "Processed #{count} work(s)"
  end

  #
  # assign a new DOI for all my works that do not have them
  #
  desc "Assign new DOI's for all my works that do not have them; optionally provide depositor email"
  task assign_doi_my_unassigned: :environment do |t, args|

    who = ARGV[ 1 ]
    who = TaskHelpers.default_user_email if who.nil?
    task who.to_sym do ; end

    count = 0
    LibraWork.search_in_batches( {depositor: who} ) do |group|
      TaskHelpers.batched_process_solr_works( group, &method( :update_work_unassigned_doi ) )
      count += group.size
    end

    puts "Processed #{count} work(s)"
  end

  #
  # assign a new DOI for all works
  #
  desc "Bulk assign new DOI's for all works"
  task assign_doi_all: :environment do |t, args|

    count = 0
    LibraWork.search_in_batches( {} ) do |group|
      TaskHelpers.batched_process_solr_works( group, &method( :update_work_doi ) )
      count += group.size
    end

    puts "Processed #{count} work(s)"
  end

  #
  # assign a new DOI for all works that do not have them
  #
  desc "Bulk assign new DOI's for all works without assigned DOI's"
  task assign_doi_all_unassigned: :environment do |t, args|

    count = 0
    LibraWork.search_in_batches( {} ) do |group|
      TaskHelpers.batched_process_solr_works( group, &method( :update_work_unassigned_doi ) )
      count += group.size
    end

    puts "Processed #{count} work(s)"
  end

  #
  # resubmit the EZID metadata for the specified work
  #
  desc "Update DOI metadata for the specified work; must provide the work id"
  task update_doi_metadata_by_id: :environment do |t, args|

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

    if update_work_metadata( work )
      puts "Updated DOI metadata for work #{work.id} (#{work.doi})"
    end

  end

  #
  # resubmit the EZID metadata for all published works from the specified depositor
  #
  desc "Update DOI metadata for all my submitted works; optionally provide depositor email"
  task update_doi_metadata_my: :environment do |t, args|

    who = ARGV[ 1 ]
    who = TaskHelpers.default_user_email if who.nil?
    task who.to_sym do ; end

    count = 0
    LibraWork.search_in_batches( {depositor: who} ) do |group|
      TaskHelpers.batched_process_solr_works( group, &method( :update_work_metadata ) )
      count += group.size
    end

    puts "Processed #{count} work(s)"
  end

  #
  # resubmit the EZID metadata for all published works
  #
  desc "Update DOI metadata for all submitted works"
  task update_doi_metadata_all: :environment do |t, args|

    count = 0
    LibraWork.search_in_batches( {} ) do |group|
      TaskHelpers.batched_process_solr_works( group, &method( :update_work_metadata ) )
      count += group.size
    end

    puts "Processed #{count} work(s)"
  end

  #
  # delete the specified DOI
  #
  desc "Delete the specified DOI; must provide the DOI"
  task delete_by_doi: :environment do |t, args|

    doi = ARGV[ 1 ]
    if doi.nil?
      puts "ERROR: no DOI specified, aborting"
      next
    end

    task doi.to_sym do ; end

    status = ServiceClient::EntityIdClient.instance.remove( doi )
    if ServiceClient::EntityIdClient.instance.ok?( status ) == false
      puts "ERROR: EZID service returns #{status}, aborting"
    else
      puts "DOI successfully deleted"
    end

  end

  #
  # revoke the specified DOI
  #
  desc "Revoke the specified DOI; must provide the DOI"
  task revoke_by_doi: :environment do |t, args|

    doi = ARGV[ 1 ]
    if doi.nil?
      puts "ERROR: no DOI specified, aborting"
      next
    end

    task doi.to_sym do ; end

    status = ServiceClient::EntityIdClient.instance.revoke( doi )
    if ServiceClient::EntityIdClient.instance.ok?( status ) == false
      puts "ERROR: EZID service returns #{status}, aborting"
    else
      puts "DOI successfully revoked"
    end

  end

  #
  # helper methods
  #

  def show_work_doi_callback( work )
    puts "#{work.id} => #{work.doi || 'None'}"
  end

  # update the DOI for the supplied work
  def update_work_unassigned_doi( work )
    if work.doi.blank? == true
      update_work_doi( work )
    end
  end

  # update the DOI for the supplied work
  def update_work_doi( work )

      if work.doi.blank? == false
         puts "WARNING: work #{work.id} already has a DOI (#{work.doi}), revoking it"
         status = ServiceClient::EntityIdClient.instance.revoke( work.doi )
         if ServiceClient::EntityIdClient.instance.ok?( status ) == false
            puts "ERROR: revoke DOI request returns #{status}, continuing anyway"
         end
      end

      # mint a new DOI
      status, id = ServiceClient::EntityIdClient.instance.newid( work )
      if ServiceClient::EntityIdClient.instance.ok?( status ) == false
        puts "ERROR: new DOI request returns #{status}, aborting"
        return false
      end

      # update the identifier
      puts "Assigned new DOI (#{id})"
      work.doi = id
      #work.permanent_url = LibraWork.doi_url( id )
      work.save!

     # update the service metadata
     status = ServiceClient::EntityIdClient.instance.metadatasync( work )
     if ServiceClient::EntityIdClient.instance.ok?( status ) == false
        puts "ERROR: metadata update returns #{status}, aborting"
        return false
     end

     return true
  end

  # update the metadata for the supplied work
  def update_work_metadata( work )

    if work.doi.blank?
      puts "WARNING: work #{work.id} does not have a DOI, ignoring"
      return false
    end

    status = ServiceClient::EntityIdClient.instance.metadatasync( work )
    if ServiceClient::EntityIdClient.instance.ok?( status ) == false
       puts "ERROR: metadata update returns #{status}, aborting"
       return false
    end

    puts "Updated metadata for #{work.id} (#{work.doi})"

    return true
  end

  end   # namespace doi

end   # namespace libraoc

#
# end of file
#
