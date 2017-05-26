focus_blue = '#2478CC'
feedback_orange = '#F19135'
logo_red = "#B03A44"
light_gray = '#c1c1c1'

slider_color = '#999'
index_bg = '#F5F5F5' #'#F4F6F8'
attention_magenta = '#FF00A4'

SLIDERGRAM_HEIGHT = 40
SLIDERGRAM_WIDTH = 150


#########
# Body: main content area

dom.BODY = ->  
  current_user = fetch '/current_user'
  auth = fetch 'auth'

  DIV
    id: 'main-content' #used in sizewhenrendered
    style:
      fontFamily: 'Avenir Next, Avenir, Calibri, Helvetica, sans-serif'
      fontSize: 16
      lineHeight: '22px'

    MASTHEAD
      key: 'masthead'


    POSTS
      key: 'posts'

    if fetch('tawking').on 
      DIV 
        style: 
          height: '70%'
          overflow: 'scroll'
          position: 'absolute'
          bottom: 0
          left: 0
          backgroundColor: 'white'

        TAWK
          name: name
          space: ''
          video: true
          audio: false


    DIV 
      key: 'auth_overlay'
      style: 
        position: 'fixed'
        top: 0 
        zIndex: 9999
        width: '100%'
        fontFamily: 'sans-serif'

      if !current_user.logged_in && auth.start
        AUTH
          login: auth.try_login or false
      else if auth.set_avatar 
        SET_AVATAR()


    LOADING_POST key: 'load_post'
    DOCUMENT_TITLE key: 'doc_title'
    SCROLL_ANCHOR_CONTROLLER key: 'scroll_anchor'
    TOOLTIP key: 'tooltip'
    StateDash()


dom.POSTS = ->
  email = fetch "/index/#{get_channel()}"

  posts = email.posts or []

  if !@local.items_to_render?
    # need to render enough posts such that they more than fill up the scrollable area
    @local.items_to_render = Math.ceil(window.innerHeight / 100)

  loc = fetch 'location'
  if loc.seek_to_hash
    idx = 0
    for pst,idx in posts 
      break if pst == "/post/#{loc.seek_to_hash}"

    if idx > @local.items_to_render
      @local.items_to_render = idx 

  DIV 
    key: 'main'
    className: 'flex'
    style: 
      width: '100%'
      height: WINDOW_HEIGHT() - fetch('masthead_height').height
      #overflow: 'hidden'
      boxSizing: 'border-box'

    POSTS_INDEX
      key: 'posts_index'

    DIV
      className: 'scrollable' # used for finding scroll parent when seeking
                              # to a post after page load
      key: 'scrollable_container'
      ref: 'scrollable_container'
      style: 
        flex: 1
        WebkitFlex: 1
        #overflowX: 'hidden'
        overflowY: 'auto'
        position: 'relative'
        height: WINDOW_HEIGHT() - fetch('masthead_height').height
        marginLeft: 10

      DIV 
        key: 'help'
        style: 
          paddingBottom: 40
          marginTop: 15

        NEW_POST 
          key: 'start_new_thread'
          placeholder: 'What are you thinking about?'
          min_height: 60
          show_border: true
        
        DIV 
          key: 'help'
          style: 
            marginTop: 20
            fontWeight: 300
            marginLeft: 115

          'Select text to express what you think or feel about it. '
          A 
            key: 'learn_more'
            target: '_blanklank'
            href: 'http://slider.chat/instructions'
            style: 
              textDecoration: 'underline'
            'Learn more'
          '.'

      DIV 
        ref: 'posts_area'

        for post,idx in posts
          if idx > @local.items_to_render
            break 
          else
            THREAD 
              post: post
              key: (post.key or post)


dom.POSTS.refresh = ->
  if !@local.bound_scroll? && @getDOMNode()
    @local.bound_scroll = true 
    @local.last_scroll_y = 0
    @local.ticking = false

    handle_scroll = => 
      items_height = @refs.posts_area.getDOMNode().offsetHeight
      el_height = items_height - window.innerHeight
      scroll_percent = @local.last_scroll_y / el_height

      if scroll_percent > 0.9

        @local.items_to_render += 5
        save @local

      @local.ticking = false

    @getDOMNode().addEventListener 'scroll', (e) =>
      @local.last_scroll_y = @refs.scrollable_container.getDOMNode().scrollTop
      if !@local.ticking
        setTimeout => 
          handle_scroll()
        , 100

      @local.ticking = true
    , true 


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
        post: fetch(child)
        key: (child.key or child)
        bgcolor: if idx % 2 == 0 then '#E9E9E9'
        last: idx == pst.children.length - 1

    NEW_POST 
      key: "new_post_#{@props.post.key}"
      placeholder: 'Add to this conversation!'
      min_height: 32
      parent: @props.post

##########
# Post
##########

post_avatar_size = 57
body_gutter = 24

dom.POST = -> 
  pst = fetch(@props.post.key)
  pst.selections ||= []
  local_pst = fetch(shared_local_key(pst))

  id = @props.post.key.split('/')[2]

  author = if pst.user then fetch(pst.user).name else 'Anonymous'
  bgcolor = if @local.editing_post 
              "#E4F2FF"
            else 
              @props.bgcolor || index_bg  #'white' # 

  @drawShareableUrl = => 
    DIV 
      style:    
        paddingTop: post_avatar_size / 2 - 5
        width: body_gutter
        textAlign: 'center'
        height: 15
      onClick: => 
        if !@suppress_click
          @local.show_shareable_link = !@local.show_shareable_link
          save @local

      IMG
        src: 'https://dl.dropboxusercontent.com/u/3403211/link.png'
        onMouseEnter: => @local.hover_link = true; save @local
        onMouseLeave: => @local.hover_link = false; save @local
        style:
          height: 10
          width: 10
          cursor: 'pointer'
          opacity: if !@local.show_shareable_link && !@local.hover_link then .15

      if @local.show_shareable_link
        path = window.location.pathname.split('/')
        path = path[path.length - 1]
        path = path.replace(/\/Statebus$/, '/statebus')
        link = "http://slider.chat/#{path}##{id}"
        INPUT 
          ref: 'shareable_link'
          style: 
            position: 'absolute'
            top: -30
            left: 0
            backgroundColor: 'white'
            width: sizeWhenRendered(link).width
          onBlur: (e) =>
            @local.show_shareable_link = false
            save @local 
            @suppress_click = true
            setTimeout (=> @suppress_click = false), 100
          onClick: (e) -> e.stopPropagation()
          value: link

  @drawEditPost = => 
    if !@height 
      @height = @refs.div.getDOMNode().clientHeight

    GROWING_TEXTAREA
      ref: 'editor'
      defaultValue: pst.body

      initial_height: @height
      style:
        #padding: "0px 10px 20px 10px"
        padding: 0
        margin: 0
        width: '100%'
        backgroundColor: bgcolor
        minHeight: 30
        fontSize: 16
        border: 'none' #'1px #888'   
        outline: 'none'       

      # enable updating anchor text of sliders given an edit
      onSelect: (e) => 
        @last_selection = [@refs.editor.getDOMNode().selectionStart, \
                           @refs.editor.getDOMNode().selectionEnd]

      onChange: (e) => 

        # For some reason, the very first time contenteditable is clicked 
        # after page load, the select event isn't fired. Observed on Chrome.
        @last_selection ||= [@refs.editor.getDOMNode().selectionStart, \
                             @refs.editor.getDOMNode().selectionEnd]

        old_text = pst.body
        new_text = protect_leading_new_line e.target.value

        update_selection_anchors(pst, old_text, new_text, \
                           @last_selection[0], @last_selection[1])

        pst.body = new_text
        save(pst)

        local_pst.slider_positions_dirty = true
        save local_pst

      onBlur: =>
        if pst.body == '' || !pst.body
          delete_post(pst)
        @local.editing_post = false; save(@local)


  mouseup = (e) => 
    sel = window.getSelection()
    # if there's a text selection, add a new selection w/ a new slider
    if !sel.isCollapsed
      e.stopPropagation()
      e.preventDefault()

      create_selection
        pst: pst
        el_with_selection: @refs.div.getDOMNode()

      local_pst.slider_positions_dirty = true
      save local_pst


    # otherwise enter editing mode
    # else if !slidergram_being_configured()
    #   @local.editing_post = true
    #   pos = get_selected_text @refs.div.getDOMNode()
    #   start = pos?.start or 0
    #   @local.editing_position = start
    #   save @local

    unregister_window_event pst

  dblclick = (e) => 
    # enter editing mode

    if slidergram_being_configured()
      done_configuring_slidergram()

    @local.editing_post = true
    pos = get_selected_text @refs.div.getDOMNode()
    start = pos?.start or 0
    @local.editing_position = start
    save @local  

  slidergrams = (pst.selections || [])
  has_active_slidergram = slidergram_being_configured() && \
     fetch(slidergram_being_configured().sel).post == pst.key

  if has_active_slidergram

    slidergrams = slidergrams.slice()
    slidergrams.push slidergram_being_configured().sel

  DIV 
    className: 'flex'
    style: 
      position: 'relative'
      zIndex: if has_active_slidergram then 1 else 0

    # scroll anchor
    A 
      name: id
      style: 
        position: 'relative'

    @drawShareableUrl()

    AVATAR
      user: pst.user
      style: 
        width: post_avatar_size
        height: post_avatar_size
        display: 'inline-block'
        position: 'relative'
        top: 0 #4

    DIV 
      ref: 'post_body'    
      style:
        flex: 1
        WebkitFlex: 1
        marginLeft: 18
        position: 'relative'
        fontFamily: if pst.monospaced then 'monaco,Consolas,"Lucida Console",monospace'
        fontSize: if pst.monospaced then 12


      DIV
        style:
          border: '1px transparent' #parity with text area
          padding: "14px 14px"
          borderRadius: if @props.first && @props.last then 16 \
                        else if @props.first then '16px 16px 0 0' \
                        else if @props.last then '0 0 16px 16px'
          boxSizing: 'border-box'
          backgroundColor: bgcolor
          width: 600
          minHeight: post_avatar_size
          position: 'relative' 
                        # positioning is to force Chrome to confine text
                        # selections to within the element. 
                        # http://stackoverflow.com/questions/14017818

        onMouseDown: (e) => 
          if !@local.editing_post
            register_window_event pst, 'click', mouseup

        onDoubleClick: if !@local.editing_post then dblclick


        DIV 
          style: 
            transform: "rotate(270deg) scaleX(-1)"
            WebkitTransform: "rotate(270deg) scaleX(-1)"
            position: 'absolute'
            left: -15
            top: 20

          Bubblemouth 
            apex_xfrac: 0
            width: 20
            height: 15
            fill: bgcolor
            stroke_width: 0

        if @local.editing_post
          @drawEditPost()
        else
          DIV ref: 'div',
            markup_text(pst.body)

      for sel in slidergrams

        SELECTION 
          key: sel.key or sel
          sel: sel 




dom.POST.refresh = ->
  pst = fetch(@props.post.key)

  # # for force-updating the slidergram positioning
  # if !@repositioned
  #   @repositioned = true
  #   setTimeout => 
  #     position_slidergrams(@refs.div.getDOMNode(), pst)
  #   , 4000

  if @local.editing_post
    if @local.editing_position
      # Focus the text area if we just clicked into the editor      
      # use select(), not focus(), because this averts the browser from 
      # automatically scrolling the page to the top of the text area, 
      # which interferes with clicking inside a long post to start editing
      @refs.editor.getDOMNode().select()
      cursor_pos = @local.editing_position
      @refs.editor.getDOMNode().setSelectionRange(cursor_pos, cursor_pos)
      @local.editing_position = null
    else if @refs.editor.getDOMNode() != document.activeElement
      @refs.editor.getDOMNode().focus()
  else
    @height = null
    local_pst = fetch(shared_local_key(pst))

    # update slidergram positions if necessary. Usually happens as a consequence
    # of editing the post
    if local_pst.slider_positions_dirty 
      local_pst.slider_positions_dirty = false
      save local_pst
      position_slidergrams(@refs.div.getDOMNode(), pst)

    # If a slidergram is set to active, select the anchor text in this post
    if local_pst.active_selection?
      range = make_selection_range(@refs.div.getDOMNode(), local_pst.active_selection)
      
      if range
        selection = window.getSelection()
        selection.removeAllRanges()
        selection.addRange(range)

    if @local.show_shareable_link
      @refs.shareable_link.getDOMNode().focus()      
      @refs.shareable_link.getDOMNode().select()


dom.SELECTION = -> 
  sel = fetch @props.sel

  return SPAN null if !sel.sliders or sel.sliders.length == 0
  sldr = fetch sel.sliders[0]
  return SPAN null if @loading() 


  local_sldr = fetch(shared_local_key(sldr))
  is_being_configured = !!local_sldr.configuring


  style = 
    position: 'absolute'    
    top: @props.top || sel.top + 16 + 4
                                 # 16 is for height of line of text
                                 # 4 is for the space in the slidergram below
                                 #   the slider baseline.
    left: @props.left || 615
    zIndex: 1

  if is_being_configured 
    style = extend style, 
      left: local_sldr.configuring.left 
      top: local_sldr.configuring.top               

  DIV 
    'data-sldr': sldr.key
    style: style
    onClick: (e) => 
      # delete self on option-click
      if e.altKey
        done_creating_slidergram(sldr, true)

    onMouseEnter: if !local_sldr.editing_label then (e) => 
      local_pst = fetch(shared_local_key(sel.post))
      local_pst.active_selection = sel.key
      save local_pst

    onMouseLeave: if !is_being_configured && !local_sldr.editing_label then (e) => 
      # only remove if we haven't added ourselves
      local_pst = fetch(shared_local_key(sel.post))          
      local_pst.active_selection = null
      save local_pst
      window.getSelection().removeAllRanges()          


    if !is_being_configured

      SLIDERGRAM 
        key: sel.key or sel
        sldr: sldr
        height: SLIDERGRAM_HEIGHT
        width: SLIDERGRAM_WIDTH
        draw_label: SLIDER_LABEL

    else 

      has_dragged = sldr.values.length > 0
      has_labeled = sldr.poles?[1]?.length > 0

      DIV 
        style: 
          backgroundColor: 'white'
          boxShadow: '0 1px 2px rgba(0,0,0,.2)'
          borderRadius: 16
          border: "1px solid #{focus_blue}"
        
        DIV 
          style: 
            position: 'absolute'
            left: 50
            top: -16

          Bubblemouth 
            apex_xfrac: .25
            width: 24
            height: 16
            fill: focus_blue
            stroke_width: 0

        DIV 
          style: 
            textAlign: 'center'
            fontSize: 14
            color: 'white' 
            marginBottom: 12
            width: '100%'
            textAlign: 'center'
            borderRadius: '15px 15px 0 0'
            backgroundColor: focus_blue
            padding: '3px 30px'
          'Your reaction to these words'


        DIV 
          style: 
            margin: '0px 30px 8px 30px'

          SLIDERGRAM 
            key: sel.key or sel
            sldr: sldr
            height: SLIDERGRAM_HEIGHT
            width: SLIDERGRAM_WIDTH
            force_ghosting: true
            draw_label: SLIDER_LABEL


        DIV 
          style:
            padding: '0px 30px'


          DIV 
            style:
              fontSize: 10
              color: focus_blue #"#646464"
              #fontWeight: 300
              position: 'relative'

            SPAN 
              style: 
                position: 'relative'
                top: -8
                left: 16
                verticalAlign: 'top'
                visibility: if has_dragged then 'hidden'

              "set your overall sentiment"

            if has_dragged
              SPAN 
                style: 
                  position: 'relative'
                  top: 10
                  left: 49
                  display: 'inline-block'
                  width: 80
                  textAlign: 'center'
                  verticalAlign: 'top'
                  lineHeight: 1.2
                  visibility: if has_labeled then 'hidden'

                "specify a reaction (optional)"

          # instructions
          DIV 
            style: 
              fontSize: 12
              backgroundColor: 'rgba(255,255,255,.5)'
              lineHeight: 1.3
              marginTop: 24
              position: 'relative'
              marginBottom: 8
              textAlign: 'right'

            # SPAN 
            #   style: 
            #     textDecoration: 'underline'
            #     cursor: 'help'
            #     color: 'aaa'
            #     marginTop: 4
            #     display: 'inline-block'
            #   onMouseEnter: (e) -> 
            #     create_tooltip "Press Enter to save<br/>Press ESC to cancel", \
            #                    e.target 
            #   onMouseLeave: clear_tooltip

            #   'tips'

            SPAN 
              style: 
                color: '#aaa'
                display: 'inline-block'
                marginRight: 12
                padding: 4
                cursor: 'pointer'
              onMouseUp: -> done_creating_slidergram(sldr, true)

              'cancel'

            SPAN 
              style: 
                color: 'white' #'#414141'
                display: 'inline-block'
                padding: '4px 16px'
                backgroundColor: focus_blue #'#F3F3F3'
                borderRadius: 16
                cursor: if has_dragged then 'pointer'
                opacity: if !has_dragged then .3
                fontSize: 16

              onClick: -> 
                if sldr.values.length > 0
                  done_creating_slidergram(sldr)

              'done'


























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
                @local.hovering || @local.focused

  DIV null,


    GROWING_TEXTAREA
      onMouseEnter: => @local.hovering = true; save @local
      onMouseLeave: => @local.hovering = false; save @local
      onFocus: => @local.focused = true; save @local
      onBlur: => @local.focused = false; save @local

      key: 'growing'
      style:
        width: 600
        minHeight: @props.min_height
        maxHeight: 600
        padding: '4px 14px'
        fontSize: 16
        marginLeft: post_avatar_size + body_gutter + 18
        border:   if show_border
                    '1px solid #ccc'
                  else
                    '1px solid transparent'
      placeholder: @props.placeholder
      value: @local.new_post
      onChange: (e) => @local.new_post = e.target.value; save(@local)

    if @local.new_post?.length > 0
      BUTTON
        type: 'submit'
        style: 
          backgroundColor: '#F5F5F5'
          border: '1px solid #ccc'
          fontSize: 16
          padding: '4px 16px'
          borderRadius: 8
          verticalAlign: 'bottom'
          display: 'inline-block'
          marginLeft: 8
          cursor: 'pointer'



        onClick: (e) =>
          if @local.new_post
            @local.new_post = protect_leading_new_line(@local.new_post)

            new_post = 
              key: new_key('post')
              body: @local.new_post
              user: your_key()
              parent: @props.parent.key if @props.parent
              children: if !@props.parent then []
              channel: if !@props.parent then get_channel()
              edits: [{
                user: your_key(),
                time: (new Date()).getTime()
                }]

            save new_post

            @local.new_post = ''
            save(@local)

            things_seen = [new_post]

            # mark everything in this thread as seen
            if @props.parent 
              things_seen.push @props.parent
              for reply in (@props.parent.children or [])
                things_seen.push reply
            
            saw_thing things_seen

        'Send'

##########      
# Message Indexes
IDX = 
  #ACTIVITY: 1
  POST: 2 
  THREADS: 1
  #FACEPILES: 3

idx_item_style = 
  borderBottom: '1px solid #D6D8DA'
  borderTop: '1px solid #fff'
  borderRight: '1px solid #C6C8CA'            
  padding: '5px 10px'
  textDecoration: 'none'
  display: 'block'
  backgroundColor: index_bg
  overflow: 'hidden'
  color: 'inherit'
  cursor: 'pointer'

summary_style = 
  color: '#000'
  fontSize: 14
  verticalAlign: 'top'
  display: 'inline-block'
  width: 200
  overflow: 'hidden'
  lineHeight: 1.2  
  paddingLeft: 16

timestamp_style = 
  fontSize: 12
  color: '#999'
  #paddingTop: 4

dom.POSTS_INDEX = -> 
  indexing = fetch('indexing')
  indexing.method = 1 if !indexing.method?

  return SPAN null if indexing.method == 0

  if !@local.items_to_render?
    @local.items_to_render = 20

  recent = fetch_recent_activity()
  data = recent.posts or []

  indexing = fetch('indexing')

  # beat = fetch('per_thread_beat')
  w = 275

  DIV 
    style: 
      width: w
      overflowY: 'auto'

    # HEART_BEAT 
    #   public_key: 'per_thread_beat'
    #   interval: 3000

    DIV 
      ref: 'items'

      for thread, idx in data
        if idx > @local.items_to_render
          break 
        else 
          do (thread) => 
            THREAD_ITEM
              key: thread.posts[0].post.key
              thread: thread 

    DIV style: {height: 34} #dummy placeholder to fill up space otherwise 
                            #occupied by the fixed index footer 
    DIV 
      style: 
        position: 'fixed'
        bottom: 0
        width: w
        backgroundColor: '#CACCCE'
        padding: '6px 8px'
        borderTop: "1px solid #C6C8CA"
        zIndex: 10

      A 
        style: 
          color: attention_magenta
          textDecoration: 'underline'
          cursor: 'pointer'

        onClick: ->
          recent = fetch_recent_activity()
          saw_thing (k for k,v of recent.unseen)

        'Mark all seen'

      DIV 
        style: 
          display: 'inline-block'
          verticalAlign: 'top'
          marginLeft: 12
          cursor: 'pointer'
          position: 'relative'
        onMouseEnter: => @local.hover_sort = true; save(@local)
        onMouseLeave: => @local.hover_sort = false; save(@local)
        
        SPAN 
          style: 
            color: '#5a5a5a'
          'Sort'

        SPAN 
          style: cssTriangle 'bottom', '#666', 8, 4,
            verticalAlign: 'bottom'
            position: 'relative'
            top: 16
            left: 4

        if @local.hover_sort
          SPAN 
            style: 
              position: 'absolute'
              bottom: 20
              width: 200
              backgroundColor: 'white'
              lineHeight: 1.2
              padding: 6
              left: 0
              fontSize: 10
              border: '1px solid black'


            """Not implemented. Sort by latest activity, thread created
               at, first poster, most replies, ..."""

      DIV 
        style: 
          display: 'inline-block'
          verticalAlign: 'top'
          marginLeft: 12
          cursor: 'pointer'
          position: 'relative'
        onMouseEnter: => @local.hover_filter = true; save(@local)
        onMouseLeave: => @local.hover_filter = false; save(@local)
        
        SPAN 
          style: 
            color: '#5a5a5a'
          'Filter'

        SPAN 
          style: cssTriangle 'bottom', '#666', 8, 4,
            verticalAlign: 'bottom'
            position: 'relative'
            top: 16
            left: 4

        if @local.hover_filter
          SPAN 
            style: 
              position: 'absolute'
              bottom: 20
              width: 200
              backgroundColor: 'white'
              lineHeight: 1.2
              padding: 6
              left: 0
              fontSize: 10
              border: '1px solid black'

            """Not implemented. Filter to threads you've participated 
               in (or haven't yet), threads you've started, threads 
               you've posted in, threads with unseen activity..."""

dom.POSTS_INDEX.refresh = ->
  if !@local.bound_scroll? && @getDOMNode()
    @local.bound_scroll = true 
    @local.last_scroll_y = 0
    @local.ticking = false

    handle_scroll = => 
      items_height = @refs.items.getDOMNode().offsetHeight
      el_height = items_height - window.innerHeight
      scroll_percent = @local.last_scroll_y / el_height
      if scroll_percent > 0.9
        @local.items_to_render += 10
        save @local

      @local.ticking = false

    @getDOMNode().addEventListener 'scroll', (e) =>
      @local.last_scroll_y = @getDOMNode().scrollTop
      if !@local.ticking
        setTimeout => 
          handle_scroll()
        , 100

      @local.ticking = true
    , true 

push_hash = (pst) -> 
  if history && history.pushState
    history.pushState(null, null, \
      """#{window.location.pathname}
         #{window.location.search}
         ##{pst.key.split('/')[2]}""")

dom.THREAD_ITEM = -> 
  thread = @props.thread
  ts = relative_time(thread.last_activity)

  speakers = (p.post.user for p in thread.posts)
  pst_head = fetch thread.posts[0].post
  avatar_size = 25
  dot_size = 8
  thread_id = pst_head.key

  expanded = @local.expanded == thread_id

  A 
    style: extend {}, idx_item_style, 
      width: 275
      backgroundColor: if expanded
                         '#EAECEE' 
                       else 
                         idx_item_style.backgroundColor
      borderTopColor: if expanded then '#EAECEE' else 'white'

    onClick: => 
      @local.expanded = if expanded then null else thread_id
      save @local

      if @local.expanded == thread_id
        loc = fetch 'location'
        loc.seek_to_hash = pst_head.key.split('/')[2]        
        save loc
        push_hash pst_head

    DIV null,
      UL 
        style:
          listStyle: 'none'
          padding: 0
          margin: 0

        for pst,idx in thread.posts
          continue if idx > 0 && !expanded
          chld = fetch pst.post
          summary = summarize chld, 55

          LI 
            style:
              paddingLeft: 0
              paddingTop: 4
              paddingBottom: if idx < thread.posts.length - 1 then 4
              position: 'relative'

            if !expanded
              faces = (fetch(p.post).user for p in thread.posts)
              faces.reverse()
              FACEPILE
                users: faces
                offsetY: 0
                offsetX: 1
                avatar_style: 
                  width: avatar_size
                  height: avatar_size
                  #borderRadius: '50%'
                  backgroundColor: 'white'

            else 
              AVATAR
                user: chld.user
                style: 
                  display: 'inline-block'
                  width: avatar_size
                  height: avatar_size
                  verticalAlign: 'top'
                  #borderRadius: '50%'
                  backgroundColor: 'white'                  

            if (!expanded && !thread.seen_all_posts) || \
               (expanded && !pst.seen)
              DIV 
                style: 
                  backgroundColor: '#F0049C'
                  position: 'absolute'
                  left: avatar_size - dot_size / 2
                  top: avatar_size / 2 - dot_size / 2 + 2
                  zIndex: 1
                  borderRadius: '50%'
                  width: dot_size
                  height: dot_size

            DIV 
              style: extend {}, summary_style, 
                width: 200
                zIndex: 1

              SPAN
                style: 
                  textDecoration: if @local.hovering == pst.post then 'underline'
                onMouseEnter: if expanded then do (pst) => (ev) => 
                  @local.hovering = pst.post; save(@local)
                onMouseLeave: if expanded then do (pst) => (ev) => 
                  @local.hovering = null; save(@local)

                onClick: do (pst) => (ev) => 
                  if @local.hovering
                    
                    push_hash fetch pst.post 

                    loc = fetch 'location'
                    loc.seek_to_hash = pst.post.split('/')[2]        
                    save loc
                    saw_thing(pst.post)
                    ev.stopPropagation()

                summary

              if !expanded 
                DIV 
                  style: extend {}, timestamp_style,
                    paddingTop: 4

                  ts                
            DIV 
              style: 
                #width: 20
                display: 'inline-block'
                position: 'relative'

              if (!expanded && !thread.seen_all_listens) || \
                 (expanded && !pst.seen_all_listens)

                console.log {thread, pst}
                DIV 
                  style: 
                    backgroundColor: '#F0049C'
                    position: 'absolute'
                    left: -2 - dot_size/2
                    top: avatar_size / 2 - dot_size / 2
                    zIndex: 1
                    borderRadius: '50%'
                    width: dot_size
                    height: dot_size

              do =>
                faces = (s.user for s in (if expanded then pst else thread).slides)
                faces.reverse()
                FACEPILE
                  users: faces
                  offsetY: 0
                  offsetX: -1
                  avatar_style: 
                    width: avatar_size
                    height: avatar_size
                    borderRadius: '50%'
                    backgroundColor: 'white'

      if expanded 
        DIV 
          style: extend {}, timestamp_style,
            marginLeft: avatar_size + summary_style.paddingLeft
            lineHeight: 1.2
            paddingBottom: 4
            position: 'relative'
            top: 4


          if thread.posts.length > 1 || thread.slides.length > 0
            relative_time_range(thread.first_activity, thread.last_activity)
          else 
            ts

          if !thread.seen_all_posts || !thread.seen_all_listens
            SPAN 
              style: 
                color: attention_magenta
                textDecoration: 'underline'
                marginLeft: 14
                display: 'inline-block'
              onClick: do (thread) -> (e) ->
                saw_thing (p.post for p in thread.posts)
                e.stopPropagation()
              'Seen'

relative_time_range = (start, end) -> 
  srt = relative_time(start)
  ert = relative_time(end)

  [sd,st] = srt.split(',')
  [ed,et] = ert.split(',')

  same_day = sd == ed 

  if same_day 
    "#{ed}: #{st} - #{et}"
  else 
    "#{sd} - #{ed},#{et}"

activity_key = (obj) -> "_#{cache(obj).key}"

# start the reporter! Will let the server know when user 
# sees stuff. 
setTimeout -> report_seen get_channel()


# saw_thing = (things_i_saw) -> 

#   save 
#     key: "/seen/#{JSON.stringify({user:your_key(), channel:get_channel()})}"
#     saw: (fetch(obj).key for obj in things_i_saw)

# saw_thing = (obj) ->
#   save 
#     key: "/seen/#{JSON.stringify({user:your_key(), channel:get_channel()})}"
#     saw: fetch(obj).key


window.unseen = (channel) -> 
  recent = fetch_recent_activity(channel)
  recent.unseen




create_selection = (args) -> 
  pst = args.pst

  text_sel = get_selected_text(args.el_with_selection)
  return if !text_sel


  # create the new slider
  selection =
    key: new_key 'selection'
    post: pst.key
    start: text_sel.start
    end: text_sel.end
    anchor_text: text_sel.selection
    sliders: []
  save selection

  slidergram = create_slidergram 
    anchor: selection 

  save slidergram

  bounds = args.el_with_selection.getBoundingClientRect()
  
  sel = document.getSelection()
  range = sel.getRangeAt(0)
  locs = range.getClientRects()
  last_line = locs[locs.length - 1]
  
  start_configuring_slidergram
    sel: selection.key
    sldr: slidergram.key
    left: (last_line?.right or mouseX) - bounds.left - 50
    top: (last_line?.bottom or mousey) + 34 - bounds.top
    is_new: true

  # Catch the mouse cursor immediately to configure the slider position
  # start_slider_mouse_tracking
  #   sldr: slidergram
  #   initial_val: DEFAULT_SLIDER_VAL



####
# (new) slidergram configuration
#
# When a slidergram is being configured, particularly a new slidergram, 
# we need to globally track this slidergram. However, having a single
# local statebus key for the value introduces too much performance 
# overhead because of the number of components that would be subscribed
# to it. These methods help track the configured slider state via window
# and shared state around the particular slidergram.  
#
slidergram_being_configured = -> window.configuring_slider

start_configuring_slidergram = (args) -> 
  if args.sldr.key? 
    args.sldr = args.sldr.key 

  sldr = args.sldr
  if slidergram_being_configured()
    done_configuring_slidergram()
  local_sldr = fetch shared_local_key(sldr)
  local_sldr.configuring = args 
  local_sldr.is_new = !!args.is_new
  save local_sldr

  window.configuring_slider = args #sldr

  # If a click bubbles all the way up to the top, that means the
  # user clicked outside of the current slidergram
  register_window_event 'slider_config', 'mouseup', (e) -> 

    click_inside_slidergram = closest e.target, (node) -> 
      node.getAttribute('data-sldr') == sldr

    if !click_inside_slidergram
      done_creating_slidergram(sldr)  
  , -1

  # If an ENTER or ESC keypress bubbles up...
  register_window_event 'slider_config', 'keyup', (e) => 
    key = (e and e.keyCode) or e.keyCode

    # Enter finishes slidergram configuration
    # Esc key finishes configuration, and cancels changes
    if key in [27, 13]
      remove_self = key == 27
      done_creating_slidergram(sldr, remove_self)

done_configuring_slidergram = -> 

  if slidergram_being_configured()
    unregister_window_event('slider_config')
    local_sldr = fetch shared_local_key(window.configuring_slider.sldr)
    local_sldr.configuring = null 
    local_sldr.is_new = null
    local_sldr.editing_label = false
    unregister_window_event "#{local_sldr.key}-label"
    save local_sldr
    window.configuring_slider = null

# TODO: this can probably be merged with done_configuring_slidergram()
done_creating_slidergram = (sldr, remove) ->
  sldr = fetch sldr 
  sel = fetch(sldr.selection or sldr.anchor)
  pst = fetch sel.post
  local_pst = fetch(shared_local_key(pst))

  done_configuring_slidergram()

  if remove 
    remove_self_from_slider(sldr)
    local_sldr = fetch(shared_local_key(sldr))
    local_sldr.dirty_opinions = true
    save local_sldr

  else 
    local_pst.slider_positions_dirty = true
    pst.selections ||= []
    pst.selections.push sel.key
    pst.channel = get_channel()
    save pst

  delete_slider_if_no_activity(sldr)

  local_pst.active_selection = null
  save local_pst

  clear_tooltip()


################
# DOM traversals
################

# Gets the start/end position of the current text selection inside of 
# a parent node. Currently used by Post to determine (1) the cursor location for 
# transitioning into edit mode and (2) anchor text for a new slidergram
get_selected_text = (parent_node) -> 
  sel = window.getSelection()

  # do a depth-first traversal from the parent node so that we can get
  # the absolute start/end position of the selection within the parent node
  anchor_pos = sel.anchorOffset
  focus_pos = sel.focusOffset

  anchor_node_found = false
  focus_node_found = false

  traverse = (node) ->
    return if anchor_node_found && focus_node_found
    
    # Look to see if the selection is part of this text node
    if node.nodeType == 3 || node.textContent == '\n'
                             # for when a post ends with a newline, and the 
                             # user clicks the end to start editing. Don't 
                             # know if this OR causes a problem in other
                             # situations

      len = node.textContent.length

      if !anchor_node_found
        if node == sel.anchorNode
          anchor_node_found = true
        else 
          anchor_pos += len

      if !focus_node_found
        if node == sel.focusNode
          focus_node_found = true
        else 
          focus_pos += len
    else
      for child in node.childNodes
        traverse(child)

  traverse parent_node

  # degenerate case where the selection spans more than just the parent_node
  if !(focus_node_found && anchor_node_found)
    console.error("Selection spans multiple posts")
    return null

  {
    selection: sel.toString()
    start: if focus_pos > anchor_pos then anchor_pos else focus_pos
    end: if focus_pos <= anchor_pos then anchor_pos else focus_pos
  }

# Finds the text nodes and offsets (with respect to parent) of a selection
get_selection_dom_info = (parent_node, selection) -> 
  selection = fetch selection

  # Degenerate case where the selected area spans beyond the parent node.
  # Ideally the system would prevent selections that span across the 
  # parent node (i.e. a post)
  if selection.end > parent_node.textContent.length 
    selection.end = parent_node.textContent.length
    console.error("""Degenerate case where the selected area spans beyond 
                     the parent node, for selection #{selection.key}. 
                     Truncating selection to 
                     (#{selection.start}-#{selection.end})""")
    save selection

  start = selection.start
  end = selection.end

  start_node = null
  start_offset = null

  end_node = null
  end_offset = null

  cur_location = 0

  # Recurse in the DOM tree for the associated post to identify the start 
  # and end nodes that we'll use to create the range
  traverse = (node) ->
    return if start_node && end_node
    
    # Look to see if the selection is part of this text node
    if node.nodeType == 3
      len = node.textContent.length
      if cur_location <= start && cur_location + len > start
        start_node = node
        start_offset = start - cur_location
      if cur_location <= end && cur_location + len >= end
        end_node = node
        end_offset = end - cur_location
      cur_location += len
    else if node.nodeType != 3
      for child in node.childNodes
        traverse(child)

  traverse parent_node

  # Special case where the end is just an empty line, which can't be selected.
  # In this case, find the previous text node. 
  if end_node && end_node.textContent == '\n' 
    prev_node = end_node.previousSibling
    if !prev_node   
      prev_node = end_node.parentNode       
      while true
        if prev_node.previousSibling?.lastChild
          prev_node = prev_node.previousSibling?.lastChild
          break
        else 
          prev_node = prev_node.parentNode
    end_node = prev_node

  {start_node, start_offset, end_node, end_offset}


get_selection_target_position = (parent_node, selection) -> 
  sel = fetch selection
  info = get_selection_dom_info(parent_node, selection)
  range = document.createRange()

  return 0 if !info.end_node

  range.selectNodeContents(info.end_node)
  rects = range.getClientRects()

  # if the end node is empty, we can't get a range on it, so we'll just 
  # use the start node instead. 
  if !rects? || rects.length == 0 
    info.end_node
    range.selectNodeContents(info.start_node)
    rects = range.getClientRects()

  if rects?.length > 0

    # rects is list of bounding boxes for the selection. This corresponds 
    # to each line. So in order to get the proper position, we estimate
    # which line the selection's endpoint resides in, and use that 
    # bounding box to set the slidergram's targeted position
    line = Math.floor(rects.length * info.end_offset / info.end_node.textContent.length)
    line = Math.max 0, line
    line = Math.min line, rects.length - 1

    # the target position needs to be adjusted by its position in the 
    # parent node
    el = parent_node
    parent_offset = 0
    while el && !isNaN(el.offsetTop) 
      parent_offset += el.offsetTop - el.scrollTop
      el = el.offsetParent

    line_height_offset = 30
    target = rects[line].top - parent_offset - line_height_offset 

    target

  else 
    0


# Creates a range (https://developer.mozilla.org/en-US/docs/Web/API/Range)
# that represents the original anchor text for a Selection.
make_selection_range = (parent_node, selection) -> 
  info = get_selection_dom_info(parent_node, selection)
  if info.start_node && info.end_node
    range = document.createRange()
    range.setStart info.start_node, info.start_offset
    range.setEnd info.end_node, info.end_offset
    range
  else 
    null


# Given an edit to a post, updates the start/end positions of the slidergrams
# anchored to its text. Handles insertions, deletions, pastes, undos etc. 
#
# Rules:
#   - An insertion beginning before a slidergram's anchor text is not 
#     incorporated into the selection. If text is selected that spans the
#     start of the anchor text, the overlapping text is removed from the 
#     slidergram's anchor text. 
#   - An insertion at the end position of a slidergram's anchor text is 
#     incorporated into the selection.
update_selection_anchors = (pst, old_text, new_text, cursor_start, cursor_end) -> 
  pst = fetch pst
  to_orphan = []
  for sel in (pst.selections || [])
    sel = fetch(sel)

    replaced_text_length = cursor_end - cursor_start
    inserted_text_length = new_text.length - old_text.length + replaced_text_length

    # when the editing anchor is before the slidergram's start anchor
    if cursor_start <= sel.start 

      # edit took place entirely before this slidergram
      if cursor_end <= sel.start
        sel.start += inserted_text_length - replaced_text_length
        sel.end   += inserted_text_length - replaced_text_length

      # edit spans start of slidergram's anchor text
      else if cursor_end < sel.end
        sel.start = cursor_end + (inserted_text_length - replaced_text_length)
        sel.end += inserted_text_length - replaced_text_length

      # edit completely wiped out this slidergram. orphan it for now. 
      else if cursor_end >= sel.end
        to_orphan.push sel

    # when the editing anchor begins inside the slidergram's selection
    else if cursor_start < sel.end

      # if the end of the selection spans the end of the selection's 
      # anchor end, we only account for replacing the amount of
      # selection text that is contained in the anchor text
      if cursor_end > sel.end
        replaced_text_length = sel.end - cursor_start
                      
      sel.end += inserted_text_length - replaced_text_length

    save sel

  # remove selections outside the loop because pst.selections gets
  # modified in the orphaning process
  for sel in to_orphan
    orphan_selection sel

# Checks this node and ancestors whether check holds true
closest = (node, check) -> 
  if !node || node == document
    false
  else 
    check(node) || closest(node.parentNode, check)


#####
# Calculate the Y-positions of all a post's slidergrams
# Uses cassowary constraint solver.
# Returns a mapping of selection key => Y-pos
#
position_slidergrams = (parent_node, pst) -> 
  debug = false

  pst = fetch pst

  return if !pst.selections || pst.selections.length == 0

  # Calculate the target positions of all
  # Note that we might want to compute/cache this calculation if it becomes too
  # computationally expensive
  y_target = {}  
  all_fetched = true
  for sel in pst.selections
    sel = fetch(sel)
    all_fetched = all_fetched && sel.start?
    y_target[sel.key] = get_selection_target_position(parent_node, sel)
  return if !all_fetched

  # cassowary constraint solver
  c = cassowary
  solver = new cassowary.SimplexSolver()

  # Stores the variables representing each slidergram's y-position 
  # that cassowary will optimize. 
  y_pos = {}
  for sel in pst.selections     
    y_pos[sel] = new c.Variable

  sorted = ([k,v] for own k,v of y_target)
  sorted = sorted.sort (a,b) -> a[1] - b[1]

  ########
  # Linear constraints
  #
  # Set the constraints for the y-position of each docked component. 
  #
  # TARGET (strength = strong)
  # The slidergram will hopefully be placed at its optimal location. 
  #        y(t) = start
  #
  # RELATIONAL
  # Add any declared constraints between different docks, constraining
  # the one higher in the stacking order to always be above and non-overlapping 
  # the one lower in the stacking order, preferring them to be right up against
  # each other.
  #        y1(t) + height <= y2(t)   (required)
  #        y1(t) + height  = y2(t)   (strong)
  # TODO: 
  #   - add strong constraint for staying within bounds of post
  #   - prefer above target to below target
  for slidergram, idx in sorted
    [k,target] = slidergram
    console.log "**#{k} constraints**" if debug

    # TARGET
    console.log "\tTARGET: #{k} == #{target}, strong" if debug
    solver.addConstraint new c.Equation \
      y_pos[k], target, c.Strength.strong

    if idx < sorted.length - 1
      [next_key, next_target] = sorted[idx + 1]
 
      console.log """\tRELATIONAL: 
                     #{next_key} >= #{k} + #{SLIDERGRAM_HEIGHT}""" if debug
      
      solver.addConstraint new c.Inequality \
                            y_pos[next_key], \
                            c.GEQ, \
                            c.plus(y_pos[k], SLIDERGRAM_HEIGHT), \
                            c.Strength.required

    # keep bounded by post
    if idx == 0 
      solver.addConstraint new c.Inequality \ 
                            y_pos[k],
                            c.GEQ, \
                            -50, \
                            c.Strength.strong
      console.log """\tBELOW TOP: 
                     #{k} >= -50""" if debug

    else if idx == sorted.length - 1
      solver.addConstraint new c.Inequality \ 
                            y_pos[k],
                            c.LEQ, \
                            parent_node.clientHeight, \
                            c.Strength.strong
      console.log """\tABOVE BOTTOM: 
                     #{k} <= #{parent_node.clientHeight}""" if debug

  solver.resolve()


  for own sel,v of y_pos    
    console.info "#{sel}: #{v.value}" if debug
    sel = cache sel
    if sel.top != v.value
      sel.top = v.value
      save sel






#########
# Masthead
#########
channel_url = (channel) -> 
  if channel == 'statebus' then channel = 'Statebus'
  if window.location.href.substring(0, 7) == 'file://'
    "#{window.location.pathname}?channel=#{channel}"
  else 
    "http://slider.chat/#{channel}"


dom.MASTHEAD = -> 
  indexing = fetch('indexing')
  showing_index = (indexing.method || 0) != 0
  tawking = fetch('tawking')

  tools = [
    {name: 'talkspace', url: 'http://192.241.208.34:3001/'},    
    {name: 'cheeseburger', url: 'http://cheeseburgertherapy.com'},        
    {name: 'considerit', url: 'https://consider.it'},
  ]

  channels = [
    {name: 'considerit'}, 
    {name: 'statebus'} ,
    {name: 'cheeseboard'} ,
    {name: 'talkspace'} ,
    {name: 'blogademia'} ,
    {name: 'invisible'} , 
    {name: 'instructions', invisibles: false},        
    {name: 'change log / report a bug', channel: 'slidebro_meta', invisibles: false}           
  ]

  not_invisibles = (c for c in channels when c.invisibles? && !c.invisibles)

  current_channel = get_channel()
  if current_channel == 'slidebro_meta'
    current_channel = 'change log / report a bug'

  unseen_messages = Object.keys((unseen() or {})).length
  DIV null, 

    if VERSION < fetch('/current_version').version
      DIV 
        key: 'new_version'
        style: 
          backgroundColor: attention_magenta
          padding: '6px 12px'
          fontSize: 18
          color: 'white'
          fontWeight: 600

        "New version available! Please refresh your browser."

    DIV 
      key: 'strip'
      style: 
        position: 'relative'
        padding: '4px 16px 4px 16px'
        borderBottom: '1px solid #ccc'
        zIndex: 10

      DIV 
        style: 
          position: 'absolute'
          right: 0

        WHO_IS_HERE
          show_auth: true



      # index button
      DIV 
        key: 'index'
        style: 
          backgroundColor: if showing_index then index_bg
          border: '1px solid #ccc'
          borderBottomColor: if showing_index then index_bg else '#ccc'
          borderRadius: if showing_index then '4px 4px 0 0'
          padding: 6
          display: 'inline-block'
          cursor: 'pointer'
          position: 'relative'
          top: 5
        onClick: -> 
          if showing_index 
            indexing.method = 0
          else 
            indexing.method = 1
          save indexing


        for i in [1,2,3,4]
          DIV 
            key: i
            style: 
              height: 3
              width: 30
              backgroundColor: '#ccc'
              borderRadius: 4
              marginBottom: if i != 4 then 3
        if unseen_messages > 0
          style = 
            fontWeight: 700
            fontSize: 18
          s = sizeWhenRendered "#{unseen_messages}", style
          DIV 
            key: 'unseen'
            style: extend style,
              position: 'absolute'
              left: (42 - s.width) / 2
              top: (33 - s.height) / 2
              color: attention_magenta
              zIndex: 1
            "#{unseen_messages}"


      # IMG
      #   src: 'https://dl.dropboxusercontent.com/u/3403211/logo.svg'
      #   style: 
      #     width: 115
      #     height: 35


      if current_channel in (c.name for c in channels) && \
         !(current_channel in (c.name for c in not_invisibles))
        DIV 
          style: 
            display: 'inline-block'
            verticalAlign: 'top'
            marginLeft: 12
            padding: 4
            fontSize: 18
            #borderRadius: 8
            #border: '1px solid #E6E6E6'
            cursor: 'pointer'
            position: 'relative'
            top: 9
          onMouseEnter: => @local.hover_channel = true; save(@local)
          onMouseLeave: => @local.hover_channel = false; save(@local)
          
          SPAN 
            style: 
              fontWeight: 700
              color: '#5a5a5a'
            current_channel

          SPAN 
            style: cssTriangle 'bottom', '#666', 8, 4,
              verticalAlign: 'bottom'
              position: 'relative'
              top: 16
              left: 4

          if @local.hover_channel
            items = []
            for c in channels when c.name != current_channel
              c.channel ||= c.name

              unseen_for_channel = unseen(c.channel)
              if unseen_for_channel

                unseen_messages = Object.keys(unseen_for_channel).length
                message_cnt = if unseen_messages > 0 then " +#{unseen_messages}" else ''
                c.name = "#{c.name}#{message_cnt}"
                c.url = channel_url c.channel
                items.push c

            if current_channel == 'considerit'

              items.push 
                name: 'hangout'
                url: 'https://hangouts.google.com/hangouts/_/yizytx6t2vhnzoogs3ric6fet4e?hl=en&hnc=0&authuser=0'

              items.push 
                name: 'sprint'
                url: '#ab7jxh9ekkaztpsexw29'

              items.push 
                name: 'backlog'
                url: 'https://considerit.us:3006/considerit'


            COLORED_LIST
              items: items
              top: 10


      BUTTON 
        style:
          backgroundColor: if tawking.on then 'magenta' else 'transparent'
          color: if tawking.on then 'white' else 'black'
          border: '1px solid #777'
          display: 'inline-block'
          marginLeft: 12
          verticalAlign: 'top'
          cursor: 'pointer'
        onClick: => tawking.on = !tawking.on; save tawking          
        'tawk'




dom.MASTHEAD.refresh = ->
  return if !@getDOMNode()
  m = fetch('masthead_height')
  h = @getDOMNode().offsetHeight
  if h && m.height != h
    m.height = h
    save m


#################
# GROWING_TEXTAREA
#################

# Auto growing text area. 
# Transfers props to a TEXTAREA.
dom.GROWING_TEXTAREA = ->
  @props.style ||= {}
  @props.style.minHeight ||= 60
  @props.style.height = \
      @local.height || @props.initial_height || @props.style.minHeight
  @props.style.fontFamily ||= 'inherit'
  @props.style.lineHeight ||= '22px'
  @props.style.resize ||= 'none'
  @props.style.outline ||= 'none'

  # save the supplied onChange function if the client supplies one
  _onChange = @props.onChange    

  @props.onClick = (ev) -> 
    ev.preventDefault(); ev.stopPropagation()

  @props.onChange = (ev) => 
    _onChange?(ev)  
    @adjustHeight()

  @adjustHeight = => 
    textarea = @getDOMNode()

    if !textarea.value || textarea.value == ''
      h = @props.initial_height || @props.style.minHeight

      if h != @local.height
        @local.height = h
        save @local
    else 
      min_height = @props.style.minHeight
      max_height = @props.style.maxHeight

      # Get the real scrollheight of the textarea
      h = textarea.style.height
      textarea.style.height = '' if @last_value?.length > textarea.value.length
      scroll_height = textarea.scrollHeight
      textarea.style.height = h  if @last_value?.length > textarea.value.length

      if scroll_height != textarea.clientHeight
        h = scroll_height + 5
        if max_height
          h = Math.min(scroll_height, max_height)
        h = Math.max(min_height, h)

        if h != @local.height
          @local.height = h
          save @local

    @last_value = textarea.value

  TEXTAREA @props

dom.GROWING_TEXTAREA.refresh = -> 
  @adjustHeight()



#################
# Misc components
#################

# HeartBeat
# Any component that renders a heartbeat will get rerendered on an interval.
# props: 
#   public_key: the key to store the heartbeat at
#   interval: length between pulses, in ms (default=1000)
dom.HEART_BEAT = ->   
  beat = fetch(@props.public_key)
  setTimeout ->    
    beat.beat = (beat.beat or 0) + 1
    save(beat)
  , (@props.interval or 1000)

  SPAN null

# ColoredList makes an inline list of links, with random background colors.
dom.COLORED_LIST = ->
  items = @props.items
  hues = getNiceRandomHues(items.length)

  UL 
    style: 
      position: 'absolute'
      top: @props.top || 10
      zIndex: 10
      listStyle: 'none'
      padding: 0

    for p, idx in items
      LI 
        style: 
          backgroundColor: hsv2rgb(hues[idx], \
                                  (@props.saturation || .6), \
                                  (@props.value || .7))
          display: 'block'
          whiteSpace: 'nowrap'
        A 
          href: if p.url then p.url
          style: 
            color: 'white' 
            padding: '3px 8px'
            display: 'block'
            textDecoration: 'none'
            textAlign: 'left'
            width: '100%'
          p.name

dom.COLORIZED_TEXT = ->
  t = @props.text
  hues = getNiceRandomHues(t.length)
  SPAN null, 
    for hue,idx in hues
      SPAN 
        style: 
          color: hsv2rgb(hue, (@props.saturation || .6), (@props.value || .6))
        t[idx]

dom.LOADING_POST = -> 
  loc = fetch 'location'

  # if loc.seek_to_hash
  #   el_present = !!document.querySelectorAll("[name='#{@props.name}']")

  if loc.seek_to_hash && !document.querySelectorAll("[name='#{loc.seek_to_hash}']")

    DIV 
      style: 
        position: 'absolute'
        top: 0
        left: 0
        width: WINDOW_WIDTH()
        height: WINDOW_HEIGHT()
        zIndex: 999
        backgroundColor: 'rgba(0,0,0,.5)'

      DIV 
        style: 
          position: 'relative'
          top: '40%'
          left: 150
          color: 'white'
          fontSize: 36
          fontWeight: 700
        "Chill out while we load post #{loc.seek_to_hash}"
  else 
    SPAN null

dom.DOCUMENT_TITLE = -> 
  unseen_messages = Object.keys(unseen()).length
  channel = get_channel()
  message_cnt = if unseen_messages > 0 then "+#{unseen_messages}" else ''
  title = "#{channel} #{message_cnt}"
  document.title = title 

  SPAN null


dom.SCROLL_ANCHOR_CONTROLLER = -> 
  loc = fetch 'location'
  SPAN null

dom.SCROLL_ANCHOR_CONTROLLER.refresh = -> 
  loc = fetch 'location'

  if loc.seek_to_hash
    scroll_to = ->

      scroll_node = document.querySelector("[name='#{loc.seek_to_hash}']")
      if scroll_node
        parent_node = scroll_node
        while parent_node.className != 'scrollable'
          parent_node = parent_node.parentNode

        parent_node.scrollTop = scroll_node.getBoundingClientRect().top \
                                - 100 + parent_node.scrollTop

        loc = fetch 'location'
        loc.seek_to_hash = null
        save loc

      else 
        setTimeout scroll_to, 50

    scroll_to()

######
# Draws a bubble mouth svg. 
# 
#           
#          p3
#         .  
#       /  \ 
#     (     \_
#     \       `\___
#  p1  `.          `- . p2
#
#       <-^----------->
#       apex =~ .15
#
# Props:
#  width: width of the element
#  height: height of the element
#  svg_w: controls the viewbox width
#  svg_h: controls the viewbox height
#  skew_x: the amount the mouth juts out to the side
#  skew_y: the focal location of the jut
#  apex_xfrac: see diagram. The percent between the p1 & p2 that p3 is. 
#  fill, stroke, stroke_width, dash_array, box_shadow

Bubblemouth = (props) -> 

  # width/height of bubblemouth in svg coordinate space
  defaults = 
    svg_w: 85
    svg_h: 100
    skew_x: 15
    skew_y: 80
    apex_xfrac: .5
    fill: 'white', 
    stroke: 'white', 
    stroke_width: 10
    dash_array: "none"   
    box_shadow: null

  for k,v of defaults 
    if !props[k]?
      props[k] = v

  full_width = props.svg_w + 4 * props.skew_x * Math.max(.5, Math.abs(.5 - props.apex_xfrac))

  if !props.width? 
    props.width = full_width
  if !props.height?
    props.height = props.svg_h

  apex = props.apex_xfrac
  svg_w = props.svg_w
  svg_h = props.svg_h
  skew_x = props.skew_x
  skew_y = props.skew_y

  cx = skew_x + svg_w / 2

  [x1, y1]   = [  skew_x - apex * skew_x,              svg_h ] 
  [x2, y2]   = [  skew_x + apex * svg_w,                   0 ]
  [x3, y3]   = [      x1 + svg_w + skew_x,             svg_h ]

  [qx1, qy1] = [ -skew_x + apex * ( cx + 2 * skew_x), skew_y ] 
  [qx2, qy2] = [  qx1 + cx,                           skew_y ]                           

  bubblemouth_path = """
    M  #{x1}  #{y1}
    Q #{qx1} #{qy1}
       #{x2}  #{y2}
    Q #{qx2} #{qy2}
       #{x3}  #{y3}
    
  """

  id = "x#{md5(JSON.stringify(props))}"

  SVG 
    version: "1.1" 
    xmlns: "http://www.w3.org/2000/svg"
    width: props.width
    height: props.height
    viewBox: "0 0 #{full_width} #{svg_h}"
    preserveAspectRatio: "none"
    style: if props.style then props.style

    DEFS null,

      # # enforces border drawn exclusively inside
      # CLIPPATH
      #   id: id
      #   PATH
      #     strokeWidth: props.stroke_width * 2
      #     d: bubblemouth_path

      # if props.box_shadow
      #   svg.dropShadow _.extend props.box_shadow, 
      #     id: "#{id}-shadow"

    if props.box_shadow
      # can't apply drop shadow to main path because of 
      # clip path. So we'll apply it to a copy. 
      PATH
        key: 'shadow'
        fill: props.fill
        style: 
          filter: "url(##{id}-shadow)"
        d: bubblemouth_path
        
    PATH
      key: 'stroke'
      fill: props.fill
      stroke: props.stroke
      strokeWidth: props.stroke_width * 2
      #clipPath: "url(##{id})"
      strokeDasharray: props.dash_array
      d: bubblemouth_path

#########
# Helpers
#########

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

# summarize takes a post and creates a summary of it. It ensures that the
#   - summary doesn't end in the middle of a word
#   - doesn't contain line breaks
summarize = (pst, max_len) -> 
  max_len ||= 50
  summary = pst.body.split('\n')[0]
  if summary.length > max_len
    summary = summary.substring(0,max_len).split(' ')
    summary.pop()
    summary = summary.join(' ') + '...'
  summary

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

hsv2rgb = (h,s,v) -> 
  h_i = Math.floor(h*6)
  f = h*6 - h_i
  p = v * (1 - s)
  q = v * (1 - f*s)
  t = v * (1 - (1 - f) * s)
  [r, g, b] = [v, t, p] if h_i==0
  [r, g, b] = [q, v, p] if h_i==1
  [r, g, b] = [p, v, t] if h_i==2
  [r, g, b] = [p, q, v] if h_i==3
  [r, g, b] = [t, p, v] if h_i==4
  [r, g, b] = [v, p, q] if h_i==5

  "rgb(#{Math.round(r*256)}, #{Math.round(g*256)}, #{Math.round(b*256)})"

# fixed saturation & brightness; random hue. adapted from 
# http://martin.ankerl.com/2009/12/09/how-to-create-random-colors-programmatically/
getNiceRandomHues = (num, seed) -> 
  golden_ratio_conjugate = 0.618033988749895
  h = seed or Math.random()
  hues = []
  i = num
  while i > 0
    hues.push h % 1
    h += golden_ratio_conjugate
    i -= 1
  hues

# Computes the width/height of some text given some styles
size_cache = {}
window.sizeWhenRendered = (str, style) -> 
  main = document.getElementById('main-content')

  return {width: 0, height: 0} if !main

  style ||= {}
  # This DOM manipulation is relatively expensive, so cache results
  style.str = str
  key = JSON.stringify style
  delete style.str

  if key not of size_cache
    style.display ||= 'inline-block'

    test = document.createElement("span")
    test.innerHTML = "<span>#{str}</span>"
    for k,v of style
      test.style[k] = v

    main.appendChild test 
    h = test.offsetHeight
    w = test.offsetWidth
    main.removeChild test

    size_cache[key] = 
      width: w
      height: h

  size_cache[key]

# Returns the style for a css triangle
cssTriangle = (direction, color, width, height, style) -> 
  style = style or {}

  switch direction
    when 'top'
      border_width = "0 #{width/2}px #{height}px #{width/2}px"
      border_color = "transparent transparent #{color} transparent"
    when 'bottom'
      border_width = "#{height}px #{width/2}px 0 #{width/2}px"
      border_color = "#{color} transparent transparent transparent"
    when 'left'
      border_width = "#{height/2}px #{width}px #{height/2}px 0"
      border_color = "transparent #{color} transparent transparent"
    when 'right'
      border_width = "#{height/2}px 0 #{height/2}px #{width}px"
      border_color = "transparent transparent transparent #{color}"

  style.width ||= 0
  style.height ||= 0
  style.borderStyle ||= 'solid'
  style.borderWidth ||= border_width
  style.borderColor ||= border_color

  style

window.extend = (obj) ->
  obj ||= {}
  for arg, idx in arguments 
    if idx > 0
      for own name,s of arg
        if !obj[name]? || obj[name] != s
          obj[name] = s
  obj

window.defaults = (obj) ->
  obj ||= {}
  for arg, idx in arguments by -1
    if idx > 0
      for own name,s of arg
        if !obj[name]?
          obj[name] = s
  obj


# check if the object is empty
is_empty = (obj) -> 
  for key of obj
    return false
  return true

# relative_time returns a human readable time that represents a given time 
# relative to now. 
relative_time = (time_since_1970) -> 
  now = new Date()
  yesterday = new Date(now.valueOf() - 1000*60*60*24)
  date = new Date()
  date.setTime(time_since_1970)

  is_today = date.toDateString() == now.toDateString()
  is_yesterday = date.toDateString() == yesterday.toDateString()

  time = """#{(date.getHours() % 12) or 12}:\
             #{if date.getMinutes() < 10 then '0' else ''}#{date.getMinutes()}
            #{if date.getHours() >= 12 then 'pm' else 'am'}
         """

  if is_today
    str = "Today, #{time}"
  else if is_yesterday
    str = "Yesterday, #{time}"
  else 
    str = "#{date.getMonth() + 1}/#{date.getDate()}/#{date.getFullYear() - 2000}, #{time}"

  str

# Gets the current caret position of a contenteditable div.
# Code adapted from http://stackoverflow.com/questions/4811822
# only part of it though...will need more code to handle some
# browsers
caret_pos = (el) -> 
  sel = window.getSelection()
  if sel.rangeCount > 0
    range = sel.getRangeAt(0)
    before_range = range.cloneRange()
    before_range.selectNodeContents(el)
    before_range.setEnd(range.endContainer, range.endOffset)
    offset = before_range.toString().length
  else 
    textRange = sel.createRange()
    before_range = doc.body.createTextRange()
    before_range.moveToElementText(element)
    before_range.setEndPoint("EndToEnd", textRange)
    offset = before_range.text.length
  offset

# Inserts a string at the current caret in a contenteditable div. Will
# replace any selected text. Assumes that the contenteditable div has 
# focus.
insert_str_at_caret = (el, str) -> 
  sel = window.getSelection()
  if sel.rangeCount > 0
    sel = window.getSelection()
    selected_length = sel.toString().length
    if sel.getRangeAt && sel.rangeCount
      range = sel.getRangeAt(0)
      range.deleteContents()
      range.insertNode( document.createTextNode(str) )
      range.collapse()
    else if document.selection && document.selection.createRange
      document.selection.createRange().text = str

    el.normalize()
  selected_length

# moves the caret to the given position in a contenteditable div. Currently
# assumes that the div only has one line...
set_caret_position = (el, pos) -> 
  range = document.createRange()
  sel = window.getSelection()

  range.setStart(el.childNodes[0], Math.min(pos, el.childNodes[0].length))
  range.collapse(true)  
  sel.removeAllRanges()
  sel.addRange(range)

# ensures that min <= val <= max
within = (val, min, max) ->
  Math.min(Math.max(val, min), max)

crossbrowserfy = (styles, property) ->
  prefixes = ['Webkit', 'ms', 'Moz']
  for pre in prefixes
    styles["#{pre}#{property.charAt(0).toUpperCase()}#{property.substr(1)}"]
  styles

##################
# Statebus helpers
##################

new_key = (type) ->
  '/' + type + '/' + Math.random().toString(36).substring(7)

shared_local_key = (key_or_object) -> 
  key = key_or_object.key || key_or_object
  if key[0] == '/'
    key = key.substring(1, key.length)
    "#{key}/shared"
  else 
    key

no_pending_fetches_for_posts_before = (pst) -> 
  email = fetch(messages_key())

  pending_before = false 
  for p in email.posts 
    if bus.pending_gets[p.key]?
      pending_before = true
      break
  
    found = p.key == pst.key

    if !found
      for c in p.children 
        if bus.pending_gets[c.key]
          pending_before = true 
          break 

        if c.key == pst.key 
          found = true
          break 

    break if found || pending_before

  !pending_before 

no_pending_fetches_for_posts = -> 
  empty = true 
  for k,v of bus.pending_gets
    if k.substring(0, 6) == '/post/' 
      empty = false
      break 
  empty

posts_in_cache = -> 
  cnt = 0 
  for k,v of bus.pending_gets
    if k.substring(0, 6) == '/post/'
      cnt += 1
  cnt

cache = (obj_or_key) ->
  bus.cache[(obj_or_key.key or obj_or_key)]

# removes all properties from object except 'key'
strip_obj = (obj) -> 
  for own k,v of obj 
    if k != 'key'
      delete obj[k]
  obj

# make sure that data is fetched from server before performing some action
# params.is_ready = function that determines whether the data is present.
# params.execute = function to run. Function will be passed the data.
# params.timeout = millisecs to wait for a fetch
# params.on_timeout = function to run if timeout
execute_when_fetched = (key, params) -> 
  data = fetch key
  if params.is_ready(data)
    params.execute(data)
  else
    if params.timeout?
      if params.timeout < 0
        params.on_timeout?()
        return
      else 
        params.timeout -= 100 

    setTimeout -> 
      execute_when_fetched(key, params)
    , 100


##############
# data helpers
##############

window.fetch_recent_activity = (channel) -> 
  channel ||= get_channel()
  fetch "/recent/#{JSON.stringify({user: your_key(), namespace: channel})}"

#your_key = -> fetch('/current_user').user

you = -> fetch(your_key())

get_your_slide = (sldr) =>
  sldr = fetch(sldr)

  you = your_key()
  your_slide = null
  for v in sldr.values
    if v?.user == you
      your_slide = v
      break
  your_slide

messages_key = (channel) -> 
  channel ||= get_channel()

  switch channel
    when 'cheeseboard'
      '/cheesemail'
    when 'considerit'
      '/email'
    else 
      "/#{channel}mail"

get_channel = -> 
  if !window.__channel
    # enable setting the channel with a ?channel= url param
    query = {}
    if location.search
      for q in location.search.substr(1).split('&')
        b = q.split('=')
        query[decodeURIComponent(b[0])] = decodeURIComponent(b[1] || '')

    if query.channel?
      channel = query.channel
    else 
      # fallback on the pathname to identify channel
      channel = location.pathname.split('/')
      channel = channel[channel.length - 1]
      channel = channel.replace(/Statebus$/, 'statebus')
    
    if channel in ['cheeseboard.html', 'cheeseboard', 'cheeseburger']
      channel = 'cheeseboard'
    else if channel.split('.').length > 1 || channel == 'slidebro' #|| channel == 'considerit1'
      # default to considerit dataset for all prototype files
      channel = 'considerit'
    window.__channel = channel

  window.__channel

get_post = (sldr) -> 
  sldr = fetch sldr 
  sel = fetch(sldr.selection or sldr.anchor)
  fetch( sel ).post

delete_post = (key_or_object) ->
  console.log 'DELETING ', (key_or_object.key or key_or_object)
  del key_or_object
  return 

  post = fetch(key_or_object)

  # channel is needed to delete stuff from the index
  if !post.channel && !post.parent
    post.channel = get_channel()
    save post 
    setTimeout -> 
      delete_post(key_or_object)
    , 100

  console.log 'deleting post', post.key


  # delete from root
  remove_from( post.key, get_channel() )

  for sel in (post.selections or [])
    delete_selection(sel)

  # delete children
  for pst in (post.children or [])
    delete_post(pst)

  # remove from parent
  if post.parent
    parent = fetch(post.parent)
    i = parent.children.indexOf(post)
    if i < 0
      i = parent.children.indexOf(post.key)

    if i > -1
      parent.children.splice(i, 1)
      save(parent)

  del(post)

delete_selection = (key_or_object) -> 
  sel = fetch(key_or_object)
  # console.log 'deleting selection', sel.key

  # delete sliders
  for sldr in (sel.sliders || [])
    del(fetch(sldr))

  orphan_selection sel
  del(sel)

orphan_selection = (key_or_object) -> 
  sel = fetch(key_or_object)
  # console.log 'orphaning selection', sel.key

  # delete from parent post
  parent = fetch(sel.post)
  i = parent.selections.indexOf(sel.key)
  if i > -1
    parent.selections.splice(i, 1)
    save(parent)


# Delete slider + selection if no one has made a slider drag
# BUG: if someone else has slid the slider, but that slide 
#      hasn't been synchronized to this client yet, the slider
#      might be erroneously deleted
delete_slider_if_no_activity = (sldr) -> 
  sldr = fetch sldr
  return if !(sldr.selection or sldr.anchor)

  sel = fetch(sldr.selection or sldr.anchor)

  for sldr in sel.sliders
    sldr = fetch sldr
    return if sldr.values.length > 0 #|| sldr.poles[1]?.length > 0

  delete_selection(sel)

# Remove current user from this slider, if they're on it
remove_self_from_slider = (sldr) -> 
  sldr = fetch sldr
  return if !(sldr.selection or sldr.anchor)

  you = your_key()
  for o, idx in sldr.values
    if o.user == you 
      sldr.values.splice(idx, 1)
      save sldr
      break

####
# moving posts around 

# makes a post available in multiple channels. It is the same post,
# so changes made to the post in one channel will propagate to others
window.cross_post = (key, destination_channel) -> 
  add_to_index(key, destination_channel)

# moves a post from one channel to another channel. 
window.move_to = (key, source_channel, destination_channel) ->
  add_to_index(key, destination_channel)
  remove_from(key, source_channel)  

# makes a copy of the post in another channel. Changes made to one 
# of the copies will not propagate to the other post. 
window.copy_to = (key, source_channel, destination_channel) ->
  # - duplicate post and all children and all selections and all sliders. 
  #   get new key for everything
  # - add post key into target message index
  console.log 'NOT IMPLEMENTED'

# adds a post to a channel
add_to_index = (key, channel) -> 
  pst = fetch(key)
  execute_when_fetched messages_key(channel),
    is_ready: (data) -> data.posts?
    execute: (index) -> 
      idx = index.posts.indexOf(pst)
      if idx == -1
        idx = index.posts.indexOf(key)
      if idx == -1
        index.posts.unshift pst
        save index

# removes a post from a channel
window.remove_from = (key, channel) -> 
  pst = fetch(key)

  execute_when_fetched messages_key(channel),
    is_ready: (data) -> data.posts?
    execute: (index) -> 
      idx = index.posts.indexOf(pst)
      if idx == -1
        idx = index.posts.indexOf(key)
      if idx > -1
        index.posts.splice idx, 1
        save index

# helper method for crossposting many messages
window.cross_posts = (urls, channel) -> 
  for url in urls
    cross_post "/post/#{url}", channel


#################
# Data migrations
#################

# force updates the avatar positions in histograms
window.refresh_avatar_positions = -> 
  for k,sl of bus.cache        
    if k.substring(0, 8) == '/slider/'
      local_sldr = fetch(shared_local_key(k))
      local_sldr.dirty_opinions = true
      save local_sldr

window.expand_posts = -> 
  email = fetch(messages_key())
  for post in email.posts 
    pst = fetch post
    pst.children = (fetch(c) for c in pst.children)
    pst.channel = get_channel()    
    save pst

window.expand_selections = -> 
  for k,v of bus.cache
    if k.substring(0, 11) == '/selection/'
      if v.sliders && v.sliders.length > 0 && !v.sliders[0].key
        console.log 'MIGRATING: ', v.sliders
        console.log "\t", (fetch(s) for s in v.sliders)
        v.sliders = (fetch(s) for s in v.sliders)
        save v

window.guess_timestamps = ->

  # estimate post edit time based on reply time 
  for k,v of bus.cache
    if k.substring(0, 6) == '/post/'
      if !v.edits?
        if v.children && v.children.length > 0
          chld = v.children[0]
          if chld.edits
            ts = chld.edits[0].time - 1000
            v.edits = [{
                time: ts 
                user: v.user
              }]
            save v
            console.log 'updated ts: ', v.key, ts

  # estimate post edit time based post made just after it, 
  # for those posts without replies
  email = fetch(messages_key())
  for post, idx in email.posts
    post = fetch(email.posts[idx])
    if !post.edits? && idx > 0

      later_post = fetch(email.posts[idx - 1])
      if later_post.edits?.length > 0
        ts = later_post.edits[0].time - 1000
        post.edits = [{
            time: ts 
            user: post.user
          }]
        post.channel = get_channel()
        save post
        console.log 'updated ts: ', post.key, ts

  # estimate times for slider drags based on parent post time
  for k,v of bus.cache
    if k.substring(0, 8) == '/slider/'
      sldr = v
      if !(sldr.selection or sldr.anchor)
        continue

      sel = fetch(sldr.selection or sldr.anchor)
      post = fetch(sel.post)
      if post.edits?.length > 0
        ts = post.edits[0].time + 1000

        for slide, idx in sldr.values 
          if !slide.updated?
            slide.updated = ts + 1000 * idx
            console.log 'updated slide: ', sldr.key, ts + 1000 * idx
        save sldr


# Increment VERSION & call force_refresh if you want people who have a 
# previous version of this file loaded to refresh their browsers
VERSION = 2
window.force_refresh = -> 
  ver = fetch('/current_version')
  if !ver.version || (VERSION && ver.version < VERSION)
    ver.version = VERSION
    save ver


#####
# Analytics
window.getSelectionDistribution = ->
  cnts = {}
  for k,sel of bus.cache        
    if k.substring(0, 11) == '/selection/'
      anchor = sel.anchor_text
      anchor = anchor.replace(/\?/g, '.')
      anchor = anchor.replace(/\!/g, '.')
      i=0
      while i < 3
        anchor = anchor.replace(/\.\./g, '.')
        i++
      sentences = anchor.split('.').length - 1
      console.log sel.anchor_text, sentences
      if !cnts[sentences]?
        cnts[sentences] = 0
      cnts[sentences] += 1

  sentence_distribution = ([k,v] for k,v of cnts)
  sentence_distribution.sort (a,b) -> a[0] - b[0]
  for p in sentence_distribution
    console.log "#{p[0]} sentences: #{p[1]}"


######################
# Actions on page load
######################
window.sbsio_msgs = false
  
  
window.onload = ->  
  # Initialize the responsive variables
  set_responsive()

  # Convenience method for programmers to access responsive variables.
  responsive = fetch('responsive_vars')
  for lvar in Object.keys(responsive)
    do (lvar) ->
      window[lvar] = -> fetch('responsive_vars')[lvar]

  style = document.createElement "style"
  style.innerHTML =   """
    * {box-sizing: border-box;}
    html, body {margin: 0; padding: 0;}
    .grab_cursor {
      cursor: move;
      cursor: grab;
      cursor: ew-resize;
      cursor: -webkit-grab;
      cursor: -moz-grab;
    } .grab_cursor:active {
      cursor: move;
      cursor: grabbing;
      cursor: ew-resize;
      cursor: -webkit-grabbing;
      cursor: -moz-grabbing;
    }
    .flex {        
      display: -ms-flex;
      display: -moz-flex;
      display: -webkit-flex;
      display: flex;
    }

    input, textarea {
      line-height: 22px;
    }

    /**
     * Eric Meyer's Reset CSS v2.0 
    (http://meyerweb.com/
    eric/tools/css/reset/)
     * http://cssreset.com
     */
    html, body, div, span, applet, object, iframe,
    h1, h2, h3, h4, h5, h6, p, blockquote, pre,
    a, abbr, acronym, address, big, cite, code,
    del, dfn, em, img, ins, kbd, q, s, samp,
    small, strike, strong, sub, sup, tt, var,
    b, u, i, center,
    dl, dt, dd, ol, ul, li,
    fieldset, form, label, legend,
    table, caption, tbody, tfoot, thead, tr, th, td,
    article, aside, canvas, details, embed, 
    figure, figcaption, footer, header, hgroup, 
    menu, nav, output, ruby, section, summary,
    time, mark, audio, video,
    input, textarea {
      margin: 0;
      padding: 0;
      border: 0;
      font-size: 100%;
      font: inherit;
      vertical-align: baseline;
    }
    /* HTML5 display-role reset for older browsers */
    article, aside, details, figcaption, figure, 
    footer, header, hgroup, menu, nav, section {
      display: block;
    }
    body {
      line-height: 1;
    }
    ol, ul {
      list-style: none;
    }
    blockquote, q {
      quotes: none;
    }
    blockquote:before, blockquote:after,
    q:before, q:after {
      content: '';
      content: none;
    }
    table {
      border-collapse: collapse;
      border-spacing: 0;
    }

}
    """
  document.body.appendChild style

  # Handle hashes in url
  loc = fetch 'location'

  hash = location.hash
  if location.hash
    loc.seek_to_hash = hash.substring(1, hash.length)
    save loc 


#################
# Input events 
#################

document.addEventListener "keypress", (e) -> 
  key = (e and e.keyCode) or e.keyCode

  # for cycling through message indexes
  if key==1 # cntrl-A
    indexing = fetch('indexing')
    indexing.method = ((indexing.method or 0) + 1) % (Object.keys(IDX).length + 1)
    save indexing


# It is sometimes nice to know the mouse position without having some kind of 
# mouseevent handy. Same with touch. We'll just call them mouseX and mouseY.
mouseX = mouseY = null
onMouseUpdate = (e) -> 
  mouseX = e.pageX
  mouseY = e.pageY
onTouchUpdate = (e) -> 
  mouseX = e.touches[0].pageX
  mouseY = e.touches[0].pageY

document.addEventListener('mousemove', onMouseUpdate, false)
document.addEventListener('mouseenter', onMouseUpdate, false)

document.addEventListener('touchstart', onTouchUpdate, false)
document.addEventListener('touchmove', onTouchUpdate, false)


######
# Registering window events.
# Sometimes you want to have events attached to the window that respond back 
# to a particular identifier, and get cleaned up properly. And whose priority
# you can control.

window.attached_events = {}

register_window_event = (id, event_type, handler, priority) -> 
  id = id.key or id
  priority = priority or 0

  attached_events[event_type] ||= []

  # remove any previous duplicates
  for e,idx in attached_events[event_type] 
    if e.id == id
      unregister_window_event(id, event_type)

  if attached_events[event_type].length == 0
    window.addEventListener event_type, handle_window_event

  attached_events[event_type].push { id, handler, priority }

  dups = []
  for e,idx in attached_events[event_type] 
    if e.id == id 
      dups.push e
  if dups.length > 1
    console.warn "DUPLICATE EVENTS FOR #{id}", event_type
    for e in dups
      console.warn e.handler

unregister_window_event = (id, event_type) -> 
  id = id.key or id

  for ev_type, events of attached_events
    continue if event_type && event_type != ev_type

    new_events = events.slice()

    for ev,idx in events by -1
      if ev.id == id 
        new_events.splice idx, 1

    attached_events[ev_type] = new_events
    if new_events.length == 0
      window.removeEventListener ev_type, handle_window_event

handle_window_event = (ev) ->
  # sort handlers by priority
  attached_events[ev.type].sort (a,b) -> b.priority - a.priority

  # so that we know if an event handler stopped propagation...
  ev._stopPropagation = ev.stopPropagation
  ev.stopPropagation = ->
    ev.propagation_stopped = true
    ev._stopPropagation()

  # run handlers in order of priority
  for e in attached_events[ev.type]

    #console.log "\t EXECUTING #{ev.type} #{e.id}", e.handler
    e.handler(ev)

    # don't run lower priority events when the event is no 
    # longer supposed to bubble
    if ev.propagation_stopped #|| ev.defaultPrevented
      break 


###############
# Profiling 
###############

# timing how long it takes to download the messages index
# start_time = (new Date()).getTime()
# check_email = -> 
#   e = fetch messages_key()
#   if !e.posts?
#     setTimeout check_email, 1
#   else
#     console.log "It took: #{(new Date()).getTime() - start_time}, \
#                           #{posts_in_cache()}, #{e.posts.length}, \
#                           #{no_pending_fetches_for_posts()}"
# check_email()


######################
# Responsive variables
######################

# Controls changes to shared system variables based upon characteristics of the device. 
# Primarily changes based on window size. 
#
# Publishes via StateBus "responsive_vars". 
#
# A convenience method for accessing those variables is provided. Say you want to do 
# fetch('responsive_vars').CONTENT_WIDTH. Instead you can just write CONTENT_WIDTH().  

######
# set_responsive
#
# Updates the responsive variables. Called once on system load, and then subsequently
# whenever there is a relevant system event that would demand the variables to be 
# recalculated (e.g. window resizing)
set_responsive = -> 
  responsive = fetch('responsive_vars')

  w = window.innerWidth
  h = window.innerHeight

  new_vals = 
    WINDOW_WIDTH: w
    WINDOW_HEIGHT: h

  # only update if we have a change
  has_new = false
  for own k,v of new_vals
    if responsive[k] != v
      has_new = true
      responsive[k] = v

  save(responsive) if has_new
      

# Whenever the window resizes, we need to recalculate the variables.
window.addEventListener "resize", set_responsive


is_mac = -> navigator.userAgent.indexOf('Mac OS X') != -1











##
# SliderLabel
#
# Supports editing of label.
#
# Hovering over the label will show a label box and a drop down menu triangle. 
#
# To enter editing mode, click on the label or the menu triangle. Editing mode 
# is also automatically entered when a user is creating a new slider. 
#
# To change the label, the user can simply type in a label. The label is default
# blank for new sliders. The user can also change the label by using the drop 
# down menu to select a previously used label. 
#
# Expand the drop down menu with previously used slider labels by clicking the 
# menu triangle or pressing UP or DOWN arrows while in editing mode. The drop
# menu is also engaged when you start typing into the label. Menu items are 
# filtered based on the characters already entered in the label.
#
# After the drop down is engaged, hitting UP/DOWN will cycle through the items. 
# Mousing over each drop down item also selects the respective item.
#
# To save changes and exit edit mode: 
#   - hit ENTER, or 
#   - click outside the edit area, or
#   - click on a label in the drop down menu
#
# What changes are saved when you hit enter?: the currently selected item 
# from the drop down menu, or the current value of the input field 
# (err...contenteditable div)? Here are the implemented rules: if the input 
# field was last typed into last, save that. Otherwise, if an item in the drop 
# is currently selected, use that. 
# 
# To cancel changes to the label, hit ESC. This will restore the version of the 
# label before edit mode was entered. 
#
# shared state (on local_sldr):
#   editing_label:  if edit mode is engaged 
#
# local state:
#   hovering:       if the user is hovering over the label
#   show_menu:      if the drop down menu is engaged
#   selected_label: the currently selected label from the drop down
#   engaged_last:   whether the user last typed something, or selected an item in 
#                   the drop down menu

dom.SLIDER_LABEL = ->
  sldr = fetch @props.sldr
  local_sldr = fetch(shared_local_key(sldr))

  return SPAN null if @loading()

  is_being_configured = !!local_sldr.configuring

  if local_sldr.editing_label && !@local.labels 
    @local.labels = get_slider_labels(get_post(@props.sldr))

    # remove current label from @local.labels, if it exists
    if sldr.poles?[1]
      for l, idx in @local.labels 
        if l.label == sldr.poles?[1]
          to_remove = idx 
          break 
      if to_remove?
        @local.labels.splice(to_remove, 1)
    save @local

  @stop_editing = (opts) => 
    return if !local_sldr.editing_label

    opts ||= {}

    local_sldr.editing_label = false
    save local_sldr

    # save the new label
    if !opts.reject_changes
      if @local.engaged_last == 'menu' && @local.selected_label?
        new_label = @local.labels[@local.selected_label].label
      else 
        new_label = @refs.label.getDOMNode().textContent

      if sldr.poles[1] != new_label
        sldr.poles[1] = new_label
        save sldr
    else 
      # Temporary hack fix: for some reason, rejecting a save and never updating
      # the slider pole never leads to the component updating the contenteditable
      # div. Refreshing properly shows the original text. However, if I modify
      # sldr, then it will update. Hence the weird code below :-p
      v = sldr.poles[1]
      sldr.poles[1] = v + ' '; save sldr
      setTimeout ->
        sldr.poles[1] = v; save sldr
      , 1

    @local.hovering = false
    @local.show_menu = false
    @local.engaged_last = null
    @local.labels = null
    @local.show_emoji = false
    save @local

    unregister_window_event "#{local_sldr.key}-label"

    if document.activeElement == @refs.label.getDOMNode()
      @refs.label.getDOMNode().blur()

    # reselect anchor text
    sel = fetch(sldr.anchor or sldr.selection)
    local_pst = fetch(shared_local_key(sel.post))
    local_pst.active_selection = sel.key
    save local_pst

  text_style = 
    fontSize: 22
    fontWeight: 300
    color: slider_color #'#999' #"#666"
    whiteSpace: 'nowrap'
    padding: '4px 6px'
    minWidth: 100


  size = sizeWhenRendered 'slider_label', extend {}, text_style

  DIV 
    style:
      position: 'relative'
      left: 6
      marginRight: 6
      top: @props.height - size.height / 2 - 1 #-size.height - 1
      #width: if @local.hovering || local_sldr.editing_label then 2500
      zIndex: if local_sldr.editing_label then 999
      display: 'inline-block' 
      verticalAlign: 'top'

    onMouseEnter: (e) => @local.hovering = true; save @local
    onMouseLeave: (e) => @local.hovering = false; save @local

    onClick: (e) => 
      e.stopPropagation()
      if !local_sldr.editing_label
        local_sldr.editing_label = true
        save local_sldr

    # instruction reminder
    if local_sldr.editing_label && !@local.show_emoji
      SPAN 
        style: 
          position: 'absolute'
          top: -22
          left: 2
          fontSize: 11
          color: feedback_orange
          backgroundColor: 'white'
          #width: 400
        if @local.engaged_last != 'menu' || !@local.selected_label?
          "alt-e to insert emoji"

    if @local.show_emoji
      DIV 
        style: 
          position: 'absolute'
          height: 124
          top: -124
          left: -50
          overflow: 'scroll'
          zIndex: 1
          backgroundColor: 'white'
          border: '1px solid #eaeaea'
          width: 250

        UL 
          style: 
            fontSize: 22

          for em in emoji
            do (em) => 
              unicode = String.fromCodePoint parseInt(em.unicode,16)
              LI 
                style: 
                  key: em.description
                  margin: 1
                  display: 'inline-block'
                  cursor: 'pointer'
                  height: '1.3em'
                  width: '1.3em'
                  position: 'relative'
                  #border: '1px solid red'
                  textAlign: 'center'
                title: em.description

                onMouseDown: (e) => 
                  e.preventDefault()
                  e.stopPropagation()

                  el = @refs.label.getDOMNode()

                  pos = caret_pos el
                  replaced_length = insert_str_at_caret el, unicode
                  set_caret_position el, pos \
                     - replaced_length \
                     + Math.ceil(parseInt(em.unicode,16) / Math.pow(16,4))
                        # some unicode characters are represented by two or more 
                        # code points (when they're greater than 0xFFFF), hence
                        # sometimes advancing the caret position by > one


                  @local.autocomplete_filter = el.textContent
                  @local.save

                SPAN 
                  style: 
                    position: 'relative'
                    top: 9
                  unicode


    # The contenteditable label
    DIV
      key: 'content_editable_label' 
      ref: 'label'
      spellCheck: false
      contentEditable: true
      style: extend {}, text_style,
        display: 'inline-block'
        border: '1px solid'
        outline: 'none'
        minHeight: 32 # firefox made short boxes when empty
        borderColor: if @local.hovering || local_sldr.editing_label #|| \
                        #(is_being_configured && sldr.poles?[1] != '')
                       '#ddd'
                     else if is_being_configured && sldr.poles?[1] == ''
                       '#efefef'
                     else 
                       'transparent'

      onKeyUp: (e) => 
        key = e.which or e.keyCode

        if key == 13
          e.preventDefault()
          return 

        if !@local.show_menu
          @local.show_menu = true
          save @local

        if key not in [38, 40]
          @local.engaged_last = 'textarea' 
          @local.autocomplete_filter = @refs.label.getDOMNode().textContent
          local_sldr.label_content = @local.autocomplete_filter

          if e.altKey && key == 69 # alt-e
            @local.show_emoji = !@local.show_emoji
            e.preventDefault()
            if sldr.poles?[1]
              sldr.poles[1] = sldr.poles[1].replace('´', '')


          save @local
          save local_sldr

      onBlur: (e) =>
        # stop editing when label loses focus...but wait a little while because 
        # the user might just be triggering the drop down menu
        # BUG: calling @stop_editing immediately or after timeout ~25ms leads to 
        #      a race condition in tandem with the cancel/done buttons. Those 
        #      buttons register an onclick handler. However, the blur event causes
        #      a rerender, such that the event handler on the cancel/done buttons
        #      is never invoked because the element is replaced before the click
        #      is registered. 
        setTimeout => 
          try 
            return if @local.hovering
            @stop_editing()
          catch 
            console.warn('component no longer around')
        , 250

      dangerouslySetInnerHTML: {__html: sldr.poles?[1]}

    # menu engage triangle
    if local_sldr.editing_label || @local.hovering
      DIV 
        key: 'menu_triangle'
        style: 
          display: 'inline-block'
          backgroundColor: if @local.show_menu then '#FECA4B'
          position: 'absolute'
          height: size.height + 2 #+ 8
          top: 0
          right: -28
          padding: '0 8px'

        onClick: (e) => 
          e.stopPropagation()
          @local.show_menu = !@local.show_menu
          save @local

          if @local.show_menu && !local_sldr.editing_label
            local_sldr.editing_label = true
            save local_sldr
          else if !@local.show_menu && local_sldr.editing_label
            @stop_editing()

        SPAN 
          style: cssTriangle 'bottom', '#000', 12, 6,
            position: 'relative'
            top: 3 + size.height / 2 

    # drop menu
    if @local.show_menu
      select_label = (idx) => 
        @local.selected_label = idx 
        @local.engaged_last = 'menu'
        save @local

      UL 
        key: 'drop_menu'
        style: 
          position: 'absolute'
          backgroundColor: 'white'
          border: '1px solid #FECA4B'
          zIndex: 1
          marginTop: -1
          maxHeight: 400
          overflow: 'scroll'

        for label, idx in @local.labels
          # implement autocomplete
          if @local.autocomplete_filter && \
             label.label.indexOf(@local.autocomplete_filter) == -1
            continue

          do (label, idx) => 
            LI 
              key: idx
              style: extend {}, text_style,
                display: 'block'
                listStyle: 'none'
                padding: '8px 6px'    
                borderBottom: if idx != @local.labels.length - 1 then '1px solid #E4E4E4'
                cursor: 'pointer'
                backgroundColor: if @local.selected_label == idx then '#F9D57E'
                minWidth: 150 + 26
              onClick: (e) => 
                e.stopPropagation()
                select_label(idx)
                @stop_editing()
              onMouseEnter: (e) => select_label(idx)
              onMouseLeave: (e) => 
                @local.selected_label = null 
                save @local
              dangerouslySetInnerHTML: {__html: label.label}



dom.SLIDER_LABEL.refresh = -> 
  sldr = fetch @props.sldr
  local_sldr = fetch(shared_local_key(sldr))  

  if local_sldr.editing_label

    # make sure that the label gains focus when it is being edited
    if @refs.label.getDOMNode() != document.activeElement
      @refs.label.getDOMNode().focus()

    # Attach shortcuts
    register_window_event "#{local_sldr.key}-label", 'keyup', (e) => 
      key = (e and e.keyCode) or e.keyCode

      has_label_selected = !(@refs.label?.getDOMNode()?.textContent == '' && 
        !(@local.selected_label? && @local.engaged_last = 'menu'))

      # Enter key finishes editing the labels
      if key == 13 
        if has_label_selected
          # prevent the enter key propagating to cause the slider 
          # configuration to complete
          e.preventDefault()
          e.stopPropagation()
        @stop_editing()

      # Esc key finishes editing the label, and cancels changes,
      # but only if the label already has something. This allows
      # an esc press to cancel the slider configuration process 
      else if key == 27 && has_label_selected
        e.preventDefault()
        e.stopPropagation()
        @stop_editing {reject_changes: true}
      
      # up/down arrow engages menu & cycles through menu items
      else if key == 40 || key == 38
        e.preventDefault() 

        idx = if !@local.show_menu
                0 
              else if !@local.selected_label?
                -1
              else 
                @local.selected_label

        items_checked = 0
        found_next_label = false

        while !found_next_label && items_checked <= @local.labels.length
          idx += if key == 40 then 1 else -1
          # cycle appropriately...                    
          if idx > @local.labels.length - 1
            idx = 0
          else if idx < 0
            idx = @local.labels.length - 1

          found_next_label = !@local.autocomplete_filter ||
              @local.labels[idx].label.indexOf(@local.autocomplete_filter) > -1
          items_checked += 1

        @local.selected_label = if found_next_label then idx else null
        @local.show_menu = true
        @local.engaged_last = 'menu'
        save @local
    , 1 # higher priority than esc/enter to finish configuring slider


# These slider labels are always available. Order in array matters, with most 
# salient labels first.
default_slider_labels = [
  "\uD83D\uDD06 understand"
  "\uD83D\uDC4C agree"
  "\u00A0\u002B resonate"
  "\uD83D\uDCA1 ahh!"
  "\uD83E\uDD14 interesting"
  "\uD83D\uDC4D good"
  "\u2713 \u00A0read this"
  "\uD83D\uDE00 happy"
  "\uD83D\uDE02 haha"
  "\u00A0\u203C important"
]

########
# get_slider_labels
#
# Returns a sorted list of all slider labels used, with meta data for each label: 
#   - overall score
#   - whether it is in the default set, and if so, it's multiplier
#   - number of times applied in this channel
#   - number of times applied by this user
#   - whether it was the last label applied by this user
#   - whether it was the last label applied to the given post (if provided)
get_slider_labels = (pst) -> 
  labels = {}

  # get all the sliders used in the post
  if pst 
    pst = cache(pst)
    sldrs_in_post = {}
    latest_ts = 0
    latest_used_in_post = null
    for sel in pst.selections
      sel = cache sel
      for sldr in sel.sliders 
        sldr = cache(sldr)
        if sldr.poles?[0]?.length > 0 && sldr.values[0]?.user
          sldrs_in_post[sldr.poles[1]] = (sldrs_in_post[sldr.poles[1]] or 0) + 1
          if latest_ts < sldr.values[0].updated
            latest_ts = sldr.values[0].updated
            latest_used_in_post = sldr.poles[1]


  # look at sliders used elsewhere in the channel
  for k,sl of bus.cache        
    if k.substring(0, 8) == '/slider/' && sl.poles?.length > 0
      key = sl.poles[1]
      if !labels[key]
        labels[key] = 
          uses: 0
          uses_by_user: 0
          uses_in_post: if pst then 0
          multiplier: 1
          used_last_in_post: false

      labels[key].uses += 1

      created_by_user = sl.values[0]?.user && sl.values[0]?.user == your_key()
      if created_by_user
        labels[key].uses_by_user += 1

      if pst && sldrs_in_post[key]
        labels[key].uses_in_post = sldrs_in_post[key]
        labels[key].used_last_in_post = latest_used_in_post == key

  # remove slider labels that have been used less than twice overall and 
  # not at all in this post. 
  if pst 
    for k,v of labels
      if v.uses_in_post == 0 && v.uses < 2
        delete labels[k]

  # incorporate default labels
  for key, idx in default_slider_labels
    if !labels[key]
      labels[key] = 
        uses: 1
        uses_by_user: 0
        uses_in_post: if pst then 0
        used_last_by_user: false
        used_last_in_post: false
    labels[key].multiplier = 1 + .1 * (default_slider_labels.length - idx)

  # create sorted list
  result = []
  for label,meta of labels
    if label?.length > 0
      # compute score
      meta.label = label 
      meta.score = meta.multiplier * ( Math.log(meta.uses + 1) + \
                                       Math.log(meta.uses_by_user + 1) + \
                                       Math.log((meta.uses_in_post or 0) + 1) )
      result.push meta

  sorted = result.sort (a,b) -> b.score - a.score
  sorted 


