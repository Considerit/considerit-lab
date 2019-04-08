
fickle.register (upstream_vars) -> 
  outer_gutter = 10
  doc_padding = 50

  content_width = Math.max 550, upstream_vars.window_width - outer_gutter * 2 - doc_padding * 2

  cell_width = 150 

  return {
    outer_gutter: outer_gutter
    doc_padding: doc_padding
    content_width: content_width
    cell_width: cell_width
    first_col_width: cell_width * 2.5
  }




set_style """
  [data-widget="BODY"]  {
    font-family: 'Raleway', Georgia,Cambria,"Times New Roman",Times,serif; // Helvetica Neue, Segoe UI, Helvetica, Arial, sans-serif; 
    font-size: 16px;
    color: black;
    line-height: 1.4;
    font-weight: normal;
    font-weight: 300;
    -webkit-font-feature-settings: 'liga' 1;
    -moz-font-feature-settings: 'liga' 1;  
    text-rendering: optimizeLegibility;  
  } [data-widget="BODY"] h1, [data-widget="BODY"] h2, [data-widget="BODY"] h3 {
    //font-family: 'Trocchi', 'Roboto Condensed', 'Helvetica', arial;
    
    font-family: 'Brandon Grotesque', 'Raleway', Helvetica, arial;
    font-weight: 400;
    //letter-spacing: 1px;
  } [data-widget="BODY"] h1 {
    font-size: 48px;
    margin-bottom: 20px;
    line-height: 1.2;
    font-weight: 400;
  }

  [data-widget="BODY"] .script {
    font-family: 'Brandon Grotesque', 'Cool Script', 'Helvetica', arial;
    font-weight: 300;
  }

  [data-widget="BODY"] a {
    //color: #{considerit_salmon};
    color: inherit;
    text-decoration: underline;
    cursor: pointer;
    font-weight: 500;
  }


  * {box-sizing: border-box;}
  html, body {margin: 0; padding: 0;}
  p {margin: 16px 0; }
  button, a {
    cursor: pointer;
  }

  textarea, input[type='text'], input[type='email'], button {
    font-size: inherit;
    font-weight: inherit;
    line-height: inherit;
    font-family: inherit;
    letter-spacing: inherit;
  }

  button, input[type='submit'] {
    background-color: #{considerit_salmon};
    border: none;
    color: white;
    font-weight: 700;
  }

  button[disabled], input[type='submit'][disabled] {
    opacity: .25;
  }

  [data-widget="BASIC_SLIDER_LABEL"] {
    font-size: 20px;
  }

  [data-widget="TEXT"] ul {
    padding-left: 16px;
    margin: 0;
  }

""", 'main-style'



dom.BODY = ->
  current_user = fetch '/current_user'
  loc = fetch 'location'

  auth = fetch 'auth'

  c = fetch '/connection'

  f = fetch('forum')
  if !f.forum?
    f.forum = forum 
    save f 
    return SPAN null

  return SPAN null if @loading()

  name = c.user?.name or c.name or c.invisible_name or 'Anon'

  DIV 
    key: f.forum
    DIV 
      style: 
        opacity: .2 if !current_user.logged_in && auth.start


      
      DIV 
        style: 
          display: if @local.tawking then 'flex'

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
            flex: if @local.tawking then 3
            minHeight: 700


          TOP()

          DIV 
            style: 
              marginLeft: 50
              marginTop: 20
            AUTH_FIRST()

          # BUTTON 
          #   onClick: => @local.tawking = !@local.tawking; save @local
          #   'Tawk'

          REFRESH_SORT_ORDER()
          MULTICRITERIA
            options: "/point_root/#{fetch('forum').forum}-options"  
            criteria: "/point_root/#{fetch('forum').forum}-criteria" 


      LAB_FOOTER() 



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

      AUTH
        login_field: 'email'


dom.TOP = -> 
  auth = fetch 'auth'
  current_user = fetch '/current_user'

  config = fetch "/config/#{forum}"
  loc = fetch 'location'

  return SPAN null if @loading()

  if !config.our_purpose? && loc.query_params.decision
    config.our_purpose = decodeURI(loc.query_params.decision)
    save config
    delete loc.query_params.decision 
    save loc

  if !config.who_we_are? && loc.query_params.who
    config.who_we_are = decodeURI(loc.query_params.who)
    save config
    delete loc.query_params.who 
    save loc


  HEADER 
    style: 
      position: 'relative' 
      #maxWidth: fickle.window_width * .95
      padding: 0

    PROTOTYPE_DISCLAIMER
      message: "Deslider is a prototype. Don't rely on it!"
      email_subject: 'Feedback about Deslider'
      style: 
        padding: '12px 28px'
    
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
        paddingLeft: 28


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
        config.who_we_are or "We are..."

      TEXT 
        ref: 'purpose'
        value: config.our_purpose or "...and we're trying to decide..."
        style: 
          fontSize: 16
          marginLeft: 8
          width: Math.min(fickle.window_width / 2, 500)

        onInput: (e) => 
          config.our_purpose = e.target.value
          save config 


      OPINION_WEIGHTS()


dom.OPINION_WEIGHTS = -> 
  current_user = fetch '/current_user'
  all_users = get_all_users() 
  opinion = fetch 'opinion' 

  return SPAN null if !current_user.logged_in && all_users.length < 2

  @local.show ?= true 

  toggleShow = => 
    @local.show = !@local.show 
    save @local 

  return SPAN null if all_users.length < 2
  DIV 
    style: 
      #position: 'fixed'
      #bottom: 0
      #right: 0
      backgroundColor: 'white'
      zIndex: 99  
      borderRadius: '4px 4px 0 0' 
      marginTop: 24


    SPAN 
      className: 'script'
      style: 
        fontSize: 22
        #backgroundColor: considerit_salmon
        color: considerit_salmon #'white'
        cursor: 'pointer'
        padding: 4
        borderRadius: '4px 4px 0 0' 
        textDecoration: 'underline'

      onClick: toggleShow
      onKeyPress: (e) => 
        if e.which in [32,13]
          e.preventDefault()
          toggleShow() 

      "Whose opinion matters to you right now?"


    if @local.show 
      DIV 
        style: 
          marginTop: 8

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
  fetch("/all_users/#{f.forum}").users 


dom.OPINION_FILTER = -> 
  

  select_opinion = => 
    opinion = fetch 'opinion'
    opinion.selected = @props.label 
    save opinion 
    @props.funk()
    resort_items()

  opinion = fetch 'opinion'
  
  if !opinion.selected? && @props.default
    select_opinion()

  selected = opinion.selected == @props.label 

  BUTTON 
    style: 
      backgroundColor: if selected then considerit_salmon else '#F3F3F3'
      padding: '4px 12px'
      cursor: 'pointer'
      textAlign: 'center'
      border: 'none'
      borderBottom: "2px solid #{if selected then considerit_salmon else 'transparent'}"

    onClick: select_opinion

    onKeyPress: (e) =>
      if e.which in [32, 13]
        e.preventDefault()
        select_opinion()

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

  





dom.PROTOTYPE_DISCLAIMER = -> 
  DIV 
    style: extend {}, (@props.style or {}),
      backgroundColor: considerit_salmon
      color: 'white'


    H3 
      style: 
        fontWeight: 700
        marginBottom: 8
        marginTop: 0

      @props.message 

    SPAN null, 
      "Please email me at "

      A 
        href: "mailto:travis@consider.it?subject=#{@props.email_subject}"
        'travis@consider.it'

      " if you think I should continue building it."

