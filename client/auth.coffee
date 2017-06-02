# Primitive client auth

# Requires: 
#   - shared.coffee

h1_style = 
  color: 'white'
  fontWeight: 800
  fontSize: 36
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


salmon = '#E16161'



File.prototype.convertToBase64 = (callback) ->
  reader = new FileReader()
  reader.onload = (e) ->
    callback(e.target.result)

  reader.onerror = (e) ->
    callback(null)

  reader.readAsDataURL(this)

dom.SET_AVATAR = -> 
  current_user = fetch '/current_user'
  you = fetch(current_user.user)
  au = fetch 'auth'
  return SPAN null if !current_user.logged_in || !au.set_avatar

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
        dataurl = canvas.toDataURL("image/png", 1.0)
        img.src = dataurl

      # make square 
      crop_to = @local.crop_to or Math.min(width, height)
      canvas.width = crop_to
      canvas.height = crop_to

      sx = @local.sx or (width - crop_to) / 2
      sy = @local.sy or (height - crop_to) / 2
      
      x = sx + (@local.offset?.x or 0)
      y = sy + (@local.offset?.y or 0)

      ctx = canvas.getContext("2d")
      ctx.drawImage img, x, y, crop_to, crop_to, 0, 0, crop_to, crop_to

      @local.cropped_base64 = canvas.toDataURL("image/png", 1.0)
      @local.sx = sx 
      @local.sy = sy 
      @local.crop_to = crop_to
      @local.width = width 
      @local.height = height
      save @local

      you.pic = @local.cropped_base64
      save you


  headshot_display_size = 300
  DIV 
    style: 
      backgroundColor: salmon 
      padding: 50

    DIV 
      style: 
        maxWidth: 600
        backgroundColor: 'white'
        boxShadow: '0 1px 2px rgba(0,0,0,.2)'
        padding: 24
        margin: 'auto'
        fontSize: 22

      DIV 
        style: 
          marginBottom: 20
        "Hi #{you.name}, please upload a nice picture of yourself. Preferably a headshot!"

      INPUT 
        ref: 'avatar_upload'
        type: 'file'
        onChange: (e) =>
          inp = @refs.avatar_upload.getDOMNode()
          selectedFile = inp.files?[0]
          if selectedFile
            selectedFile.convertToBase64 (base64) =>
              if base64
                @local.base64 = base64
                delete @local.height 
                delete @local.width
                delete @local.sx 
                delete @local.sy 
                delete @local.crop_to
                delete @local.offset
                save_headshot(base64)
              else 
                @local.error = 'Problem uploading that image'
              
              save @local
          else 
            @local.error = 'Problem uploading that image'
            save @local

      if @local.base64 
        headshot_height = headshot_display_size * @local.height / @local.width
        left = @local.sx * headshot_display_size / @local.width + (@local.offset?.xx or 0)
        top = @local.sy * headshot_height / @local.height + (@local.offset?.yy or 0)
        width = headshot_display_size - (2 * @local.sx) * headshot_display_size / @local.width
        height = (headshot_display_size - (2 * @local.sy) * headshot_display_size / @local.height) * @local.height / @local.width

        start_drag = (evt, evt_end) =>
          @local.start = {x: mouseX, y: mouseY}
          @local.dragging = true
          save @local
          register_window_event 'avatar_resize', evt_end, =>
            @local.dragging = false 
            save @local
            unregister_window_event 'avatar_resize', evt

        dragging = =>
          if @local.dragging 
            @local.offset = 
              x: (mouseX - @local.start.x) * @local.width / headshot_display_size
              y: (mouseY - @local.start.y) * @local.height / headshot_height
              xx: (mouseX - @local.start.x)
              yy: (mouseY - @local.start.y)

            save @local

            save_headshot()

        DIV 
          style: 
            position: 'relative'

          IMG 
            src: @local.base64
            style: 
              width: headshot_display_size
              height: headshot_height
              opacity: .25

          DIV 
            className: 'grab_cursor'
            style: 
              border: "3px dashed #{salmon}"
              position: 'absolute'
              left: left - 3
              top: top - 3
              width: width
              height: height
              borderRadius: '50%'
              zIndex: 1
            onMouseDown: =>
              start_drag('mousedown', 'mouseup')
            onTouchStart: =>
              start_drag('touchstart', 'touchend')
            onMouseMove: dragging 
            onTouchMove: dragging



          IMG 
            src: @local.cropped_base64
            style: 
              pointerEvents: 'none'
              position: 'absolute'
              left: left
              top: top
              width: width
              height: height
              borderRadius: '50%'
              zIndex: 1

      else if you.pic

        AVATAR 
          user: you 
          hide_tooltip: true
          style: 
            width: headshot_display_size
            height: headshot_display_size
            borderRadius: '50%'

      if true
        close = =>
          au = fetch('auth')
          au.set_avatar = false 
          save au

        BUTTON 
          onClick: close

          onKeyPress: (e) =>
            if e.which in [18,32]
              close()

          if you.pic || @local.base64 
            'Done'
          else 
            'Cancel'



dom.USER_MENU = -> 

  auth = fetch 'auth'
  current_user = fetch '/current_user'

  start = (login) -> 
    auth.start = true 
    auth.try_login = login
    save auth

  logout = ->
    current_user.logout = true 
    auth.start = false

    save current_user
    save auth 

  set_avatar = =>
    auth.set_avatar = true 
    save auth

  edit_profile = =>
    auth.edit_profile = true 
    save auth

  action = (label, funk) ->
    A
      style: 
        fontSize: 14
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
                action('Change Picture', -> set_avatar())
                action('Edit Profile', -> edit_profile())
                action('Logout', -> logout())
              ]
             else 
              [
                action('Login', -> start(true))
                action('Register', -> start(false))
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


dom.AUTH_BUTTONS = -> 
  auth = fetch 'auth'

  start = (login) -> 
    auth.start = true 
    auth.try_login = login
    save auth

  DIV null,
    A 
      onClick: -> start(true)
      style: @props.style or {}
      'Login'

    A 
      style: @props.style or {}
      onClick: -> start(false)
      'Create account'

dom.AUTH = -> 
  auth = fetch 'auth'
  current_user = fetch '/current_user'
  return SPAN null if current_user.logged_in

  if !@local.credentials?
    @local.credentials = 
      name: fetch('/connection').name

  if !@local.login?
    @local.login = if !@props.login? then false else @props.login

  toggle_form = => 
    @local.login = !@local.login 
    save @local

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
      , 3000

      DIV 
        style: 
          backgroundColor: '#eee'
          color: 'red'
        current_user.error
    else 
      SPAN null


  login = => 
    enabled = @local.credentials.name && @local.credentials.password

    submit_login = => 
      if enabled 
        current_user.login_as =
          name: @local.credentials.name 
          pass: @local.credentials.password  
        save current_user
      

    DIV null, 
    
      H1 
        style: h1_style
        'Welcome back!'

      DIV 
        style: inner_container_style
                     
        name_field

        password_field 

        DIV 
          style: extend {}, field_style,
            marginTop: 35

          INPUT 
            type: 'submit'
            style: extend '', submit_button_style, 
              opacity: if !enabled then .5
              cursor: if !enabled then 'auto' else 'pointer'
            value: 'Login'
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
          login: @local.credentials.name
          email: @local.credentials.email 
          pass: @local.credentials.password 
        current_user.login_as =
          login: @local.credentials.name
          name: @local.credentials.name 
          pass: @local.credentials.password  
        save current_user

        auth.set_avatar = true 
        save auth

    DIV null, 
    
      H1 
        style: h1_style
        'Glad you\'re joining us!'

      DIV 
        style: inner_container_style
                     
        name_field
        email_field
        password_field

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


  DIV   
    style: 
      backgroundColor: salmon
      padding: 20

    DIV 
      style: 
        maxWidth: 560
        margin: 'auto'
        

      if @local.login 
        login()
      else 
        register()

      DIV 
        style: 
          marginTop: 24
          textAlign: 'center'
        BUTTON 
          style: 
            
            backgroundColor: 'transparent'
            border: 'none'
            fontSize: 18
            textDecoration: 'underline'
            cursor: 'pointer'
            opacity: .7
            color: 'white'

          onClick: => 
            auth.start = false 
            save auth
          onKeyPress: (e) -> 
            if e.which == 32 || e.which == 13
              auth.start = false 
              save auth

          'Nevermind, cancel'




dom.EDIT_PROFILE = -> 
  auth = fetch 'auth'
  current_user = fetch '/current_user'
  user = current_user.user
  return SPAN null if !current_user.logged_in || !auth.edit_profile

  if !@local.credentials?
    @local.credentials = 
      name: user.name
      email: user.email

  if !@local.login?
    @local.login = if !@props.login? then false else @props.login

  toggle_form = => 
    @local.login = !@local.login 
    save @local

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
      , 3000

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
      auth.edit_profile = false 
      save auth


  DIV   
    style: 
      backgroundColor: salmon
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


      DIV 
        style: 
          marginTop: 24
          textAlign: 'center'
        BUTTON 
          style: 
            
            backgroundColor: 'transparent'
            border: 'none'
            fontSize: 18
            textDecoration: 'underline'
            cursor: 'pointer'
            opacity: .7
            color: 'white'

          onClick: => 
            auth.edit_profile = false 
            save auth
          onKeyPress: (e) -> 
            if e.which == 32 || e.which == 13
              auth.edit_profile = false 
              save auth

          'Done'






