# bus.honk = false
# bus.dev_with_single_client = false


fickle.register (vars) -> 
  return {
    gutter: 80 
    padding: Math.max 80, vars.window_width / 8
    max_text_width: 650
    collapsed_histo_height: 50
  }

if React.addons?.Perf?
  window.Perf = React.addons.Perf 
  Perf.start()
  window.perf_out = -> 
    Perf.stop()
    m = Perf.getLastMeasurements()
    Perf.printExclusive(m)
    Perf.printWasted(m)

get_root_slug = -> 
  loc = fetch 'location'
  slug =  if !loc.url || loc.url == '/' 
            'proto_root' 
          else
            loc.url.replace(/\/$/, '')
  "/point/#{slug}"


dom.BODY = -> 
  
  root = get_root_slug()

  DIV
    id: 'main-content' #used in sizewhenrendered
    style:
      fontFamily: avenir
      fontSize: 16
      position: 'relative'

    onClick: -> 
      close_children()

    project_fonts() if project_fonts?

    # NAVIGATION()

    POINT 
      key: root
      point: root
      depth: 0

    TOOLTIP key: 'tooltip' if TOOLTIP?


working_width = -> 
  fickle.window_width - 2 * fickle.padding - fickle.gutter

text_width = (pnt, depth) -> 
  .55 * working_width()
  
opinion_width = (pnt, depth) -> 
  100 * Math.floor (working_width() - text_width(pnt, depth)) / 100


unfocused_opacity = .6
dom.POINT = -> 
  collapsed = @props.collapsed

  if !collapsed 
    fetch "/all#{@props.point}"
    return SPAN null if @loading()
    
  pnt = fetch @props.point


  depth = @props.depth 

  w = fickle.window_width

  histoheight = if collapsed 
                  fickle.collapsed_histo_height 
                else 
                  Math.min(300, Math.max(50, 3 * pnt.sliders?[0].values.length))

  open_children = get_open_children(pnt)
  
  open_child = if open_children.length > 0 then open_children[open_children.length - 1]

  minimize = !@props.minimized && collapsed && get_open_children(pnt.parent).length > 0

  max_depth = max_depth_of_open_point()

  DIV 
    style: 

      opacity: if minimize then unfocused_opacity
      pointerEvents: if minimize then 'none'

      position: 'relative'
      width: w
      left: if depth > 0 then -fickle.padding

      top: if depth > 0 && !collapsed && !open_child then -5
      padding: "#{if depth > 0 && !collapsed && !open_child then 20 else 15}px #{fickle.padding}px 5px #{fickle.padding}"

      borderTop: if depth > 0 && !collapsed && !open_child then '1px solid #d0d0d0' else '1px solid transparent'
      backgroundColor: if !collapsed then hsv2rgb(0,0, 1 - .06 * (max_depth - depth) )
      boxShadow: if depth > 0 && !collapsed then "rgba(0, 0, 0, 0.1) 0px 0px 10px 3px, rgba(0, 0, 0, 0.2) 0px 1px 2px"

      #transition: 'opacity .2s, background-color .2s, box-shadow .2s, padding .2s, top .2s'
      transitionTimingFunction: 'ease-in'


    onClick: (e) =>
      close_children pnt
      e.stopPropagation()

    DIV 
      style: 
        position: 'relative'

      # point description
      DIV 
        style:
          position: 'relative'
          display: 'inline-block'
          verticalAlign: 'top'
          width: if pnt.sliders?.length > 0 then text_width(pnt, depth) else w - 2 * fickle.padding
          top: if !collapsed then -7

        POINT_DESCRIPTION
          pnt: pnt
          depth: depth
          collapsed: collapsed
          minimized: @props.minimized || minimize || open_child
          min_height: if !collapsed && pnt.sliders?.length > 0 
                        histoheight + 15 
                      else 
                        fickle.collapsed_histo_height

      # slidergrams
      DIV
        style: 
          display: 'inline-block'
          position: 'relative'
          paddingLeft: fickle.gutter
          #verticalAlign: if !collapsed then 'bottom'

        for sldr in (pnt.sliders or [])
          SLIDERGRAM
            width: opinion_width(pnt, depth)
            height: histoheight
            sldr: sldr
            show_labels: true

    # sublists
    if !collapsed
      DIV 
        style: 
          position: 'relative'
          marginTop: 35

        for [type, children] in organize_children_by_type(pnt)
          if open_child
            contains_open_child = false 
            for c in (children or []) 
              if open_child == (c.key or c)
                contains_open_child = true 


          LIST
            key: type.key or type
            parent: pnt
            type: type
            points: children
            depth: @props.depth
            unfocused: false
            minimize: open_child && !contains_open_child
            contains_open_child: contains_open_child

dom.LIST = -> 
  type = fetch @props.type  
  return SPAN null if @loading()

  collapse_list_length = 5

  if !@local.collapsed?
    @local.collapsed = @props.points?.length > collapse_list_length + 1

  points = @props.points or []
  total_points = points.length

  points.sort (a,b) -> 
    b.sliders?[0]?.values?.length - a.sliders?[0]?.values?.length

  if @local.collapsed
    points = points.slice(0,collapse_list_length)

  DIV 
    style: 
      marginTop: 20
      marginBottom: 45
      position: 'relative'
      opacity: if @props.minimize then unfocused_opacity
      pointerEvents: if @props.minimize then 'none'
      #transition: 'opacity .2s'


    DIV 
      style: extend {}, list_styles.list_header(@props.depth),
        marginBottom: 8
        position: 'relative'
        opacity: if @props.contains_open_child then unfocused_opacity
        #transition: 'opacity .2s'

      resolve_type(type, 'category') or 'Points'

    DIV
      style: 
        marginTop: 0
        position: 'relative'

      for pnt in points
        POINT 
          key: pnt.key or pnt 
          point: pnt
          depth: @props.depth + 1
          collapsed: !is_point_open(pnt)
          minimized: @props.minimize


      if !@local.collapsed
        DIV 
          style: 
            opacity: if @props.contains_open_child then unfocused_opacity
            pointerEvents: if @props.contains_open_child || @props.minimize then 'none'
            #transition: 'opacity .2s'

          NEW_POINT
            type: type
            parent: @props.parent
            depth: @props.depth + 1

      else 
        DIV 
          style:
            backgroundColor: if !@props.contains_open_child && !@props.minimize then '#f6f7f9' else 'transparent'
            pointerEvents: if @props.contains_open_child || @props.minimize then 'none'
            cursor: 'pointer'
            padding: 8
            marginLeft: -8
            color: focus_blue
            fontSize: 18
            display: 'inline-block'
            marginTop: 4
            opacity: if @props.contains_open_child then unfocused_opacity
            #transition: 'opacity .2s, background-color .2s'

          onClick: => 
            @local.collapsed = false
            save @local


          "Show #{total_points - collapse_list_length} more"
          SPAN 
            style: 
              color: '#777'
            " or "
          "add a new one"

dom.POINT_DESCRIPTION = -> 
  collapsed = @props.collapsed
  pnt = @props.pnt 
  min_height = @props.min_height 
  depth = @props.depth 

  point_avatar_size = if collapsed then 40 else 40


  if !@local.collapse_description? && !@loading() && !collapsed
    s = sizeWhenRendered "<DIV class='embedded_html'>#{pnt.description}</div>",
        fontSize: 21 

    if s.height >= 300      
      @local.description_collapsed = @local.collapse_description = true
    else 
      @local.collapse_description = false
    save @local


  DIV
    style:
      border: '1px transparent' #parity with text area
      boxSizing: 'border-box'
      minHeight: min_height
      wordWrap: 'break-word'
      pointerEvents: if @props.minimized then 'none'
      position: 'relative' 
                    # positioning is to force Chrome to confine text
                    # selections to within the element. 
                    # http://stackoverflow.com/questions/14017818

    AVATAR
      onClick: if !collapsed then (e) =>
        toggle_point pnt, depth
        e.stopPropagation()      
      user: pnt.creator
      hide_tooltip: true      
      style: 
        width: point_avatar_size
        height: point_avatar_size
        left: -point_avatar_size - 20
        position: 'absolute'
        top: if collapsed then 5 else 12 
        verticalAlign: 'top'
        display: if pnt.treat_authorless then 'none'
        cursor: 'pointer'


    # Summary
    SPAN 
      style: extend list_styles.point_header(depth, !collapsed),
        cursor: if depth > 0 then 'pointer'
        #transition: "font-size .2s"
        borderBottom: "1px solid \
                       #{if @local.hover && collapsed then 'black' else 'transparent'}"
      onClick: (e) =>
        @local.hover = false
        toggle_point pnt, depth
        e.stopPropagation()
      onMouseEnter: if collapsed then => @local.hover = true; save(@local)
      onMouseLeave: if collapsed then => @local.hover = false; save(@local)


      pnt.summary
      if pnt.description?.length > 0 && collapsed
        SPAN 
          dangerouslySetInnerHTML: { __html: '&hellip;'}
          style: 
            color: light_gray

    # Meta data
    DIV 
      style: 
        fontSize: list_styles.point_header(depth).fontSize - 4
        color: light_gray
        fontStyle: 'italic'
        marginTop: if !collapsed then 4

      SPAN 
        style:
          paddingRight: 16

        prettyDate pnt.created_at

        if pnt.creator
          SPAN 
            style: {}
            " by #{fetch(pnt.creator)?.name or 'Anonymous'}"


      if pnt.children?.length > 0 && collapsed
        SPAN null, 
          SPAN 
            dangerouslySetInnerHTML: { __html: '&bull;'}
            style: 
              paddingRight: 4
          "#{pnt.children?.length}"

      # if !collapsed && depth > 0 
      #   IMG 
      #     src: '/images/expand.png'
      #     style:
      #       height: 15
      #       width: 15
      #       position: 'relative'
      #       top: 2
      #       cursor: 'pointer'
      #       opacity: .3              
      #     onClick: => 
      #       close_children()
      #       Earl.load_page pnt.key.substring(7)
      #       scrollTo(0,0)


    # Description
    if pnt.description && !collapsed
      collapse = !@local.collapse_description? || \
                  @local.description_collapsed 

      DIV 
        style: 
          paddingTop: 10
          marginTop: 10

        DIV 
          style: extend list_styles.point_text(depth), 
            fontSize: 18
            maxHeight: if collapse then 300
            overflow: if collapse then 'hidden'

          RENDER_HTML
            html: pnt.description

        if @local.collapse_description
          DIV 
            style:
              backgroundColor: if !@props.minimized then '#f6f7f9'
              cursor: 'pointer'
              padding: 8
              marginLeft: -8
              color: if !@props.minimized then focus_blue
              fontSize: 18
              marginTop: 4
              display: 'inline-block'

            onClick: (e) => 
              @local.description_collapsed = !@local.description_collapsed
              save @local
              e.stopPropagation()

            if @local.description_collapsed
              SPAN 
                style: 
                  textDecoration: if !@props.minimized then 'underline'
                'Expand full text'
            else 
              'Hide full text'

dom.NAVIGATION = -> 
  root = fetch get_root_slug()

  open = get_open_children(root)
  open.push root.key 
  open.reverse()

  return SPAN null if open.length == 1

  DIV 
    id: 'navigation'
    style: 
      position: 'fixed'
      top: 0
      left: 0
      fontSize: 16
      zIndex: 999
      backgroundColor: "rgba(0,0,0,.75)"
      padding: "3px #{fickle.padding}px"
      width: fickle.window_width


    for pnt, depth in open
      do (pnt, depth) => 
        pnt = fetch pnt 

        SPAN null,
          SPAN 
            style: 
              color: feedback_orange
              fontWeight: 700
              cursor: 'pointer'
            onClick: (e) => 
              close_children pnt 
              e.stopPropagation()
              # TODO: scroll to top of clicked point

            "#{pnt.summary.substring(0,20)}#{if pnt.summary.length > 20 then '...' else ''}"

          if depth < open.length - 1
            SPAN 
              style: 
                color: '#bbb'
                padding: '0 12px'

              '/'


is_point_open = (pnt) -> 
  fetch('open_points')[(pnt.key or pnt)]?

toggle_point = (pnt, depth) -> 
  open = fetch('open_points')
  depth ||= 0 

  already_open = open[pnt.key]?

  if already_open
    delete open[pnt.key]
  else 
    for k,v of open 
      delete open[k] if k != 'key'

    # only enable parents to be open 
    open_pnt = pnt 
    while true 
      open[open_pnt.key] = depth
      depth -= 1

      if !open_pnt.parent || depth < 0
        break 

      open_pnt = fetch open_pnt.parent 

  save open

get_open_children = (pnt) -> 
  return [] if !pnt 
  open = fetch('open_points')
  pnt = fetch pnt 

  open_children = []
  for k,v of open 
    if k != 'key'
      ancestor = fetch k 
      while ancestor.parent && ancestor = fetch(ancestor.parent)
        if ancestor.key == pnt.key
          open_children.push k 
          continue 

  open_children 

close_children = (pnt) -> 
  open = fetch('open_points')

  if pnt 
    pnt = fetch pnt 
    open_children = get_open_children pnt 
  else 
    open_children = (k for k,v of open when k != 'key')

  if open_children.length > 0 
    for k in open_children
      delete open[k]
    save open

max_depth_of_open_point = -> 
  open = fetch('open_points')
  max = 0
  for k,v of open 
    if k != 'key' && v > max 
      max = v
  max 


##############
# DATA ENTRY
#############

dom.NEW_POINT = -> 
  type = @props.type.key or @props.type
  you = your_key()
  w = 500

  depth = @props.depth

  DIV 
    style:
      position: 'relative'
      minHeight: 30
      marginTop: 10


    if !@local.editing
      SPAN 
        style: extend {}, list_styles.point_header(depth),
          #marginLeft: 68
          color: focus_blue
          cursor: 'pointer'
          borderBottom: "1px solid #{focus_blue}"

        onClick: (e) => 
          @local.editing = true; save(@local)
        
        "Add new"

    else 

      DIV 
        style: 
          marginLeft: -9
          display: 'inline-block'
          width: w
        TEXTAREA 
          key: 'summary'
          ref: 'summary'
          pattern:'^.{3,}'
          placeholder: "Summarize your point"
          required:'required'
          style: extend {}, list_styles.point_header(depth),
            width: w
            border: "1px solid #eaeaea"
            outline: 'none'
            padding: '6px 8px'
            resize: 'none'

        GROWING_TEXTAREA
          key: 'description'
          ref: 'description'
          placeholder: "Add details here (optional)"

          style: 
            fontSize: 16
            padding: '6px 8px'
            marginTop: 8
            width: '100%'
            minHeight: 40
            border: '1px solid #eaeaea'   
            outline: 'none'       

        DIV 
          style: 
            marginTop: 8

          SPAN 
            style: 
              backgroundColor: focus_blue
              color: 'white'
              cursor: 'pointer'
              borderRadius: 16
              padding: '4px 24px'
              display: 'inline-block'
              marginLeft: 12
              float: 'right'

            onClick: => 
              create_point
                parent: @props.parent
                type: type
                summary: @refs.summary.getDOMNode().value
                description: @refs.description.getDOMNode().value 

              @local.editing = false 
              save @local

            'Done'

          SPAN 
            style: 
              color: '#888'
              cursor: 'pointer'
              float: 'right'
              padding: '4px 0px'
            onClick: => @local.editing = null; save(@local)
            'cancel'

          DIV style: clear: 'both'





######################
# Style
######################

focus_blue = '#2478CC'
feedback_orange = '#F19135'
attention_magenta = '#FF00A4'
logo_red = "#B03A44"
light_gray = '#afafaf'
light_blue = '#F6F7F9'
bg_color = '#fdfdfd'

avenir = 'Avenir Next W01, Avenir Next, Avenir, Helvetica, sans-serif'
architect = 'Architects Daughter W00'



list_styles = 
  list_header: (depth) -> 
    fontSize: 38
    fontWeight: 500
    fontStyle: 'italic'

    # fontSize: 34
    # fontWeight: 500
    # fontFamily: architect

  point_header: (depth, expanded) -> 
    fontSize: if expanded then 38 else 20
    fontWeight: if expanded then 800 else 500

  point_text: (depth) -> 
    fontSize: 18
    fontWeight: 400


# style = document.createElement "style"
# style.innerHTML =   ""
# document.body.appendChild style