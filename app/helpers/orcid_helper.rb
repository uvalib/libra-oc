module OrcidHelper

   #
   # determine of a work is suitable to be uploaded to ORCID as an activity
   #
   def work_suitable_for_orcid_activity( cid, work )

     # works that are private should not be sent to ORCID
     return false, 'Work is private' if work.is_private?

     # works that are not authored by the specified user should not be sent to ORCID
     return false, 'Not author' if !contains_computing_id( work.authors, cid )

     # works that do not have DOI's cannot go to ORCID
     return false, 'Missing DOI' if work.doi.blank?

     # works that do not have titles cannot go to ORCID
     return false, 'Missing title' if work.title.blank?

     # OK to send to ORCID
     return true
   end

   #
   # per the ORCID license, the best way to show an ORCID
   #
   def display_orcid_from_url( orcid_url )
     return '' if orcid_url.blank?
     return orcid_url.gsub( /https?:\/\//, '' )
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
   # A displayable status based on the orcid status
   #
   def displayable_orcid_status( status )

      return '' if status.blank?

      case status
        when 'pending'
          return 'Pending'
        when 'complete'
          return 'In ORCID'
        when 'error'
          return 'Email Us'
      end
      return status
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
   # does the list of authors contain the supplied computing ID
   #
   def contains_computing_id( authors, cid )

      # list is empty
      return false if authors.empty?

      authors.each do |a|
         return true if a.computing_id == cid
      end

      # nothing found
      return false

   end

end

#
# end of file
#
