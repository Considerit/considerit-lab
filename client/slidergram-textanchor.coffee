dom.TEXT = ->
  obj = fetch @props.obj 
  @props.attr ||= 'body'
  @props.edit_permission ?= -> true 
  @props.autofocus ?= true 

  local_obj = fetch shared_local_key obj
  
  txt = obj[@props.attr]

  editor_style = defaults (@props.style or {}),
    padding: 0
    margin: 0
    lineHeight: 'inherit'
    minHeight: 14
    border: 'none'
    outline: 'none'   
    display: 'inline-block'
    fontSize: 'inherit'
    fontFamily: 'inherit'
    backgroundColor: 'transparent'
    width: '100%'
    position: 'relative' 
                  # positioning is to force Chrome to confine text
                  # selections to within the element. 
                  # http://stackoverflow.com/questions/14017818


  DIV 
    onBlur: if @local.editing then (e) =>

      setTimeout =>
        contained = closest document.activeElement, (node) => 
          node == @getDOMNode()

        return if contained 

        @local.editing = false
        save @local
        @props.onToggleEditMode?(@local.editing)
        @props.onBlur?(e) 
           

    if @local.editing && @props.edit_permission()
      if @props.html_WYSIWYG

        WYSIWYG
          obj: @props.obj
          attr: @props.attr
          placeholder: @props.placeholder or ''
          style: {}
          cursor: @local.editing_position
          surrounding_text: @local.surrounding_text
          autofocus: @props.autofocus
          disable_html: @props.disable_html

      else

        AUTOSIZEBOX extend {}, @props,
          ref: 'editor'
          className: 'editor'
          value: txt
          style: editor_style
          cursor: @local.editing_position
          autofocus: @props.autofocus

          onKeyDown: (e) =>
            @props.onKeyDown?(e)

            if e.which == 8 && obj[@props.attr] == '' # delete key on empty field     
              if (obj.children or []).length == 0
                del obj        
          
          onChange: (e) => 
            @props.onChange?(e)

            new_text = protect_leading_new_line e.target.value
            obj[@props.attr] = new_text
            save(obj)


    else 
      props = extend {}, @props,
        ref: 'text_field'
        className: 'text_field' + (@props.className or '')
        style: editor_style
        onDoubleClick: if @props.edit_permission() then (e) => 

          @props.onDoubleClick?(e, @local.editing)

          @local.editing = true
          @props.onToggleEditMode?(@local.editing)

          pos = get_selected_text @refs.text_field.getDOMNode()
          @local.editing_position = pos?.start or 0


          sel = window.getSelection()
          @local.surrounding_text = sel.anchorNode.textContent
          save @local 

      DIV null, 
        STYLE """ 
          .text_field:empty:before {
            content: attr(placeholder);
            display: block;
            color: #999;
            pointer-events: none;
          }

          .image-grid {
            //width: 70vw;
            width: 100%;
            position: relative;

            // padding: 12px 24px;
            // background-color: #f6f7f9;
            margin: 36px 0;
            // border-radius: 32px;
            // border: 1px solid #ddd;
            // box-shadow: 0 1px 2px rgba(0,0,0,.25);            
          }
          .image-grid ul {
            display: flex;
            flex-wrap: wrap;
            list-style: none;
            padding-left: 0px;
          }
          .image-grid ul li {
            // height: 300px;
            // height: 150px;
            flex-grow: 1;
            margin-bottom: 0px;
          } 
          .image-grid img, .image-grid video {
            max-height: 100%;
            min-width: 100%;

            object-fit: cover;
            vertical-align: bottom;
            border: 1px solid #f6f7f9;
          }
          .image-grid li:last-child {
            flex-grow: 10;
          }

          .modal_eligible:hover {
            opacity: .85;   
            cursor: pointer;         
          }
          """


        if @props.html_WYSIWYG
          props.dangerouslySetInnerHTML = {__html: txt}   
          props.key = txt     
          UncontrolledText props 
        else 
          props.txt = markup_text(txt) 
          UncontrolledText props 

dom.UncontrolledText = ->
  if @props.dangerouslySetInnerHTML
    DIV @props
  else
    DIV @props, @props.txt

dom.UncontrolledText.shouldComponentUpdate = -> 
  false


mute_all = -> 
  media = document.querySelectorAll("video, audio")
  for m in media 
    m.muted = true


dom.UncontrolledText.refresh = ->


  configure_modal_media = (media) ->

    open_modal = (e) ->
      modal_state = fetch 'image_modal'
      modal_state.img_or_video = e.target.outerHTML
      modal_state.all = (m.outerHTML for m in media)
      mute_all()
      save modal_state

    for m in media 
      m.classList.add 'modal_eligible'

      if m.hasAttribute "controls"
        m.removeAttribute "controls"

      m.onclick = open_modal 
      m.onkeydown = (e) ->
        if e.which == 13 || e.which == 32 # ENTER or SPACE
          open_modal e 
          e.preventDefault()

  grids = @getDOMNode().querySelectorAll('.image-grid')

  for grid in grids
    images = grid.childNodes
    caption = null

    height = grid.style.height or "175px"

    new_html = """<ul>"""
    for img in images when img.outerHTML
      if img.tagName.toLowerCase() == 'figcaption'
        caption = img
      else 
        if height 
          img.setAttribute 'height', height 

        if img.getAttribute 'width'
          img.removeAttribute 'width'
        new_html += "<li>#{img.outerHTML}</li>"

    if !grid.classList.contains('single')
      new_html += "<li></li>"

    new_html += "</ul>"

    if caption
      new_html += caption.outerHTML
    #grid.style.left = "#{-getCoords(@getDOMNode()).left}px"
    grid.innerHTML = new_html
    if grid.style.height 
      grid.style.height = null


    configure_modal_media grid.querySelectorAll('img,video') 


  figures = @getDOMNode().getElementsByTagName('figure')
  for fig in figures
    configure_modal_media fig.querySelectorAll('img,video') 


  for link in @getDOMNode().getElementsByTagName('a')
    if !link.getAttribute('target') && link.getAttribute('href')?[0] != '#'
      link.setAttribute('target', '_blank')



  # only play videos when they're in the viewport
  videos = @getDOMNode().querySelectorAll('video:not([data-initialized])')

  for video in videos
    do (video) =>

      video.setAttribute 'data-initialized', "" 
      if video.hasAttribute 'autoplay'
        video.setAttribute 'playsinline', ""   

      video.addEventListener "loadstart", (e) ->
        video.classList.add 'loading'
        if video.hasAttribute 'controls'
          video.setAttribute 'data-controls', ""
        if !video.hasAttribute('poster')
          video.setAttribute 'controls', ""

      video.addEventListener 'loadeddata', (e) ->
        if video.readyState >= 1
          video.classList.remove 'loading'
          if !video.hasAttribute 'data-controls'
            video.removeAttribute 'controls'
          eligible_to_play = null
          observer = new IntersectionObserver (entries) ->
            entries.forEach (entry) ->
              if !entry.isIntersecting
                eligible_to_play = false
                pause_video()
              else if video.hasAttribute 'autoplay'
                eligible_to_play = true
                play_video()
          , {}

          play_video = ->
            video.play()
          pause_video = ->
            video.pause()


          observer.observe video

          onVisibilityChange = ->
            if document.hidden || !eligible_to_play
              pause_video()
            else if video.hasAttribute 'autoplay'
              play_video()

          document.addEventListener 'visibilitychange', onVisibilityChange

  if @props.edit_permission() && !@checked_aspects
    @checked_aspects = true 

    console.log "delaying by 5sec"
    setTimeout =>
      return if !@isMounted()

      # try to fill in missing aspect-ratios for imgs and videos
      media = @getDOMNode().querySelectorAll('img,video')
      media = (m for m in media when !m.style.aspectRatio && !m.getAttribute('style'))

      if media.length > 0
        console.log "Media that needs aspect ratio", media 
        ensure_loaded = setInterval =>
          media_loaded = true
          for m in media 
            media_loaded &&= (m.complete or m.readyState == 4) && (m.naturalWidth or m.videoWidth)
          if media_loaded
            all_loaded()
            clearInterval ensure_loaded
          else 
            console.log "Media still loading"
        , 1000


        all_loaded = =>
          console.log "All media is loaded, checking if we can insert aspect ratios"
          made_changes = false 
          post = @props.obj

          for m in (media or [])
            aspect = m.style.aspectRatio
            sty = " style=\"aspect-ratio: #{m.naturalWidth or m.videoWidth} / #{m.naturalHeight or m.videoHeight}\" "

            for field in ['body', 'src'] when field of post 
              idx = post[field].indexOf(m.getAttribute('src'))

              if idx > -1
                idx += m.getAttribute('src').length + 1
                console.log "inserting", m, sty, idx, post[field][idx-1], post[field][idx], post[field][idx+1]
                post[field] = "#{post[field].slice(0, idx)}#{sty}#{post[field].slice(idx)}"
                made_changes = true 
              else 
                console.log "Could not find place to insert aspect ratio for ", m, field
          if made_changes
            save post
    , 5000




dom.IMAGE_MODAL = -> 
  modal_state = fetch 'image_modal'

  return SPAN null if !modal_state.img_or_video

  needs_navigation = modal_state.all?.length > 1

  if needs_navigation
    for sib,idx in modal_state.all
      if sib == modal_state.img_or_video
        current_idx = idx
        break 

  close_modal = ->
    modal_state.img_or_video = null 
    save modal_state
    mute_all()

  prev_sibling = ->
    modal_state.img_or_video = modal_state.all[current_idx - 1]
    save modal_state

  next_sibling = ->
    modal_state.img_or_video = modal_state.all[current_idx + 1]
    save modal_state

  DIV 
    id: 'IMAGE_MODAL'

    BUTTON 
      className: 'close'
      dangerouslySetInnerHTML: __html: "&times;"
      onClick: close_modal
      onKeyDown: (e) -> 
        if e.which == 13 || e.which == 32 # ENTER or SPACE
          close_modal()
          e.preventDefault()

    DIV 
      key: modal_state.open
      ref: 'media'
      dangerouslySetInnerHTML: __html: modal_state.img_or_video.replace('playsinline', '').replace('-small', '').replace('data-autoplay', 'autoplay').replace('muted', '').replace('modal_eligible', '').replace('height:', 'heightb:')


    if current_idx > 0
      BUTTON 
        className: 'prev'
        dangerouslySetInnerHTML: __html: "<span>&#8249;</span>"
        onClick: prev_sibling
        onKeyDown: (e) -> 
          if e.which == 13 || e.which == 32 # ENTER or SPACE
            prev_sibling()
            e.preventDefault()

    if needs_navigation && current_idx < modal_state.all.length - 1
      BUTTON 
        className: 'next'
        dangerouslySetInnerHTML: __html: "<span>&#8250;</span>"
        onClick: next_sibling
        onKeyDown: (e) -> 
          if e.which == 13 || e.which == 32 # ENTER or SPACE
            next_sibling()
            e.preventDefault()



    STYLE """
      #IMAGE_MODAL {
        position: fixed;
        z-index: 1;
        padding-top: 5vh;
        left: 0;
        top: 0;
        width: 100%;
        height: 100%;
        overflow: auto;
        background-color: rgba(0,0,0,0.9);
      }

      #IMAGE_MODAL img, #IMAGE_MODAL video {
        margin: auto;
        display: block;
        width: auto;
        height: 90vh;
      }

      #IMAGE_MODAL .caption {
        margin: auto;
        display: block;
        width: auto;
        max-height: 70vh;
        text-align: center;
        color: #ccc;
        padding: 10px 0;
        height: 150px;
      }

    /* The Close Button */
    #IMAGE_MODAL .close {
      position: absolute;
      top: 15px;
      right: 35px;
      color: #f1f1f1;
      font-size: 40px;
      font-weight: bold;
      transition: 0.3s;
      background-color: transparent;
    }

    #IMAGE_MODAL .close:hover,
    #IMAGE_MODAL .close:focus {
      cursor: pointer;
    }

    #IMAGE_MODAL .prev, #IMAGE_MODAL .next {
      position: absolute;
      top: 50%;
      margin-top: -60px;
      font-size: 56px;
      background-color: #444;
      font-weight: 400;
      border-radius: 50%;
      width: 55px;
      height: 55px;
    }
    #IMAGE_MODAL .prev span, #IMAGE_MODAL .next span {
      position: relative;
      top: -20px;
    }

    #IMAGE_MODAL .next {
      right: 50px;
    }
    #IMAGE_MODAL .prev {
      left: 50px;
    }




    """

dom.IMAGE_MODAL.refresh = ->
  modal_state = fetch 'image_modal'
  return if !modal_state.img_or_video

  m = @refs.media.getDOMNode().childNodes[0]
  if m.tagName == 'VIDEO'
    m.setAttribute "controls", true

  close_modal = ->
    modal_state.img_or_video = null 
    save modal_state
    mute_all()

  get_idx = -> 
    current_idx = 0 
    for sib,idx in modal_state.all
      if sib == modal_state.img_or_video
        current_idx = idx
        break 
    current_idx

  prev_sibling = ->
    current_idx = get_idx()
    if current_idx > 0
      modal_state.img_or_video = modal_state.all[get_idx() - 1]
      save modal_state

  next_sibling = ->
    current_idx = get_idx()
    if current_idx < modal_state.all.length - 1
      modal_state.img_or_video = modal_state.all[get_idx() + 1]
      save modal_state

  @getDOMNode().onclick = (e) ->
    if e.target.tagName.toLowerCase() not in ['img', 'video'] && e.target.className not in ['prev', 'next']
      close_modal()

  document.body.onkeydown = (e) ->
    if modal_state.img_or_video
      if e.key == 'Escape' || e.keyCode == 27
        close_modal()
      else if e.keyCode == 39
        next_sibling()
      else if e.keyCode == 37 
        prev_sibling()

      if e.keyCode >= 37 && e.keyCode <= 40
        e.preventDefault()
        e.stopPropagation()





dom.SLIDERGRAM_TEXT = -> 

  obj = fetch @props.obj 
  @props.attr ||= 'body'
  @props.edit_permission ?= -> true 

  slidergrams_disabled = @props.slidergrams_disabled

  local_obj = fetch shared_local_key obj


  if !slidergrams_disabled 
    slidergrams = (obj.selections || [])
    has_active_slidergram = slidergram_being_configured() && \
       fetch(slidergram_being_configured().sel).post == obj.key

    if has_active_slidergram
      slidergrams = slidergrams.slice()
      slidergrams.push slidergram_being_configured().sel

  TEXT_WRAPPER = @props.wrapper or BUBBLE_WRAP

  wrapper_attrs = defaults {}, @props.wrapper_attributes,
    wrapper_style: defaults {}, @props.wrapper_style,
      flex: 2
    dummy: obj
    dummy2: local_obj

  DIV 
    style: 
      display: 'flex'
      position: 'relative'
      zIndex: if has_active_slidergram then 1 else 0

    # scroll anchor
    A 
      name: obj.key.split('/')[2]
      style: 
        position: 'relative'

    TEXT_WRAPPER wrapper_attrs,
      DIV null,
        if @props.children 
          DIV ref: 'children',
            @props.children 

        TEXT 
          ref: 'slidergram_text'
          html_WYSIWYG: @props.html_WYSIWYG
          slidergrams: !slidergrams_disabled 
          obj: obj 
          attr: @props.attr 
          edit_permission: @props.edit_permission

          width: wrapper_attrs.width or @props.width

          onToggleEditMode: (editing) =>
            @local.editing = editing; save @local

          # enable updating anchor text of sliders given an edit
          onSelect: (e) => 
            editor = @getDOMNode().getElementsByClassName('editor')[0]
            @last_selection = [editor.selectionStart, \
                               editor.selectionEnd]

          onChange: (e) =>
            # For some reason, the very first time contenteditable is clicked 
            # after page load, the select event isn't fired. Observed on Chrome.
            editor = @getDOMNode().getElementsByClassName('editor')[0]
            @last_selection ||= [editor.selectionStart, \
                                 editor.selectionEnd]

            old_text = obj[@props.attr]
            new_text = protect_leading_new_line e.target.value

            if !@props.html_WYSIWYG
              update_selection_anchors(obj, old_text, new_text, \
                                 @last_selection[0], @last_selection[1])

            obj[@props.attr] = new_text
            save(obj)

            local_obj.slider_positions_dirty = true
            save local_obj


          # for no-edit mode
          onDoubleClick: (e) =>
            if slidergram_being_configured()
              done_configuring_slidergram()

          onMouseDown: (e) => 
            if !@local.editing && fetch('/current_user').logged_in && !slidergrams_disabled
              register_window_event obj, 'click', (e) => 
                sel = window.getSelection()
                # if there's a text selection, add a new selection w/ a new slider
                if !sel.isCollapsed
                  e.stopPropagation()
                  e.preventDefault()

                  create_selection
                    pst: obj
                    el_with_selection: @getDOMNode().getElementsByClassName('text_field')[0]

                  local_obj.slider_positions_dirty = true
                  save local_obj

                unregister_window_event obj


    DIV   
      style: defaults {}, (@props.slidergram_container_style or {}),
        flex: 1
        top: @local.offset or 0
        position: 'relative'
      
      if !slidergrams_disabled
        for sel in slidergrams

          SELECTION 
            html_WYSIWYG: @props.html_WYSIWYG
            key: sel.key or sel
            sel: sel 
            label: @props.slidergram_label or BASIC_SLIDER_LABEL
            slidergram_width: @props.slidergram_width 
            slidergram_height: @props.slidergram_height 
            offset_for_new: @props.width
            style: 
              left: 15

dom.SLIDERGRAM_TEXT.refresh = ->

  if !@props.slidergrams_disabled
    offset = @refs.slidergram_text.getDOMNode().getBoundingClientRect().top - @getDOMNode().getBoundingClientRect().top

    if @local.offset != offset
      @local.offset = offset
      save @local

  if !@local.editing  
    obj = fetch @props.obj 
    local_obj = fetch shared_local_key obj

    # update slidergram positions if necessary. Usually happens as a consequence
    # of editing the post
    if local_obj.slider_positions_dirty 
      local_obj.slider_positions_dirty = false
      save local_obj
      position_slidergrams
        el: @getDOMNode().getElementsByClassName('text_field')[0]
        text_obj: obj
        slidergram_height: (@props.slidergram_height or DEFAULT_SLIDERGRAM_HEIGHT) + 32/2

    # If a slidergram is set to active, select the anchor text in this post
    if local_obj.active_selection?
      range = make_selection_range(@getDOMNode().getElementsByClassName('text_field')[0], local_obj.active_selection)
      
      if range
        selection = window.getSelection()
        selection.removeAllRanges()
        selection.addRange(range)

DEFAULT_SLIDERGRAM_HEIGHT = 40
DEFAULT_SLIDERGRAM_WIDTH = 150

dom.SELECTION = -> 
  sel = fetch @props.sel

  return SPAN null if !sel.sliders or sel.sliders.length == 0
  sldr = fetch sel.sliders[0]
  return SPAN null if @loading() 


  local_sldr = fetch(shared_local_key(sldr))
  local_pst = fetch(shared_local_key(sel.post))

  is_being_configured = !!local_sldr.configuring

  style = defaults {}, (@props.style or {}), 
    position: 'absolute'    
    zIndex: if local_pst.active_selection == sel.key then 999 else 1
    left: 0
    top: @props.top || sel.top + 16 + 4
                                 # 16 is for height of line of text
                                 # 4 is for the space in the slidergram below
                                 #   the slider baseline.

  slider_label = @props.label or BASIC_SLIDER_LABEL

  if is_being_configured 
    style = extend style, 
      left: local_sldr.configuring.left - @props.offset_for_new
      top: local_sldr.configuring.top               

  slidergram_width = @props.slidergram_width or DEFAULT_SLIDERGRAM_WIDTH
  slidergram_height = @props.slidergram_height or DEFAULT_SLIDERGRAM_HEIGHT

  DIV 
    'data-sldr': sldr.key
    style: style
    onClick: (e) => 
      # delete self on option-click
      if e.altKey
        done_creating_slidergram(sldr, true)

    onMouseEnter: if !local_sldr.editing_label then (e) => 
      local_pst.active_selection = sel.key
      save local_pst

    onMouseLeave: if !is_being_configured && !local_sldr.editing_label then (e) => 
      # only remove if we haven't added ourselves
      local_pst.active_selection = null
      save local_pst
      window.getSelection().removeAllRanges()          


    if !is_being_configured
      logged_in = fetch('/current_user').logged_in
      DIV null,
        SLIDERGRAM 
          key: sel.key or sel
          sldr: sldr
          height: slidergram_height
          width: slidergram_width
          draw_label: slider_label
          max_avatar_radius: 15
          one_sided: @props.one_sided

        # if !logged_in
        #   AUTH_FIRST
        #     before: ''
        #     after: ' to add yourself'
        #     show_login: true
        #     show_create: false
        #     style: 
        #       backgroundColor: 'transparent'
        #       fontSize: 12
        #       padding: 0
        #       color: '#a2a2a2'


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
            height: slidergram_height
            width: slidergram_width
            force_ghosting: true
            draw_label: slider_label
            one_sided: true


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

    #TODO: insert anchors into post if HTML post

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

    # todo: get rid of this. shouldn't have to change anything on anchor post except selections
    if get_forum?
      pst.forum = get_forum()
    else if get_channel?
      pst.channel = get_channel()

    save pst


  delete_slider_if_no_activity(sldr)

  local_pst.active_selection = null
  save local_pst

  clear_tooltip()

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
position_slidergrams = (opts) -> 
  parent_node = opts.el 
  pst = opts.text_obj 
  slidergram_height = opts.slidergram_height

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
                     #{next_key} >= #{k} + #{slidergram_height}""" if debug
      
      solver.addConstraint new c.Inequality \
                            y_pos[next_key], \
                            c.GEQ, \
                            c.plus(y_pos[k], slidergram_height), \
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

cache = (obj_or_key) ->
  bus.cache[(obj_or_key.key or obj_or_key)]



######

markup_text = (text) ->
  text ||= ''

  paragraphs = text.split('\n')  

  return "<span>#{paragraphs[0]}</span>" if paragraphs.length == 1


  for p in paragraphs
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

      if linkify?

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




orphan_selection = (key_or_object) -> 
  sel = fetch(key_or_object)
  # console.log 'orphaning selection', sel.key

  # delete from parent post
  parent = fetch(sel.post)
  i = parent.selections.indexOf(sel.key)
  if i > -1
    parent.selections.splice(i, 1)
    save(parent)
