# adds nodejs requirements of:
#     passwordgen
#     bcrypt-nodejs

auth_server_funcs = module.exports = (master, client) ->
  console.assert client

  client('initiate_reset_pass').to_save = (o, t) ->

    return t.abort(o) if !o.who? && !o.email?

    usr = null 
    if !o.who && o.email 
      for candidate in (master.fetch('users').all or [])
        if candidate.email == o.email
          usr = candidate
          break
    else 
      usr = master.fetch "user/#{o.who}"

    console.log 'got reset request', o, usr

    email_not_found = -> 
      console.log 'user not found', o, usr
      send_email 
        subject: "[#{process.env.APP_NAME}] password reset requested"
        text: "Someone requested a reset code for #{o.email} at #{process.env.APP_NAME}. But there is no user registered with that email. If you requested the reset, please create a new account instead, or try a different one of your email addresses. If you didn't, you can ignore this email."
        html: "Someone requested a reset code for #{o.email} at #{process.env.APP_NAME}. But there is no user registered with that email. If you requested the reset, please create a new account instead, or try a different one of your email addresses. If you didn't, you can ignore this email."
        recipient: o.email

    if usr 
      secret = new (require('passwordgen'))().phrase(18)
      reset = master.fetch('reset_pass')
      reset.keys ?= {}
      reset.keys[secret] = usr.key
      master.save reset

      if usr.email
        send_email 
          subject: "[#{process.env.APP_NAME}] password reset code"
          text: "Copy and paste the following random words back to the password reset code field: #{secret}"
          html: "Copy and paste the following random words back to the password reset code field: <p><b>#{secret}</b></p>"
          recipient: usr.email
      else 
        email_not_found()
    else 
      email_not_found()

    t.abort(o)

  client('reset_pass').to_fetch = (old) -> return old or {}

  client('reset_pass').to_save = (o, t) ->
    reset = master.fetch('reset_pass')

    reset.keys ?= {}

    # Good token!
    if reset.keys[o.token]
      console.log('Token accepted! For', reset.keys[o.token])
      user = master.fetch(reset.keys[o.token])
      # console.log('user is', user)

      if o.pass 
        # console.log('good reset pass got password', o)
        user.pass = require('bcrypt-nodejs').hashSync(o.pass)
        master.save(user)
        delete reset.keys[o.token]
        o.successful = true
        master.save(reset)
      else 
        current_user = client.fetch('current_user') 
        current_user.error = 'New password is required'
        client.save current_user

    # Bad token
    else
      console.log('bad reset pass token', {o, keys:reset.keys})
      current_user = client.fetch('current_user') 
      current_user.error = 'Incorrect code! Make sure you copied and pasted correctly.'
      client.save current_user
    
    client.save.fire(o)
    t.done(o)
