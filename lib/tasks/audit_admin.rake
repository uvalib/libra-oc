#
# Some helper tasks to edit works
#

namespace :libraoc do

namespace :audit do

    desc "Show audit history for a specified user; must provide the user id"
    task by_user: :environment do |t, args|

      user_id = ARGV[ 1 ]
      if user_id.nil?
        puts "ERROR: no user id specified, aborting"
        next
      end

      task user_id.to_sym do ; end

      user = User.find_by_email( User.email_from_cid( user_id ) )
      if user.nil?
        puts "ERROR: user #{user_id} does not exist, aborting"
        next
      end

      audits = user.audit_history
      audits.each do |a|
        puts a
      end
      puts "Displayed #{audits.length} audit record(s)"

    end

    desc "Show audit history for a specified work; must provide the work id"
    task by_work: :environment do |t, args|

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

      audits = work.audit_history
      audits.each do |a|
        puts a
      end
      puts "Displayed #{audits.length} audit record(s)"

    end

end   # namespace attach

end   # namespace libraoc

#
# end of file
#
