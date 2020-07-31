window.considerit_salmon = '#F45F73' ##f35389' #'#df6264' #E16161


# Tracking mouse positions
# It is sometimes nice to know the mouse position. Let's just make it
# globally available.
window.mouseX = window.mouseY = null
onMouseUpdate = (e) -> 
  window.mouseX = e.pageX
  window.mouseY = e.pageY
onTouchUpdate = (e) -> 
  window.mouseX = e.touches[0].pageX
  window.mouseY = e.touches[0].pageY

document.addEventListener('mousemove', onMouseUpdate, false)
document.addEventListener('mouseenter', onMouseUpdate, false)

document.addEventListener('touchstart', onTouchUpdate, false)
document.addEventListener('touchmove', onTouchUpdate, false)





########
# Statebus helpers

server_slash = (key) -> 
  if key[0] != '/'
    '/' + key 
  else 
    key


window.new_key = (type, text) ->
  text ||= ''
  '/' + type + '/' + slugify(text) + (if text.length > 0 then '-' else '') + Math.random().toString(36).substring(7)

shared_local_key = (key_or_object) -> 
  key = key_or_object.key || key_or_object
  if key[0] == '/'
    key = key.substring(1, key.length)
    "#{key}/shared"
  else 
    key

window.your_key = ->
  current_user = fetch('/current_user')
  current_user.user?.key or current_user.user

window.wait_for_bus = (cb) -> 
  if !bus?
    setTimeout -> 
      wait_for_bus(cb)
    , 10
  else 
    cb()


##############
# Manipulating objects
window.extend = (obj) ->
  obj ||= {}
  for arg, idx in arguments 
    if idx > 0      
      for own name,s of arg
        if !obj[name]? || obj[name] != s
          obj[name] = s
  obj

window.defaults = (o) ->
  obj = {}

  for arg, idx in arguments by -1      
    for own name,s of arg
      obj[name] = s
  extend o, obj



# ensures that min <= val <= max
window.within = (val, min, max) ->
  Math.min(Math.max(val, min), max)

window.crossbrowserfy = (styles, property) ->
  prefixes = ['Webkit', 'ms', 'Moz']
  for pre in prefixes
    styles["#{pre}#{property.charAt(0).toUpperCase()}#{property.substr(1)}"]
  styles


window.get_script_attr = (script, attr) ->
  sc = document.querySelector("script[src*='#{script}'][src$='.coffee'], script[src*='#{script}'][src$='.js']")
  val = sc.getAttribute(attr)

  if val == ''
    val = true 
  val 
  

slugify = (text) -> 
  text ||= ""
  text.toString().toLowerCase()
    .replace(/\s+/g, '-')           # Replace spaces with -
    .replace(/[^\w\-]+/g, '')       # Remove all non-word chars
    .replace(/\-\-+/g, '-')         # Replace multiple - with single -
    .replace(/^-+/, '')             # Trim - from start of text
    .replace(/-+$/, '')             # Trim - from end of text
    .substring(0, 30)

# Checks this node and ancestors whether check holds true
window.closest = (node, check) -> 
  if !node || node == document
    false
  else 
    check(node) || closest(node.parentNode, check)


####################
### Tracking 
###
#####

# Used to track which items a user has interacted with. Useful for e.g. notifications.
window.saw_thing = (keys_or_objects) -> 
  seen = fetch 'seen_in_session'
  seen.items ||= {}

  if !(keys_or_objects instanceof Array)
    keys_or_objects = [keys_or_objects]
  for key_or_object in keys_or_objects
    key = key_or_object.key or key_or_object
    seen.items[key] = false 

  save seen

# call this method if you want your application to report to the server what users 
# see (via saw_thing)
window.report_seen = (namespace) ->
  wait_for_bus -> 
    namespace ||= '' 
    do (namespace) -> 
      reporter = bus.reactive -> 
        seen = fetch 'seen_in_session'
        seen.items ||= {}

        to_report = []
        for k,v of seen.items when k != 'key' && !v 
          to_report.push k 
          seen.items[k] = true

        if to_report.length > 0 
          save
            key: "/seen/#{JSON.stringify({user:your_key(), namespace: namespace})}"
            saw: to_report

          save seen 

      reporter()








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



# Computes the width/height of some text given some styles
size_cache = {}
window.sizeWhenRendered = (str, style) -> 
  main = document.getElementById('main-content') or document.querySelector('[data-widget="body"]')

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

window.getCoords = (el) ->
  rect = el.getBoundingClientRect()
  docEl = document.documentElement

  offset = 
    top: rect.top + window.pageYOffset - docEl.clientTop
    left: rect.left + window.pageXOffset - docEl.clientLeft
  extend offset,
    cx: offset.left + rect.width / 2
    cy: offset.top + rect.height / 2
    width: rect.width 
    height: rect.height



# HEARTBEAT
# Any component that renders a HEARTBEAT will get rerendered on an interval.
# props: 
#   public_key: the key to store the heartbeat at
#   interval: length between pulses, in ms (default=1000)
dom.HEARTBEAT = ->   
  beat = fetch(@props.public_key or 'pulse')
  if !beat.beat?
    setInterval ->   
      beat.beat = (beat.beat or 0) + 1
      save(beat)
    , (@props.interval or 1000)

  SPAN null



dom.AUTOSIZEBOX = ->
  @props.style ||= {}
  @props.style.resize = if @props.style.width or @props.cols then 'none' else 'horizontal'
  @props.rows ||= 1
  TEXTAREA @props

resizebox = (target) ->
  target.style.height = null
  while (target.rows > 1 && target.scrollHeight < target.offsetHeight )
    target.rows--
  while (target.scrollHeight > target.offsetHeight && target.rows < 999)
    target.rows++

dom.AUTOSIZEBOX.up      = -> resizebox @getDOMNode()

dom.AUTOSIZEBOX.refresh = -> 
  resizebox @getDOMNode()

  if !@init 
    @init = true 
    el = @getDOMNode()

    if (@props.autofocus || @props.cursor) && el != document.activeElement
      # Focus the text area if we just clicked into the editor      
      # use select(), not focus(), because this averts the browser from 
      # automatically scrolling the page to the top of the text area, 
      # which interferes with clicking inside a long post to start editing
      el.select()

    if @props.cursor && el.setSelectionRange
      el.setSelectionRange(@props.cursor, @props.cursor)




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
  _onClick = @props.onClick

  @props.onClick = (ev) -> 
    _onClick?(ev)  
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












dom.WYSIWYG = -> 
  my_data = fetch @props.obj

  @local.edit_code ?= true

  DIV 
    style: 
      position: 'relative'
    onBlur: @props.onBlur

    DIV 
      style: 
        position: 'absolute'
        top: -28
        left: 0

      for mode in [{label: 'rich text', val: false}, {label: 'raw html', val: true}]  
        do (mode) =>
          BUTTON
            style: 
              background: 'transparent'
              border: 'none'
              textTransform: 'uppercase'
              color: if !!@local.edit_code == mode.val then '#555' else '#999'
              padding: '0px 8px 0 0'
              fontSize: 12
              fontWeight: 700
              cursor: if !!@local.edit_code == mode.val then 'auto'

            onClick: (e) => 
              @local.edit_code = mode.val
              save @local

            mode.label

    if @local.edit_code
      AUTOSIZEBOX
        style: 
          width: '100%'
          fontSize: 'inherit'
        value: my_data[@props.attr]
        autofocus: true
        onChange: (e) => 
          my_data[@props.attr] = e.target.value
          save my_data
        
    else 
      TRIX_WYSIWYG @props


dom.TRIX_WYSIWYG = ->
  
  if !@local.initialized
    # We store the current value of the HTML at
    # this component's key. This allows the  
    # parent component to fetch the value outside 
    # of this generic wysiwyg component. 
    # However, we "dangerously" set the html of the 
    # editor to the original @props.html. This is 
    # because we don't want to interfere with the 
    # wysiwyg editor's ability to manage e.g. 
    # the selection location. 
    my_data = fetch @props.obj
    @original_value = my_data[@props.attr] or ''
    @local.initialized = true
    save @local
 
  DIV defaults {}, @props,
    style: @props.style or {}

    dangerouslySetInnerHTML: __html: """
        <input id="#{@local.key}-input" value="#{@original_value.replace(/\"/g, '&quot;')}" type="hidden" name="content">
        <trix-editor autofocus=#{!!@props.autofocus} class='trix-editor' input="#{@local.key}-input" placeholder='#{@props.placeholder or 'Write something!'}'></trix-editor>
      """

dom.TRIX_WYSIWYG.refresh = -> 
  if !@init 
    @init = true
    editor = @getDOMNode().querySelector('.trix-editor')

    editor.addEventListener 'trix-change', (e) =>
      html = editor.innerHTML
      my_data = fetch @props.obj
      my_data[@props.attr] = html
      save my_data

    if @props.cursor
      editor.editor.setSelectedRange @props.cursor





# I prefer using Trix now...

dom.QUILL_WYSIWYG = ->

  my_data = fetch @props.obj

  @supports_Quill = !!Quill

  if !@local.initialized
    # We store the current value of the HTML at
    # this component's key. This allows the  
    # parent component to fetch the value outside 
    # of this generic wysiwyg component. 
    # However, we "dangerously" set the html of the 
    # editor to the original @props.html. This is 
    # because we don't want to interfere with the 
    # wysiwyg editor's ability to manage e.g. 
    # the selection location. 
    @original_value = my_data[@props.attr] or ''
    @local.initialized = true
    save @local

  @show_placeholder = (!my_data[@props.attr] || (@editor?.getText().trim().length == 0)) && !!@props.placeholder

  DIV 
    style: 
      position: 'relative'


    if @local.edit_code || !@supports_Quill
      AutoGrowTextArea
        style: 
          width: '100%'
          fontSize: 18
        defaultValue: my_data[@props.attr]
        onChange: (e) => 
          my_data[@props.attr] = e.target.value
          save my_data

    else

      DIV 
        ref: 'editor'
        id: 'editor'
        dangerouslySetInnerHTML:{__html: @original_value}
        style: @props.style


dom.QUILL_WYSIWYG.refresh = -> 
  return if !@supports_Quill || !@refs.editor || @mounted
  @mounted = true 

  getHTML = => @getDOMNode().querySelector(".ql-editor").innerHTML

  # Attach the Quill wysiwyg editor
  @editor = new Quill @refs.editor.getDOMNode(),
    styles: true #if/when we want to define all styles, set to false
    placeholder: if @show_placeholder then @props.placeholder else ''
    theme: 'snow'

  keyboard = @editor.getModule('keyboard')
  delete keyboard.bindings[9]    # 9 is the key code for tab; restore tabbing for accessibility

  @editor.on 'text-change', (delta, old_contents, source) => 
    if source == 'user'
      my_data = fetch @props.obj
      my_data[@props.attr] = getHTML()

      if my_data[@props.attr].indexOf(' style') > -1
        # strip out any style tags the user may have pasted into the html

        removeStyles = (el) ->
          el.removeAttribute 'style'
          if el.childNodes.length > 0
            for child in el.childNodes
              removeStyles child if child.nodeType == 1

        node = @editor.root
        removeStyles node
        my_data[@props.attr] = getHTML()

      save my_data









window.insert_grab_cursor_style = -> 
  set_style """
      a { 
        cursor: pointer; 
        text-decoration: underline;
      }
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


    """, 'grab-cursor'

# Takes an ISO time and returns a string representing how
# long ago the date represents.
# from: http://stackoverflow.com/questions/7641791
window.prettyDate = (time) ->
  date = new Date(time) #new Date((time || "").replace(/-/g, "/").replace(/[TZ]/g, " "))
  diff = (((new Date()).getTime() - date.getTime()) / 1000)
  day_diff = Math.floor(diff / 86400)

  return if isNaN(day_diff) || day_diff < 0

  # TODO: pluralize properly (e.g. 1 days ago, 1 weeks ago...)
  r = day_diff == 0 && (
    diff < 60 && "just now" || 
    diff < 120 && "1 minute ago" || 
    diff < 3600 && Math.floor(diff / 60) + " minutes ago" || 
                              diff < 7200 && "1 hour ago" || 
                              diff < 86400 && Math.floor(diff / 3600) + " hours ago") || 
                              day_diff == 1 && "Yesterday" || 
                              day_diff < 7 && day_diff + " days ago" || 
                              day_diff < 31 && Math.ceil(day_diff / 7) + " weeks ago" ||
                              "#{date.getMonth() + 1}/#{date.getDay() + 1}/#{date.getFullYear()}"

  r = r.replace('1 days ago', '1 day ago').replace('1 weeks ago', '1 week ago').replace('1 years ago', '1 year ago')
  r



window.hsv2rgb = (h,s,v) -> 
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

# renders styled HTML, TODO: strip script tags first
dom.RENDER_HTML = -> 
  DIV 
    className: 'embedded_html'
    dangerouslySetInnerHTML:
      __html: @props.html





dom.LAB_FOOTER = -> 
  DIV 
    style: 
      marginTop: 40
      padding: '20px 0 20px 0'
      fontFamily: '"Brandon Grotesque", Raleway, Helvetica, arial'
      borderTop: '1px solid #D6D7D9'
      backgroundColor: '#F6F7F9'
      color: "#777"
      fontSize: 30
      fontWeight: 300


    DIV 
      style: 
        textAlign: 'center'        
        marginBottom: 6

      "Made at "

      A 
        onMouseEnter: => 
          @local.hover = true
          save @local
        onMouseLeave: => 
          @local.hover = false
          save @local
        href: 'http://consider.it'
        target: '_blank'
        title: 'Consider.it\'s homepage'
        style: 
          position: 'relative'
          top: 6
          left: 3
        
        DRAW_LOGO 
          height: 31
          clip: false
          o_text_color: considerit_salmon
          main_text_color: considerit_salmon        
          draw_line: true 
          line_color: '#D6D7D9'
          i_dot_x: if @local.hover then 142 else 252
          transition: true


    # DIV 
    #   style: 
    #     fontSize: 16
    #     textAlign: 'center'

    #   "An "
    #   A 
    #     href: 'https://invisible.college'
    #     target: '_blank'
    #     style: 
    #       color: 'inherit'
    #       fontWeight: 400
    #     "Invisible College"
    #   " laboratory"


dom.LOADING_INDICATOR = -> 
  DIV
    className: 'loading sk-wave'
    dangerouslySetInnerHTML: __html: """
      <div class="sk-rect sk-rect1"></div>
      <div class="sk-rect sk-rect2"></div>
      <div class="sk-rect sk-rect3"></div>
      <div class="sk-rect sk-rect4"></div>
      <div class="sk-rect sk-rect5"></div>
    """


window.set_style = (sty, id) ->
  style = document.createElement "style"
  style.id = id if id
  style.innerHTML = sty
  document.head.appendChild style



# loading indicator styles below are 
# Copyright (c) 2015 Tobias Ahlin, The MIT License (MIT)
# https://github.com/tobiasahlin/SpinKit
set_style """
  .sk-wave {
    margin: 40px auto;
    width: 50px;
    height: 40px;
    text-align: center;
    font-size: 10px; }
    .sk-wave .sk-rect {
      background-color: rgba(223, 98, 100, .5);
      height: 100%;
      width: 6px;
      display: inline-block;
      -webkit-animation: sk-waveStretchDelay 1.2s infinite ease-in-out;
              animation: sk-waveStretchDelay 1.2s infinite ease-in-out; }
    .sk-wave .sk-rect1 {
      -webkit-animation-delay: -1.2s;
              animation-delay: -1.2s; }
    .sk-wave .sk-rect2 {
      -webkit-animation-delay: -1.1s;
              animation-delay: -1.1s; }
    .sk-wave .sk-rect3 {
      -webkit-animation-delay: -1s;
              animation-delay: -1s; }
    .sk-wave .sk-rect4 {
      -webkit-animation-delay: -0.9s;
              animation-delay: -0.9s; }
    .sk-wave .sk-rect5 {
      -webkit-animation-delay: -0.8s;
              animation-delay: -0.8s; }

  @-webkit-keyframes sk-waveStretchDelay {
    0%, 40%, 100% {
      -webkit-transform: scaleY(0.4);
              transform: scaleY(0.4); }
    20% {
      -webkit-transform: scaleY(1);
              transform: scaleY(1); } }

  @keyframes sk-waveStretchDelay {
    0%, 40%, 100% {
      -webkit-transform: scaleY(0.4);
              transform: scaleY(0.4); }
    20% {
      -webkit-transform: scaleY(1);
              transform: scaleY(1); } }
  """, 'loading-indicator-styles'



