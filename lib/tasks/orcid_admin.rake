#
# Some helper tasks to list and search ORCID's
#

require_dependency 'libraoc/serviceclient/orcid_access_client'
require_dependency 'libraoc/helpers/orcid_helpers'

namespace :libraoc do

  namespace :orcid do

  desc "List known ORCID's from the ORCID service"
  task list_remote_orcids: :environment do |t, args|

    count = 0
    status, r = ServiceClient::OrcidAccessClient.instance.get_attribs_all( )
    if ServiceClient::OrcidAccessClient.instance.ok?( status )
      r.sort_by! { |details| details['cid'] }
      r.each do |details|
        puts "#{details['cid']} -> #{details['orcid']} (authenticated: #{details['oauth_access_token'].blank? ? 'NO' : 'yes'})"
        count += 1
      end
      puts "#{count} ORCIDS(s) listed"

    else
      puts "ERROR: ORCID service returns #{status}, aborting"
    end
  end

  desc "List known local ORCID's"
  task list_local_orcids: :environment do |t, args|

    count = 0
    User.order( :email ).each do |user|
      if user.orcid.blank? == false
        orcid = orcid_from_orcid_url( user.orcid )
        cid = User.cid_from_email( user.email )
        puts "#{cid} -> #{orcid} (authenticated: #{user.orcid_access_token.blank? ? 'NO' : 'yes'})"
        count += 1
      end
    end

    puts "#{count} ORCIDS(s) listed"

  end

  desc "Harvest remote ORCID's and update the local users"
  task harvest_remote_orcids: :environment do |t, args|

    count = 0
    User.order( :email ).each do |user|
      if user.orcid.blank?

        cid = User.cid_from_email( user.email )
        status, attribs = ServiceClient::OrcidAccessClient.instance.get_attribs_by_cid(cid )
        if ServiceClient::OrcidAccessClient.instance.ok?( status )
          orcid = orcid_from_orcid_url( attribs['uri'] )
          puts "#{cid} <- #{orcid}"
          user.orcid = orcid
          user.save!
          count += 1
        end
      end
    end
    puts "#{count} user(s) updated"

  end

  desc "Harvest local ORCID's and push to ORCID service"
  task harvest_local_orcids: :environment do |t, args|

     count = 0
     User.order( :email ).each do |user|
       if user.orcid.blank? == false
         orcid = orcid_from_orcid_url( user.orcid )
         cid = User.cid_from_email( user.email )

         puts "Updating ORCID attributes for #{cid} (#{orcid})"
         status = ServiceClient::OrcidAccessClient.instance.set_attribs_by_cid(
             cid,
             orcid,
             user.orcid_access_token,
             user.orcid_refresh_token,
             user.orcid_scope )
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

  desc "Purge unauthenticated local ORCID's"
  task purge_local_orcids: :environment do |t, args|

    count = 0
    User.order( :email ).each do |user|
      if user.orcid.blank? == false && user.orcid_access_token.blank? == true
        user.orcid = nil
        user.save!
        count += 1
      end
    end
    puts "#{count} ORCID(s) purged"

  end

  desc "Update ORCID with an activity; must provide the work id; optionally provide author email"
  task update_author_activity: :environment do |t, args|

    work_id = ARGV[ 1 ]
    if work_id.nil?
      puts "ERROR: no work id parameter specified, aborting"
      next
    end

    task work_id.to_sym do ; end

    who = ARGV[ 2 ]
    who = TaskHelpers.default_user_email if who.nil?
    task who.to_sym do ; end

    cid = User.cid_from_email( who )

    work = TaskHelpers.get_work_by_id( work_id )
    if work.nil?
      puts "ERROR: work #{work_id} does not exist, aborting"
      next
    end

    if Helpers.work_suitable_for_orcid_activity( cid, work ) == false
      puts "ERROR: work #{work_id} is not suitable to report as activity for #{cid}, aborting"
      next
    end

    status, update_code = ServiceClient::OrcidAccessClient.instance.set_activity_by_cid( cid, work )
    if ServiceClient::OrcidAccessClient.instance.ok?( status )
      puts "==> OK, update code [#{update_code}]"
    else
      puts "ERROR: ORCID service returns #{status}, aborting"
    end

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
