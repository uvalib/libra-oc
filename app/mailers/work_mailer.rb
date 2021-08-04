class WorkMailer < ActionMailer::Base
	add_template_helper(PublicViewHelper)

	#
	# user has just submitted a work, send them a success email
	#
	def work_submitted( work, to, from )
		@recipient = User.displayname_from_email( to )
		@title = work.title.first
    @visibility = work.is_publicly_visible? ? 'public' : 'UVa-only'
		@embargo_release_date = work.embargo_release_date
		@visibility_after_embargo = work.visibility_after_embargo
    @rights_name = RightsService.label( work.rights.first )
		@doi_url = work.doi_url
		subject = 'Work successfully deposited to Libra'
		logger.info "Sending email (successful deposit); to: #{to} (#{@recipient}), from: #{from}, subject: #{subject}"
    mail( to: to, from: from, subject: subject )
	end

end
