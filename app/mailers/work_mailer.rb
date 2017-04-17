class WorkMailer < ActionMailer::Base

	#
	# user has just submitted a work, send them a success email
	#
	def work_submitted( work, to, from )
		@recipient = User.displayname_from_email( to )
    @visibility = work.is_publicly_visible? ? 'public' : 'UVa-only'
		@rights = work.rights.join(' ')
		@doi_url = work.doi_url
		subject = 'Work successfully deposited to libra-oc'
		logger.info "Sending email (successful deposit); to: #{to} (#{@recipient}), from: #{from}, subject: #{subject}"
    mail( to: to, from: from, subject: subject )
	end

end
