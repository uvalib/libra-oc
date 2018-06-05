module Libraoc::CreateBehavior

  extend ActiveSupport::Concern

  included do

    before_create :create_behavior

    private

    def create_behavior

      self.date_created = Hyrax::TimeService.time_in_utc.to_s if self.date_created.blank?

    end

  end

end
