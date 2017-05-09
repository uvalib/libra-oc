#
# Some helper tasks to list and search ORCID's
#

require_dependency 'libraoc/serviceclient/orcid_access_client'

namespace :libraoc do

  namespace :orcid do

  desc "List known ORCID's (from the ORCID service)"
  task list_orcids: :environment do |t, args|

    count = 0
    status, r = ServiceClient::OrcidAccessClient.instance.get_all( )
    if ServiceClient::OrcidAccessClient.instance.ok?( status )
      r.sort_by! { |details| details['cid'] }
      r.each do |details|
        puts "#{details['cid']} -> #{details['orcid']}"
        count += 1
      end
      puts "#{count} ORCIDS(s) listed"

    else
      puts "ERROR: ORCID service returns #{status}, aborting"
    end
  end

  desc "Update ORCID's for local users"
  task update_orcids: :environment do |t, args|

    count = 0
    User.order( :email ).each do |user|
      if user.orcid.blank?

        cid = User.cid_from_email( user.email )
        status, r = ServiceClient::OrcidAccessClient.instance.get_by_cid( cid )
        if ServiceClient::OrcidAccessClient.instance.ok?( status )
          orcid = orcid_from_orcid_url( r )
          puts "#{cid} <- #{orcid}"
          user.orcid = orcid
          user.save!
          count += 1
        end
      end
    end
    puts "#{count} user(s) updated"

  end

  desc "Harvest ORCID's"
  task harvest_orcids: :environment do |t, args|

     count = 0
     User.order( :email ).each do |user|
       if user.orcid.blank? == false
         orcid = orcid_from_orcid_url( user.orcid )
         cid = User.cid_from_email( user.email )
         puts "Setting #{cid} ORCID to: #{orcid}"
         status = ServiceClient::OrcidAccessClient.instance.set_by_cid( cid, orcid )
         if ServiceClient::OrcidAccessClient.instance.ok?( status )
           count += 1
         else
           puts "ERROR: ORCID service returns #{status}, aborting"
           next
         end
       end
     end

     puts "#{count} ORCID(s) harvested"
  end

  desc "Search ORCID; must provide a search pattern, optionally provide a start index and max count"
  task search_orcid: :environment do |t, args|

    search = ARGV[ 1 ]
    if search.nil?
      puts "ERROR: no search parameter specified, aborting"
      next
    end

    task search.to_sym do ; end

    start = ARGV[ 2 ]
    if start.nil?
      start = "0"
    end

    task start.to_sym do ; end

    max = ARGV[ 3 ]
    if max.nil?
      max = "100"
    end

    task max.to_sym do ; end

    count = 0
    status, r = ServiceClient::OrcidAccessClient.instance.search( search, start, max )
    if ServiceClient::OrcidAccessClient.instance.ok?( status )
      r.each do |details|
        puts "#{details['last_name']}, #{details['first_name']} (#{details['display_name']}) -> #{details['orcid']}"
        count += 1
      end
      puts "#{count} ORCIDS(s) listed"

    else
      puts "ERROR: ORCID service returns #{status}, aborting"
    end

  end

  #
  # Send work metadata to the ORCID profiloe service
  #
  desc "Send work metadata to ORCID profile; must provide the work id"
  task work_to_orcid: :environment do |t, args|

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

    depositor = User.find_by_user_key( work.depositor )
    if depositor.nil?
      puts "ERROR: depositor #{work.depositor} does not exist, aborting"
      next
    end

    if depositor.orcid.blank?
      puts "ERROR: depositor #{work.depositor} does not have an assigned ORCID, aborting"
      next
    end

    puts "ERROR: Not implemented"
  end


  def orcid_from_orcid_url( orcid_url )
    return '' if orcid_url.blank?
    return orcid_url.gsub( 'http://orcid.org/', '' )
  end

  end   # namespace orcid

end   # namespace libraoc

#
# end of file
#
