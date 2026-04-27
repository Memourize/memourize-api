class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("SMTP_FROM", ENV["SMTP_USER"])
  layout "mailer"
end
