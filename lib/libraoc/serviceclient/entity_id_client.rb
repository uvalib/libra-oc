require_dependency 'libraoc/serviceclient/base_client'
require_dependency 'app/helpers/url_helper'

module ServiceClient

  class EntityIdClient < BaseClient

    # get the helpers
    include UrlHelper

    DC_GENERAL_TYPE_TEXT ||= 'Text'
    DC_GENERAL_TYPE_SOUND ||= 'Sound'
    DC_GENERAL_TYPE_IMAGE ||= 'Image'
    DC_GENERAL_TYPE_COLLECTION ||= 'Collection'
    DC_GENERAL_TYPE_EVENT ||= 'Event'
    DC_GENERAL_TYPE_AUDIOVISUAL ||= 'Audiovisual'
    DC_GENERAL_TYPE_OTHER ||= 'Other'

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
    #
    def newid( work )
      url = "#{self.url}/dois"
      payload =  self.construct_payload( work , {event: 'publish'})
      status, response = rest_post( url, payload )
      #puts "==> #{status}: #{response}"
      return status, response['details']['id'] if ok?( status ) && response['details'] && response['details']['id']
      return status, ''
    end

    #
    # update an existing DOI with any metadata we can determine from the supplied work
    #
    def metadatasync( work )
      #puts "=====> metadatasync #{work.doi}"
      url = "#{self.url}/dois/#{work.bare_doi}"
      payload =  self.construct_payload( work )
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
      attributes[:resourceTypeGeneral] = dc_general_type(work.resource_type)
      attributes[:resourceType] = work.resource_type

      yyyymmdd = ServiceClient.extract_yyyymmdd_from_datestring( work.published_date )
      yyyymmdd = ServiceClient.extract_yyyymmdd_from_datestring( work.date_created ) if yyyymmdd.nil?
      attributes[:dates] = [{date: yyyymmdd, dateType: 'Issued'}] if yyyymmdd
      attributes[:url] = fully_qualified_work_url( work.id ) # 'http://google.com'
      attributes[:publisher] = work.publisher if work.publisher.present?

      #puts "==> #{h.to_json}"
      payload = {
        data: {
          type: 'dois',
          attributes: attributes
        }
      }
      puts payload
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

    private

    #
    # general type definition based on the work resource type
    #
    def dc_general_type( resource_type )

      return DC_GENERAL_TYPE_TEXT if resource_type.blank?
      case resource_type
        when 'Audio'
          return DC_GENERAL_TYPE_SOUND
        when 'Image'
          return DC_GENERAL_TYPE_IMAGE
        when 'Journal'
          return DC_GENERAL_TYPE_COLLECTION
        when 'Map', 'Poster', 'Other', 'Educational Resource'
          return DC_GENERAL_TYPE_OTHER
        when 'Presentation'
          return DC_GENERAL_TYPE_EVENT
        when 'Video'
          return DC_GENERAL_TYPE_AUDIOVISUAL
        else
          return DC_GENERAL_TYPE_TEXT
      end
    end

    #
    # Datacite Person format
    # this includes sorting by index and removing any duplicates
    #
    def format_people( people_list, type=nil )

      res = []
      return people_list.to_a
        .uniq { |p| p.index }
        .sort{|a,b| a.index <=> b.index}
        .map { | p |
          person = { givenName: p.first_name,
              familyName: p.last_name,
              affiliation: [p.department, p.institution].reject(&:blank?).join(', '),
          }
          person[:contributorType] = type if type.present?
          person
        }
    end
  end
end
