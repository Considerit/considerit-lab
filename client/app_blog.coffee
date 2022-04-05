
is_host = ->
  fetch('/current_user').user?.email == 'travis@consider.it'

fickle.register (upstream_vars) -> 
  window_w = upstream_vars.window_width

  mobile_layout = window_w < 800
  if mobile_layout

    doc_padding = 28
    content_width = Math.max 550, window_w - 2 * doc_padding

    author_col = 0
    opinion_col = 0 #Math.max 50, content_width * .2
    content_col = Math.max 200, Math.min(700, content_width - opinion_col)


  else 
    bubble_padding_x = 50
    bubble_padding_y = 24

    doc_padding = 0
    content_width = window_w - 2 * doc_padding
    author_col = Math.min(150, content_width * .15) * .8
    opinion_col = Math.max 50, content_width * .17
    content_col = Math.max 200, Math.min(820, content_width - opinion_col - author_col - 2 * bubble_padding_x)

  mouth_width = content_col * 0.07

  return {
    mobile_layout: mobile_layout
    content_width: content_width
    doc_padding: doc_padding
    content_col: content_col
    author_col: author_col
    opinion_col: opinion_col
    slidergram_height: 40
    bubble_padding_x: bubble_padding_x
    bubble_padding_y: bubble_padding_y
    mouth_width: mouth_width
  }

window.considerit_salmon = '#F45F73' ##f35389' #'#df6264' #E16161
window.considerit_gray = '#F6F7F9' #'#f2f3f5'
window.considerit_green = '#bdb75b'

focus_blue = '#2478CC'
post_bg = '#F5F5F5' #'#F4F6F8'


brandon = '"Brandon Grotesque", "Montserrat", Helvetica, arial'

set_style """
  [data-widget="BODY"]  {
    font-family: 'Montserrat', Computer Modern Serif, Georgia,Cambria,"Times New Roman",Times,serif; // Helvetica Neue, Segoe UI, Helvetica, Arial, sans-serif; // 'Computer Modern Sans', 'Helvetica', arial;
    font-size: 18px;
    color: black;
    line-height: 1.5;
    font-weight: normal;
    font-weight: 400;
    -webkit-font-feature-settings: 'liga' 1;
    -moz-font-feature-settings: 'liga' 1;  
    text-rendering: optimizeLegibility;  
  } [data-widget="BODY"] h1, [data-widget="BODY"] h2, [data-widget="BODY"] h3 {
    //font-family: 'Trocchi', 'Roboto Condensed', 'Computer Modern Concrete', 'Computer Modern Bright', 'Helvetica', arial;
    
    font-family: 'Brandon Grotesque', 'Montserrat', Helvetica, arial;
    font-weight: 400;
    //letter-spacing: 1px;
  } [data-widget="BODY"] h1 {
    font-size: 48px;
    margin-bottom: 20px;
    line-height: 1.2;
    font-weight: 700;
  }

  [data-widget="BODY"] .script {
    font-family: 'Brandon Grotesque', 'Cool Script', 'Helvetica', arial;
    font-weight: 400;
  }

  [data-widget="BODY"] a {
    color: #{considerit_salmon};
    // color: inherit;
    text-decoration: underline;
    cursor: pointer;
    font-weight: 600;
  }


  * {box-sizing: border-box;}
  html, body {margin: 0; padding: 0;}
  p {margin: 16px 0; }
  button, a {
    cursor: pointer;
  }

  textarea, input[type='text'], input[type='email'], input[type='password'], button {
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

  [data-widget="BODY"] figure {
    margin:  1.5em 0px;
    padding: 0;
    width: 100%;
    text-align: center;
  } 

  [data-widget="BODY"] figure img, [data-widget="BODY"] figure video {
    border: 1px solid #ddd;
  }

  figcaption {
    font-size: 85%;
    text-align: left;
    padding: 12px;
    text-align: left;
    background: #eee;
  }

  figcaption.short {
    text-align: center;
  }
  .update {
    font-size: 85%;
    text-align: left;
    padding: 12px;
    text-align: left;
    background: #eee;    
  }

  h1 {
    position: relative;
  }
  [data-widget="BODY"] h2 {
    font-weight: 500;
  }
  h1 img {
    position: absolute;
    width: 120px;
    left: -165px;
    top: 4px;
  }

  li {
    margin-bottom: 8px;
  }


  figure.side {
    width: 40%;
  }
  figure.right.side {
    float: right;
    margin-left: 24px;
  }
  figure.left.side {
    float: left; 
    margin-right: 24px;
  }

"""


SLIDERGRAMS_ENABLED = false 

#########
# Body: main content area

insert_grab_cursor_style()
dom.BODY = ->  
  if bus.honk
    bus.honk = false

  current_user = fetch '/current_user'

  loc = fetch 'location'
  return LOADING_INDICATOR() if !loc.path? 

  DIV 
    style: 
      padding: "0 #{fickle.doc_padding}px"
      background: 'linear-gradient(180deg, rgba(244,95,115,1) 80px, rgba(255,255,255,1) 80px)'

    DIV 
      style: 
        paddingBottom: 40

      PAGE_HEADER()

    BLOG_AUTH()


    DIV 
      style: 
        marginTop: if fickle.mobile_layout then 80 else 0
        minHeight: '100vh'

      if !loc.path || loc.path == '/'
        INTRO()

      else if loc.path.match '/prototype-liquid-finance-thhdbb'
        DIV 
          style: 
            padding: '120px 80px'

          if loc.path.match /\/prototype-liquid-finance-thhdbb\/[a-zA-Z]+/
            LIQUID_NETWORK
              name: loc.path.split('/prototype-liquid-finance-thhdbb')[1]

          else 
            LIQUID_FINANCE_INDEX()

      else 
        BLOG_POST
          key: "/post/#{loc.url}" 
          post: "/post/#{loc.url}" 

    PAGE_FOOTER()

    TOOLTIP?({key: 'tooltip'})
    IMAGE_MODAL()
    

dom.BODY.up = -> 
  document.title = "Travis Kriplean's blog"


dom.BLOG_AUTH = ->
  auth = fetch 'auth'
  return DIV null if !auth.form 

  DIV 
    key: 'auth_overlay'
    style: 
      top: 0 
      zIndex: 9999
      width: '100%'
      height: '100%'
      position: 'fixed'

    AUTH
      login_field: 'email'
      style:
        backgroundColor: considerit_salmon
      additional_questions: additional_registration_questions

dom.INLINE_BLOG_AUTH = -> 
  INLINE_LOGIN
    additional_questions: additional_registration_questions


additional_registration_questions =  
  render: ->

    return DIV null
    
    user = fetch('/current_user').user
    if user 
      private_user = fetch user.key + '/private/'

      private_user["#{get_forum()}_subscribe_to_email"] ?= false



    DIV 
      style: 
        display: 'flex'




      INPUT 
        id: 'mailing_list'
        type: 'checkbox'
        defaultChecked: if private_user? then private_user["#{get_forum()}_subscribe_to_email"] else false
        style: 
          position: 'relative'
          top: 4
          marginRight: 8
          fontSize: 18
          minWidth: 20

      LABEL 
        htmlFor: 'mailing_list'
        style: 
          fontSize: 14


        "It's ok for me to send you occasional email about new blog posts, like so occasional that I still haven't sent any"

  private: (obj) -> 
    obj["#{get_forum()}_subscribe_to_email"] = document.getElementById('mailing_list')?.checked
    obj 

dom.PAGE_HEADER = -> 
  auth = fetch 'auth'
  current_user = fetch '/current_user'

  HEADER 
    style: 
      position: 'relative' 
      #maxWidth: fickle.window_width * .95
      padding: 0
      marginLeft: if !fickle.mobile_layout then 20
      width: fickle.content_width

    # DIV 
    #   key: 'logo'
    #   style: 
    #     position: 'relative'
    #     whiteSpace: 'nowrap'

    #   if !fickle.mobile_layout
    #     SPAN 
    #       className: 'script'
    #       style: 
    #         fontSize: 34
    #         color: considerit_salmon
    #         lineHeight: 1

    #       "The "


    #   A 
    #     onMouseEnter: => 
    #       @local.hover = true
    #       save @local
    #     onMouseLeave: => 
    #       @local.hover = false
    #       save @local
    #     href: 'http://consider.it'
    #     target: '_blank'
    #     title: 'Consider.it\'s homepage'
    #     style: 
    #       position: 'relative'
    #       top: 7 
        
    #     DRAW_LOGO 
    #       clip: false
    #       o_text_color: considerit_salmon
    #       main_text_color: considerit_salmon        
    #       draw_line: false 
    #       i_dot_x: if @local.hover then 142 else 252
    #       transition: true
    #       height: 36

    #   SPAN 
    #     className: 'script'
    #     style: 
    #       fontSize: 34
    #       color: considerit_salmon
    #       lineHeight: 1

    #     " Blog"

    #   HR 
    #     style: 
    #       border: 'none'
    #       borderTop: "1px solid #D6D7D9"
    #       outline: 'none'
    #       position: 'absolute'
    #       zIndex: -1
    #       bottom: -6
    #       width: 290



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


    if fetch('location').path != '/'

      A 
        href: "/?c=true##{fetch('location').path.replace(/\//, '')}"      
        style: 
          fontFamily: brandon
          position: 'absolute'
          left: 0
          top: 20
          fontWeight: 800
          color: 'white' #'#888'
          textDecoration: 'none'
          fontSize: 26
          zIndex: 1

        dangerouslySetInnerHTML: __html: "&lt;&nbsp;<span style='text-decoration: underline'>back home</span>"
        

dom.INTRO = -> 

  root = fetch "/post/#{get_forum()}_root"
  DIV 
    style: {}



    BLOG_POST
      key: 'root post'
      enable_comments: false 
      show_meta: false
      post: root



    DIV 
      style: 
        marginLeft: if !fickle.mobile_layout then fickle.author_col + fickle.mouth_width
        marginTop: 24
        padding: if fickle.mobile_layout then 0 else "0px #{fickle.bubble_padding_x}px"
        width: fickle.content_col
        
      INDEX()  





dom.INDEX = ->
  root = fetch "/post/#{get_forum()}_root"
  posts = root.children

  posts.sort (a,b) ->
    a = fetch(a); b = fetch(b)
    if a.published && b.published
      (b.published_on or b.edits?[0]?.time) - (a.published_on or a.edits?[0]?.time)
    else if !a.published && !b.published
      b.edits?[0]?.time - a.edits?[0]?.time
    else if !a.published
      1
    else 
      -1

  current_user = fetch '/current_user'

  DIV 
    key: 'index'
    style: 
      boxSizing: 'border-box'
      marginLeft: 0
      position: 'relative'

    # DIV 
    #   className: 'script'    
    #   style: 
    #     position: 'absolute'
    #     left: -fickle.bubble_padding_x * 3
    #     top: -33
    #     color: '#A2A2A2'
    #     fontSize: 22
    #     display: if fickle.mobile_layout then 'none'
    #     verticalAlign: 'top'

    #   "Read a post!"

    #   SVG 
    #     viewBox: "0 0 49 17"
    #     stroke: '#A2A2A2'
    #     fill: '#A2A2A2'
    #     width: 36
    #     dangerouslySetInnerHTML: __html: """<g><path d="M6.2,9.3 C6,9.4 6.2,10.9 6.2,10.9 C13,10.6 19.7,9.3 26.5,8.8 C33.3,8.3 40.1,8.1 47,7.6 C47.2,7.6 47.2,4.1 46.9,4 C33.9,3.1 18.5,4.7 6.2,9.3 Z"></path><path d="M0.2,16.1 C6.1,16 11.9,16.5 17.7,16.5 C17.8,16.5 17.9,13.7 17.6,13.6 C12.6,12.7 7.4,12.8 2.4,13.1 C5.5,9.2 8.8,5.4 11.6,1.3 C11.7,1.2 11.5,0.6 11.6,0.5 C7.2,3.7 3.5,9 0.2,13.2 C-0.1,13.6 6.66133815e-16,16.1 0.2,16.1 Z"></path></g>"""
    #     style: 
    #       position: 'relative'
    #       top: 42
    #       right: '29%'
    #       zIndex: 2
    #       verticalAlign: 'top'
    #       transform: 'rotate(220deg)'

    DIV null,

      for post,idx in (posts or [])
        POST_SUMMARY 
          post: post
          key: (post.key or post)

    if is_host()

      DIV 
        style: 
          paddingBottom: 40
          marginTop: 15

        NEW_POST 
          placeholder: 'What are you thinking about?'
          min_height: 60
          show_border: true
          with_title: true
          parent: root
          publish_immediately: false
          wrapper_style: 
            width: fickle.content_col - fickle.bubble_padding_x * 2
            marginLeft: fickle.bubble_padding_x


set_style """

  [data-widget="POST_SUMMARY"] {
    min-height: 200px;
  }

  [data-widget="POST_SUMMARY"] .img_thumb img {
    object-fit: cover;
    width: 350px;
    max-height: 350px;
  }

"""

dom.POST_SUMMARY = -> 
  
  post = fetch @props.post 
  date = post.published_on or post.edits?[0]?.time

  return SPAN null if !post.published && post.user != fetch('/current_user').user?.key
  
  if date 
    date = new Date(date)
    month = 'Jan. Feb. Mar. Apr. May June July Aug. Sep. Oct. Nov. Dec.'.split(' ')[date.getMonth()]
    day = date.getDate()
    year = date.getYear() + 1900

  DIV 
    style: 
      marginBottom: 48
      position: 'relative'
      left: if !fickle.mobile_layout then -(fickle.author_col + fickle.mouth_width)
      width: fickle.content_col + fickle.author_col

    A name: "#{post.key.split('/')[2]}"
    
    DIV 
      style: 
        marginBottom: 8
        display: 'flex'


      if post.image && fickle.content_col > 625
        DIV 
          className: 'img_thumb'
          style: 
            marginRight: 24
            marginTop: 12
          
          IMG 
            src: post.image

      DIV 
        className: 'info_thumb' 

        H2 
          style: 
            marginTop: 0
            marginBottom: 8

          A
            href: "/#{post.key.split('/')[2]}"
            style: 
              color: considerit_salmon #'black'
              fontWeight: 600
              fontSize: 36
            post.title

        DIV 
          style:
            color: '#888'
            fontSize: 14
            marginBottom: 18

          "#{month} #{day}, #{year} by Travis Kriplean" 

          if !post.published && is_host()
            SPAN 
              style: 
                color: considerit_salmon
                marginLeft: 8
                display: 'inline-block'
                padding: '1px 2px'
              'unpublished'

          if post.published && is_host()
            BUTTON 
              style: 
                backgroundColor: 'transparent'
                border: 'none'
                textDecoration: 'underline'
                color: 'black'
              onClick: (e) ->
                if confirm('You sure you want to unpublish this post?')
                  post.published_on = null 
                  post.published = false
                  save post
              'unpublish'

          if is_host()
            BUTTON 
              style: 
                backgroundColor: 'transparent'
                border: 'none'
                textDecoration: 'underline'
                color: 'black'
              onClick: (e) ->
                if confirm('You sure you want to delete this post?')
                  bus.delete post
              'delete'

        if post.description
          DIV 
            style: 
              fontSize: 14
              color: '#666'
            if post.description.length > 300
              post.description.substring(0,300) + '...'
            else 
              post.description





dom.BLOG_POST = ->
  @props.enable_comments ?= true 
  @props.show_meta ?= true

  post = fetch @props.post 
  date = post.published_on or post.edits?[0]?.time

  return DIV null if !date 

  current_user = fetch('/current_user')
  loc = fetch 'location'
  if date 
    date = new Date(date)
    month = 'Jan. Feb. Mar. Apr. May June July Aug. Sep. Oct. Nov. Dec.'.split(' ')[date.getMonth()]
    day = date.getDate()
    year = date.getYear() + 1900

  is_author = current_user.user?.key == post.user 

  DIV 
    className: if post.longform then 'longform'


    # # trying to trick the browser into preloading some important media
    # if post.key == '/post/an-informal-curriculum-for-hom-fx1md'
    #   DIV 
    #     dangerouslySetInnerHTML: __html: """
    #       <video src="https://ddbjipgwr13mk.cloudfront.net/static/media/an-informal-curriculum-for-hom-fx1md/IMG_1769 3.mp4" poster="https://ddbjipgwr13mk.cloudfront.net/static/media/bear-loader.webp"  importance="high" width="100%" controls autoplay loop muted>
    #         <source src="https://ddbjipgwr13mk.cloudfront.net/static/media/an-informal-curriculum-for-hom-fx1md/IMG_1769 3.mp4" type="video/mp4">
    #       </video>"""
    #     style: 
    #       height: 1
    #       opacity: .1
    #       overflow: 'hidden'


    DIV 
      style: 
        marginTop: if post.longform then 80
        display: 'flex'
        flexDirection: 'row'
        alignItems: 'flex-start'
        marginLeft: if !fickle.mobile_layout then -fickle.doc_padding

      if !fickle.mobile_layout
        DIV 
          style: 
            position: if post.longform then 'absolute'
          TRAVIS()

      DIV 
        style: 
          margin: if post.longform then 'auto' 

        DIV 

          style: 
            width: fickle.content_col + fickle.mouth_width # - fickle.bubble_padding_x * 2
            position: 'relative'

          SLIDERGRAM_TEXT
            obj: post 
            attr: 'body'
            slidergrams_disabled: true
            slidergram_width: fickle.opinion_col
            slidergram_height: fickle.slidergram_height
            edit_permission: -> fetch('/current_user').user?.key == post.user

            width: fickle.content_col #- fickle.bubble_padding_x * 2
            html_WYSIWYG: true

            wrapper: if post.longform then DIV else BUBBLE_WRAP
            wrapper_attributes:
              wrapper_style: 
                paddingLeft: if !fickle.mobile_layout then fickle.mouth_width

              width: fickle.content_col 
              bubble_style: if fickle.mobile_layout
                              padding: 0
                              backgroundColor: 'transparent'
                              boxShadow: 'none'
                            else 
                              borderRadius: 64
                              padding: "#{fickle.bubble_padding_y}px #{fickle.bubble_padding_x}px #{fickle.bubble_padding_y * 1.5}px #{fickle.bubble_padding_x}px"

              mouth_style:
                width: fickle.mouth_width
                top: fickle.mouth_width * 3
                transform: 'rotate(270deg) scaleX(1)'
                left: -fickle.mouth_width + 1
                display: if fickle.mobile_layout then 'none'
              mouth_shadow: 
                dy: -1
                dx: -3
                opacity: .2


            slidergram_container_style:
              marginLeft: -32 / 2 - 15

            DIV 
              ref: 'title_block' 
              style: 
                paddingBottom: 48

              H1 
                style: 
                  marginTop: 10
                  marginBottom: 0

                TITLE_BLOCK 
                  post: post 

              if @props.show_meta 

                DIV
                  style: 
                    padding: '12px 0 0 0'
                    color: '#888'
                    fontSize: 14

                  "published #{month} #{day}, #{year} by Travis Kriplean" 

        if is_author && post.parent
          DIV 
            style: 
              marginLeft: 50
              marginTop: 20


            DIV null, 
              LABEL 
                style: {}
                "Description"

                TEXTAREA 
                  type: 'text'
                  defaultValue: post.description
                  onChange: (ev) -> 
                    post.description = ev.target.value 
                    save post 

            DIV null,
              LABEL 
                style: {}
                "Image (link)"

                INPUT 
                  type: 'text'
                  defaultValue: post.image
                  onChange: (ev) -> 
                    post.image = ev.target.value 
                    save post 


            BUTTON 
              backgroundColor: considerit_salmon
              fontSize: 24
              padding: '8px 16px'
              color: 'white'
              border: 'none'

              onClick: ->
                post.published = !post.published 
                post.published_on = (new Date()).getTime()

                save post

              if !post.published

                'Publish'
              else 
                'Unpublish'


        if @props.enable_comments
          DIV 
            style: 
              marginLeft: if !post.longform then fickle.mouth_width
              marginTop: 50

            COMMENTS
              post: post


      if !fickle.mobile_layout && SLIDERGRAMS_ENABLED
        logged_in = fetch('/current_user').logged_in
        DIV 
          className: 'script'
          style: 
            fontSize: 20
            position: 'relative'
            marginTop: @local.instructions_top or 140
            paddingLeft: 15
            display: 'inline-block'


          SVG 
            viewBox: "0 50 100 125"
            stroke: considerit_salmon
            fill: considerit_salmon
            width: 50
            dangerouslySetInnerHTML: __html: """<path d="M29.2,62.3c-0.2,0.1,0,1.6,0,1.6c6.8-0.3,13.5-1.6,20.3-2.1c6.8-0.5,13.6-0.7,20.5-1.2c0.2,0,0.2-3.5-0.1-3.6  C56.9,56.1,41.5,57.7,29.2,62.3z"/><path d="M23.2,69.1c5.9-0.1,11.7,0.4,17.5,0.4c0.1,0,0.2-2.8-0.1-2.9c-5-0.9-10.2-0.8-15.2-0.5c3.1-3.9,6.4-7.7,9.2-11.8  c0.1-0.1-0.1-0.7,0-0.8c-4.4,3.2-8.1,8.5-11.4,12.7C22.9,66.6,23,69.1,23.2,69.1z"/>"""
            style: 
              position: 'absolute'
              left: -19
              top: 25
              zIndex: 2
              transform: 'rotate(-20deg)'

          DIV
            style: 
              color: considerit_salmon
              letterSpacing: -1
              lineHeight: 1.2
              width: fickle.opinion_col

            DIV 
              style: 
                color: considerit_salmon

              'Select text to create reaction slidergrams'

            # SPAN 
            #   style: 
            #     color: '#A2A2A2'


            #   ' ...and add yourself to existing sliders!'

            if !logged_in
              AUTH_FIRST
                before: ''
                after: ' required first'
                show_login: true
                show_create: false
                style: 
                  fontFamily: brandon
                  backgroundColor: 'transparent'
                  fontSize: 'inherit'
                  padding: 0
                  color: '#a2a2a2'
                  lineHeight: 1.2
                  marginBottom: 0
                  display: 'inline'
                button_style: 
                  fontWeight: 400
            else if loc.path != '/reaction-slidergram-instructio'
              A 
                href: '/reaction-slidergram-instructio'

                style: 
                  fontFamily: brandon
                  color: '#a2a2a2'
                  lineHeight: 1.2
                  fontWeight: 300
                'learn more'

dom.BLOG_POST.refresh = ->
  if SLIDERGRAMS_ENABLED && @refs.title_block
    rect = @refs.title_block.getDOMNode().getBoundingClientRect()
    instructions_top = @refs.title_block.getDOMNode().getBoundingClientRect().height - 20
    if @local.instructions_top != instructions_top
      @local.instructions_top = instructions_top
      save @local

  dragon_roar = =>
    audio = new Audio('https://ddbjipgwr13mk.cloudfront.net/static/media/exploring-the-mythical-6h6z2/Dragon Tense.mp3');
    audio.play()
    setTimeout ->
      audio.pause()
    , 3000


  post = fetch @props.post 
  if post.key == "/post/exploring-the-mythical-6h6z2"
    img = @getDOMNode().querySelector('img.modal_eligible')
    if img
      img.removeEventListener('mouseenter', dragon_roar) 
      img.addEventListener('mouseenter', dragon_roar) 







dom.TITLE_BLOCK = -> 
  current_user = fetch '/current_user'
  post = fetch @props.post 

  DIV null, 
    if @local.editing && current_user.user?.key == post.user  
      AUTOSIZEBOX
        key: 'title_editor'
        style: 
          width: '100%'
          fontSize: 'inherit'
          backgroundColor: 'transparent'
          border: 'none'
          padding: 0 
          margin: 0
          outline: 'none'
        value: post.title
        onChange: (e) => 
          post.title = e.target.value
          save post
        onDoubleClick: => 
          if current_user.user?.key == post.user
            @local.editing = false
            save @local

    else 
      SPAN 
        key: 'title'
        onDoubleClick: => 
          if current_user.user?.key == post.user
            @local.editing = true
            save @local
        
        post.title

dom.COMMENTS = ->
  posts = fetch(@props.post).children or []

  posts.sort (a,b) -> 
    a = fetch(a)
    b = fetch(b)
    (b.published_on or b.edits?[0].time) - (a.published_on or a.edits?[0].time)

  current_user = fetch '/current_user'

  DIV 
    style: 
      boxSizing: 'border-box'
      position: 'relative'


    H1 
      style: 
        fontWeight: 800

      "Let's talk"




    START_THREAD
      post: @props.post 

    # # Divider
    # DIV 
    #   style: 
    #     position: 'relative'
    #     paddingBottom: 24

    #   DIV 
    #     style: 
    #       boxShadow: '0px 1px 2px rgba(0, 0, 0, 0.1)'
    #       borderBottom: '1px solid #dadada'
    #       width: fickle.window_width * 2
    #       pointerEvents: 'none'
    #       position: 'absolute'
    #       height: 5
    #       top: -5
    #       left: -fickle.window_width
    #       display: 'block'




    DIV 
      ref: 'posts_area'

      for post,idx in (posts or [])
        THREAD 
          post: post
          key: (post.key or post)





#########
# Thread
#########

dom.START_THREAD = ->
  current_user = fetch '/current_user'
  credentials = fetch 'credentials'

  DIV 
    position: 'relative'

    DIV 
      className: 'script'    
      style: 
        position: 'absolute'
        left: -fickle.bubble_padding_x * 3
        top: -22
        color: considerit_salmon
        fontSize: 22
        display: if fickle.mobile_layout then 'none'
        verticalAlign: 'top'
        
      DIV 
        style: 
          width: 120
          letterSpacing: -1
          lineHeight: 1.2
          position: 'relative'
        "Tell me what you think!"

        SVG 
          viewBox: "0 0 49 17"
          stroke: considerit_salmon
          fill: considerit_salmon
          width: 36
          dangerouslySetInnerHTML: __html: """<g><path d="M6.2,9.3 C6,9.4 6.2,10.9 6.2,10.9 C13,10.6 19.7,9.3 26.5,8.8 C33.3,8.3 40.1,8.1 47,7.6 C47.2,7.6 47.2,4.1 46.9,4 C33.9,3.1 18.5,4.7 6.2,9.3 Z"></path><path d="M0.2,16.1 C6.1,16 11.9,16.5 17.7,16.5 C17.8,16.5 17.9,13.7 17.6,13.6 C12.6,12.7 7.4,12.8 2.4,13.1 C5.5,9.2 8.8,5.4 11.6,1.3 C11.7,1.2 11.5,0.6 11.6,0.5 C7.2,3.7 3.5,9 0.2,13.2 C-0.1,13.6 6.66133815e-16,16.1 0.2,16.1 Z"></path></g>"""
          style: 
            position: 'relative'
            top: 18
            right: '-10%'
            zIndex: 2
            verticalAlign: 'top'
            transform: 'rotate(205deg)'

    if !current_user.logged_in 
      DIV 
        style: 
          # border: "1px dashed #aaa"
          width: fickle.content_col
          margin: "0px 0 24px 0"


        INLINE_BLOG_AUTH()

        # AUTH_FIRST
        #   style: 
        #     backgroundColor: 'white'
        #     # fontFamily: brandon
        #     color: '#222'
        #     fontSize: 18
        #     marginBottom: 0
        #     padding: "18px 36px"
        #   button_style:
        #     color: considerit_salmon
        #   before: 'Please '
        #   after: ' to add a comment'

    NEW_POST 
      key: 'new post'
      placeholder: 'Reply to Travis\' post'
      min_height: 72
      show_border: true
      parent: @props.post
      wrapper_style: 
        width: fickle.content_col # - fickle.bubble_padding_x * 2
        # marginLeft: fickle.bubble_padding_x
        margin: "0px 0 55px 0"
        display: 'block'
      text_box_style:
        padding: '2px 6px' 
      disabled: !current_user.logged_in && !(credentials.name && credentials.email && credentials.password) 

dom.THREAD = ->  
  pst = fetch(@props.post.key or @props.post)
  pst.children ||= []
  current_user = fetch '/current_user'

  user_name = if pst.user then fetch(pst.user).name else 'Anonymous'
  possessive_name = if user_name[user_name.length - 1] == 's' then "#{user_name}'" else "#{user_name}'s"
  
  DIV 
    style: 
      marginBottom: 60

    POST 
      post: pst
      first: true
      last: !pst.children || pst.children.length == 0


    for child,idx in (pst.children or [])
      POST 
        post: child
        key: (child.key or child)
        bgcolor: if idx % 2 == 0 then '#E9E9E9'
        last: idx == pst.children.length - 1

    DIV 
      style: 
        paddingLeft: 36 #fickle.bubble_padding_x


      if !current_user.logged_in 
        DIV 
          style: 
            width: fickle.content_col

          AUTH_FIRST
            style: 
              backgroundColor: 'white'
              
              color: '#999'
              fontSize: 18
              marginBottom: 0
              padding: "8px 0px"
            button_style:
              color: '#999'
              fontWeight: 600
              textDecoration: 'underline'

            before: 'Please '
            after: " to reply to #{possessive_name} thread"
      else 
        NEW_POST 
          key: "new_post_#{@props.post.key}"
          placeholder: "Reply to #{possessive_name} thread"
          min_height: 32
          parent: @props.post
          wrapper_style: 
            width: fickle.content_col # - fickle.bubble_padding_x * 2
            margin: "4px 0px"



##########
# NewPost
#
# props:
#   placeholder, min_height, 
#   parent: the parent post, if any
dom.NEW_POST = -> 
  @props.min_height ||= 60
  @props.placeholder ||= "New post"
  @props.publish_immediately ?= true 

  if @props.parent 
    @props.parent = fetch(@props.parent)

  show_border = @props.show_border

  DIV 
    style: 
      width: '100%'
    onMouseEnter: => @local.hovering = true; save @local
    onMouseLeave: => @local.hovering = false; save @local


    DIV 
      style: defaults {}, (@props.wrapper_style or {}),
        display: 'inline-block'

      if @props.with_title
        AUTOSIZEBOX
          onFocus: => @local.focused = true; save @local
          onBlur: => @local.focused = false; save @local
          onChange: (e) => @local.title = e.target.value; save(@local)

          key: 'title'
          style: defaults {}, (@props.text_box_style or {}),
            width: '100%'
            minHeight: @props.min_height
            maxHeight: 600
            padding: 0
            fontSize: 18
            border:   if show_border
                        '1px solid #ccc'
                      else
                        '1px solid transparent'
            marginBottom: 10
            outline: 'none'
          placeholder: 'Short title'
          value: @local.title

      if !@props.with_title

        AUTOSIZEBOX
          onFocus: => @local.focused = true; save @local
          onBlur: => @local.focused = false; save @local
          onChange: (e) => @local.new_post = e.target.value; save(@local)

          key: 'body'
          style: defaults {}, (@props.text_box_style or {}),
            width: '100%'
            minHeight: @props.min_height
            maxHeight: 600
            padding: 0
            fontSize: 18
            border:   if show_border
                        '1px solid #ccc'
                      else
                        '1px solid transparent'
            display: 'block'
            outline: 'none'
          placeholder: @props.placeholder
          value: @local.new_post

      if (@props.with_title || @local.new_post?.length > 0) && (!@props.with_title || @local.title?.length > 0)
        BUTTON
          type: 'submit'
          disabled: if @props.disabled || (!@props.with_title && !@local.new_post) then true
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



          onClick: (e) =>
            if @local.new_post || @props.with_title

              submit_post = =>
                if @local.new_post 
                  @local.new_post = protect_leading_new_line(@local.new_post)

                new_post = 
                  key: new_key('post', @local.title)
                  body: @local.new_post
                  title: if @props.with_title then @local.title
                  user: your_key()
                  parent: @props.parent.key if @props.parent
                  children: if !@props.parent then []
                  forum: if !@props.parent then get_forum()
                  published: @props.publish_immediately
                  published_on: if @props.publish_immediately then (new Date()).getTime()
                  edits: [{
                    user: your_key(),
                    time: (new Date()).getTime()
                    }]

                save new_post

                @local.new_post = ''
                save @local

              current_user = fetch '/current_user'
              if !current_user.logged_in 
                submit_inline_registration 'email', additional_registration_questions

                if !@waiting_for_login
                  @waiting_for_login = true 
                  wait_for_login = setInterval =>
                    if current_user.logged_in
                      @waiting_for_login = false
                      clearInterval wait_for_login
                      submit_post()
                    else if current_user.error
                      clearInterval wait_for_login
                  , 100

              else 
                submit_post()




          'Post'


dom.POST = -> 
  pst = fetch @props.post 

  DIV 
    style: 
      position: 'relative'
    onClick: (e) =>
      current_user = fetch '/current_user'
      if current_user.logged_in && current_user.user.email == 'travis@consider.it'
        @local.show_admin_options = !@local.show_admin_options
        save @local

    SLIDERGRAM_TEXT
      obj: pst 
      attr: 'body'
      slidergram_width: fickle.opinion_col
      slidergram_height: fickle.slidergram_height
      slidergrams_disabled: true

      width: fickle.content_col

      edit_permission: -> fetch('/current_user').user?.key == pst.user

      wrapper: BUBBLE_WRAP
      wrapper_attributes: 
        user: pst.user 
        width: fickle.content_col #- fickle.bubble_padding_x + 14
        style: 
          flex: 1
        wrapper_style: 
          # margin: "0px #{fickle.bubble_padding_x - 14}px"
          margin: 0
        bubble_style: 
          borderRadius: 18
          padding: "24px 36px" #"#{fickle.bubble_padding_y / 2}px #{fickle.bubble_padding_x}px #{fickle.bubble_padding_y / 2}px #{fickle.bubble_padding_x}px"
          #boxShadow: 'none'
          backgroundColor: @props.bgcolor or considerit_gray
          minHeight: 54
        mouth_style:
          width: 20 #fickle.mouth_width / 2 
          top: 6
          transform: 'rotate(270deg) scaleX(-1)'
          left: -20 + 1 #- 2
          # display: if fickle.mobile_layout then 'none'
        mouth_shadow: 
          dy: -1
          dx: 3
          opacity: .2
          fill: '#666666'
        avatar_style: 
          top: -48
          left: -105
          borderRadius: '50%'
          width: 100
          height: 100
    if @local.show_admin_options
      button_style = 
        display: 'block'
        marginBottom: 2


      parent = if pst.parent then fetch(pst.parent) else null

      DIV 
        style: 
          position: 'absolute'
          right: -50
          top: 0
          zIndex: 999

        BUTTON
          style: button_style
          onClick: (e) => 
            if confirm("Are you sure?")
              console.log 'deleting'
              parent = fetch(pst.parent)
              idx = parent.children.indexOf pst.key 
              parent.children.splice(idx, 1)
              save parent

          'delete'

        if parent?.parent != "/post/blog_root"
          BUTTON
            style: button_style
            onClick: (e) =>
              parent = fetch(pst.parent)
              grandparent = fetch(parent.parent)

              # add post to grandparent
              grandparent.children.push pst.key

              # remove this post from parent
              idx = parent.children.indexOf pst.key 
              parent.children.splice(idx, 1)

              # update guardian info
              pst.parent = grandparent.key

              save grandparent
              save parent
              save pst 
            'pop'



window.get_forum = -> 'blog'

# textareas strip out any leading \n. This throws off our slidergram 
# anchor text parity, creating mistakes when updating slidergram 
# positions. To prevent textareas from stripping out the leading 
# new line, we'll replace a leading new line with a space and \n
#
# TODO: can we just handle this in markup_text?
protect_leading_new_line = (str) -> 
  str ||= ''
  if str.length > 0 && str[0] == '\n'
    str = " \n#{str.substring(1)}"
  str




dom.TRAVIS = ->

  social = [
    {f: 'https://ddbjipgwr13mk.cloudfront.net/static/social/linkedin.svg', l: 'https://www.linkedin.com/in/travis-kriplean/'}
    {f: 'https://ddbjipgwr13mk.cloudfront.net/static/social/twitter.svg', l: 'https://twitter.com/tkriplean'}
    {f: 'https://ddbjipgwr13mk.cloudfront.net/static/social/facebook.svg', l: 'https://www.facebook.com/travis.kriplean'}
    {f: 'https://ddbjipgwr13mk.cloudfront.net/static/social/github.svg', l: 'https://github.com/tkriplean'}
  ]

  DIV 
    style: 
      marginTop: 80
      marginRight: 8

    DIV 
      style: 
        display: 'inline-block'
        # padding: '0 20px'

      IMG 
        src: 'https://ddbjipgwr13mk.cloudfront.net/static/blinking_travis.gif'
        style: 
          width: fickle.author_col
          height: fickle.author_col * 600/292

    UL 
      style: 
        #marginLeft: 24
        marginTop: 2
        textAlign: 'center'
        listStyle: 'none'
        marginLeft: fickle.author_col * .46
        padding: 0

      for link,idx in social 
        LI 
          style: 
            display: 'block'
            marginBottom: 2
          A
            href: link.l
            target: '_blank'
            style: 
              backgroundColor: if idx % 2 == 0 then considerit_green else considerit_salmon
              display: 'inline-block'
              #padding: '10px 13px'
              marginLeft: 2
              textAlign: 'center'
              borderRadius: '100%'
              boxShadow: '0 1px 1px rgba(0,0,0,.9)'
              width: 42 * fickle.author_col / 200
              height: 42 * fickle.author_col / 200
              verticalAlign: 'middle'
              display: 'table-cell'
            IMG
              style: 
                maxWidth: 20 * fickle.author_col / 200
                maxHeight: 20 * fickle.author_col / 200
                fill: 'white'
                verticalAlign: 'middle'
              src: link.f 


dom.MAILING_LIST_SIGNUP = ->
  current_user = fetch('/current_user')
  already_subscribed = current_user.logged_in && fetch(current_user.user.key + '/private/')?["#{get_forum()}_subscribe_to_email"]?

  lst = fetch('mailing_list')

  mailing_list_signup = => 
    list = fetch("/mailing_list/#{get_forum()}")
    list.new_address = @local.email
    save list
    lst.signed_up = true 
    save lst


  DIV 
    style:       
      color: 'white'
      fontFamily: '"Brandon Grotesque", Montserrat, Helvetica, arial'
      maxWidth: 400
      margin: 'auto'


    if !lst.signed_up && !already_subscribed
      DIV null, 
        DIV 
          style: 
            fontWeight: 700
            fontSize: 24
            color: considerit_salmon
            marginBottom: 8

          'Want to be notified about new posts?'

        INPUT 
          type: 'email'
          placeholder: 'Email address'
          value: @local.email 
          style: 
            padding: '4px 12px'
            width: '70%'
          onChange: (e) =>
            @local.email = e.target.value 
            save @local


        BUTTON 
          disabled: if !@local.email || !@local.email?.split('@')[1] then true else undefined
          onClick: mailing_list_signup 
          style: 
            padding: '4px 12px'
            marginLeft: 8
            display: 'inline-block'
            backgroundColor: '#414141'
          onKeyPress: (e) -> 
            if e.which in [32, 13]
              mailing_list_signup()
          'Sign up'

        DIV 
          style: 
            textAlign: 'center'
            color: '#777'

          "...or follow along via "
          A 
            href: '/feed'
            stay_away_Earl: true
            style: {}
              
            'rss'
          '.'

    else 
      DIV 
        style: 
          fontWeight: 700
          fontSize: 24
          color: considerit_salmon
          marginBottom: 8
          textAlign: 'center'
        'Follow along via '


        A 
          href: '/feed'
          stay_away_Earl: true
          style: {}
            
          'rss'
        '.'





dom.PAGE_FOOTER = -> 

  FOOTER 
    style: 
      # height: 266
      width: '100%'
      marginTop: 100

    MAILING_LIST_SIGNUP()    

    LAB_FOOTER()    










