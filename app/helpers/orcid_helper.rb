module OrcidHelper

   #
   # determine of a work is suitable to be uploaded to ORCID as an activity
   #
   def work_suitable_for_orcid_activity( cid, work )

     # works that are not publically visible should not be sent to ORCID
     return false, 'Not publicly visible' if work.is_publicly_visible? == false

     # works that are not authored by the specified user should not be sent to ORCID
     author_cid = first_author_cid( work.authors )
     return false, "Not author (author reported as #{author_cid})" if author_cid != cid

     # works that do not have DOI's cannot go to ORCID
     return false, 'Missing DOI' if work.doi.blank?

     # works that do not have titles cannot go to ORCID
     return false, 'Missing title' if work.title.blank?

     # OK to send to ORCID
     return true
   end

   #
   # extract the bare ORCID from the full URL
   #
   def orcid_from_orcid_url( orcid_url )
     return '' if orcid_url.blank?
     tokens = orcid_url.split( "/" )
     return '' if tokens.length == 0
     return tokens[ tokens.length - 1 ]
   end

   #
   # normalize an ORCID URL to the ORCID environment
   # Necessary because sufia *assumes* we are in the orcid.org domain
   # when we might be in the sandbox.orcid.org domain
   #
   def normalize_orcid_url( orcid_url )
     bare_orcid = orcid_from_orcid_url( orcid_url )
     return "#{ENV['ORCID_BASE_URL']}/#{bare_orcid}"
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