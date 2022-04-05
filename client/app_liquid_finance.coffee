
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


#########
# Body: main content area

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

    AUTH_WRAPPER()

    DIV 
      style: 
        minHeight: '100vh'
        marginTop: 100
        paddingLeft: 80

      if loc.path == '/'
        LIQUID_FINANCE_INDEX()
      else 
        LIQUID_NETWORK
          name: loc.path

    PAGE_FOOTER()

    TOOLTIP?({key: 'tooltip'})
    

dom.BODY.up = -> 
  document.title = "Liquid Finance Prototype"








dom.AUTH_WRAPPER = ->
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
        

dom.PAGE_FOOTER = -> 

  FOOTER 
    style: 
      width: '100%'
      marginTop: 100

    LAB_FOOTER()    










