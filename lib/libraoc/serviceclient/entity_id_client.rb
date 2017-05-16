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
       #h['creator_firstname'] = author_firstname( work.authors ) if author_firstname( work.authors )
       #h['creator_lastname'] = author_lastname( work.authors ) if author_lastname( work.authors )
       #h['creator_department'] = author_department( work.authors ) if author_department( work.authors )
       #h['creator_institution'] = author_institution( work.authors ) if author_institution( work.authors )

       # open content uses the datacite schema
       schema = 'datacite'
       h['schema'] = schema
       h[schema] = {}

       # needed for datacite schema
       h[schema]['abstract'] = work.abstract if work.abstract.present?
       h[schema]['creators'] = work.authors if work.authors.present?
       h[schema]['contributors'] = work.contributors if work.contributors.present?
       h[schema]['keywords'] = work.keyword if work.keyword.present?
       h[schema]['rights'] = work.rights[ 0 ] if work.rights.present?
       h[schema]['sponsors'] = work.sponsoring_agency if work.sponsoring_agency.present?
       h[schema]['resource_type'] = work.resource_type if work.resource_type.present?
       h[schema]['general_type'] = dc_general_type( work.resource_type ) if work.resource_type.present?

       yyyymmdd = extract_yyyymmdd_from_datestring( work.published_date )
       yyyymmdd = extract_yyyymmdd_from_datestring( work.date_created ) if yyyymmdd.nil?
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

     def author_firstname( authors )
       return authors[ 0 ].first_name if authors && authors[ 0 ] && authors[ 0 ].first_name.present?
       return nil
     end

     def author_lastname( authors )
       return authors[ 0 ].last_name if authors && authors[ 0 ] && authors[ 0 ].last_name.present?
       return nil
     end

     def author_department( authors )
       return authors[ 0 ].department if authors && authors[ 0 ] && authors[ 0 ].department.present?
       return nil
     end

     def author_institution( authors )
       return authors[ 0 ].institution if authors && authors[ 0 ] && authors[ 0 ].institution.present?
       return nil
     end

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
     # attempt to extract YYYY-MM-DD from a date string
     #
     def extract_yyyymmdd_from_datestring( date )

       return nil if date.blank?

       #puts "==> DATE IN [#{date}]"
       begin

         # try yyyy-mm-dd (at the start of the string)
         dts = date.match( /^(\d{4}-\d{1,2}-\d{1,2})/ )
         return dts[ 0 ] if dts

         # try yyyy/mm/dd (at the start of the string)
         dts = date.match( /^(\d{4}\/\d{1,2}\/\d{1,2})/ )
         return dts[ 0 ].gsub( '/', '-' ) if dts

         # try yyyy-mm (at the start of the string)
         dts = date.match( /^(\d{4}-\d{1,2})/ )
         return dts[ 0 ] if dts

         # try yyyy/mm (at the start of the string)
         dts = date.match( /^(\d{4}\/\d{1,2})/ )
         return dts[ 0 ].gsub( '/', '-' ) if dts

         # try mm/dd/yyyy (at the start of the string)
         dts = date.match( /^(\d{1,2}\/\d{1,2}\/\d{4})/ )
         return DateTime.strptime( dts[ 0 ], "%m/%d/%Y" ).strftime( "%Y-%m-%d" ) if dts

         # try yyyy (anywhere in the string)
         dts = date.match( /(\d{4})/ )
         return dts[ 0 ] if dts

       rescue => ex
         #puts "==> EXCEPTION: #{ex}"
         # do nothing...
       end

       # not sure what format
       return nil
     end
   end
end
