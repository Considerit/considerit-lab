
th_style = extend {}, 
  marginTop: 'auto'

cell_style = 
  textAlign: 'center'
  minHeight: 50

criteria_weight_style = extend {}, th_style, 
  fontSize: 36
  fontWeight: 300
  fontFamily: 'Brandon Grotesque'

  #fontWeight: 700
  # fontFamily: 'Computer Modern Serif'

item_style = 
  fontSize: 16
  fontWeight: 400
  letterSpacing: -1
  #lineHeight: 1.2
  # fontFamily: 'Computer Modern Serif'

option_header_style = extend {}, item_style,  
  width: 120
  verticalAlign: 'bottom'
  #textAlign: 'left'


style = document.createElement "style"
style.id = "table-styles"
style.innerHTML =   """
  [data-widget='HEADER_ROW'], [data-widget='EVALUATION_ROW'], [data-widget='ADD_CRITERIA_ROW'], [data-widget='OVERALL_SCORE_ROW'] {
    display: flex;
    flex-direction: row;
  } 

  [data-widget='HEADER_ROW'] > div, [data-widget='EVALUATION_ROW'] > div, [data-widget='ADD_CRITERIA_ROW'] > div, [data-widget='OVERALL_SCORE_ROW'] > div {
    padding: 10px 16px 3px 16px;
  } 
"""
document.head.appendChild style


##########
# Calculates current sort order and compares it to previous sorts 
# of the same set of items. Returns current sorted list, last sort order,
# and whether the current sort order is dirty.
_saved_sorts = {} # not saved in statebus cause I don't want items saved to server
cached_sort_order = (args) -> 
  key = args.key or 'sort_order'
  items = args.items 
  sort_funk = args.sort_funk 
  freshen = args.freshen

  if key of _saved_sorts
    dirty_items = _saved_sorts[key]
  else 
    dirty_items = items
    freshen = true 

  # remove deleted items
  dirty_items = dirty_items.filter (item) -> item in items
  
  # add new items
  new_items = items.filter (item) -> item not in dirty_items
  dirty_items = dirty_items.concat new_items

  items.sort sort_funk

  if freshen
    dirty_items = items 

  _saved_sorts[key] = dirty_items

  is_dirty = md5(( (o.key or o) for o in items)) != md5(( (o.key or o) for o in dirty_items))

  v = fetch key
  if !!v.dirty != is_dirty
    v.dirty = !freshen && is_dirty
    save v

  return dirty_items






compare_by_sliders = (memoized) ->

  (a,b) ->

    for pnt in [a,b]
      if !memoized[(pnt.key or pnt)]
        pnt = fetch(pnt) 
        if pnt.auto_calc
          auto_calc_value_from_children pnt 
        
        memoized[pnt.key] =  if pnt.sliders
                               get_average_value(pnt.sliders[0])
                             else 
                               -1
    a = a.key if a.key 
    b = b.key if b.key 

    v1 = memoized[a] 
    v2 = memoized[b]
    if v1 == v2 
      a < b # for stable sort
    else 
      v2 - v1 






get_sorted_options = (args) ->
  key = 'options_sort' 
  sort = fetch key  # subscribe 
  args ||= {}

  #console.trace()
  if args.update_dirty || !_saved_sorts[key]
    root = fetch("/point_root/#{fetch('forum').forum}-options")
    return [] if Object.keys(root).length < 2
    items = root.children or []    

    cached_sort_order
      key: sort.key
      items: items
      sort_funk: compare_by_sliders({})
      freshen: args.freshen
  else 
    _saved_sorts[key] or []


get_sorted_criteria = (args) -> 
  key = 'criteria_sort'
  sort = fetch key # subscribe 
  args ||= {}

  if args.update_dirty || !_saved_sorts[key]

    root = fetch("/point_root/#{fetch('forum').forum}-criteria")
    return [] if Object.keys(root).length < 2
    items = root.children or []
    
    cached_sort_order
      key: sort.key
      items: items
      sort_funk: compare_by_sliders({})
      freshen: args.freshen
  else 
    _saved_sorts[key] or []




table_width = (cols) -> 
  Math.max fickle.window_width, fickle.cell_width * (cols + 4)

refresh_button = (args) ->
  args ||= {}  
  fill = args.fill or '#888'
  width = args.width or 20
  height = args.height or width

  SVG
    width: width 
    height: height
    viewBox: "0 0 100 125" 
    G null, 
      PATH
        fill: fill
        d: "M29.455,58.993c-3.851-8.647-2.062-18.514,4.554-25.136c6.619-6.616,16.492-8.405,25.146-4.556   c0.082,0.036,0.166,0.051,0.248,0.082l-4.238,3.327c-1.77,1.388-2.08,3.944-0.691,5.715c0.803,1.022,1.998,1.559,3.205,1.559   c0.883,0,1.766-0.284,2.512-0.868l10.744-8.428c1.219-0.955,1.789-2.518,1.473-4.033l-2.797-13.415   c-0.457-2.199-2.609-3.612-4.814-3.154c-2.201,0.458-3.615,2.614-3.156,4.816l1.291,6.197c-0.035-0.018-0.064-0.042-0.102-0.058   c-12.1-5.383-25.92-2.864-35.217,6.423c-9.285,9.292-11.805,23.112-6.42,35.209c0.749,1.683,2.401,2.683,4.134,2.683   c0.614,0,1.239-0.127,1.837-0.392C29.446,63.947,30.469,61.274,29.455,58.993z"
      PATH
        fill: fill
        d: "M78.814,37.026c-1.012-2.283-3.686-3.31-5.969-2.296c-2.283,1.012-3.311,3.685-2.295,5.967   c3.844,8.656,2.057,18.523-4.561,25.138c-6.482,6.482-16.081,8.321-24.601,4.774l4.231-3.317c1.767-1.388,2.079-3.947,0.688-5.718   c-1.387-1.767-3.946-2.079-5.714-0.688l-10.746,8.428c-1.218,0.955-1.79,2.518-1.473,4.031l2.796,13.413   C31.57,88.68,33.262,90,35.15,90c0.274,0,0.555-0.028,0.833-0.084c2.2-0.461,3.615-2.615,3.157-4.817l-1.285-6.167   c4.023,1.685,8.218,2.517,12.367,2.517c8.159,0,16.122-3.178,22.167-9.226C81.67,62.948,84.193,49.128,78.814,37.026z"


insert_grab_cursor_style()

dom.MULTICRITERIA = -> 
  options = fetch(@props.options)
  criteria = fetch(@props.criteria) 

  options = options.children or []
  
  for option in options
    sync_option_with_criteria
      option: option 
      criteria: criteria

  if @loading() && !@local.initialized
    return SPAN null 

  leaveFocus = => 
    active = fetch 'active_cells'
    active.col = null
    active.row = null
    save active 


  DIV 
    ref: 'table'
    style: 
      width: table_width(options.length)

    onMouseLeave: leaveFocus
    onBlur: leaveFocus

    HEADER_ROW
      key: "header"
      ref: 'header'
      options: @props.options

    HEADER_ROW
      key: "header-moored"
      options: @props.options
      is_fixed: true

    for criterion, row_idx in get_sorted_criteria()
      EVALUATION_ROW
        key: criterion.key or criterion
        criterion: criterion
        options: @props.options
        row_idx: row_idx

    ADD_CRITERIA_ROW
      key: 'add criteria'
      criteria: @props.criteria 
      options: @props.options

    OVERALL_SCORE_ROW
      key: 'overall score'
      options: @props.options 


dom.MULTICRITERIA.refresh = -> 

  if !@local.initialized? && @refs.table 
    @local.initialized = true 

    window.addEventListener 'scroll', (e) =>  

      if !@requested 
        @requested = true   
        requestAnimationFrame => 
          scrolltop = fetch 'scrolltop'
          scrollleft = fetch 'scrollleft'

          st = document.body.scrollTop
          sl = document.body.scrollLeft
          if scrollleft.left != sl
            scrollleft.left = sl 
            save scrollleft 
          if scrolltop.top != st
            scrolltop.top = st
            save scrolltop 
          

          moored_headers = fetch('moored_headers')

          @requested = false

          # header row
          el = @refs.header?.getDOMNode()
          return if !el
          parent_offset = 0
          parent_offset_left = 0 
          while el && !isNaN(el.offsetTop) 
            parent_offset += el.offsetTop #- el.scrollTop
            if el != document.body 
              parent_offset_left += el.offsetLeft #- el.scrollTop
            el = el.offsetParent

          if st > parent_offset #+ @refs.header.getDOMNode().offsetHeight
            if !moored_headers.header_row_unmoored || moored_headers.first_col_unmoored != parent_offset_left - sl
              moored_headers.header_row_unmoored = true 
              moored_headers.first_col_unmoored = parent_offset_left - sl
              save moored_headers         
          else if moored_headers.header_row_unmoored
            moored_headers.header_row_unmoored = false 
            moored_headers.first_col_unmoored = parent_offset_left - sl
            save moored_headers

          # first col 
          if sl > parent_offset_left
            if moored_headers.first_col_unmoored != sl
              moored_headers.first_col_unmoored = sl # parent_offset_left #+ document.body.scrollLeft
              save moored_headers 
          else if moored_headers.first_col_unmoored
            moored_headers.first_col_unmoored = false 
            save moored_headers




evaluation_hue = (val) -> 4 + (96-4) * val 
criterion_lightness = (val) -> 60 - (40 * val) 

dom.EVALUATION_ROW = -> 
  criterion = fetch(@props.criterion)

  options = fetch(@props.options).children or []

  crit2opt2eval = fetch('evaluation_to_criteria')
  active_cells = fetch 'active_cells'

  DIV 
    style: 
      backgroundColor: if @props.row_idx % 2 == 0 then '#f8f8f8'

    ROW_HEADER
      key: 'header'
      pnt: criterion
      row_idx: @props.row_idx

    ROW_HEADER
      key: 'header-moored'
      pnt: criterion
      row_idx: @props.row_idx
      moored: true

    OPINION_CELL
      key: criterion.key or criterion
      pnt: criterion 
      saturation: 0
      lightness: criterion_lightness
      row: @props.row_idx 
      col: 0 
      active: active_cells.row == @props.row_idx || active_cells.col == 0

    for option, idx in get_sorted_options() 
      continue if criterion.key not of crit2opt2eval
      for evaluation in crit2opt2eval[criterion.key][(option.key or option)] or []
        OPINION_CELL
          key: evaluation.key or evaluation
          pnt: evaluation
          criterion: criterion
          style: cell_style
          row: @props.row_idx
          col: idx + 1
          hue: evaluation_hue
          active: active_cells.row == @props.row_idx || active_cells.col == idx + 1

    DIV # dummy for add option
      style: 
        width: fickle.cell_width



window.resort_items = -> 
  get_sorted_options 
    update_dirty: true     
    freshen: true
  get_sorted_criteria
    update_dirty: true     
    freshen: true

wait_for_bus ->
  initialized = false  
  track_dirty_sort_order = bus.reactive ->
    f = fetch 'forum'

    return if !f.forum || f.forum == ''

    get_sorted_options 
      update_dirty: true 
      freshen: !initialized
    get_sorted_criteria   
      update_dirty: true 
      freshen: !initialized

    if !@loading()
      initialized = true 


  track_dirty_sort_order()



dom.REFRESH_SORT_ORDER = -> 
  criteria_sort = fetch 'criteria_sort'
  options_sort = fetch 'options_sort'

  dirty = options_sort.dirty || criteria_sort.dirty


  if dirty 
    selected = fetch('opinion').selected
    if !@time || selected != @selected
      @time = Date.now() / 1000
      @selected = fetch('opinion').selected
    time_to_resort = 10 - Math.round(Date.now() / 1000 - @time)
    if time_to_resort <= 0 
      resort_items()
      dirty = false
      @time = null
      @selected = null

  return SPAN null if !dirty
  
  DIV 
    style: 
      position: 'fixed'
      bottom: 0
      backgroundColor: "#444"
      color: 'white'
      textAlign: 'center'
      padding: '4px'
      width: '100%'
      zIndex: 999

    HEARTBEAT
      public_key: fetch('REFRESH_SORT_ORDER').key
      interval: 1000

    "You're out of sorts! #{time_to_resort} seconds until resorting"

    BUTTON 
      onClick: resort_items 
      onKeyPress: (e) -> 
        if e.which in [32,13]
          e.preventDefault()
          resort_items()
      style: 
        color: '#999'
        backgroundColor: 'transparent'
        border: 'none'
        fontSize: 12
        cursor: 'pointer'

      'do now'
      # refresh_button
      #   width: 40
      #   fill: '#bbb'


dom.HEADER_ROW = -> 
  options = fetch(@props.options).children or []

  add_option = => 
    pnt = create_point 
      parent: fetch(@props.options)
      text: ''
    to_focus = fetch 'to_focus'
    to_focus.pnt = pnt.key
    save to_focus

  active = fetch 'active_cells'

  setFocus = (idx) => 
    active.col = idx
    active.row = null
    save active 

  leaveFocus = => 
    active.col = null
    save active 

  scroll = fetch 'scrollleft'

  moored_headers = fetch('moored_headers')
  unmoored = moored_headers.header_row_unmoored
  unmoored_x = moored_headers.first_col_unmoored
  
  style = extend {}, (@props.style or {})

  if !@props.is_fixed && unmoored
    extend style, 
      visibility: if !@props.is_fixed && unmoored then 'hidden'

  if @props.is_fixed

    extend style, 
      position: 'fixed'
      top: 0
      left: unmoored
      width: table_width(options.length)
      backgroundColor: 'white'
      zIndex: 9999
      visibility: if !unmoored then 'hidden'
      transform: "translate(#{-scroll.left or 0}px, 0px)"


  DIV 
    style: style       

    DIV 
      style: extend {}, criteria_weight_style, 
        textAlign: 'right'
        width: fickle.cell_width
        backgroundColor: if @props.row_idx % 2 == 1 then '#f8f8f8' else 'white'
        borderBottom: '1px solid #bbb'
        #visibility: if unmoored_x || unmoored then 'hidden'


      'Criteria'

    DIV 
      style: extend {}, criteria_weight_style, 
        textAlign: 'center'
        width: fickle.cell_width
        borderBottom: '1px solid #bbb'
        position: 'relative'
      onMouseEnter: do(idx) => => setFocus(0)
      #onMouseLeave: leaveFocus
      onFocus: do(idx) => => setFocus(0)
      #onBlur: leaveFocus

      if get_sorted_criteria().length > 0 
        'Weight'

    for option,idx in get_sorted_options()

      DIV 
        key: option.key or option
        style: extend {}, option_header_style, th_style, cell_style,
          width: fickle.cell_width
          borderBottom: '1px solid #bbb'
        onMouseEnter: do(idx) => => setFocus(idx + 1)
        #onMouseLeave: leaveFocus
        onFocus: do(idx) => => setFocus(idx + 1)
        #onBlur: leaveFocus



        EDITABLE_POINT
          point: option
          autofocus: (@props.is_fixed && unmoored_x) || (!@props.is_fixed && !unmoored_x)
          style: extend {}, item_style, 
            verticalAlign: 'bottom'
            maxWidth: fickle.cell_width
            textAlign: 'center'

    DIV  
      style: extend {}, option_header_style, th_style, cell_style,
        width: fickle.cell_width
        borderBottom: '1px solid #bbb'
      BUTTON 
        onClick: add_option
        onKeyPress: (e) => 
          if e.which in [32, 13]
            e.preventDefault()
            add_option()

        style: 
          backgroundColor: 'transparent'
          border: 'none'
          cursor: 'pointer'
          fontSize: 16
          color: considerit_salmon
          fontWeight: 400

        '+'
        SPAN 
          style: 
            textDecoration: 'underline'
            paddingLeft: 2
            

          'add option'

dom.HEADER_ROW.refresh = -> 
  top = @getDOMNode().offsetTop
  height = @getDOMNode().offsetHeight

  if @local.top != top || @local.height != height
    @local.top = top    # bug! it should actually add together all 
                        # offset tops for offsetparents up to document.body!!! very brittle
    @local.height = height
    save @local 






wait_for_bus -> 
  evaluation_to_criteria_map = bus.reactive -> 
    f = fetch 'forum'

    return if !f.forum || f.forum == ''

    crit2opt2eval = 
      key: 'evaluation_to_criteria'

    options = get_sorted_options()
    options2evals = {}
    for option in options
      option = fetch option if !option.key
      options2evals[option.key] = ( fetch(evaluation) for evaluation in (option.children or []))

    for criterion in get_sorted_criteria()
      criterion = criterion.key if criterion.key
      crit2opt2eval[criterion] = {}
      for option in options 
        option = option.key if option.key
        crit2opt2eval[criterion][option] = ( evaluation.key for evaluation in options2evals[option] when evaluation.ref == criterion )
    
    bus.forget 
    save crit2opt2eval

  evaluation_to_criteria_map()






dom.ROW_HEADER = ->
  moored_headers = fetch('moored_headers')
  moorable = @props.moored
  unmoored_x = moored_headers.first_col_unmoored
  scroll = fetch 'scrolltop'

  
  setFocus = => 
    active_cells = fetch 'active_cells'
    active_cells.row = @props.row_idx 
    active_cells.col = null
    save active_cells 

  leaveFocus = => 
    active_cells = fetch 'active_cells'
    active_cells.row = null
    save active_cells 


  sty_col = 
    textAlign: 'right'
    width: fickle.cell_width
    backgroundColor: if @props.row_idx % 2 == 0 then '#f8f8f8' else 'white'

  if moorable
    extend sty_col, 
      position: 'fixed'
      left: 0
      top: @local.top
      transform: "translate(0, #{-scroll.top}px)"
      height: @local.height
      zIndex: 999
      visibility: if !unmoored_x then 'hidden'

  else if unmoored_x
    extend sty_col,
      visibility: 'hidden'

  DIV 
    style: extend {}, option_header_style, sty_col

    onMouseEnter: setFocus
    #onMouseLeave: leaveFocus
    onFocus: setFocus
    #onBlur: leaveFocus

    EDITABLE_POINT
      point: @props.pnt
      autofocus: (moorable && unmoored_x) || (!moorable && !unmoored_x)
      style: extend {}, item_style, 
        textAlign: 'right'
        verticalAlign: 'middle'

dom.ROW_HEADER.refresh = -> 
  if @props.moored
    node = @getDOMNode()

    if node 
      top = node.offsetTop
      height = node.offsetHeight

      if @local.top != top || @local.height != height
        @local.top = top
        @local.height = height
        save @local 

dom.ADD_CRITERIA_ROW = -> 
  criteria = fetch @props.criteria 
  options = fetch(@props.options).children or []

  add_criteria = => 
    pnt = create_point 
      parent: criteria 
      text: ''

    to_focus = fetch('to_focus')
    to_focus.pnt = pnt.key 
    save to_focus

  moored_headers = fetch('moored_headers')
  unmoored_x = moored_headers.first_col_unmoored
  scroll = fetch 'scrolltop'

  DIV null,
    for idx in [0,1]
      sty_col = 
        textAlign: 'right'
        width: fickle.cell_width
        backgroundColor: if @props.row_idx % 2 == 1 then '#f8f8f8' else 'white'

      if idx == 0 && unmoored_x
        extend sty_col, 
          visibility: 'hidden'
      else if idx == 1
        extend sty_col, 
          position: 'fixed'
          left: 0
          top: @local.top
          zIndex: 999
          visibility: if !unmoored_x then 'hidden'
          transform: "translate(0, #{-scroll.top}px)"

      DIV 
        style: extend {}, option_header_style, sty_col

        BUTTON 
          onClick: add_criteria
          onKeyPress: (e) => 
            if e.which in [32, 13]
              e.preventDefault()
              add_criteria()

          style: 
            backgroundColor: 'transparent'
            border: 'none'
            cursor: 'pointer'
            fontSize: 16
            color: considerit_salmon
            fontWeight: 400


          '+'
          SPAN 
            style: 
              textDecoration: 'underline'
              paddingLeft: 2
            'add criteria'

    DIV 
      style: 
        textAlign: 'center'
        fontSize: 24
        width: fickle.cell_width

      ''

    for option in options 
      DIV 
        style: 
          width: fickle.cell_width
        key: option.key or option

dom.ADD_CRITERIA_ROW.refresh = -> 
  top = @getDOMNode().offsetTop
  height = @getDOMNode().offsetHeight

  if @local.top != top || @local.height != height
    @local.top = top
    @local.height = height
    save @local 



dom.OVERALL_SCORE_ROW = -> 
  options = fetch(@props.options).children or []

  
  setFocus = => 
    active = fetch 'active_cells'
    active.row = 9999
    active.col = null
    save active 

  leaveFocus = => 
    active = fetch 'active_cells'
    active.row = null
    save active 

  return SPAN null if options.length == 0


  active_cells = fetch 'active_cells'

  DIV null,

    DIV 
      style: 
        width: fickle.cell_width


    DIV 
      style: extend {}, criteria_weight_style,
        textAlign: 'center'
        width: fickle.cell_width

      onMouseEnter: setFocus
      onMouseLeave: leaveFocus
      onFocus: setFocus
      onBlur: leaveFocus

      'Overall'

    for option, col_idx in get_sorted_options()
      OPINION_CELL
        key: option.key or option
        pnt: option
        hue: evaluation_hue
        row: 9999 
        col: col_idx + 1
        active: active_cells.row == 9999 || active_cells.col == col_idx + 1

    DIV # dummy for add option
      style: 
        width: fickle.cell_width


dom.OPINION_CELL = -> 

  pnt = fetch @props.pnt
  criterion = @props.criterion
  if @props.criterion
    criterion = fetch @props.criterion

  if Object.keys(pnt).length == 1 || (criterion && Object.keys(criterion).length == 1)
    return DIV null 

  sldr = fetch(pnt.sliders[0])
  if Object.keys(sldr).length == 1
    return DIV null

  if pnt.auto_calc
    auto_calc_value_from_children pnt

  saturation = if @props.saturation? then @props.saturation else 50
  if criterion
    weight = get_average_value(criterion.sliders[0])
    if weight > -1 
      weight = Math.round(weight * 80)
      saturation = 10 + weight
    else
      saturation = 0

  my_value = get_average_value(sldr)
  if my_value > -1
    hue = @props.hue?(my_value) or 0 
    lightness = @props.lightness?(my_value) or 75
  else 
    hue = 0 
    lightness = 100

  active = @props.active


  return SPAN null if @loading()


  setFocus = => 
    active_cells = fetch 'active_cells'

    if active_cells.row? && active_cells.row != @props.row 
      active_cells.row = null

    if active_cells.col? && active_cells.col != @props.col 
      active_cells.col = null 

    save active_cells 

    @local.focused = true
    save @local


  leaveFocus = => 
    active_cells = fetch 'active_cells'
    
    save active_cells

    @local.focused = false
    save @local

  show_slider = @local.focused || active

  DIV     
    onMouseEnter: setFocus
    onMouseLeave: leaveFocus
    onFocus: setFocus
    onBlur: leaveFocus


    style: extend {}, (@props.style or {}), cell_style,
      backgroundColor: if my_value > -1 then "hsl(#{hue}, #{saturation}%, #{lightness}%)"
      width: fickle.cell_width
      display: 'flex'
      flexDirection: 'column'        


    DIV 
      style: 
        display: if !show_slider then 'none'

      SLIDERGRAM
        sldr: sldr
        width: fickle.cell_width - 40
        height: 20
        no_label: true
        no_feedback: false
        read_only: !!pnt.auto_calc

    if my_value > -1 
      DIV 
        style: 
          display: if show_slider then 'none'
          fontSize: 14
          fontWeight: 700
          color: if lightness > 50 || saturation > 50 then 'black' else 'white'
          opacity: .5

        "#{(my_value * 10).toFixed(1)}"

    else 
      DIV  
        style: 
          opacity: .3
          display: if show_slider then 'none'

        "-"









###################################
# ADDING / EDITING POINTS
##



dom.EDITABLE_POINT = -> 
  pnt = fetch @props.point

  pnt.text ||= ''

  empty = pnt.text == ''

  style = extend {}, (@props.style or {}),
    width: '100%'
    backgroundColor: 'transparent'
  if empty 
    style = extend {}, style, 
      minHeight: 20
      backgroundColor: 'white'
      border: '1px solid #ccc'

  TEXT 
    key: "editable-#{pnt.key}"
    style: style
    value: pnt.text 
    disabled: if !fetch('/current_user').logged_in then 'disabled'
    focus_now: @props.autofocus && fetch('to_focus').pnt == pnt.key
    onInput: (e) => 
      pnt.text = e.target.value
      save pnt

    onKeyDown: (e) =>
      if e.which == 8 && pnt.text == '' # delete key on empty field     
        delete_point pnt

dom.EDITABLE_POINT.refresh = ->
  if @props.autofocus
    to_focus = fetch 'to_focus'
    if to_focus.pnt && (to_focus.pnt == (@props.point.key or @props.point)) 
      to_focus.pnt = null 
      save to_focus


set_style """ 
 .text_editor:empty:before {
    content: attr(placeholder);
    display: block;
    color: #999;
    pointer-events: none;
} """

dom.TEXT = ->
  txt = @props.value

  onBlur = @props.onBlur 
  onClick = @props.onClick

  editor_style = defaults (@props.style or {}),
    padding: 0
    margin: 0
    #width: '100%'
    border: 'none'
    outline: 'none'   
    display: 'inline-block'
    lineHeight: 1.2

  if (@props.focus_now || @local.focus_now) && !@local.editing 
    @local.editing = true 

  if @local.editing
    AUTOSIZEBOX extend @props,
      ref: 'editor'
      value: txt
      onBlur:  (e) => @local.editing = false; save @local; onBlur?(e) 
      style: editor_style
      autofocus: true

  else 
    start_editing = (e) => 
      @local.editing = true; save @local
      onClick?(e)
      save @local 

    DIV extend {}, @props,
      className: 'text_editor' + (@props.className or '')
      dangerouslySetInnerHTML: __html: txt
      style: editor_style
      onClick: (e) => 
        if !txt || txt.length == 0 
          start_editing(e)

      onDoubleClick: start_editing




auto_calc_value_from_children = (pnt) ->
  pnt = fetch pnt 
  return if !pnt.sliders? || pnt.sliders.length == 0 || !pnt.children

  sldr = fetch pnt.sliders[0]

  ratings = []

  for child,idx in pnt.children 
    child = fetch child 
    continue if !child.sliders? || child.sliders.length == 0 

    csldr = fetch child.sliders[0]

    # get my rating, if any, for this dimension
    v = get_your_slide csldr 
    continue if !v 

    # get my or the group's weight for the criteria
    criterion = fetch child.ref 
    continue if !criterion.sliders or criterion.sliders.length == 0 
    crit_sldr = fetch criterion.sliders[0]
    weight = get_your_slide crit_sldr
    if weight == null 
      sum = 0
      for w in crit_sldr.values 
        sum += w.value         
      weight = sum / crit_sldr.values.length
    else 
      weight = weight.value

    ratings.push [v.value,weight]

  return if ratings.length == 0

  #####
  # combine ratings across individual dimensions by weight 
  overall_score = 0
   
  # normalize weights so they add up to one
  rat_sum = 0
  for r in ratings 
    rat_sum += r[1]

  for r in ratings 
    overall_score += r[0] * r[1]
  overall_score /= rat_sum 

  my_score = get_your_slide sldr 
  if !my_score
    my_score = 
      user: your_key()
      explanation: ''
    sldr.values.push my_score 

  my_score.value = overall_score
  save sldr 


sync_option_with_criteria = (args) -> 

  missing = []
  criteria = fetch args.criteria 
  option = fetch args.option 

  for criterion in (criteria.children or [])
    found = false 
    for child in (option.children or [])
      if fetch(child).ref == (criterion.key or criterion)
        found = true; break 
    missing.push(fetch(criterion)) if !found 

  for criterion in missing 
    s = create_point
      parent: option 
      text: criterion.text
      ref: criterion.key

  if !option.auto_calc
    option.auto_calc = criteria.key
    save option 




create_point = (opt) -> 
  parent = opt.parent
  return if !parent

  sibling = opt.sibling
  if sibling
    sibling = fetch sibling
  parent = fetch parent

  sibling = if parent.children?.length > 0 then fetch(parent.children[parent.children.length - 1]) else null

  new_pnt = extend opt,
    key: new_key('point')
    parent: parent.key
    sliders: []
    text: opt.text or ''
    user: your_key()

  save new_pnt

  slidergram = create_slidergram
    anchor: new_pnt 
    poles: if sibling then fetch(sibling.sliders[0]).poles

  save new_pnt

  parent.children ||= []
  parent.children.push new_pnt.key
  save parent

  new_pnt 

window.delete_point = (pnt) ->
  return if !pnt
  console.log "DELETING #{pnt.key or pnt}"
  pnt = fetch pnt

  for child in (pnt.children or [])
    delete_point(child)

  if pnt.parent 
    parent = fetch pnt.parent 
    idx = parent.children.indexOf(pnt.key)
    if idx > -1 
      parent.children.splice(idx, 1)
      save parent 
  else 
    console.error('HMMMM, point doesn\'t have parent?', pnt)
  for slider in (pnt.sliders or [])
    del slider

  del pnt


