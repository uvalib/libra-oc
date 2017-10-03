
module Helpers

   #
   # determine of a work is suitable to be uploaded to ORCID as an activity
   #
   def work_suitable_for_orcid_activity( cid, work )

     # works that are not publically visible should not be sent to ORCID
     return false if work.is_publicly_visible? == false

     # OK to send to ORCID
     return true
   end
end

#
# end of file
#