
module Helpers

   #
   # determine of a work is suitable to be uploaded to ORCID as an activity
   #
   def work_suitable_for_orcid_activity( cid, work )

     # works that are not publically visible should not be sent to ORCID
     return false, 'Not publicly visible' if work.is_publicly_visible? == false

     # works that are not authored by the specified user should not be sent to ORCID
     author_cid = first_author_cid( work.authors )
     return false, "Not author (author reported as #{author_cid})" if author_cid != cid

     # OK to send to ORCID
     return true
   end

  private

   #
   # return the computing ID of the first author
   #
   def first_author_cid( authors )

      return 'none' if authors.empty?
      authors.each do |a|
         if a.index == 0
            return a.computing_id if a.computing_id.present?
            return 'none'
         end

      end

      # nothing found
      return 'none'

   end

end

#
# end of file
#