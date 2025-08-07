#
# Some helper tasks to edit works
#

namespace :libraoc do

namespace :audit do

    desc "Show the audit history, must provide the audit start and end dates (YYYY-MM-DD)"
    task show: :environment do |t, args|

      start_export_date = ARGV[ 1 ]
      if start_export_date.nil?
        puts "ERROR: no start date specified, aborting"
        next
      end
      task start_export_date.to_sym do ; end

      end_export_date = ARGV[ 2 ]
      if end_export_date.nil?
        puts "ERROR: no end date specified, aborting"
        next
      end
      task end_export_date.to_sym do ; end

      # validate the start date
      export_dt = convert_date( start_export_date )
      if export_dt.nil?
        puts "ERROR: start date must be in the form YYYY-MM-DD, aborting"
        next
      end

      # validate the end date
      export_dt = convert_date( end_export_date )
      if export_dt.nil?
        puts "ERROR: end date must be in the form YYYY-MM-DD, aborting"
        next
      end

      audits = Audit.where( 'created_at >= ? AND created_at <= ?', start_export_date, end_export_date ).order( created_at: :desc )
      audits.each do |a|
        puts a
      end
      puts "Displayed #{audits.length} audit record(s) (start: #{start_export_date}, end: #{end_export_date})"

    end

    desc "Export the audit history, must provide the audit start and end dates (YYYY-MM-DD)"
    task export: :environment do |t, args|

      start_export_date = ARGV[ 1 ]
      if start_export_date.nil?
        puts "ERROR: no start date specified, aborting"
        next
      end
      task start_export_date.to_sym do ; end

      end_export_date = ARGV[ 2 ]
      if end_export_date.nil?
        puts "ERROR: no end date specified, aborting"
        next
      end
      task end_export_date.to_sym do ; end

      # validate the start date
      export_dt = convert_date( start_export_date )
      if export_dt.nil?
        puts "ERROR: start date must be in the form YYYY-MM-DD, aborting"
        next
      end

      # validate the end date
      export_dt = convert_date( end_export_date )
      if export_dt.nil?
        puts "ERROR: end date must be in the form YYYY-MM-DD, aborting"
        next
      end

      filename = "open-audit-export-#{Time.now.strftime("%m-%d-%Y-%H-%M-%S")}.tsv"
      audits = Audit.where( 'created_at >= ? AND created_at <= ?', start_export_date, end_export_date ).order( created_at: :asc )
      File.open( filename, 'wt' ) do |f|
        audits.each do |a|
          f.write( "#{a.to_tsv}\n" )
        end
        f.close
      end
      puts "Exported #{audits.length} audit record(s) to #{filename} (start: #{start_export_date}, end: #{end_export_date})"

    end

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
        puts a.by_user
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
        puts a.by_work
      end
      puts "Displayed #{audits.length} audit record(s)"

    end

end   # namespace audit

end   # namespace libraoc

#
# end of file
#
