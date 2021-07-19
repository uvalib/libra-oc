module VisibilityHelper

  #
  # can we view this work
  #
  def can_view_work?( work )
    can_view = can_view?( work )
    puts "==> can_view_work = #{can_view}"
    return( can_view )
  end

  #
  # can we download files from the work
  #
  def can_download_files?( work )
    check_embargo(work)
    can_download = can_download?( work )
    puts "==> can_download_files = #{can_download}"
    return( can_download )
  end

  def check_embargo(work)
    # if the embargo is expired
    if work.embargo.present? && !work.embargo.active?
      #check for visibility updates
      if work.embargo.visibility_after_embargo != work.visibility
        puts "Updating embargo visibility"
        work.embargo_visibility!
        work.save!
      end
    end
  end

  #
  # determine work visibility
  #
  def can_view?( work )

    # no work, no access
    if work.nil?
      puts "==> work is undefined; view access is DENIED"
      return false
    end

    # this work is owned by the current user regardless of visibility
    if current_user.present? && work.is_mine?( current_user.email )
      puts "==> work is user owned; view access is GRANTED"
      return true
    end

    # if this is a publicly visible work
    if work.is_publicly_visible?
      puts "==> work is publicly visible; view access is GRANTED"
      return true
    end

    # if this is an institutional visible work
    if work.is_institution_visible?
      puts "==> work is institution visible; view access is GRANTED"
      return true
    end

    # if the current user is an admin
    if current_user.present? && current_user.admin?
       puts "==> user is an admin; view access is GRANTED"
       return true
    end

    # Check embargo status
    if work.embargo.present? && work.embargo.active?
      puts "==> work is embargoed; view access is GRANTED"
      return true
    end

    # if the work is private, we have already checked for an admin
    if work.is_private?
       puts "==> work is private; view access is DENIED"
       return false
    end

    puts "==> unclear work state; view access is DENIED"
    return false
  end

  #
  # determine files in work visibility
  #
  def can_download?( work )

    # verify we can actually view this
    return false unless can_view?( work )

    # if the current user is an admin
    if current_user.present? && current_user.admin?
      puts "==> user is an admin; download access is GRANTED"
      return true
    end

    # check to see if we are on grounds or not...
    on_grounds = is_on_grounds( )

    # if this is an institution visible work it should only be visible on-grounds
    if work.is_institution_visible? && on_grounds == true
      puts "==> work is institution visible and on grounds; download access is GRANTED"
      return true
    end

    # if this is an institution visible work it should only be visible if we are on-grounds
    if work.is_institution_visible? && on_grounds == false
      puts "==> work is institution visible and OFF grounds; download access is DENIED"
      return false
    end

    # Check embargo status
    if work.embargo.present? && work.embargo.active?
      puts "==> work is embargoed; Download access is DENIED"
      return false
    end

    # no other reason to restrict (we know they can view the metadata) so they can download the files too
    puts "==> no reason to restrict; download access is GRANTED"
    return true
  end

  #
  # determine from the IP address if we are on-grounds or not
  #
  def is_on_grounds

    if @grounds_override
      return true if @grounds_override == 'on'
      return false if @grounds_override == 'off'
    end
    uva_ips = uva_ip_blocks
    #puts "==> Remote IP: #{request.remote_ip}"
    #puts "==> Forwarded IP: #{request.env["HTTP_X_FORWARDED_FOR"]}"
    in_uva_ips = uva_ips.any?{ |block| block.include?( request.remote_ip ) }
    puts "===> #{request.remote_ip} @ UVa is #{in_uva_ips}"
    return in_uva_ips
  end

  #
  # load the IP block configuration
  #
  def uva_ip_blocks
    uva_ip_ranges_list = [ ]
    File.open( Rails.application.config.ip_whitelist, 'r' ).each_line { |line|
      line.strip!
      uva_ip_ranges_list.push line
    }

    return uva_ip_ranges_list.map { |subnet| IPAddr.new subnet }
  end

  #
  # helper to create radio buttons for the debug panel
  #
  def create_radio( name, value, label, is_default = false )
    attr = { type: "radio", name: name, value: value}
    if params[name.to_sym] == value || (params[name.to_sym].nil? && is_default)
      attr[:checked] = 'checked'
    end
    return content_tag(:input, ' ' + label, attr)
  end

  def embargo_notice(work)
    return "" if work.embargo.present? && !work.embargo.active?

    return "This item is embargoed and not available until #{date_formatter(work.embargo_release_date)}."
  end

  def show_proof_embargo_notice(work)
    return work.embargo.present? && work.embargo.active? &&
      (current_user.admin? || work.depositor == current_user.email)
  end

end
