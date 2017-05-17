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

end