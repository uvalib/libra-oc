class Audit < ActiveRecord::Base

  def self.audit( work_id, user_id, field, before, after )
    audit = Audit.new
    audit.work_id = work_id
    audit.user_id = user_id
    audit.field = field
    audit.before = before
    audit.after = after
    audit.save!
  end

  def to_s
    return "#{created_at}: #{user_id}/#{work_id} '#{field}' #{before} -> #{after}"
  end

  def by_user
    return "#{created_at}: updated work #{work_id} #{field_activity}"
  end

  def by_work
    return "#{created_at}: user #{user_id} #{field_activity}"
  end

  private

  def field_activity
    if field == 'files'
      if before.blank?
        return "added file #{after}"
      else
        return "removed file #{before}"
      end
    else
      return "#{field} was '#{before.truncate( 32 )}', now '#{after.truncate( 32 )}'"
    end
  end

end