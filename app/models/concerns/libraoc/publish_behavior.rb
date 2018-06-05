module Libraoc::PublishBehavior

  extend ActiveSupport::Concern

  included do

    before_save :assign_published_date, :if => :published_date_unassigned?

    private

    def published_date_unassigned?
      return self.published_date.blank?
    end

    def assign_published_date

      # dont set the published date on private works or legacy works
      if is_private? == false && is_legacy_content? == false
         self.published_date = Hyrax::TimeService.time_in_utc.to_s
      end

    end

  end

end
