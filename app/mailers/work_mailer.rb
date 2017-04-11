class WorkMailer < ActionMailer::Base

	#
	# user has just submitted a public work, send them a success email
	#
	def public_work_submitted( work, to, from )
		@recipient = User.displayname_from_email( to )
		@rights = work.rights.join(' ')
		@doi_url = work.doi
		subject = 'Work successfully deposited to libra-oc'
		logger.info "Sending email (successful deposit); to: #{to} (#{@recipient}), from: #{from}, subject: #{subject}"
    mail( to: to, from: from, subject: subject )
	end

end
