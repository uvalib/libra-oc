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
end