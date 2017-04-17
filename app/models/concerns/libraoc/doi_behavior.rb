require_dependency 'libraoc/serviceclient/entity_id_client'

module Libraoc::DoiBehavior

  extend ActiveSupport::Concern

  included do

    after_save :allocate_doi, :if => :doi_unassigned?

    def doi_url
      return '' if self.doi.nil?
      return "https://doi.org/#{self.doi.gsub('doi:', '')}"
    end

    private

    def doi_unassigned?
      return self.doi.blank?
    end

    def allocate_doi

      if is_private? == false

         puts "Allocating a new DOI..."

         status, id = ServiceClient::EntityIdClient.instance.newid( self )
         if ServiceClient::EntityIdClient.instance.ok?( status )

           self.doi = id

           puts "Updating DOI metadata for #{id}..."

           # update the service metadata
           status = ServiceClient::EntityIdClient.instance.metadatasync( self )
           if ServiceClient::EntityIdClient.instance.ok?( status )
             # save our new DOI
             self.save!
           else
             # clear the DOI and note the error
             puts "ERROR: DOI metadata update returns #{status}"
           end
         else
           puts "ERROR: DOI create returns #{status}"
         end

      end

    end

  end

end
