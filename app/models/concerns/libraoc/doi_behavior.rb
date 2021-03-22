require_dependency 'libraoc/serviceclient/entity_id_client'

module Libraoc::DoiBehavior

  extend ActiveSupport::Concern

  included do

    # create the DOI if required
    after_save :allocate_doi, :unless => :doi_assigned?

    # update the associated metadata if required
    before_update :update_doi, :if => :doi_assigned?

    # revoke the DOI if required
    before_destroy :revoke_doi, :if => :doi_assigned?

    def doi_url
      return '' if self.doi.nil?
      return "#{ENV['DOI_BASE_URL']}/#{self.doi.gsub('doi:', '')}"
    end

    def bare_doi
      return '' if self.doi.nil?
      return self.doi.gsub 'doi:', ''
    end

    private

    def doi_assigned?
      return self.doi.present?
    end


    def authors_changed?

      changed = self.authors.any? { |a| a.changed? || a.new_record? }
      #puts "==> AUTHORS CHANGED: #{changed}"
      return changed
    end

    def contributors_changed?

      changed = self.contributors.any? { |a| a.changed? || a.new_record? }
      #puts "==> CONTRIBUTORS CHANGED: #{changed}"
      return changed
    end

    #
    # allocate a DOI to a work that does not have one...
    #
    def allocate_doi

      if is_private? == false

         puts "Allocating a new DOI"

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
