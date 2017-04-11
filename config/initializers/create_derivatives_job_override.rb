CreateDerivativesJob.class_eval do
  def perform(file_set, file_id, filepath=nil)
    if Toggles.enable_derivatives
      self.class.perform_now file_set, file_id, filepath
    end
  end
end
