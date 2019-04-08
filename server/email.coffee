try
  mailgun = require('mailgun-js')
    apiKey: process.env.MAILGUN_API_KEY
    domain: process.env.MAILGUN_DOMAIN

  global.send_email = ({subject, html, text, recipient, sender}) ->
    sender ||= process.env.MAILGUN_SENDER
    console.log 'SENDING TO ', recipient
    mailgun.messages().send
      from: sender
      to: recipient
      subject: subject
      text: text
      html: html or text
catch e 
  global.send_email = -> 
    console.error 'could not send message beecause mailgun failed to load'
