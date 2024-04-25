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
    return "#{Audit.localtime( created_at )}: #{user_id} updated #{work_id} #{field_activity}"
  end

  def to_psv
    return "#{Audit.localtime( created_at )}|#{user_id}|#{work_id}|#{field_psv}"
  end

  def by_user
    return "#{Audit.localtime( created_at )}: updated #{work_id} #{field_activity}"
  end

  def by_work
    return "#{Audit.localtime( created_at )}: #{user_id} #{field_activity}"
  end

  def self.localtime( datetime )
    return 'unknown' if datetime.blank?
    begin
      return datetime.localtime.strftime( '%Y-%m-%d %H:%M:%S %Z' )
    rescue => ex
      # do nothing
    end
    return datetime
  end

  private

  def field_activity
    if field == 'files'
      if before.blank?
        return "added file '#{after}'"
      elsif after.blank?
        return "removed file '#{before}'"
      else
        return "renamed file '#{before}' to '#{after}'"
      end
    else
      bf = 'empty'
      af = 'empty'
      bf = "'#{before.truncate( 32 )}'" unless before.blank?
      af = "'#{after.truncate( 32 )}'" unless after.blank?
      return "#{field} was #{bf}, now #{af}"
    end
  end

  def field_psv
    if field == 'files'
      if before.blank?
        return "file|empty|#{after}"
      elsif after.blank?
        return "file|#{before}|empty"
      else
        return "file|#{before}|#{after}"
      end
    else
      bf = 'empty'
      af = 'empty'
      bf = "#{before.squish}" unless before.blank?
      af = "#{after.squish}" unless after.blank?
      return "#{field}|#{bf}|#{af}"
    end
  end

end
