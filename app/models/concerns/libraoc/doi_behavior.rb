require_dependency 'libraoc/serviceclient/entity_id_client'

module Libraoc::DoiBehavior

  extend ActiveSupport::Concern

  included do

    # create the DOI if required
    after_save :allocate_doi, :if => :doi_unassigned?

    # update the associated metadata if required
    before_update :update_doi, :if => :doi_update_required?

    # revoke the DOI if required
    before_destroy :revoke_doi, :if => :doi_assigned?

    def doi_url
      return '' if self.doi.nil?
      return "#{ENV['DOI_BASE_URL']}/#{self.doi.gsub('doi:', '')}"
    end

    private

    def doi_unassigned?
      return self.doi.blank?
    end

    def doi_assigned?
      return self.doi.present?
    end

    def doi_update_required?

      return false if doi_unassigned?

      changed = self.abstract_changed? ||
                authors_changed? ||
                contributors_changed? ||
                self.keyword_changed? ||
                self.rights_changed? ||
                self.sponsoring_agency_changed? ||
                self.resource_type_changed? ||
                self.published_date_changed? ||
                self.date_created_changed? ||
                self.title_changed? ||
                self.publisher_changed?
      #puts "==> DOI METADATA CHANGED: #{changed}"
      return changed
    end

    def authors_changed?

      #changed = self.authors.any? { |a| a.changed? }
      #puts "==> AUTHORS CHANGED: #{changed}"
      # TODO: DPG: this is not reliable, assume they have not changed
      return false
    end

    def contributors_changed?

      #changed = self.contributors.any? { |a| a.changed? }
      #puts "==> CONTRIBUTORS CHANGED: #{changed}"
      # TODO: DPG: this is not reliable, assume they have not changed
      return false
    end

    #
    # allocate a DOI to a work that does not have one...
    #
    def allocate_doi

      if is_private? == false

         puts "Allocating a new DOI..."

         status, id = ServiceClient::EntityIdClient.instance.newid( self )
         if ServiceClient::EntityIdClient.instance.ok?( status )

           self.doi = id

           puts "Sending DOI metadata for #{id}..."

           # update the service metadata
           status = ServiceClient::EntityIdClient.instance.metadatasync( self )
           if ServiceClient::EntityIdClient.instance.ok?( status )
             # save our new DOI
             self.save!
           else
             # note the error
             puts "ERROR: DOI metadata send returns #{status}"
           end
         else
           puts "ERROR: DOI create returns #{status}"
         end

      end

    end

    #
    # update the DOI metadata asd necessary
    #
    def update_doi

      if is_private? == false

        puts "Updating DOI metadata for #{self.doi}..."

        # update the service metadata
        status = ServiceClient::EntityIdClient.instance.metadatasync( self )
        if ServiceClient::EntityIdClient.instance.ok?( status ) == false
          # note the error
          puts "ERROR: DOI metadata update for #{self.id} returns #{status}"
        end

      end

    end

    #
    # attempt to revoke a DOI before we delete the work
    #
    def revoke_doi
      puts "Revoking existing DOI #{self.doi}"

      # attempt the revoke
      status = ServiceClient::EntityIdClient.instance.revoke( self.doi )
      if ServiceClient::EntityIdClient.instance.ok?( status ) == false
        # report the error
        puts "ERROR: DOI revoke returns #{status}"
      end

    end

  end

end
