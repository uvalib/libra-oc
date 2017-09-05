#
# Some helper tasks to edit works
#

namespace :libraoc do

namespace :antivirus do

    desc "Refresh the antivirus signatures"
    task refresh: :environment do |t, args|

      ok = system( 'freshclam' )
      puts "Refresh #{ok ? 'completed successfully' : 'aborted with an error'}"

    end

end   # namespace antivirus

end   # namespace libraoc

#
# end of file
#
