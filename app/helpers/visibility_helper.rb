module VisibilityHelper

	#
	# can we view this work
	#
	def can_view_work?( work )
		can_view = can_access?( work )
		puts "==> can_view_work = #{can_view}"
		return( can_view )
	end

	#
	# can we download files from the work
	#
	def can_download_files?( work )
		can_download = can_access?( work )
		puts "==> can_download_files = #{can_download}"
		return( can_download )
	end

	#
	# determine work visibility
	#
	def can_access?( work )

		# no work, no access
		return false if work.nil?

		# this work is owned by the current user regardless of visibility
		return true if current_user.present? && work.is_mine?( current_user.email )

		# if this is a publicly visible work
		return true if work.is_publicly_visible?

		# assume the work is not publicly visible and only visible on-grounds
		return is_on_grounds( )

	end

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

	def uva_ip_blocks
		uva_ip_ranges_list = [ ]
		File.open( Rails.application.config.ip_whitelist, 'r' ).each_line { |line|
			line.strip!
			uva_ip_ranges_list.push line
		}

		return uva_ip_ranges_list.map { |subnet| IPAddr.new subnet }
	end

	def create_radio( name, value, label, is_default = false )
		attr = { type: "radio", name: name, value: value}
		if params[name.to_sym] == value || (params[name.to_sym].nil? && is_default)
			attr[:checked] = 'checked'
		end
		return content_tag(:input, ' ' + label, attr)
	end

end
