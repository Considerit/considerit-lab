IDLE_THRESHOLD = 1000 * 60 * 5 # 5 minute idle period

connection_shares_space = (other_conn) ->
  conn = fetch '/connection'

  conn.client != other_conn.client && \
  conn.location?.host == other_conn.location?.host && \
  conn.location?.path == other_conn.location?.path


connections_sharing_space = (filter) -> 
  filter ||= connection_shares_space
  connections = fetch('/connections').all or []
  conn = fetch '/connection'
  
  (c for c in connections when conn.client != c.client && filter(c))

active_connections = (idle_threshold, filter) -> 
  idle_threshold ?= IDLE_THRESHOLD
  connections_sharing_space (c) -> 
    (!filter || filter(c)) && \
    connection_shares_space(c) && \ 
    (c.last_seen && new Date().getTime() - c.last_seen < idle_threshold)

dom.WHO_IS_HERE = ->
  connections = connections_sharing_space()
  conn = fetch('/connection')

  connections.sort sort_by_colors

  connections.push conn

  tawkconns = tawkbus?.fetch('/connections')

  avatar_size = 44
  avatar_separation = 28

  UL
    style: defaults {}, (@props.style or {}),
      listStyle: 'none'
      #width: '100%'
      position: 'fixed'
      top: 2
      right: 20
      width: 100 + connections.length * avatar_separation
      zIndex: 10

    LI null,
      HEARTBEAT
        public_key: fetch('other_users_pulse').key
        interval: 5000

    for c,idx in connections when c.client
      is_idle = !c.last_seen? || new Date().getTime() - c.last_seen > (@props.idle_thresh or IDLE_THRESHOLD)
      is_idle = false

      boxShadow = "0 1px 2px rgba(0,0,0,.15)"
      if tawkconns
        tawkconn = tawkconns.all.find (tc) -> c.client in (tc.embedded_connections or [])

        volume = 0 
        if tawkconn?.audio
          volume = tawkbus.fetch("stream/#{tawkconn.id}").volume

          if volume > 0
            boxShadow += ", 0 0px 4px #{c.color}"
          if volume > 25 
            boxShadow += ", 0 0px 8px #{c.color}"
          if volume > 50 
            boxShadow += ", 0 0px 16px #{c.color}"
          if volume > 75 
            boxShadow += ", 0 0px 32px #{c.color}"

      LI 
        style: 
          paddingRight: 5
          opacity: if is_idle then .4 else 1
          display: 'inline-block'
          verticalAlign: 'top'
          position: 'absolute'
          left: idx * avatar_separation
          paddingLeft: if conn.client == c.client then 100
          zIndex: 10

        if tawkconns && tawkconn && tawkconn.video
          DIV 
            style: 
              position: 'relative'
              width: avatar_size
              height: avatar_size
              display: 'block'
              border: "3px solid #{c.color}"
              borderRadius: '50%'
              boxShadow: boxShadow 
              overflow: 'hidden'
              opacity: .9999 # http://stackoverflow.com/questions/5736503

            VIDEO 
              src: tawkbus.fetch("stream/#{tawkconn.id}").url
              style: 
                width: avatar_size * 1.5
                height: avatar_size * 1.5
                position: 'relative'
                top: -avatar_size * .25
                left: -avatar_size * .25

        else  
          a = do(avatar_size,c,boxShadow) -> -> AVATAR 
            style: 
              width: avatar_size
              height: avatar_size
              backgroundColor: if !c.user?.pic? then c.color else 'white'
              display: 'inline-block'
              border: "3px solid #{c.color}"
              borderRadius: '50%'
              boxShadow: boxShadow
              zIndex: 10
            hide_tooltip: conn.client == c.client
            user: c.user?.key or c.user or c 
            add_initials: false
            color: c.color 

          if @props.show_auth && conn.client == c.client
            USER_MENU 
              wrap: a
          else 
            a()

dom.CURSORS = -> 
  all_conn = fetch '/connections'

  DIV
    style: 
      zIndex: 99999

    HEARTBEAT
      public_key: fetch('pulse').key
      interval: 5000

    for c in connections_sharing_space()
      CURSOR
        key: c.client
        connection: c

dom.CURSOR = -> 
  c = @props.connection
  [x,y] = guess_cursor_location(c)

  is_idle = !c.last_seen? || new Date().getTime() - c.last_seen > (@props.idle_thresh or IDLE_THRESHOLD)
  DIV 
    style: 
      position: 'absolute'
      left: x
      top: y
      zIndex: 99999
      display: if is_idle then 'none' else 'block'
      pointerEvents: 'none'

    DRAW_CURSOR c.color
    
    SPAN 
      style: 
        fontSize: 11
        opacity: .6
        fontFamily: 'sans-serif'
      c.user?.name or c.name or c.invisible_name or 'Anon'


DRAW_CURSOR = (bg_color) ->
  SVG 
    x: 0
    y: 0
    width: 28
    height: 28

    viewBox: "4 7 28 28" 
    
    POLYGON
      fill: "#FFFFFF" 
      points: "8.2,20.9 8.2,4.9 19.8,16.5 13,16.5 12.6,16.6"

    POLYGON
      fill: "#FFFFFF" 
      points: "17.3,21.6 13.7,23.1 9,12 12.7,10.5"

    RECT
      x: "12.5" 
      y: "13.6" 
      transform: "matrix(0.9221 -0.3871 0.3871 0.9221 -5.7605 6.5909)" 
      width: "2" 
      height: "8"
      fill: bg_color or 'black'
      
    POLYGON 
      points: "9.2,7.3 9.2,18.5 12.2,15.6 12.6,15.5 17.4,15.5"
      fill: bg_color or 'black'

guess_cursor_location = (c) -> 
  for path in (c.paths or [])
    if path.disambig_idx? > 0 
      hover_els = document.querySelectorAll(path.selector)
    else 
      hover_els = [document.querySelector(path.selector)]

    if hover_els.length > 0 && hover_els[0] 
      hovering_on = hover_els[(path.disambig_idx or 0)]

      rect = hovering_on.getBoundingClientRect()
      docEl = document.documentElement
      offset = 
        y: rect.top + window.pageYOffset - docEl.clientTop
        x: rect.left + window.pageXOffset - docEl.clientLeft

      x_ratio = rect.width / path.offset.w
      y_ratio = rect.height / path.offset.h

      return [offset.x + x_ratio * path.offset.x, offset.y + y_ratio * path.offset.y]

  return [c.cursor?.x or 0, c.cursor?.y or 0]




#############################
# Save connection when dirty
# Rate limiting helps performance

if !window.presence_no_updates && !get_script_attr('presence', 'no-updates')
  connection_is_dirty = false 
  setInterval -> 
    if bus? && connection_is_dirty
      conn = bus.cache['/connection']
      save conn 
      connection_is_dirty = false
  , 150



#############################
# Initialize connection & keep nsync with current user 

wait_for_bus -> 
  init_conn = bus.reactive -> 
    conn = fetch('/connection')
    connections = fetch('/connections')

    if tawkbus? 
      tawkconn = tawkbus.fetch('/connection')

      if tawkconn.client?
        if !tawkconn.embedded_connections || tawkconn.embedded_connections.indexOf(conn.client) == -1
          tawkconn.embedded_connections ||= []
          tawkconn.embedded_connections.push conn.client 
          tawkbus.save tawkconn

    if conn.client?

      colors = (c.color for c in connections.all when c.color && c.client != conn.client)

      if !conn.color? || conn.color.indexOf('hsl') == -1 || (colors.indexOf(conn.color) > -1 && colors.length < 360)
        conn.color = get_next_color(fetch('/connections').all)
        save conn
      if conn.user? && conn.user.name != conn.name
        conn.name = conn.user.name 
        save conn 
      else if !conn.invisible_name?
        conn.invisible_name = random_name()
        save conn

  init_conn()


dom.RAINBOW = ->
  @local.num ||= 25
  @local.s ||= 80
  @local.l ||= 60

  if @local.colors?.length != @local.num
    @local.colors = []
    for i in [0..@local.num-1]
      hue = get_next_hue @local.colors 
      @local.colors.push hue
    @local.colors.sort (a,b) -> a - b 

  DIV 
    style: 
      marginTop: 120
      position: 'relative'

    DIV 
      style: 
        height: 50

      for i in [0..@local.num-1]
        hue = @local.colors[i]
        SPAN 
          style: 
            borderRadius: '50%'
            width: 45
            height: 45
            display: 'inline-block'
            backgroundColor: "hsl(#{hue}, #{@local.s}%, #{@local.l}%)"
            boxShadow: '0 1px 2px rgba(0,0,0,.1)'
            position: 'absolute'
            left: i * 30

    DIV null,
      INPUT 
        type: 'text'
        defaultValue: @local.num 
        placeholder: 'num colors'
        onChange: (e) => 
          @local.num = parseInt(e.target.value or 25)
          delete @local.colors
          save @local

      INPUT 
        type: 'text'
        defaultValue: @local.s 
        placeholder: 'saturation'
        onChange: (e) => 
          @local.s = parseInt(e.target.value or .5)
          delete @local.colors
          save @local

      INPUT 
        type: 'text'
        defaultValue: @local.l 
        placeholder: 'lightness'
        onChange: (e) => 
          @local.l = parseInt(e.target.value or .5)
          delete @local.colors
          save @local



hsl_regex = /hsl\((\d+),\s*([\d.]+)%,\s*([\d.]+)%\)/

sort_by_colors = (a,b) ->
  a_is_hsl = a.color?.indexOf('hsl') > -1
  b_is_hsl = b.color?.indexOf('hsl') > -1

  if a_is_hsl && b_is_hsl
    parseInt(hsl_regex.exec(a.color)[1]) - parseInt(hsl_regex.exec(b.color)[1])

  else if !a_is_hsl && !b_is_hsl
    -1
  else if a_is_hsl
    1 
  else 
    -1


get_next_color = (colors) -> 
  hue_distribution = (parseInt(hsl_regex.exec(c.color)[1]) for c in colors when c.color?.indexOf('hsl') > -1)

  hue = get_next_hue(hue_distribution)

  s = 78
  l = 63

  "hsl(#{hue}, #{s}%, #{l}%)"

get_next_hue = (hue_distribution) ->
  hues = (0 for i in [0..359] )
  impact = .25 * 360

  for hue in hue_distribution
    for idx in [0..impact-1]
      forward = hue + idx
      if forward > hues.length
        forward -= hues.length
      hues[forward] += 100 * Math.pow((impact - idx) / impact, 4)
      if idx > 0
        back = hue - idx 
        if back < 0 
          back += hues.length
        hues[back] += 100 * Math.pow((impact - idx) / impact, 4)


  hues = ([hue, value] for value, hue in hues)
  hues.sort (a,b) -> a[1] - b[1]

  hues[Math.floor(Math.random() * 10)][0]



#############################
# Shadow location resource

wait_for_bus -> 

  shadow_loc = bus.reactive -> 
    loc = fetch 'location'
    conn = fetch '/connection'

    conn.location = {}
    for k,v of loc when k != 'key'
      conn.location[k] = v 
    connection_is_dirty = true 

  shadow_loc()



################################
# Track cursor

if !window.presence_no_updates && !get_script_attr('presence', 'no-updates')
  onMouseUpdate = (e) -> update_position e, e.pageX, e.pageY
  onTouchUpdate = (e) -> update_position e, e.touches[0].pageX, e.touches[0].pageY

matching_attr_whitelist = ['id', 'data-widget', 'data-key', 'class', 'href', 'src']
matching_attr_blacklist = ['data-reactid', 'style', 'disabled']
update_position = (e,x,y) -> 
  conn = fetch '/connection'

  target = e.target 
  path = []
  offsets = []
  targets = []

  while target.parentNode && target.parentNode.tagName?.toUpperCase() != 'BODY'
    el = target.tagName

    rect = target.getBoundingClientRect()
    docEl = document.documentElement

    offset = 
      y: y - (rect.top + window.pageYOffset - docEl.clientTop)
      x: x - (rect.left + window.pageXOffset - docEl.clientLeft)
      w: rect.width 
      h: rect.height  

    for attr in (target.attributes or {}) when attr.name in matching_attr_whitelist #attr.name not in matching_attr_blacklist
      el += "[#{attr.name}='#{attr.value}']"

    path.unshift el 
    offsets.unshift offset 
    targets.unshift target 

    target = target.parentNode

  paths = []
  selector = ""
  for p,idx in path 
    selector += (if idx > 0 then ' > ' else '') + p 

    selected = document.querySelectorAll(selector)
    # if idx == path.length - 1 && selected.length > 1
    #   console.warn("Target is not specified enough to distinguish from siblings for shared cursors", e.target, selector, selected.length)

    disambig_idx = 0 
    for el,disambig_idx in selected 
      break if el == targets[idx] 

    paths.unshift 
      selector: selector
      disambig_idx: disambig_idx
      offset: offsets[idx]
  
  extend conn, 
    paths: paths
    cursor: {x,y}
    last_seen: (new Date()).getTime()  

  connection_is_dirty = true 

document.addEventListener('mousemove', onMouseUpdate, false)
document.addEventListener('mouseenter', onMouseUpdate, false)

document.addEventListener('touchstart', onTouchUpdate, false)
document.addEventListener('touchmove', onTouchUpdate, false)


#############################
# Track key presses
document.addEventListener 'keypress', ->
  conn = fetch '/connection'
  conn.last_seen = (new Date()).getTime()
  connection_is_dirty = true 
, false


#############################
# Helpers

window.random_name = -> 
  names = """
    Scholar
    Professor
    Scientist
    Philosopher
    Academic
    Thinker
    Intellectual
    Student
    Teacher
    Sage 
    Savant
    Researcher
    Monastic
    Critic
    Pupil
    Theorist
    Faculty
    Instructor
    Mystic
    Intern
    Inventor
    Polymath
    Artist
    Creator
    Observer
    Patron
    Apprentice
    Entrepreneur
    Hacker    
    Guru 
    Geek
    Nerd
    Mathematician
  """

  adjectives = """
    Sly 
    Secretive
    Sneaky
    Anonymous
    Masked
    Invisible
    Covert
    Mysterious
    Undercover
    Private
    Furtive
    Disguised
    Incognito
    Hermetic
    Reclusive
    Hidden
    Hooded
    Cloaked
    Midnight
    Shadowy
    Shy
    Inconspicuous
    Obscured
    Unnoticed
    Occult
  """

  names = names.split('\n')
  name = names[Math.floor(Math.random() * names.length)].trim()

  adjs = adjectives.split('\n')
  adj = adjs[Math.floor(Math.random() * adjs.length)].trim()

  "#{adj} #{name}"
