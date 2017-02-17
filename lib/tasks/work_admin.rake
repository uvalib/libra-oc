#
# Some helper tasks to create and delete works
#

# pull in the helpers
require_dependency 'tasks/task_helpers'
include TaskHelpers

#require_dependency 'libra2/app/helpers/service_helper'
#include ServiceHelper

#require_dependency 'libra2/lib/serviceclient/entity_id_client'

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
    author = Author.new first_name: 'author first', last_name: 'author last',
      computing_id: 'abc123', department: 'Library', institution: 'UVA'

    contributor = Contributor.new first_name: 'contributor first', last_name: 'contributor last' , computing_id: 'abc123', department: 'Library' , institution: 'UVA'

    work = create_work( user, title, description, author, contributor )

    filename = TaskHelpers.get_random_image( )
    TaskHelpers.upload_file( user, work, filename, File.basename( filename ) )

    TaskHelpers.show_libra_work work

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

  def create_work( user, title, description, author, contributor )
     return( create_libra_work( user, title, description, author, contributor ) )
  end

  def create_libra_work( user, title, description, author, contributor )

    # look up user details
    #user_info = user_info_by_email( user.email )
    #if user_info.nil?
      # fill in the defaults
    #  user_info = Helpers::UserInfo.create(
    #      "{'first_name': 'First name', 'last_name': 'Last name'}".to_json )
    #end


    work = LibraWork.create!(title: [ title ] ) do |w|

      # generic work attributes
      w.apply_depositor_metadata(user)
      w.creator = [ user.email ]
      #w.author_email = user.email
      #w.author_first_name = user_info.first_name
      #w.author_last_name = user_info.last_name
      #w.author_institution = LibraWork::DEFAULT_INSTITUTION

      w.authors = [author]
      w.contributors = [contributor]

      w.date_uploaded = CurationConcerns::TimeService.time_in_utc
      #w.date_created = CurationConcerns::TimeService.time_in_utc.strftime( "%Y-%m-%d" )
      w.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      #w.visibility_during_embargo = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      #w.embargo_state = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      w.description = [ description ]
      #w.work_type = work_type
      #w.draft = work_type == LibraWork::WORK_TYPE_THESIS ? 'true' : 'false'

      w.abstract = "hello abstract"

      #w.publisher = LibraWork::DEFAULT_PUBLISHER
      #w.department = 'Placeholder department'
      #w.degree = 'Placeholder degree'
      #w.notes = 'Placeholder notes'
      #w.admin_notes << 'Placeholder admin notes'
      #w.language = LibraWork::DEFAULT_LANGUAGE

      # assign some contributors
      # there's something about the way suffia handles contributors that messes up the ordering
      # so be explicit
      #contributor = []
      #contributor << TaskHelpers.contributor_fields_from_cid( 0, 'sah' )
      #contributor << TaskHelpers.contributor_fields_from_cid( 1, 'ecr2c' )
      #contributor << TaskHelpers.contributor_fields_from_cid( 2, 'naw4t' )
      #w.contributor = contributor

      w.rights << 'http://creativecommons.org/licenses/by/3.0/us/'
      #w.license = LibraWork::DEFAULT_LICENSE

      #print "getting DOI..."
      #status, id = ServiceClient::EntityIdClient.instance.newid( w )
      #if ServiceClient::EntityIdClient.instance.ok?( status )
      #   w.identifier = id
      #   w.permanent_url = LibraWork.doi_url( id )
      #   puts "done"
      #else
      #   puts "error"
      #end
    end

    return work
  end

end   # namespace work

end   # namespace libraoc

#
# end of file
#
