class TestMailer < ActionMailer::Base

	def email( to, from, subject )
		mail( to: to, from: from, subject: subject )
	end
end
