require 'rest_client'

module ServiceClient

   class BaseClient

     DEFAULT_RETRIES ||= 3

     def configuration
       @configuration
     end

     #
     # basic helper
     #
     def ok?( status )
       return( status == 200 || status == 201 )
     end

     #
     # configuration helper
     #
     def timeout
       configuration[ :timeout ]
     end

     #
     # REST get with default retry behavior
     #
     def rest_get( url, tries = DEFAULT_RETRIES )
       attempts = 0
       while attempts < tries
          puts "WARNING: request timeout: #{url} after #{self.timeout} second(s), retrying..." if attempts != 0
          status, response = rest_get_internal( url )
          return status, response if status != 408
          attempts += 1
       end

       # done trying...
       puts "ERROR: request timeout: #{url}; gave up after #{tries} try(s)"
       return 408, {}
     end

     #
     # REST put with default retry behavior
     #
     def rest_put( url, payload, tries = DEFAULT_RETRIES )
       attempts = 0
       while attempts < tries
          puts "WARNING: request timeout: #{url} after #{self.timeout} second(s), retrying..." if attempts != 0
          status, response = rest_send_internal( url, :put, payload )
          return status, response if status != 408
          attempts += 1
       end

       # done trying...
       puts "ERROR: request timeout: #{url}; gave up after #{tries} try(s)"
       return 408, {}
     end

     #
     # REST post with default retry behavior
     #
     def rest_post( url, payload, tries = DEFAULT_RETRIES )
       attempts = 0
       while attempts < tries
          puts "WARNING: request timeout: #{url} after #{self.timeout} second(s), retrying..." if attempts != 0
          status, response = rest_send_internal( url, :post, payload )
          return status, response if status != 408
          attempts += 1
       end

       # done trying...
       puts "ERROR: request timeout: #{url}; gave up after #{tries} try(s)"
       return 408, {}
     end

     #
     # REST delete with default retry behavior
     #
     def rest_delete( url, tries = DEFAULT_RETRIES )
       attempts = 0
       while attempts < tries
          puts "WARNING: request timeout: #{url} after #{self.timeout} second(s), retrying..." if attempts != 0
          status =  rest_delete_internal( url )
          return status if status != 408
          attempts += 1
       end

       # done trying...
       puts "ERROR: request timeout: #{url}; gave up after #{tries} try(s)"
       return 408
     end

     private

     #
     # send the supplied payload to the supplied endpoint using the supplied HTTP method (:put, :post)
     #
     def rest_send_internal( url, method, payload )
       begin
         response = RestClient::Request.execute( method: method,
                                                 url: URI.escape( url ),
                                                 payload: payload,
                                                 content_type: :json,
                                                 accept: :json,
                                                 open_timeout: self.timeout,
                                                 read_timeout: self.timeout / 2 )

         if ok?( response.code ) && response.empty? == false && response != ' '
           return response.code, JSON.parse( response )
         end
         return response.code, {}
       rescue RestClient::BadRequest => ex
         log_error( method, url, ex, payload )
         return 400, {}
       rescue RestClient::ResourceNotFound => ex
         #log_error( method, url, ex, payload )
         return 404, {}
       rescue RestClient::RequestTimeout => ex
         #log_error( method, url, ex, payload )
         return 408, {}
       rescue RestClient::Exception, SocketError, Exception => ex
         log_error( method, url, ex, payload )
         return 500, {}
       end
     end

     def rest_get_internal( url )
       begin
         response = RestClient::Request.execute( method: :get,
                                                 url: URI.escape( url ),
                                                 accept: :json,
                                                 open_timeout: self.timeout,
                                                 read_timeout: self.timeout / 2 )

         if ok?( response.code ) && response.empty? == false && response != ' '
           return response.code, JSON.parse( response )
         end
         return response.code, {}
       rescue RestClient::BadRequest => ex
         log_error( :get, url, ex )
         return 400, {}
       rescue RestClient::ResourceNotFound => ex
         #log_error( :get, url, ex )
         return 404, {}
       rescue RestClient::RequestTimeout => ex
         #log_error( :get, url, ex )
         return 408, {}
       rescue RestClient::Exception, SocketError, Exception => ex
         log_error( :get, url, ex )
         return 500, {}
       end
     end

     def rest_delete_internal( url )
       begin
         response = RestClient::Request.execute( method: :delete,
                                                 url: URI.escape( url ),
                                                 open_timeout: self.timeout,
                                                 read_timeout: self.timeout / 2 )

         return response.code
       rescue RestClient::BadRequest => ex
         log_error( :delete, url, ex )
         return 400
       rescue RestClient::ResourceNotFound => ex
         #log_error( :delete, url, ex )
         return 404
       rescue RestClient::RequestTimeout => ex
         #log_error( :delete, url, ex )
         return 408
       rescue RestClient::Exception, SocketError, Exception => ex
         log_error( :delete, url, ex )
         return 500
       end
     end

     #
     # load the supplied configuration file
     #
     def load_config( filename )

       fullname = "#{Rails.application.root}/lib/libraoc/config/#{filename}"
       begin
         config_erb = ERB.new( IO.read( fullname ) ).result( binding )
       rescue StandardError => ex
         raise( "#{filename} could not be parsed with ERB. \n#{ex.inspect}" )
       end

       begin
         yml = YAML.load( config_erb )
       rescue Psych::SyntaxError => ex
         raise "#{filename} could not be parsed as YAML. \nError #{ex.message}"
       end

       config = yml.symbolize_keys
       @configuration = config[ Rails.env.to_sym ].symbolize_keys || {}
     end

     #
     # error log helper
     #
     def log_error( method, url, ex = nil, payload = nil )

       verb = 'GET'
       verb = 'POST' if method == :post
       verb = 'PUT' if method == :put
       verb = 'DELETE' if method == :delete

       puts "ERROR: #{verb} url; #{url}"
       puts "ERROR: #{verb} payload; #{payload}" if payload.nil? == false
       puts "ERROR: #{ex.class}; #{ex}" if ex.nil? == false

     end
   end

end
