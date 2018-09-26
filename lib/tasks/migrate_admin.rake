#
# Some helper tasks to edit works
#

# pull in the helpers
require_dependency 'lib/tasks/task_helpers'
include TaskHelpers

namespace :libraoc do

namespace :migrate do

    desc "Migration to ordered fields (language, keyword, related_url, sponsoring_agency)"
    task ordered_fields: :environment do |t, args|

      # disable the workflow callbacks
      TaskHelpers.disable_workflow_callbacks

      successes = 0
      errors = 0
      LibraWork.search_in_batches( {} ) do |group|
        group.each do |w|
          begin
            print "."

            work = LibraWork.find( w['id'] )

            # this will migrate the fields...
            work.language = work.language
            work.keyword = work.keyword
            work.related_url = work.related_url
            work.sponsoring_agency = work.sponsoring_agency

            work.save!

            successes += 1
          rescue => e
            errors += 1
          end
        end
      end

      puts "done"
      puts "Processed #{successes} work(s), #{errors} error(s) encountered"

    end

    desc "Re-save all works"
    task resave_all: :environment do |t, args|

      successes = 0
      errors = 0
      LibraWork.search_in_batches( {} ) do |group|
        group.each do |w|
          begin
            print "."
            work = LibraWork.find( w['id'] )
            work.save!

            successes += 1
          rescue => ex
            puts "EXCEPTION: #{ex}"
            errors += 1
          end
        end
      end

      puts "done"
      puts "Processed #{successes} work(s), #{errors} error(s) encountered"

    end

    desc "Re-save work by id; must provide the work id"
    task resave_by_id: :environment do |t, args|

      work_id = ARGV[ 1 ]
      if work_id.nil?
        puts "ERROR: no work id specified, aborting"
        next
      end

      task work_id.to_sym do ; end

      begin
         work = LibraWork.find( work_id )
         work.save!

         puts "done"
      rescue => ex
         puts "EXCEPTION: #{ex}"
      end

    end

    desc "Re-save all works in batch; must provide the file name containing the list of work ids"
    task resave_batch: :environment do |t, args|

      filename = ARGV[ 1 ]
      if filename.nil?
        puts "ERROR: no file name specified, aborting"
        next
      end

      task filename.to_sym do ; end

      successes = 0
      errors = 0

      File.open( filename, 'r').each do |line|

         begin
            print "."
            work = LibraWork.find( line.strip )
            work.save!

            successes += 1
         rescue => ex
            puts "EXCEPTION: #{ex}"
            errors += 1
         end

      end

      puts "done"
      puts "Processed #{successes} work(s), #{errors} error(s) encountered"

    end

end   # namespace migrate

end   # namespace libraoc

#
# end of file
#
