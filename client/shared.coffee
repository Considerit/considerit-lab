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


window.new_key = (type) ->
  '/' + type + '/' + Math.random().toString(36).substring(7)

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

window.defaults = (obj) ->
  obj ||= {}
  for arg, idx in arguments by -1
    if idx > 0
      for own name,s of arg
        if !obj[name]?
          obj[name] = s
  obj



# ensures that min <= val <= max
within = (val, min, max) ->
  Math.min(Math.max(val, min), max)

crossbrowserfy = (styles, property) ->
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



# PULSE
# Any component that renders a PULSE will get rerendered on an interval.
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
  while (target.scrollHeight > target.offsetHeight )
    target.rows++

dom.AUTOSIZEBOX.up      = -> resizebox @getDOMNode()
dom.AUTOSIZEBOX.refresh = -> resizebox @getDOMNode()



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


dom.GRAB_CURSOR = -> 
  STYLE """
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


    """

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

