module Libraoc::AuditBehavior

  extend ActiveSupport::Concern

  included do

    # hook to audit any pending changes when we update a record
    before_update :audit_changes

    # attributes we are auditing and their audit methods
    AUDIT_KEYS = {
        'abstract'           => :audit_string_change,
        'admin_notes'        => :audit_string_change,
#        'contributors'       => :audit_person_array_change,
#        'creators'           => :audit_person_array_change,
        'keyword'            => :audit_string_array_change,
        'language'           => :audit_string_array_change,
        'notes'              => :audit_string_change,
        'published_date'     => :audit_string_change,
        'publisher'          => :audit_string_change,
        'related_url'        => :audit_string_array_change,
        'resource_type'      => :audit_string_change,
        'rights'             => :audit_string_array_change,
        'source_citation'    => :audit_string_change,
        'sponsoring_agency'  => :audit_string_array_change,
        'title'              => :audit_string_array_change,
    }

    private

    def audit_changes

      # check for changes and return if we do not have any
      changes = self.changed_attributes
      return if changes.blank?

      # lookup the work and return if we cannot find it
      before_work = get_before_work( id )
      return if before_work.nil?

      # enumerate each change and if it is one we are interested in
      changes.keys.each do |k|
         if AUDIT_KEYS.keys.include? k
           send( AUDIT_KEYS[ k ], k, before_work[k], self[k] )
         else
           puts "==> IGNORING REPORTED CHANGE FOR #{k}"
         end
      end

    end

    def work_id
      return self.id || 'none'
    end

    def user_id
      return 'dpg3k'
    end

    def audit_string_change(field, before, after )
      audit( field, before, after )
    end

    def audit_string_array_change(field, before, after )
      audit( field, before.join( ', ' ), after.join( ', ' ) )
    end

    def audit_person_array_change(field, before, after )
      before_people = before.map{ |p| p.to_s }
      after_people = after.map{ |p| p.to_s }
      audit( field, before_people, after_people )
    end

    def audit( field, before, after )
      before = '' if before.nil?
      after = '' if after.nil?

      if before != after
         puts "** AUDIT ** field #{field} was [#{before}], now [#{after}]"
         Audit.audit( work_id, user_id, field, before, after )
      else
         puts "** WARNING ** field #{field} reported changed but not - before [#{before}], after [#{after}]"
      end

    end

    def get_before_work( id )
      begin
        return LibraWork.find( id )
      rescue => ex
        # do noting
      end
      return nil
    end
  end

end