class VisibilityCopyJob < ActiveJob::Base
  def perform(work)
    work.file_sets.each do |file|
      file.visibility = work.visibility # visibility must come first, because it can clear an embargo/lease
      if work.lease
        file.build_lease unless file.lease
        file.lease.attributes = work.lease.attributes.except('id')
        file.lease.save
      end
      if work.embargo
        file.build_embargo unless file.embargo
        file.embargo.attributes = work.embargo.attributes.except('id')
        file.embargo.save
      end
      file.save!
    end
  end
end
