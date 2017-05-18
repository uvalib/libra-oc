class WorkAuditJob < ActiveJob::Base

    queue_as :audit

    # attributes we are auditing and their audit methods
    AUDIT_FIELDS ||= {
        'abstract'           => :string,
        'admin_notes'        => :string,
#        'authors'            => :person_array,
#        'contributors'       => :person_array,
#        'file_sets'          => :files,
        'keyword'            => :string_array,
        'language'           => :string_array,
        'notes'              => :string,
        'published_date'     => :string,
        'publisher'          => :string,
        'related_url'        => :string_array,
        'resource_type'      => :string,
        'rights'             => :string_array,
        'source_citation'    => :string,
        'sponsoring_agency'  => :string_array,
        'title'              => :string_array,
#        'visibility'         => :string
    }

    AUDIT_PERSON_FIELDS ||= [
       'first_name',
       'last_name',
       'computing_id',
       'department',
       'institution',
    ]

    ID_FIELD_NAME ||= 'id'
    PRIVATE_FIELD_NAME ||= 'private'

    def self.serialize_work( work )
       ret = {}
       #return ret if work.nil?
       AUDIT_FIELDS.keys.each do |k|
         ret[ k ] = work[ k ]
       end
       # handle the special case
       ret[ ID_FIELD_NAME ] = work.id
       ret[ PRIVATE_FIELD_NAME ] = work.is_private?

       return ret.to_json
    end

    def perform( user_id, before, after )
      audit_changes( user_id, before, after )
    end

    private

    def audit_changes( user_id, before, after )

      # convert to hash
      begin
         before = JSON.parse( before )
         after = JSON.parse( after )
      rescue JSON::ParserError => ex
        puts "ERROR #{ex}, no work audit"
        return
      end

      # do not audit if this work is private
      return if after[ PRIVATE_FIELD_NAME ]

      # dont audit the transition from private to non-private
      return if before[ PRIVATE_FIELD_NAME ]

      # enumerate each field and see if we need to audit it
      work_id = after[ ID_FIELD_NAME ]
      AUDIT_FIELDS.keys.each do |k|
        case AUDIT_FIELDS[ k ]
          when :string
            audit_string_change( user_id, work_id, k, before[k], after[k] )
          when :string_array
            audit_string_array_change( user_id, work_id, k, before[k], after[k] )
          when :person_array
            audit_person_array_change( user_id, work_id, k, before[k], after[k] )
          #when :files
          #  audit_files_change( user_id, work_id, 'files', before.file_sets, after.file_sets )
          #when :visibility
          #  audit_string_change( user_id, work_id, k, before.visibility, after.visibility )
        end
      end
    end

    def audit_string_change( user_id, work_id, field, before, after )
      audit( user_id, work_id, field, before, after )
    end

    def audit_string_array_change( user_id, work_id, field, before, after )

      # short cut...
      return if before.blank? && after.blank?

      # use sorted arrays so we dont audit benign changes
      before = before.sort || []
      after = after.sort || []
      audit( user_id, work_id, field, before.join( ', ' ), after.join( ', ' ) )
    end

    def audit_person_array_change( user_id, work_id, field, before, after )

      # short cut...
      return if before.blank? && after.blank?

      before_people = before.map{ |p| person_hash_to_audit( p )} || []
      after_people = after.map{ |p| person_hash_to_audit( p ) } || []
      audit( user_id, work_id, field, before_people.join( ', ' ), after_people.join( ', ' ) )
    end

    def audit( user_id, work_id, field, before, after )
      before = '' if before.nil?
      after = '' if after.nil?

      if before != after
        puts "** AUDIT ** field #{field} was [#{before}], now [#{after}]"
        Audit.audit( work_id, user_id, field, before, after )
      #else
      #  puts "** WARNING ** field #{field} unchanged - before [#{before}], after [#{after}]"
      end

    end

    def person_hash_to_audit( ph )
      return "#{ph[ AUDIT_PERSON_FIELDS[ 0 ]]}/#{ph[ AUDIT_PERSON_FIELDS[ 1 ]]}/#{ph[ AUDIT_PERSON_FIELDS[ 2 ]]}/#{ph[ AUDIT_PERSON_FIELDS[ 3 ]]}/#{ph[ AUDIT_PERSON_FIELDS[ 4 ]]}"
    end

end
