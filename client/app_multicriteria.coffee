window.considerit_salmon = '#df6264'

fickle.register (upstream_vars) -> 
  outer_gutter = 10
  doc_padding = 50

  content_width = Math.max 550, upstream_vars.window_width - outer_gutter * 2 - doc_padding * 2

  return {
    outer_gutter: outer_gutter
    doc_padding: doc_padding
    content_width: content_width
    cell_width: 150
  }

style = document.createElement "style"
style.id = "overall-styles"
style.innerHTML =   """
  #content {
    font-family: 'Computer Modern Serif', 'Computer Modern Bright', 'Helvetica', arial;
  }
"""
document.head.appendChild style

dom.body = ->
  current_user = fetch '/current_user'
  loc = fetch 'location'

  auth = fetch 'auth'

  c = fetch '/connection'

  f = fetch('forum')
  if !f.forum?
    f.forum = forum 
    save f 

  return SPAN null if @loading()

  name = c.user?.name or c.name or c.invisible_name or 'Anon'

  DIV 
    key: f.forum
    DIV 
      style: 
        opacity: .2 if !current_user.logged_in && auth.start

      
      DIV 
        style: 
          display: 'flex'

        if @local.tawking
          DIV 
            style: 
              resize: 'horizontal'
              borderRight: '1px solid #999'
              minWidth: 300
              backgroundColor: 'white'
              zIndex: 1
              position: 'relative'

            TAWK
              name: name
              space: f.forum
              video: true
              audio: false
              width: 300
              scratch_disabled: true

        DIV 
          style: 
            flex: if @local.tawking then 3 else 1 

          TOP()

          DIV 
            style: 
              marginLeft: 50
              marginTop: 20
            AUTH_FIRST()

          # BUTTON 
          #   onClick: => @local.tawking = !@local.tawking; save @local
          #   'Tawk'

          MULTICRITERIA
            options: "/point_root/#{fetch('forum').forum}-options"  
            criteria: "/point_root/#{fetch('forum').forum}-criteria"  


      StateDash()
      CURSORS()
      TOOLTIP()


    
    DIV 
      key: 'auth_overlay'
      style: 
        position: 'fixed'
        top: 0 
        zIndex: 999999
        width: '100%'

      if !current_user.logged_in && auth.start
        AUTH
          login: auth.try_login or false
      else if auth.edit_profile
        EDIT_PROFILE()
      else if auth.set_avatar 
        SET_AVATAR()

dom.TOP = -> 
  auth = fetch 'auth'
  current_user = fetch '/current_user'

  config = fetch "/config/#{forum}"

  HEADER 
    style: 
      position: 'relative' 
      #maxWidth: fickle.window_width * .95
      padding: 0

    DIV 
      key: 'auth'
      style: 
        textAlign: 'right'

      WHO_IS_HERE
        show_auth: true
        style: 
          position: 'absolute'
          # left: 10
          # top: 10

    DIV 
      key: 'title'
      style: 
        textAlign: 'left'
        paddingTop: 50
        paddingLeft: 50


      H1 
        style: 
          margin: 0
          fontSize: 60
          marginBottom: 4
        contentEditable: true 
        ref: 'title'         
        onInput: (e) => 
          config.who_we_are = @refs.title.getDOMNode().textContent
          save config 
        config.who_we_are or "We're humans...(describe who you are)"

      DIV 
        ref: 'purpose'
        style: 
          fontSize: 16
          marginLeft: 8
          maxWidth: Math.min(fickle.window_width / 2, 500)

        contentEditable: true          
        onInput: (e) => 
          config.our_purpose = @refs.purpose.getDOMNode().textContent
          save config 
        config.our_purpose or "We're evaluating projects...(describe your purpose)"


      OPINION_WEIGHTS()


dom.OPINION_WEIGHTS = -> 
  current_user = fetch '/current_user'
  all_users = get_all_users() 
  opinion = fetch 'opinion' 

  return SPAN null if !current_user.logged_in && all_users.length < 2

  toggleShow = => 
    @local.show = !@local.show 
    save @local 

  DIV 
    style: 
      #position: 'fixed'
      #bottom: 0
      #right: 0
      backgroundColor: 'white'
      zIndex: 99  
      borderRadius: '4px 4px 0 0' 
      marginTop: 8


    SPAN 
      className: 'script'
      style: 
        fontSize: 22
        #backgroundColor: considerit_salmon
        color: considerit_salmon #'white'
        cursor: 'pointer'
        padding: 4
        borderRadius: '4px 4px 0 0' 

      onClick: toggleShow
      onKeyPress: (e) => 
        if e.which in [32,13]
          e.preventDefault()
          toggleShow() 

      "Whose opinion matters to you right now?"


    if @local.show 
      DIV null, 

        if all_users?.length > 1
          if all_users[all_users.length - 1] == your_key()
            all_users.reverse()

          OPINION_FILTER
            label: 'Everyone'
            funk: ->
              opinion = fetch 'opinion'
              opinion.weights = null
              save opinion
            users: all_users
            default: true

        if current_user.logged_in
          OPINION_FILTER
            label: 'Just ME!'
            funk: ->
              opinion.weights = {}
              opinion.weights[your_key()] = 1
              save opinion

            users: [current_user.user.key or current_user.user]


        for user in all_users when user != your_key()

          OPINION_FILTER
            label: fetch(user).name
            funk: do (user) -> ->
              opinion = fetch 'opinion'
              opinion.weights = {}
              opinion.weights[user] = 1
              save opinion
            users: [user]


window.get_all_users = -> 
  f = fetch('forum')
  fetch("/users/#{f.forum}").users 


dom.OPINION_FILTER = -> 
  opinion = fetch 'opinion'

  if !opinion.selected? && @props.default
    opinion.selected = @props.label 
    save opinion 

  selected = opinion.selected == @props.label 

  BUTTON 
    style: 
      backgroundColor: if selected then considerit_salmon else '#F3F3F3'
      padding: '4px 12px'
      cursor: 'pointer'
      textAlign: 'center'
      border: 'none'
      borderBottom: "2px solid #{if selected then considerit_salmon else 'transparent'}"

    onClick: (e) => 
      opinion = fetch 'opinion'
      opinion.selected = @props.label 
      save opinion
      @props.funk()

    onKeyPress: (e) =>
      if e.which in [32, 13]
        e.preventDefault()
        opinion = fetch 'opinion'
        opinion.selected = @props.label 
        save opinion
        @props.funk()

    FACEPILE
      users: @props.users
      offsetY: 0
      offsetX: 10
      avatar_style: 
        width: 50
        height: 50
        borderRadius: '50%'
        backgroundColor: '#777'
    BR null 
    SPAN 
      style: 
        fontSize: 14 
        fontWeight: 400
        color: if selected then 'white' else 'black'
        #opacity: .7

      @props.label 

  

orange = '#e89e00'
dom.AUTH_FIRST = -> 
  current_user = fetch '/current_user'

  return SPAN null if current_user.logged_in
  
  start_auth = (login) ->
    auth = fetch 'auth' 
    auth.start = true 
    auth.try_login = login
    save auth

  button_style = 
    backgroundColor: 'transparent'
    border: 'none'
    textDecoration: 'underline'
    color: 'white'
    #fontStyle: 'italic'
    # fontFamily: 'sans-serif'
    fontSize: 18
    cursor: 'pointer'
    padding: 0
    fontWeight: 600

  if !current_user.logged_in 

    DIV 
      style: 
        backgroundColor: orange
        color: 'white'
        #fontStyle: 'italic'
        # fontFamily: 'sans-serif'
        fontSize: 18
        display: 'inline-block'
        padding: '4px 4px'
        marginBottom: 10
      "Please "

      BUTTON 
        onClick: -> start_auth(true)
        onKeyPress: (e) -> 
          if e.which in [13, 32]
            start_auth(true)
        style: button_style

        "login" 

      " or " 
      BUTTON 
        style: button_style

        onClick: -> start_auth(false)
        onKeyPress: (e) -> 
          if e.which in [13, 32]
            start_auth(false)

        "create an account"

      " to participate"


