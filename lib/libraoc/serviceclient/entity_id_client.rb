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
       url = "#{self.url}/healthcheck"
       status, _ = rest_get( url )
       return( status )
     end

     #
     # create a new DOI and associate any metadata we can determine from the supplied work
     #
     def newid( work )
       url = "#{self.url}/#{self.shoulder}?auth=#{self.authtoken}"
       payload =  self.construct_payload( work )
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
       url = "#{self.url}/#{work.doi}?auth=#{self.authtoken}"
       payload =  self.construct_payload( work )
       status, _ = rest_put( url, payload )
       return status
     end

     #
     # get the details for the specified doi
     #
     def metadataget( doi )
       #puts "=====> metadataget #{doi}"
       url = "#{self.url}/#{doi}?auth=#{self.authtoken}"
       status, response = rest_get( url )
       return status, response['details'] if ok?( status ) && response['details']
       return status, ''
     end

     #
     # remove a DOI entry
     #
     def remove( doi )
       #puts "=====> remove #{doi}"
       url = "#{self.url}/#{doi}?auth=#{self.authtoken}"
       status = rest_delete( url )
       return status
     end

     #
     # revoke a DOI entry
     #
     def revoke( doi )
       #puts "=====> revoke #{doi}"
       url = "#{self.url}/revoke/#{doi}?auth=#{self.authtoken}"
       status, _ = rest_put( url, nil )
       return status
     end

     #
     # construct the request payload
     #
     def construct_payload( work )
       h = {}

       # open content uses the datacite schema
       schema = 'datacite'
       h['schema'] = schema
       h[schema] = {}

       # needed for datacite schema
       h[schema]['abstract'] = work.abstract if work.abstract.present?
       h[schema]['creators'] = author_cleanup( work.authors ) if work.authors.present?
       h[schema]['contributors'] = contributor_cleanup( work.contributors ) if work.contributors.present?
       h[schema]['keywords'] = work.keyword if work.keyword.present?
       h[schema]['rights'] = work.rights_display if work.rights_display.present?
       h[schema]['sponsors'] = work.sponsoring_agency if work.sponsoring_agency.present?
       h[schema]['resource_type'] = work.resource_type if work.resource_type.present?
       h[schema]['general_type'] = dc_general_type( work.resource_type ) if work.resource_type.present?

       yyyymmdd = ServiceClient.extract_yyyymmdd_from_datestring( work.published_date )
       yyyymmdd = ServiceClient.extract_yyyymmdd_from_datestring( work.date_created ) if yyyymmdd.nil?
       h[schema]['publication_date'] = yyyymmdd if yyyymmdd
       h[schema]['url'] = fully_qualified_work_url( work.id ) # 'http://google.com'
       h[schema]['title'] = work.title.join( ' ' ) if work.title.present?
       h[schema]['publisher'] = work.publisher if work.publisher.present?

       #puts "==> #{h.to_json}"
       return h.to_json
     end

     #
     # helpers
     #

     def shoulder
       configuration[ :shoulder ]
     end

     def authtoken
       configuration[ :authtoken ]
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
         when 'Map', 'Poster', 'Other'
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
     # cleanup author list
     # this includes ensuring the index value is the correct type and removing any duplicates
     #
     def author_cleanup( authors )

       res = []
       authors.each do | p |
         ix = p.index
         ix = ix.to_i if ix.instance_of? String
         res << Author.new(
             index: ix,
                      first_name: p.first_name,
                      last_name: p.last_name,
                      computing_id: p.computing_id,
                      department: p.department,
                      institution: p.institution )
       end
       return res.uniq { |p| p.index }
     end

     #
     # cleanup contributor list
     # this includes ensuring the index value is the correct type and removing any duplicates
     #
     def contributor_cleanup( authors )

       res = []
       authors.each do | p |
         ix = p.index
         ix = ix.to_i if ix.instance_of? String
         res << Contributor.new(
           index: ix,
                    first_name: p.first_name,
                    last_name: p.last_name,
                    computing_id: p.computing_id,
                    department: p.department,
                    institution: p.institution )
       end
       return res.uniq { |p| p.index }
     end

   end
end
