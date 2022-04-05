# Primitive client auth

# Requires: 
#   - shared.coffee

h1_style = 
  color: 'white'
  fontWeight: 500
  fontSize: 48
  textAlign: 'center'
  marginBottom: 24
  marginTop: 24

label_style = 
  fontSize: 16
  paddingBottom: 4
  textAlign: 'left'
  color: '#666'

input_style = 
  border: '1px solid #ddd'
  padding: '4px 8px'
  fontSize: 18
  backgroundColor: '#fafafa'
  width: '100%'

submit_button_style = 
  backgroundColor: '#676767'
  fontSize: 28
  width: '100%'
  padding: '12px 0'
  color: 'white'
  borderRadius: 8
  fontWeight: 'bold'
  border: 'none'
  boxShadow: '0 1px 2px rgba(0,0,0,.2)'
  cursor: 'pointer'

field_style = 
  marginBottom: 12

inner_container_style = 
  backgroundColor: 'white'
  boxShadow: '0 1px 2px rgba(0,0,0,.2)'
  padding: '50px 100px 20px 100px'   


dom.AUTH = -> 
  auth = fetch 'auth'
  current_user = fetch '/current_user'

  if current_user.logged_in && auth.form in ['register', 'login']
    auth.form = null 
    save auth 

  return SPAN null if !auth.form



  DIV   
    style: defaults {}, (@props.style or {}),
      backgroundColor: if considerit_salmon? then considerit_salmon else '#E16161'
      padding: 20


    DIV 
      id: 'lightbox'

    DIV
      id: 'modal'
      ref: 'dialog'
      role: 'dialog'

      DIV 
        style: 
          maxWidth: 560
          margin: 'auto'
          

        switch auth.form 
          when "register", "login"
            LOGIN_or_REGISTER
              login_field: @props.login_field
              additional_questions: @props.additional_questions
          when "edit_profile"
            EDIT_PROFILE
              additional_questions: @props.additional_questions
          when "upload_avatar"
            SET_AVATAR()
          when "reset_password"
            RESET_PASSWORD
              login_field: @props.login_field



        DIV 
          style: 
            marginTop: 24
            textAlign: 'center'

          BUTTON 
            style: 
              backgroundColor: 'transparent'
              border: 'none'
              #textDecoration: 'underline'
              cursor: 'pointer'
              opacity: .7
              color: 'white'

            onClick: => 
              auth.form = null 
              save auth
            onKeyPress: (e) -> 
              if e.which == 32 || e.which == 13
                auth.form = null 
                save auth

            if auth.form == "upload_avatar" && current_user.user && !fetch(current_user.user).pic
              'Nope, I shall remain faceless'
            else 
              'Nevermind, cancel'

if makeModal?
  makeModal dom.AUTH




################
## AUTH forms ##
################

dom.LOGIN_or_REGISTER = -> 
  current_user = fetch '/current_user'
  auth = fetch 'auth'

  @props.login_field ?= 'name' # other option is 'email'

  if !@local.credentials?
    @local.credentials = 
      name: fetch('/connection').name

  toggle_form = -> 
    auth.form = if auth.form == 'login' then 'register' else 'login'
    save auth

  name_field = DIV style: field_style,
    DIV 
      style: label_style
      'What\'s your name?'

    INPUT
      ref: 'name'
      type: 'text'
      style: input_style
      value: @local.credentials.name
      onChange: (e) =>
        @local.credentials.name = e.target.value
        save @local

  email_field = DIV style: field_style,
    DIV 
      style: label_style
      'Your email, please:'

    INPUT
      ref: 'email'
      type: 'email'
      style: input_style
      value: @local.credentials.email
      onChange: (e) =>
        @local.credentials.email = e.target.value
        save @local

  password_field = DIV style: field_style,

    DIV style: label_style,
      'Password:'

    INPUT
      ref: 'password'
      type: 'password'
      style: input_style
      value: @local.credentials.password
      onChange: (e) =>
        @local.credentials.password = e.target.value
        save @local

  errors = \
    if current_user.error
      flash = setTimeout => 
        delete current_user.error 
        save current_user
      , 10000

      DIV 
        style: 
          backgroundColor: '#eee'
          color: 'red'
        current_user.error
    else 
      SPAN null


  login = => 
    reset_password = @local.reset_password
    enabled = ((@props.login_field == 'email' && @local.credentials.email) || (@props.login_field == 'name' && @local.credentials.name) ) && (@local.credentials.password || reset_password)

    submit_login = => 

      if enabled 
        if reset_password
          auth.form = 'reset_password'
          save auth
          save
            key: '/initiate_reset_pass'
            email: @local.credentials.email
            who: if !@local.credentials.email then @local.credentials.name

        else 
          current_user.login_as =
            login: @local.credentials[@props.login_field] 
            pass: @local.credentials.password  
          save current_user
    
    forgot_password = => 
      @local.reset_password = !@local.reset_password
      save @local

    DIV null, 
    
      H1 
        style: h1_style
        'Welcome back!'

      DIV 
        style: inner_container_style
                 
        if @props.login_field == 'email'    
          email_field
        else 
          name_field

        if !reset_password
          password_field 

        if !reset_password
          BUTTON 
            style: 
              backgroundColor: 'transparent'
              textDecoration: 'underline'
              fontSize: 12
              color: '#888'
              fontWeight: 400
              padding: 0
              # display: 'none'
            onClick: forgot_password
            onKeyPress: (e) =>
              if e.which == 32 || e.which == 13
                forgot_password()
            "Help, I forgot my password!"


        DIV 
          style: extend {}, field_style,
            marginTop: 35

          INPUT 
            type: 'submit'
            style: extend '', submit_button_style, 
              opacity: if !enabled then .5
              cursor: if !enabled then 'auto' else 'pointer'
            value: if reset_password then 'Email me a reset code' else 'Login'
            disabled: !enabled
            onClick: submit_login
            onKeyPress: (e) =>
              if e.which == 32 || e.which == 13
                submit_login()

        errors

      DIV 
        style: 
          textAlign: 'center'
          marginTop: 24

        A 
          style: 
            textDecoration: 'underline'
            color: 'white'
            fontSize: 24

          onClick: toggle_form
          onKeyPress: (e) -> 
            if e.which == 32 || e.which == 13
              toggle_form()

          "I don't have an account yet!"

  register = =>
    enabled = @local.credentials.name && @local.credentials.email \
              && @local.credentials.password

    submit_registration = => 
      if enabled 
        current_user.create_account =
          name: @local.credentials.name
          login: @local.credentials[@props.login_field]
          email: @local.credentials.email 
          pass: @local.credentials.password 
        current_user.login_as =
          login: @local.credentials[@props.login_field]
          name: @local.credentials.name 
          pass: @local.credentials.password  

        if @props.additional_questions
          current_user.private = {}
          current_user.public = {}
          @props.additional_questions?.private?(current_user.private)
          @props.additional_questions?.public?(current_user.public)
        save current_user


        wait_for_login = setInterval ->
          if current_user.logged_in
            auth.form = 'upload_avatar' 
            save auth
            clearInterval wait_for_login
          else if current_user.error
            clearInterval wait_for_login
        , 100

    DIV null, 
    
      H1 
        style: h1_style
        'Glad you\'re joining us!'

      DIV 
        style: inner_container_style
                     
        name_field
        email_field
        password_field

        @props.additional_questions?.render?()

        DIV 
          style: extend {}, field_style,
            marginTop: 50

          INPUT 
            type: 'submit'
            style: extend '', submit_button_style, 
              opacity: if !enabled then .5
              cursor: if !enabled then 'auto' else 'pointer'
            value: 'Join'
            disabled: !enabled
            onClick: submit_registration
            onKeyPress: (e) =>
              if e.which == 32 || e.which == 13
                submit_registration()

        errors

      DIV 
        style: 
          marginTop: 24
          fontSize: 24
          textAlign: 'center'

        A 
          style: 
            textDecoration: 'underline'
            color: 'white'

          onClick: toggle_form
          onKeyPress: (e) -> 
            if e.which == 32 || e.which == 13
              toggle_form()

          "I already have an account!"

  if auth.form == 'login'
    login()
  else 
    register()



dom.INLINE_LOGIN = ->
  current_user = fetch '/current_user'
  auth = fetch 'auth'

  credentials = fetch 'credentials'

  if !credentials.init?
    credentials.init = true 
    credentials.name = fetch('/connection').name

  toggle_form = -> 
    auth.form = 'login'
    save auth

  name_field = DIV style: field_style,

    INPUT
      ref: 'name'
      type: 'text'
      style: input_style
      value: credentials.name
      placeholder: "Your name"
      onChange: (e) =>
        credentials.name = e.target.value
        save credentials

  email_field = DIV style: field_style,

    INPUT
      ref: 'email'
      type: 'email'
      style: input_style
      value: credentials.email
      placeholder: "Your email"
      onChange: (e) =>
        credentials.email = e.target.value
        save credentials

  password_field = DIV style: field_style,

    INPUT
      ref: 'password'
      type: 'password'
      style: input_style
      placeholder: 'A password'
      value: credentials.password
      onChange: (e) =>
        credentials.password = e.target.value
        save credentials

  errors = \
    if current_user.error
      flash = setTimeout => 
        delete current_user.error 
        save current_user
      , 10000

      DIV 
        style: 
          backgroundColor: '#eee'
          color: 'red'
        current_user.error
    else 
      SPAN null


  DIV null, 
  
    DIV
      style: 
        marginBottom: 24
      
      @props.intro_text or "Hi, please introduce yourself when posting."
      " Or "
      A 
        style: 
          textDecoration: 'underline'

        onClick: toggle_form
        onKeyPress: (e) -> 
          if e.which == 32 || e.which == 13
            toggle_form()
        "log in"
      " if you already have an account."


    DIV 
      style: {}
                   
      name_field
      email_field
      password_field

      @props.additional_questions?.render?()


      SET_AVATAR
        inline_form: true

      if @props.add_submit_button
        BUTTON
          disabled: !credentials_filled_out()
          onClick: ->
            submit_inline_registration 'email', window.additional_registration_questions
          onKeyPress: (e) -> 
            if e.which == 32 || e.which == 13
              submit_inline_registration 'email', window.additional_registration_questions

          style: 
            backgroundColor: considerit_salmon
            color: 'white'
            fontWeight: 600
            border: 'none'
            fontSize: 18
            padding: '2px 16px'
            borderRadius: 8
            verticalAlign: 'top'
            display: 'block'
            #marginLeft: 8
            cursor: 'pointer'
            marginTop: 4
            marginLeft: 8
            marginBottom: 2
          "Register"

        

      errors

credentials_filled_out = ->
  credentials = fetch 'credentials'  
  credentials.name && credentials.email?.length > 2 && credentials.email?.indexOf("@") > -1 && credentials.email?.indexOf(".") > -1 && credentials.password

window.submit_inline_registration = (login_field, additional_questions) -> 
  credentials = fetch 'credentials'
  current_user = fetch '/current_user'

  current_user.create_account =
    name: credentials.name
    login: credentials[login_field]
    email: credentials.email 
    pass: credentials.password 

  current_user.login_as =
    login: credentials[login_field]
    name: credentials.name 
    pass: credentials.password  

  if additional_questions
    current_user.private = {}
    current_user.public = {}
    additional_questions?.private?(current_user.private)
    additional_questions?.public?(current_user.public)
  save current_user






dom.RESET_PASSWORD = -> 
  current_user = fetch '/current_user'
  auth = fetch 'auth' 
  reset = fetch('/reset_pass')

  if reset.successful
    auth.form = 'login'
    current_user = fetch '/current_user'
    current_user.error = "Password successfully changed! Now login."
    bus.save current_user
    bus.save auth



  if !@local.credentials?
    @local.credentials = 
      name: fetch('/connection').name

  token_field = DIV style: field_style,
    DIV 
      style: label_style
      'Your password reset code (from email):'

    INPUT
      ref: 'reset_token'
      style: input_style
      value: @local.credentials.password_reset_token
      onChange: (e) =>
        @local.credentials.password_reset_token = e.target.value
        save @local

  password_field = DIV style: field_style,

    DIV style: label_style,
      'A new password:'

    INPUT
      ref: 'password'
      type: 'password'
      style: input_style
      value: @local.credentials.password
      onChange: (e) =>
        @local.credentials.password = e.target.value
        save @local

  errors = \
    if current_user.error
      flash = setTimeout => 
        delete current_user.error 
        save current_user
      , 5000

      DIV 
        style: 
          backgroundColor: '#eee'
          color: 'red'
        current_user.error
    else 
      SPAN null


  enabled = @local.credentials.password

  reset_pass = => 
    reset.pass = @local.credentials.password
    reset.token = @local.credentials.password_reset_token
    bus.save reset

  DIV null, 
  
    H1 
      style: h1_style
      'Reset your password'

    DIV 
      style: inner_container_style

      token_field

      password_field 

      DIV 
        style: extend {}, field_style,
          marginTop: 35

        INPUT 
          type: 'submit'
          style: extend '', submit_button_style, 
            opacity: if !enabled then .5
            cursor: if !enabled then 'auto' else 'pointer'
          value: 'Update password'
          disabled: !enabled
          onClick: reset_pass
          onKeyPress: (e) =>
            if e.which == 32 || e.which == 13
              reset_pass()

      errors

      DIV 
        style: 
          fontSize: 12
          marginTop: 12

        "Still having problems? Email "
        A 
          style: 
            textDecoration: 'underline'
          href: "mailto:travis@consider.it?subject=Login woes"
          "travis@consider.it"





dom.EDIT_PROFILE = -> 
  auth = fetch 'auth'
  current_user = fetch '/current_user'
  user = current_user.user
  return SPAN null if !current_user.logged_in

  if !@local.credentials?
    @local.credentials = 
      name: user.name
      email: user.email

  if !@local.login?
    @local.login = if !@props.login? then false else @props.login


  name_field = DIV style: field_style,
    DIV 
      style: label_style
      'What\'s your name?'

    INPUT
      ref: 'name'
      type: 'text'
      style: input_style
      value: @local.credentials.name
      onChange: (e) =>
        @local.credentials.name = e.target.value
        save @local

  email_field = DIV style: field_style,
    DIV 
      style: label_style
      'Your email, please:'

    INPUT
      ref: 'email'
      type: 'email'
      style: input_style
      value: @local.credentials.email
      onChange: (e) =>
        @local.credentials.email = e.target.value
        save @local

  password_field = DIV style: field_style,

    DIV style: label_style,
      'Password:'

    INPUT
      ref: 'password'
      type: 'password'
      style: input_style
      value: @local.credentials.password
      onChange: (e) =>
        @local.credentials.password = e.target.value
        save @local

  errors = \
    if current_user.error
      flash = setTimeout => 
        delete current_user.error 
        save current_user
      , 5000

      DIV 
        style: 
          backgroundColor: '#eee'
          color: 'red'
        current_user.error
    else 
      SPAN null


  enabled = @local.credentials.name && @local.credentials.email

  submit_changes = => 
    if enabled 
      user.name = @local.credentials.name or user.name 
      user.email = @local.credentials.email or user.email 
      if @local.credentials.password
        user.pass = @local.credentials.password

      save user

      if @props.additional_questions
        current_user.private ||= {}
        current_user.public ||= {}
        @props.additional_questions?.private?(current_user.private)
        @props.additional_questions?.public?(current_user.public)
        save current_user

      auth.form = null 
      save auth



  DIV   
    style: 
      padding: 20

    DIV 
      style: 
        maxWidth: 560
        margin: 'auto'
        

      DIV null, 
      
        H1 
          style: h1_style
          'Edit Profile'

        DIV 
          style: inner_container_style
                       
          name_field
          email_field
          password_field

          @props.additional_questions?.render?()

          DIV 
            style: extend {}, field_style,
              marginTop: 50

            INPUT 
              type: 'submit'
              style: extend '', submit_button_style, 
                opacity: if !enabled then .5
                cursor: if !enabled then 'auto' else 'pointer'
              value: 'Update'
              disabled: !enabled
              onClick: submit_changes
              onKeyPress: (e) =>
                if e.which == 32 || e.which == 13
                  submit_changes()

          errors
          
File.prototype.convertToBase64 = (callback) ->
  reader = new FileReader()
  reader.onload = (e) ->
    callback(e.target.result)

  reader.onerror = (e) ->
    callback(null)

  reader.readAsDataURL(this)

dom.SET_AVATAR = -> 
  current_user = fetch '/current_user'

  au = fetch 'auth'

  @local.cropped ?= {left: 0, top: 0}

  save_headshot = (base64) =>
    base64 ||= @local.base64
    img = document.createElement("img")
    img.src = base64

    # img.width and img.height don't get set immediately
    setTimeout => 
      canvas = document.createElement 'canvas'

      ctx = canvas.getContext("2d")
      ctx.drawImage(img, 0, 0)

      MAX_WIDTH = 1000
      MAX_HEIGHT = 1000
      width = img.width
      height = img.height

      resized = false 
      if width > MAX_WIDTH
        height *= MAX_WIDTH / width
        width = MAX_WIDTH
        resized = true 
      
      if height > MAX_HEIGHT
        width *= MAX_HEIGHT / height
        height = MAX_HEIGHT
        resized = true 

      if resized 
        canvas.width = width
        canvas.height = height
        ctx = canvas.getContext("2d")
        ctx.drawImage(img, 0, 0, width, height)
        @local.base64 = canvas.toDataURL("image/png", 1.0)
        img.src = @local.base64

      # make square 
      squared_size = @local.squared_size or Math.min(width, height)
      zoomed = squared_size * @local.zoom
      canvas.width = zoomed
      canvas.height = zoomed

      x = (@local.cropped?.left or 0)
      y = (@local.cropped?.top or 0)

      @local.squared_size = squared_size
      @local.width = width 
      @local.height = height
      save @local

      ctx = canvas.getContext("2d")
      ctx.drawImage img, x, y, zoomed, zoomed, 0, 0, zoomed, zoomed
      @local.cropped_base64 = canvas.toDataURL("image/png", 1.0)


      if current_user.logged_in
        you = fetch(current_user.user)
        you.pic = @local.cropped_base64
        save you
      else
        console.log 'WAITING TO LOGIN!'
        cropped_base64 = @local.cropped_base64
        wait_until_login = setInterval =>
          current_user = fetch '/current_user'
          if current_user.logged_in
            you = fetch current_user.user
            you.pic = cropped_base64
            save you
            clearInterval wait_until_login
        , 500



  headshot_display_size = if @props.inline_form then 100 else 300

  display_ratio = headshot_display_size / @local.width

  DIV 
    style: 
      padding: 12

    if !@props.inline_form
      H1 
        style: extend {}, h1_style, 
          textAlign: 'center'
        'Upload Avatar'
    else 
      DIV 
        style: 
          fontSize: 16
        "Upload your avatar (optional):"

    if !@props.inline_form
      DIV 
        style: 
          marginBottom: 20
          color: 'white'
          fontSize: 14
          textAlign: 'center'

        "Please upload a nice picture of yourself! Preferably a headshot."


    DIV 
      style: 
        backgroundColor: if !@props.inline_form then 'white'
        boxShadow: if !@props.inline_form then '0 1px 2px rgba(0,0,0,.2)'
        padding: if !@props.inline_form then 24
        margin: if !@props.inline_form then 'auto'
        fontSize: 22
        maxWidth: headshot_display_size + 24 * 2


      INPUT 
        ref: 'avatar_upload'
        type: 'file'
        onChange: (e) =>
          inp = e.target
          selectedFile = inp.files?[0]
          if selectedFile
            selectedFile.convertToBase64 (base64) =>
              if base64
                @local.base64 = base64
                @local.zoom = 1
                @local.cropped = {left: 0, top: 0}
                delete @local.height 
                delete @local.width
                delete @local.squared_size
                delete @local.cropped
                save_headshot(base64)
              else 
                @local.error = 'Problem uploading that image'
              
              save @local
          else 
            @local.error = 'Problem uploading that image'
            save @local

      DIV 
        style: 
          marginTop: 12

        if @local.base64 

          start_drag = (evt, evt_end) =>
            @local.last_mouse = {x: mouseX, y: mouseY}
            @local.dragging = true
            save @local
            register_window_event 'avatar_resize', evt_end, =>
              @local.dragging = false 
              save @local
              save_headshot()
              unregister_window_event 'avatar_resize', evt

          dragging = (e) =>
            return if !@local.dragging 

            @local.cropped = 
              left: Math.min @local.width  - @local.squared_size * @local.zoom, Math.max(0, @local.cropped.left + 1 / display_ratio * (mouseX - @local.last_mouse.x))
              top:  Math.min @local.height - @local.squared_size * @local.zoom, Math.max(0, @local.cropped.top  + 1 / display_ratio * (mouseY - @local.last_mouse.y))
            @local.last_mouse = {x: mouseX, y: mouseY}

            save @local
            e.preventDefault() # prevent text selection

          DIV 
            style: 
              position: 'relative'
              
            IMG 
              ref: 'full_avatar'
              src: @local.base64
              style: 
                width: headshot_display_size
                height: headshot_display_size * @local.height / @local.width
                #opacity: .25
                pointerEvents: 'none'
              onMouseDown: (e) -> e.preventDefault(); e.stopPropagation()
              onTouchStart: (e) -> e.preventDefault(); e.stopPropagation()
              onMouseMove: (e) -> e.preventDefault(); e.stopPropagation()
              onTouchMove: (e) -> e.preventDefault(); e.stopPropagation()

            # cutout the cropped section
            SVG 
              width: headshot_display_size
              height: headshot_display_size * @local.height / @local.width
              style: 
                position: 'absolute'
                left: 0
                top: 0

              DEFS null,
                MASK
                  id: 'hole'

                  RECT 
                    width: '100%'
                    height: '100%'
                    fill: 'white'

                  CIRCLE
                    r: @local.squared_size / 2 * @local.zoom * display_ratio
                    cx: (@local.cropped.left + @local.zoom * @local.squared_size / 2) * display_ratio
                    cy: (@local.cropped.top  + @local.zoom * @local.squared_size / 2) * display_ratio

              RECT 
                mask: 'url(#hole)'
                fill: 'white'
                style: 
                  width: '100%'
                  height: '100%'
                  opacity: .6

            # draggable cropped region
            DIV 
              className: 'grab_cursor'
              style: 
                position: 'absolute'
                left: @local.cropped.left * display_ratio
                top: @local.cropped.top * display_ratio
                width: @local.squared_size * @local.zoom * display_ratio
                height: @local.squared_size * @local.zoom * display_ratio
                zIndex: 1
                border: '1px dashed gray'
              onMouseDown: => start_drag('mousedown', 'mouseup')
              onTouchStart: => start_drag('touchstart', 'touchend')
              onMouseMove: dragging 
              onTouchMove: dragging

            # zoom slider
            INPUT 
              type: 'range'
              min: 10
              max: 100
              step: 2 
              value: @local.zoom * 100
              style: 
                display: 'block'
                width: headshot_display_size
                marginTop: 8
              onChange: (e) =>
                @local.zoom = e.target.value / 100
                save @local
                save_headshot()

            # upload button
            if !@props.inline_form
              INPUT 
                type: 'submit'
                style: extend {}, submit_button_style, 
                  marginTop: 40

                value: 'Done'
                onClick: -> au.form = null; save au

                onKeyPress: (e) =>
                  if e.which in [18,32]
                    au.form = null; save au

        else if current_user.logged_in 
          you = fetch(current_user.user)
          if you.pic

            AVATAR 
              user: you 
              hide_tooltip: true
              style: 
                width: headshot_display_size
                height: headshot_display_size
                borderRadius: '50%'


################
## AUTH forms ##
################

dom.USER_MENU = -> 

  auth = fetch 'auth'
  current_user = fetch '/current_user'

  logout = ->
    current_user.logout = true 
    auth.form = null

    save current_user
    save auth 

  action = (label, funk) ->
    A
      style: 
        fontSize: 18
        color: 'white'
        fontWeight: 500
        width: '100%'
        display: 'block'
        paddingRight: '2px 6px'
        textDecoration: 'none'
        cursor: 'pointer'

      onClick: funk
      onKeyPress: (e) => 
        if e.which in [13, 32]
          funk()
      label

  children = if current_user.logged_in
              [
                action('Change Picture', -> auth.form = 'upload_avatar'; save(auth))
                action('Edit Profile', -> auth.form = 'edit_profile'; save(auth))
                action('Logout', -> logout())
              ]
             else 
              [
                action('Login', -> auth.form = 'login'; save(auth))
                action('Register', -> auth.form = 'register'; save(auth))
              ]

  conn = fetch '/connection'

  @local.text ||= current_user.user?.name or conn.name or ""

  DIV 
    style: 
      position: 'absolute'
      # bottom: -25
      right: 2
      display: 'inline-block'

    onFocus: => @local.focused = true; save @local
    onBlur: => @local.focused = false; save @local 
    onMouseEnter: => @local.hovering = true; save @local 
    onMouseLeave: => @local.hovering = false; save @local

    SPAN 
      style: 
        position: 'relative'
        right: 0
      @props.wrap?()

    if !current_user.logged_in
      INPUT 
        type: 'text' 
        ref: 'editor'
        placeholder: 'Write your name'

        style:
          padding: "2px 4px"
          margin: 0
          width: '100%'
          border: "3px solid #{conn.color}"
          outline: 'none'   
          fontSize:  11
          minWidth: 80

        onInput: (e) => 
          new_text = @refs.editor.getDOMNode().value
          @local.text = new_text
          # BUG: Allowing the user to change user name arbitrarily will lead to 
          #       even more collisions!
          if current_user.user
            current_user.user.name = @local.text 
            save current_user.user     
          else          
            conn.name = new_text
            save conn


        defaultValue: @local.text 

    UL 
      style: 
        position: 'relative'
        # bottom: -43
        backgroundColor: conn.color
        display: if @local.focused || @local.hovering then 'block' else 'none'
        border: "3px solid #{conn.color}"
      for child, idx in children
        LI 
          style: 
            whiteSpace: 'nowrap'
            display: 'block'
            listStyle: 'none'
            textAlign: 'right'
            color: 'white'
          child 

orange = '#e89e00'
dom.AUTH_FIRST = ->  
  current_user = fetch '/current_user'

  return SPAN null if current_user.logged_in
  
  @props.before ?= "Please "
  @props.after ?= " to participate"
  @props.show_login ?= true 
  @props.show_create ?= true 

  start_auth = (login) ->
    auth = fetch 'auth' 
    auth.form = if login then 'login' else 'register' 
    save auth

  button_style = defaults {}, (@props.button_style or {}),
    backgroundColor: 'transparent'
    border: 'none'
    textDecoration: 'underline'
    color: 'inherit'
    fontSize: 'inherit'
    cursor: 'pointer'
    padding: 0
    fontWeight: 600

  if !current_user.logged_in 

    DIV 
      style: defaults {}, (@props.style or {}),
        backgroundColor: orange
        color: 'white'
        fontSize: 18
        display: 'inline-block'
        padding: '4px 4px'
        marginBottom: 10

      "#{@props.before}"

      if @props.show_login
        BUTTON 
          onClick: -> start_auth(true)
          onKeyPress: (e) -> 
            if e.which in [13, 32]
              start_auth(true)
          style: button_style

          "login" 

      if @props.show_create && @props.show_login
        " or " 

      if @props.show_create
        BUTTON 
          style: button_style

          onClick: -> start_auth(false)
          onKeyPress: (e) -> 
            if e.which in [13, 32]
              start_auth(false)

          "create an account"

      "#{@props.after}"

