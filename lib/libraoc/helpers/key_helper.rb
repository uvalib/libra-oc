require_dependency 'libraoc/helpers/redis_helper'

module Helpers

  class KeyHelper

    include RedisHelper

    def initialize( )
      redis_config( )
    end

    def keys( pattern )
       return nil if redis_connect( ) == false
       keys = list_keys( pattern )
       return nil if redis_close( ) == false
       return keys
    end

    def string_value( key )
      return nil if redis_connect( ) == false
      val = redis_get_string_value( key )
      return nil if redis_close( ) == false
      return val
    end

    def hash_value( key )
      return nil if redis_connect( ) == false
      val = redis_get_hash_value( key )
      return nil if redis_close( ) == false
      return val
    end

    def ttl( key )
      return nil if redis_connect( ) == false
      val = redis_get_ttl( key )
      return nil if redis_close( ) == false
      return val
    end

    def delete( key )
      return if redis_connect( ) == false
      redis_delete_key( key )
      redis_close( )
    end
  end
end

#
# end of file
#