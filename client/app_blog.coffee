


fickle.register (upstream_vars) -> 
  window_w = upstream_vars.window_width

  

  if window_w < 600
    doc_padding = 28

    author_col = 0
    opinion_col = Math.max 50, content_width * .2
    content_col = Math.max 200, Math.min(700, content_width - opinion_col)


  else 
    doc_padding = 20
    content_width = window_w - 2 * doc_padding
    author_col = Math.min 200, content_width * .15
    opinion_col = Math.max 50, content_width * .125
    content_col = Math.max 200, Math.min(700, content_width - opinion_col - author_col)

  return {
    mobile_layout: window_w < 600
    doc_padding: doc_padding
    content_col: content_col
    author_col: author_col
    opinion_col: opinion_col
    slidergram_height: 40
  }

window.considerit_salmon = '#f35389' #'#df6264'
window.considerit_gray = '#F6F7F9'
window.considerit_green = '#bdb75b'

focus_blue = '#2478CC'
post_bg = '#F5F5F5' #'#F4F6F8'


style = document.createElement "style"
style.id = "overall-styles"
style.innerHTML =   """
  [data-widget="BODY"], [data-widget="BODY"] input, [data-widget="BODY"] button  {
    font-family: 'Computer Modern Serif', 'Helvetica', arial;
    font-size: 18px;
    color: #222;
    line-height: 1.4;
    -webkit-font-feature-settings: 'liga' 1;
    -moz-font-feature-settings: 'liga' 1;    
  } [data-widget="BODY"] h1, [data-widget="BODY"] h2, [data-widget="BODY"] h3 {
    font-family: 'Computer Modern Concrete', 'Computer Modern Bright', 'Helvetica', arial;
  } [data-widget="BODY"] h1 {
    font-size: 62px;
    margin-bottom: 20px;
    font-weight: 400;
    line-height: 1.2;
  }

  [data-widget="BODY"] .script {
    font-family: 'Cool Script', 'Helvetica', arial;
  }

  [data-widget="BODY"] .sans {
    font-family: 'Computer Modern Bright', 'Helvetica', arial;
  }

  [data-widget="BODY"] a {
    color: #{considerit_salmon};
    text-decoration: underline;
    cursor: pointer;
    font-weight: 500;
  }


  * {box-sizing: border-box;}
  html, body {margin: 0; padding: 0;}
  p {margin: 8px 0px}



"""
document.head.appendChild style


#########
# Body: main content area

dom.BODY = ->  
  current_user = fetch '/current_user'
  auth = fetch 'auth'

  loc = fetch 'location'

  DIV 
    style: 
      padding: "0 #{fickle.doc_padding}px"

    DIV 
      style: 
        marginBottom: 60
      PAGE_HEADER()

    DIV 
      key: 'auth_overlay'
      style: 
        # position: 'fixed'
        top: 0 
        zIndex: 9999
        width: '100%'
        fontFamily: 'sans-serif'
        

      if !current_user.logged_in && auth.start
        AUTH
          login: auth.try_login or false
      else if auth.set_avatar 
        SET_AVATAR()


    if loc.path == '/'
      INTRO()

    else 
      BLOG_POST
        post: get_post_with_slug(loc.url)


    TOOLTIP key: 'tooltip'
    StateDash()
    GRAB_CURSOR()

dom.BODY.up = -> 
  document.title = "Consider.it Blog"

get_post_with_slug = (slug) -> 
  posts = fetch("/all_posts/#{get_forum()}").posts
  posts.find (p) -> p.title && slugify(p.title) == slug

dom.PAGE_HEADER = -> 
  auth = fetch 'auth'
  current_user = fetch '/current_user'

  HEADER 
    style: 
      position: 'relative' 
      #maxWidth: fickle.window_width * .95
      padding: 0



    DIV 
      key: 'logo'
      style: 
        position: 'relative'
        whiteSpace: 'nowrap'

      SPAN 
        className: 'script'
        style: 
          fontSize: 42
          color: considerit_salmon

        "The "

      A 
        href: 'https://consider.it'
        target: '_blank'
        style: 
          position: 'relative'
          top: 14 
          padding: '0 12px 0 6px'
        DRAW_LOGO
          line_color: '#D3D3D3'
          draw_line: false
          o_text_color: considerit_salmon
          main_text_color: considerit_salmon
          # width: fickle.window_width - 20
          # line_width: 2
          # line_length: fickle.window_width - 20

      SPAN 
        className: 'script'
        style: 
          fontSize: 42
          color: considerit_salmon

        " Blog"

      HR 
        style: 
          border: 'none'
          borderTop: "2px solid #D3D3D3"
          outline: 'none'
          position: 'absolute'
          zIndex: -1
          bottom: 0
          width: '100%'



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
        style: 
          position: 'absolute'
          left: 20
          textDecoration: 'none'
          fontWeight: 600
          color: '#888'

        href: "/?c=true##{fetch('location').path.replace(/\//, '')}"

        '< back'


dom.INTRO = -> 
  body = """
    <p>I created <a href="https://consider.it" target="_blank">Consider.it</a> as part of my Computer Science dissertation 
    "<a href="https://www.dropbox.com/s/lgrat3ip0jlq373/dissertation.pdf?dl=0" target="_blank">Encouraging Reflective Discussion on the Web</a>" at the University of Washington. Since 
    then, I've bootstrapped my work creating technology for helping large communities 
    better understand each other.</p> 

    <p>Though Consider.it has been widely used, I've communicated little 
    outside of an <a href="https://invisible.college" target="_blank">
    Invisible College</a> since leaving academia. This blog reflects my intention to be more public in my work. I am writing about
    new designs and prototypes, exciting use cases, open collaboration, and digital engagement. Call me out on 
    <a href="https://twitter.com/tkriplean" target="_blank">Twitter</a> if 
    I don't post at least once per month!</p>

    <p>This blog is also a playground for new inventions,
    so hopefully it will be fun for you. Please 
    <a href="mailto:travis@consider.it" target="_blank">email me</a> if you get bit by a bug.</p>
  """ 

  mouth_width = fickle.content_col * .07

  DIV 
    style: 
      marginTop: 40
      display: 'flex'
      flexDirection: 'row'

    if !fickle.mobile_layout
      TRAVIS()

    DIV 
      style: 
        marginLeft: if !fickle.mobile_layout then mouth_width #if !fickle.mobile_layout then 50


      DIV 
        className: 'sans'

        BUBBLE_WRAP
          
          title: 'Welcome! I\'m Travis Kriplean, your friendly dialogue-ngineer.'
          body: body
          width: Math.min 700, fickle.content_col + fickle.opinion_col - mouth_width
          bubble_style: if fickle.mobile_layout
                          padding: 0
                          backgroundColor: 'transparent'
                          boxShadow: 'none'
                        else 
                          borderRadius: 64
                          padding: '30px 30px'

          title_style: 
            fontSize: 18
            marginBottom: 0
          body_style: 
            fontSize: 18
          mouth_style:
            width: mouth_width
            top: mouth_width * 1.5
            transform: 'rotate(270deg) scaleX(1)'
            left: -mouth_width - 2
            display: if fickle.mobile_layout then 'none'
          mouth_shadow: 
            dy: -1
            dx: -3
            opacity: .2


      DIV 
        style: 
          marginTop: 28
          padding: if fickle.mobile_layout then 0 else '0px 30px'
          width: Math.min 700, fickle.content_col + fickle.opinion_col - mouth_width
        
        INDEX()      



    

dom.INDEX = ->
  posts = fetch("/all_posts/#{get_forum()}").posts

  current_user = fetch '/current_user'

  DIV 
    key: 'index'
    style: 
      boxSizing: 'border-box'
      marginLeft: 0

    DIV null,

      for post,idx in (posts or [])
        console.log post
        POST_SUMMARY 
          post: post
          key: (post.key or post)

    if current_user.logged_in && current_user.user.email == 'travis@consider.it'

      DIV 
        style: 
          paddingBottom: 40
          marginTop: 15

        NEW_POST 
          key: 'start_new_thread'
          placeholder: 'What are you thinking about?'
          min_height: 60
          show_border: true
          with_title: true


dom.POST_SUMMARY = -> 
  
  post = fetch @props.post 
  date = post.edits?[0]?.time


  if date 
    date = new Date(date)
    month = 'Jan. Feb. Mar. Apr. May June July Aug. Sep. Oct. Nov. Dec.'.split(' ')[date.getMonth()]
    day = date.getDate()
    year = date.getYear() + 1900

  DIV 
    style: 
      marginBottom: 24
      #marginLeft: fickle.author_col

    A name: "#{slugify(post.title or "")}"
    H2 
      style: 
        fontSize: 42
        marginBottom: 8
        
      A
        href: "/#{slugify(post.title or "")}"
        style: 
          color: considerit_salmon #'black'
        post.title

    DIV 
      className: 'sans'
      fontSize: 16
      color: '#666'

      "posted #{month} #{day}, #{year} by Travis Kriplean" 





dom.BLOG_POST = ->
  

  post = fetch @props.post 
  date = post.edits?[0]?.time

  if date 
    date = new Date(date)
    month = 'Jan. Feb. Mar. Apr. May June July Aug. Sep. Oct. Nov. Dec.'.split(' ')[date.getMonth()]
    day = date.getDate()
    year = date.getYear() + 1900

  DIV null,

    DIV 
      style: 
        marginTop: 40
        display: 'flex'
        flexDirection: 'row'

      if !fickle.mobile_layout
        TRAVIS()

      DIV 
        style: 
          paddingLeft: 50
          width: Math.min 800, fickle.content_col + fickle.opinion_col

        H1 
          style: 
            marginTop: 10

          post.title

        DIV
          style: 
            margin: '0px 0 50px 0'
            color: '#666'
            #fontStyle: 'italic'

          "posted #{month} #{day}, #{year} by Travis Kriplean" 


          # "by Travis Kriplean, creator of "
          # A 
          #   href: 'https://consider.it'
          #   target: '_blank'
          #   'Consider.it'




        DIV 
          style: 
            width: fickle.content_col
            position: 'relative'

          SLIDERGRAM_TEXT
            obj: post 
            attr: 'body'
            slidergram_width: fickle.opinion_col
            slidergram_height: fickle.slidergram_height

            width: fickle.content_col
            html_WYSIWYG: true

            wrapper: DIV
            wrapper_attributes:
              style:
                paddingRight: 28

        DIV 
          style: 
            marginLeft: 0

          COMMENTS
            post: post



dom.COMMENTS = ->
  posts = fetch(@props.post).children


  DIV 
    style: 
      boxSizing: 'border-box'

    AUTH_FIRST()

    DIV 
      style: 
        paddingBottom: 40
        marginTop: 15

      NEW_POST 
        key: 'new post'
        placeholder: 'What do you think?'
        min_height: 60
        show_border: true
        parent: @props.post
      

    DIV 
      ref: 'posts_area'

      for post,idx in (posts or [])
        THREAD 
          post: post
          key: (post.key or post)




#########
# Thread
#########

dom.THREAD = ->
  pst = fetch(@props.post.key or @props.post)
  pst.children ||= []


  DIV 
    style: 
      marginBottom: 40

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
      style: {}

      NEW_POST 
        key: "new_post_#{@props.post.key}"
        placeholder: 'Add to this conversation!'
        min_height: 32
        parent: @props.post


##########
# NewPost
#
# props:
#   placeholder, min_height, 
#   parent: the parent post, if any
dom.NEW_POST = -> 
  @props.min_height ||= 60
  @props.placeholder ||= "New post"

  if @props.parent 
    @props.parent = fetch(@props.parent)

  show_border = @props.show_border || \
                @local.new_post?.length > 0 || \
                @local.title?.length > 0 || \
                @local.hovering || @local.focused

  DIV 
    style: 
      width: 600
    onMouseEnter: => @local.hovering = true; save @local
    onMouseLeave: => @local.hovering = false; save @local


    if @props.with_title
      AUTOSIZEBOX
        onFocus: => @local.focused = true; save @local
        onBlur: => @local.focused = false; save @local
        onChange: (e) => @local.title = e.target.value; save(@local)

        key: 'title'
        style:
          width: 600
          minHeight: @props.min_height
          maxHeight: 600
          padding: '4px 14px'
          fontSize: 16
          border:   if show_border
                      '1px solid #ccc'
                    else
                      '1px solid transparent'
          marginBottom: 10
        placeholder: 'Short title'
        value: @local.title

    AUTOSIZEBOX
      onFocus: => @local.focused = true; save @local
      onBlur: => @local.focused = false; save @local
      onChange: (e) => @local.new_post = e.target.value; save(@local)

      key: 'body'
      style:
        width: 600
        minHeight: @props.min_height
        maxHeight: 600
        padding: '4px 14px'
        fontSize: 16
        border:   if show_border
                    '1px solid #ccc'
                  else
                    '1px solid transparent'
        display: 'block'
      placeholder: @props.placeholder
      value: @local.new_post

    if @local.new_post?.length > 0 && (!@props.with_title || @local.title?.length > 0)
      BUTTON
        type: 'submit'
        style: 
          backgroundColor: considerit_salmon
          color: 'white'
          fontWeight: 600
          border: 'none'
          fontSize: 18
          padding: '6px 16px'
          borderRadius: 8
          verticalAlign: 'bottom'
          display: 'inline-block'
          #marginLeft: 8
          cursor: 'pointer'
          marginTop: 4



        onClick: (e) =>
          if @local.new_post
            @local.new_post = protect_leading_new_line(@local.new_post)

            new_post = 
              key: new_key('post')
              body: @local.new_post
              title: if @props.with_title then @local.title
              user: your_key()
              parent: @props.parent.key if @props.parent
              children: if !@props.parent then []
              forum: if !@props.parent then get_forum()
              edits: [{
                user: your_key(),
                time: (new Date()).getTime()
                }]

            save new_post

            @local.new_post = ''
            save @local


        'Post'


dom.POST = -> 
  pst = fetch @props.post 

  SLIDERGRAM_TEXT
    obj: pst 
    attr: 'body'
    slidergram_width: fickle.opinion_col
    slidergram_height: fickle.slidergram_height

    width: fickle.content_col

    wrapper: BUBBLE_WRAP
    wrapper_attributes: 
      user: pst.user 
      style: 
        width: fickle.content_col
        flex: 1
      mouth_style:
        width: 20
        height: 15 
      bubble_style: 
        padding: 14
        # borderRadius: if @props.first && @props.last then 16 \
        #               else if @props.first then '16px 16px 0 0' \
        #               else if @props.last then '0 0 16px 16px'




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
    {f: '/static/social/linkedin.svg', l: 'https://www.linkedin.com/in/travis-kriplean/'}
    {f: '/static/social/twitter.svg', l: 'https://twitter.com/tkriplean'}
    {f: '/static/social/facebook.svg', l: 'https://www.facebook.com/travis.kriplean'}
    {f: '/static/social/github.svg', l: 'https://github.com/tkriplean'}
  ]

  DIV null,

    DIV 
      style: 
        display: 'inline-block'
        # padding: '0 20px'

      IMG 
        src: '/static/travis_big.png'
        style: 
          width: fickle.author_col * .8
          height: (fickle.author_col * .8) * 600/292

    UL 
      style: 
        #marginLeft: 24
        marginTop: 2
        textAlign: 'center'
        listStyle: 'none'
        marginLeft: fickle.author_col * .085
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
              padding: 10
              marginLeft: 2
              textAlign: 'center'
              borderRadius: '100%'
              boxShadow: '0 1px 1px rgba(0,0,0,.9)'

            IMG
              style: 
                width: 20
                fill: 'white'
              src: link.f 





markup_text = (text) ->
  text ||= ''

  for p in text.split('\n')
    # replace a leading space with a non-breaking space
    if p[0] == ' '
      p = "\u00A0#{p.substring(1, p.length)}"

    # defeat html collapsing spaces 
    # (has to be done twice to make sure that odd numbers of consecutive spaces
    # are properly guarded against collapse)
    p = p.replace /\ \ /g, "\u00A0 "
    p = p.replace /\ \ /g, "\u00A0 "

    P 
      style: 
        minHeight: '22px'
        margin: 0

      if linkifyStr?

        for t in linkify.tokenize p
          text = t.v.join('')
          if t.isLink
            link = linkify.find(text)
            href = link?[0].href
            internal = href.indexOf("slider.chat#{location.pathname}") > -1
            if internal
              anchor = href.split('#')
              anchor = anchor[1] || 0            
              href = "##{anchor}"      

            if href 
              A 
                href: href
                target: if !internal then '_blank'
                onClick: (e) -> e.stopPropagation()
                text
            else 
              text
          else 
            text
      else 
        p

      # Insert a dummy newline to replace the one eliminated from the post body
      # by the split. This enables us to maintain parity of character count / 
      # positioning between the text nodes of the rendered post and the input 
      # box during editing. This in turn makes it much easier to maintain anchor
      # text positions on selections when text is edited. 
      SPAN 
        style: 
          display: 'none'
        '\n'






