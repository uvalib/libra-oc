require_dependency 'libraoc/serviceclient/base_client'
require_dependency 'libraoc/serviceclient/orcid_access_client'
require_dependency 'app/helpers/url_helper'

module ServiceClient

  class EntityIdClient < BaseClient

    # get the helpers
    include UrlHelper


    UVA_AFFILIATION = {
      name: "University of Virginia",
      schemeUri: "https://ror.org",
      affiliationIdentifier: "https://ror.org/0153tk833",
      affiliationIdentifierScheme: "ROR"
    }

    #
    # configure with the appropriate configuration file
    #
    def initialize
      load_config( "entityid.yml" )
    end

    #
    # singleton stuff
    #

    @@instance = new

    def self.instance
      return @@instance
    end

    private_class_method :new

    #
    # check the health of the endpoint
    #
    def healthcheck
      url = "#{self.url}/heartbeat"
      status, _ = rest_get( url )
      return( status )
    end

    #
    # create a new DOI and associate any metadata we can determine from the supplied work
    # It is still in the draft state after this and needs metadatasync to publish
    #
    def newid( work )
      url = "#{self.url}/dois"
      payload =  self.construct_payload( work )
      status, response = rest_post( url, payload )
      #puts "==> #{status}: #{response}"
      new_doi = response.dig('data', 'id')
      return status, "doi:#{new_doi}" if ok?( status ) && new_doi
      return status, ''
    end

    #
    # update an existing DOI with any metadata we can determine from the supplied work
    #
    def metadatasync( work )
      #puts "=====> metadatasync #{work.doi}"
      url = "#{self.url}/dois/#{work.bare_doi}"
      payload =  self.construct_payload( work, {event: 'publish'})
      status, _ = rest_put( url, payload )
      return status
    end

    #
    # get the details for the specified doi
    #
    def metadataget( doi )
      #puts "=====> metadataget #{doi}"
      url = "#{self.url}/dois/#{doi}"
      status, response = rest_get( url )
      return status, response if ok?( status )
      return status, ''
    end

    #
    # remove a DOI entry
    # Deletes the DOI
    #
    def remove( doi )
      #puts "=====> remove #{doi}"
      url = "#{self.url}/dois/#{doi}"
      status = rest_delete( url )
      return status
    end

    #
    # revoke a DOI entry
    # Marks the record as not findable, but it still exists.
    #
    def revoke( doi )
      #puts "=====> revoke #{doi}"
      url = "#{self.url}/dois/#{doi}"
      status, _ = rest_put( url, {event: 'hide'} )
      return status
    end

    #
    # construct the request payload
    #
    def construct_payload( work, attributes = {})

      attributes[:prefix] = shoulder.gsub('doi:', '')

      # For a new record, not including a DOI will have Datacite generate one
      attributes[:doi] = work.bare_doi if work.doi.present?

      attributes[:titles] = [{title: work.title.join(' ')}]
      if work.abstract.present?
        attributes['descriptions'] = [{
          description: work.abstract,
          descriptionType: 'Abstract'
        }]
      end
      attributes[:creators] = format_people( work.authors) if work.authors.present?
      attributes[:contributors] = format_people( work.contributors, 'Other' ) if work.contributors.present?
      attributes[:subjects] = work.keyword.map{|k| {subject: k}} if work.keyword.present?
      attributes[:rightsList] = [{rights: work.rights_display}] if work.rights_display.present?
      attributes[:fundingReferences] = work.sponsoring_agency.map{|f| {funderName: f}} if work.sponsoring_agency.present?
      attributes[:types] = datacite_resource_type(work.resource_type)

      yyyymmdd = ServiceClient.extract_yyyymmdd_from_datestring( work.published_date )
      # published date cannot be only a year
      yyyymmdd = ServiceClient.extract_yyyymmdd_from_datestring( work.date_created ) if yyyymmdd.blank?
      attributes[:dates] = [{date: yyyymmdd, dateType: 'Issued'}] if yyyymmdd.present?
      attributes[:publicationYear] = yyyymmdd.first(4) if yyyymmdd.present?

      attributes[:url] = fully_qualified_work_url( work.id ) # 'http://google.com'
      attributes[:publisher] = work.publisher if work.publisher.present?

      #puts "==> #{h.to_json}"
      payload = {
        data: {
          type: 'dois',
          attributes: attributes
        }
      }
      #puts "#{payload.to_json}"
      return payload.to_json
    end

    #
    # helpers
    #

    def shoulder
      configuration[ :shoulder ]
    end

    def url
      configuration[ :url ]
    end

    def datacite_resource_type resource_type
      datacite_format = {resourceTypeGeneral: 'Other', resourceType: 'Other'}

      # Lookup type in config/resource_types.yml
      authority_type = ResourceTypesService.authority.find(resource_type)
      # Resource type not found
      return datacite_format if authority_type.empty?

      general_type = authority_type['dataCiteGeneral'] if authority_type['dataCiteGeneral'].present?

      datacite_format[:resourceTypeGeneral] = general_type
      datacite_format[:resourceType] = resource_type

      return datacite_format
    end

    #
    # Datacite Person format
    # this includes sorting by index and removing any duplicates
    #
    def format_people( people_list, type=nil )

      res = []
      return people_list.to_a
        .uniq { |p| p.index }
        .sort{|a,b| a.index.to_i <=> b.index.to_i}
        .map { | p |
          person = {
            givenName: p.first_name,
              familyName: p.last_name,
              nameType: 'Personal'
          }
          person[:affiliation] = UVA_AFFILIATION if p.computing_id.present?
          person[:contributorType] = type if type.present?

          # if person has a ORCID account
          orcid_status, orcid_attribs = ServiceClient::OrcidAccessClient.instance.
            get_attribs_by_cid(p.computing_id)

          if orcid_attribs['uri'].present?
            person[:nameIdentifiers] = {
              schemeUri: URI(orcid_attribs['uri']),
              nameIdentifier: orcid_attribs['uri'],
              nameIdentifierScheme: "ORCID"
            }
          elsif orcid_status > 300
            Rails.logger.error "ORCID Error during DataCite payload #{orcid_attribs}\n#{person}"
          end
          person
        }
    end
  end
end
