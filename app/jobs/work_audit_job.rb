class WorkAuditJob < ActiveJob::Base

    queue_as :audit

    # attributes we are auditing and their audit methods
    AUDIT_FIELDS ||= {
        'abstract'           => :string,
        'admin_notes'        => :string_array,
        'authors'            => :person_array,
        'contributors'       => :person_array,
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
    }

    # fields used to audit a person record
    AUDIT_PERSON_FIELDS ||= [
       'first_name',
       'last_name',
       'computing_id',
       'department',
       'institution',
    ]

    # some special cases
    ID_FIELD_NAME ||= 'id'
    VISIBILITY_FIELD_NAME ||= 'visibility'
    FILES_FIELD_NAME ||= 'files'

    def self.serialize_work( work )
       ret = {}
       return ret.to_json if work.nil?
       AUDIT_FIELDS.keys.each do |k|
         ret[ k ] = work[ k ]
       end

       # handle the special case
       ret[ ID_FIELD_NAME ] = work.id
       ret[ VISIBILITY_FIELD_NAME ] = work.visibility
       ret[ FILES_FIELD_NAME ] = work.file_sets.map { |fs| fs.label }

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
      return if after[ VISIBILITY_FIELD_NAME ] == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE

      # dont audit the transition from private to non-private
      #return if before[ VISIBILITY_FIELD_NAME ] == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE

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
        end
      end

      # handle special cases
      audit_string_change( user_id, work_id,
                           VISIBILITY_FIELD_NAME,
                           before[VISIBILITY_FIELD_NAME],
                           after[VISIBILITY_FIELD_NAME] )

      # handle special cases
      audit_files_array_change( user_id, work_id,
                                FILES_FIELD_NAME,
                                before[FILES_FIELD_NAME],
                                after[FILES_FIELD_NAME] )
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

      # TODO: another case where weappear to get duplicates sometimes
      before_people = before.uniq.map{ |p| person_hash_to_audit( p )} || []
      after_people = after.uniq.map{ |p| person_hash_to_audit( p ) } || []
      audit( user_id, work_id, field, before_people.join( ', ' ), after_people.join( ', ' ) )
    end

    def audit_files_array_change( user_id, work_id, field, before, after )

      # short cut...
      return if before.blank? && after.blank?

      # in case we have nil values
      before = [] if before.blank?
      after = [] if after.blank?

      #
      # when filesets are removed from a work, it goes via a different controller so we do not see it here
      # we only need to account for *added* filesets
      #
      after.each do |fn|
        if before.include?( fn ) == false
          audit( user_id, work_id, field, '', fn )
        end
      end

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
