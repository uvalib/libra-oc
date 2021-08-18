module ExportsHelper

  def format_visibility( rec )
    return 'Private' if rec.is_private?
    return 'UVa only' if rec.is_institution_visible?
    return 'Public' if rec.is_publicly_visible?
    return 'Embargoed' if rec.has_embargo?
    return 'unknown'
  end

  def format_abstract( rec )
    return '' if rec.abstract.blank?
    return transform_newlines( format_array( rec.abstract, ' ' ) )
  end

  def format_notes( rec )
    return '' if rec.notes.blank?
    return transform_newlines( first_from_array( rec.notes ) )
  end

  def format_admin_notes( rec )
    return '' if rec.admin_notes.blank?
    return transform_newlines( format_array( rec.admin_notes, ', ' ).gsub( LibraWork::ADMIN_NOTE_DATE_MARKER, '-' ) )
  end

  def format_array( array, delimiter )
    return '' if array.blank?
    return array.sort.join( delimiter )
  end

  def first_from_array( array )
    return '' if array.blank?
    return array.first
  end

  def format_file_count( rec )
    return( rec.file_set_ids.blank? ? 0 : rec.file_set_ids.length )
  end

  def format_view_count( rec )
     return( get_work_view_count( rec ) )
  end

  def format_download_count( rec )
    return 0 if rec.file_set_ids.blank?
    sum = 0
    rec.file_set_ids.each do |fsid|
      sum += get_file_download_count( fsid )
    end
    return sum
  end

  def format_aggregate_filesize( rec )
    return 0 if rec.file_set_ids.blank?

    total_size = 0
    tstart = Time.now
    FileSet.search_in_batches( { id: rec.file_set_ids } ) do |fsg|
      elapsed = Time.now - tstart
      puts "===> extracted #{fsg.length} fileset(s) in #{elapsed}"
      fsg.each do |fsid|
        total_size += fsid[ 'file_size_is' ] unless fsid[ 'file_size_is' ].blank?
      end
      tstart = Time.now
    end

    return total_size
  end

  private

  def transform_newlines( str )
     return str.gsub( /\n/, ' ' )
  end

end
