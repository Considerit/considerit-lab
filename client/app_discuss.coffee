
fickle.register (upstream_vars) -> 
  outer_gutter = 10
  doc_padding = 50

  content_width = Math.max 550, upstream_vars.window_width - outer_gutter * 2 - doc_padding * 2

  return {
    outer_gutter: outer_gutter
    doc_padding: doc_padding
    content_width: content_width
  }

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
          NAVIGATION()

          # BUTTON 
          #   onClick: => @local.tawking = !@local.tawking; save @local
          #   'Tawk'

          if loc.url == '/summary' 
            MULTICRITERIA_SUMMARY
              options: "/point_root/#{fetch('forum').forum}-options"  
              criteria: "/point_root/#{fetch('forum').forum}-criteria"  

          else 
            DISCUSS()

      StateDash()
      CURSORS()
      TOOLTIP()


    
    DIV 
      key: 'auth_overlay'
      style: 
        position: 'fixed'
        top: 0 
        zIndex: 9999
        width: '100%'

      AUTH
        login_field: 'email'


dom.TOP = -> 
  auth = fetch 'auth'
  current_user = fetch '/current_user'
  HEADER 
    style: 
      position: 'relative' 


    DIV 
      key: 'auth'
      style: 
        textAlign: 'right'

      WHO_IS_HERE
        show_auth: true

    if forum == 'statebus'
      DIV 
        key: 'title'
        style: 
          textAlign: 'center'
          paddingTop: 40


        H1 
          style: 
            margin: 0
          "We're making Statebus."

        DIV 
          style: 
            marginTop: 20
            fontSize: 20
          'A new World Wide Web where data is synchronized & remixable by default'

    else if forum == 'sac'
      DIV 
        key: 'title'
        style: 
          textAlign: 'center'
          paddingTop: 40


        H1 
          style: 
            margin: 0
          "We're Angels."

        DIV 
          style: 
            marginTop: 20
            fontSize: 20
          'Rank and discuss the merits of these companies.'

    else if forum == 'wa_infoaccess'
      DIV 
        key: 'title'
        style: 
          textAlign: 'center'
          paddingTop: 40
          maxWidth: 800
          margin:'auto'


        H1 
          style: 
            margin: 0
          "We're the Open Data Advisory Group."

        # DIV 
        #   style: 
        #     marginTop: 20
        #     fontSize: 20
        #   'Evaluate projects against our criteria'

    else if forum == 'socioenactive'
      DIV 
        key: 'title'
        style: 
          textAlign: 'center'
          paddingTop: 40
          maxWidth: 800
          margin:'auto'


        H1 
          style: 
            margin: 0
            fontSize: 60
          "We're the Socioenactive Systems Group."

        DIV 
          style: 
            marginTop: 20
            fontSize: 20
          'Help us choose a logo'


    else if forum == 'token_evaluation'
      DIV 
        key: 'title'
        style: 
          textAlign: 'center'
          paddingTop: 40
          maxWidth: 800
          margin:'auto'


        H1 
          style: 
            margin: 0
            fontSize: 60
          "We're cryptocurrency investors."

        DIV 
          style: 
            marginTop: 20
            fontSize: 20
          'How good are these token investments?'





dom.NAVIGATION = -> 

  li_style = 
    display: 'inline-block'        
    verticalAlign: 'top'

  a_style = 
    cursor: 'pointer'
    display: 'inline-block'
    padding: '25px 20px'
    color: '#444'
    fontWeight: 600
    fontSize: 22

  loc = fetch 'location'

  auth = fetch 'auth'

  links = []

  if _cur_prototype == 'multicriteria'
    if forum == 'socioenactive'
      option_label = 'Logos'    
    else if forum == 'wa_infoaccess'
      option_label = 'Projects'
    else if forum == 'token_evaluation'
      option_label = 'Tokens'    
    else 
      option_label = 'Options'

    links = [ 
              {label: 'Criteria', href: '/criteria'}  
              {label: option_label, href: '/options'} 
              {label: 'Matrix', href: '/summary'}
            ]

  DIV 
    style: 
      textAlign: 'center'

    UL 
      style: 
        listStyle: 'none'
        display: 'inline-block'
        padding: 0
        marginTop: 20

      for link in links 
        LI 
          key: link.href

          style: extend {}, li_style,
            backgroundColor: if loc.url == link.href then '#eee' else 'white'

          A 
            href: link.href
            style: a_style
              
            link.label


templates = 
  question: 
    placeholder: 'Ask a question'
    validate: (txt) -> (txt or '').indexOf('?') > -1
  todo: 
    placeholder: 'Add a todo'
  review: 
    placeholder: 'Post a review'

forum_config = 
  default: 
    0: 
      placeholder: 'Express an idea, ask a question, post a link, ...'

  sac: 
    0: 
      placeholder: 'Add a company to evaluate'
      auto_subpoints: [
        'Team'
        'Idea'
        'Market'
        'Progress'
      ]
      no_replies: true

    1: 
      placeholder: 'Add a pro or con, or ask a question'
      no_replies: true
      style: 
        fontWeight: 600

    2: 
      no_replies: true
      hide_avatar: true
      style: 
        fontStyle: 'italic'

  wa_infoaccess_options: 
    0: 
      placeholder: 'Add a project to evaluate'
      auto_subpoints: []
      no_replies: true

    1: 
      no_replies: true
      no_sort: true   
      criteria: "/point_root/wa_infoaccess-criteria"   
      style: 
        fontWeight: 600

    2: 
      no_replies: true
      hide_avatar: true
      style: 
        fontStyle: 'italic'

  wa_infoaccess_criteria: 
    0: 
      placeholder: 'Add an evaluation criterion'
      no_replies: false

    1: 
      placeholder: 'Add a comment'
      no_replies: true
      style: 
        fontWeight: 600


  token_evaluation_options: 
    0: 
      placeholder: 'Add a token to evaluate'
      auto_subpoints: []
      no_replies: true

    1: 
      no_replies: true
      no_sort: true   
      criteria: "/point_root/token_evaluation-criteria"   
      style: 
        fontWeight: 600

    2: 
      no_replies: true
      hide_avatar: true
      style: 
        fontStyle: 'italic'


  token_evaluation_criteria: 
    0: 
      placeholder: 'Add an evaluation criterion'
      no_replies: false

    1: 
      placeholder: 'Add a comment'
      no_replies: true
      style: 
        fontWeight: 600


  pdx_home_options: 
    0: 
      placeholder: 'Add a home to evaluate'
      auto_subpoints: []
      no_replies: true

    1: 
      no_replies: true
      no_sort: true   
      criteria: "/point_root/pdx_home-criteria"   
      style: 
        fontWeight: 600

    2: 
      no_replies: true
      hide_avatar: true
      style: 
        fontStyle: 'italic'

  pdx_home_criteria: 
    0: 
      placeholder: 'Add an evaluation criterion'
      no_replies: false

    1: 
      placeholder: 'Add a comment'
      no_replies: true
      style: 
        fontWeight: 600


  socioenactive_options: 
    0: 
      placeholder: 'Add a logo to evaluate'
      auto_subpoints: []
      no_replies: true
      hide_avatar: true


    1: 
      no_replies: true
      hide_avatar: true
      no_sort: true   
      criteria: "/point_root/socioenactive-criteria"   
      style: 
        fontWeight: 600

    2: 
      no_replies: false
      hide_avatar: true
      new_post_label: '+ note'
      placeholder: 'Add note'      
      style: 
        fontStyle: 'italic'

  socioenactive_criteria: 
    0: 
      placeholder: 'Add an evaluation criterion'
      no_replies: false

    1: 
      placeholder: 'Add a comment'
      no_replies: false
      style: 
        fontWeight: 600

dom.DISCUSS = -> 
  space = fetch('forum').forum

  if _cur_prototype == 'multicriteria'
    loc = fetch 'location'

    if loc.url == '/criteria'
      tab = 'criteria'
    else 
      tab = 'options'

    root = fetch "/point_root/#{space}-#{tab}"
    template = forum_config["#{space}_#{tab}"] or forum_config[space]
  else
    root = fetch "/point_root/#{space}"
    template = forum_config[space]


  DISCUSSION
    root: root.key
    template: template or forum_config.default 

    style: 
      width: fickle.content_width + 20
