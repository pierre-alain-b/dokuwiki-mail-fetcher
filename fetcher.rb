require 'net/imap'
require 'mail'
require 'yaml'

#Retrieve settings from external file
settings = YAML.load_file('settings.yml')

#Start the actual work
imap = Net::IMAP.new(settings['imap_host'], settings['imap_port'], settings['imap_ssl'], nil, false)
imap.authenticate('LOGIN', settings['imap_user'], settings['imap_password'])
imap.select('INBOX')
      
#Select unseen messages only
imap.search(["NOT", "SEEN"]).each do |message_id|
	#Get the full content
	raw = imap.fetch(message_id, "BODY[]")[0].attr["BODY[]"]
	imap.store(message_id, '+FLAGS', [:Seen])
	#Parse it with mail library
	mail = Mail.read_from_string(raw)
	token = mail.to.to_s
	#If multipart or auth token not included, then discard the mail and send a warning
	if mail.multipart? or (not token.include?(settings['token_email'].to_s))
    		imap.copy(message_id, 'Untreated')
    	else
		content = mail.body.decoded
		name = mail.subject
		date = mail.date

		#Here, create the file
		puts content

		imap.copy(message_id, 'Treated')
	end
        imap.store(message_id, '+FLAGS', [:Deleted])
end
imap.expunge #Delete all mails with deleted flags
imap.close
