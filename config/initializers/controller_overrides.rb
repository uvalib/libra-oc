#require_dependency 'libraoc/helpers/statistics_helper'

DownloadsController.class_eval do

  include StatisticsHelper

  #
  # override so we can generate a download event whenever a file is downloaded
  # standard sufia uses google analytics for this and this approach was easier
  # than integrating with piwik
  #
  def show

    #
    # assume we need a file download event unless the file is a string. This means that the
    # file is a thumbnail (special sufia magic) and we dont want a download event when downloading
    # thumbnails
    #
    if file.kind_of?( String ) == false
      # save file download statistics
      file_download_event( params['id'], current_user )
    end
    super
  end

end

