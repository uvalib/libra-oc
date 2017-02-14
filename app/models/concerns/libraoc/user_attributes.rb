module Libraoc::UserAttributes

  extend ActiveSupport::Concern

  included do

     # extract the computing ID from the supplied email address; assumes computing_id@blablabla.bla
     def self.cid_from_email( em )
        return '' if em.nil? || em.empty?
        return em.split( "@" )[ 0 ]
     end
  end

end