
th_style = extend {}, 
  marginTop: 'auto'

cell_style = 
  textAlign: 'center'

criteria_weight_style = extend {}, th_style, 
  fontSize: 36
  #fontWeight: 700
  fontFamily: 'Computer Modern Serif'

item_style = 
  fontSize: 16
  fontWeight: 500
  #lineHeight: 1.2
  fontFamily: 'Computer Modern Serif'

option_header_style = extend {}, item_style,  
  width: 120
  verticalAlign: 'bottom'
  textAlign: 'left'


style = document.createElement "style"
style.id = "table-styles"
style.innerHTML =   """
  [data-widget='HEADER_ROW'], [data-widget='EVALUATION_ROW'], [data-widget='ADD_CRITERIA_ROW'], [data-widget='OVERALL_SCORE_ROW'] {
    display: flex;
    flex-direction: row;
    min-height: 50px;
  } 

  [data-widget='HEADER_ROW'] > div, [data-widget='EVALUATION_ROW'] > div, [data-widget='ADD_CRITERIA_ROW'] > div, [data-widget='OVERALL_SCORE_ROW'] > div {
    padding: 10px 16px;
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

  is_dirty = md5((o.key or o for o in items)) != md5((o.key or o for o in dirty_items))

  v = fetch key
  if v.dirty != is_dirty
    v.dirty = is_dirty 
    save v

  console.log dirty_items
  return dirty_items






compare_by_sliders = (memoized) -> 
  (a,b) ->

    for pnt in [a,b]
      if !memoized[(pnt.key or pnt)]
        pnt = fetch(pnt) 
        auto_calc_value_from_children pnt if pnt.auto_calc
        
        memoized[(pnt.key or pnt)] =  if pnt.sliders
                                        get_average_value(pnt.sliders[0])
                                      else 
                                        -1

    memoized[(b.key or b)] - memoized[(a.key or a)]                   



get_sorted_options = (args) ->
  key = 'options_sort' 
  fetch key # subscribe 
  args ||= {}
  if args.update_dirty || !_saved_sorts[key]
    items = fetch("/point_root/#{fetch('forum').forum}-options").children or []
    sort = fetch key

    cached_sort_order
      key: sort.key
      items: items
      sort_funk: compare_by_sliders({})
      freshen: args.freshen
  else 
    _saved_sorts[key] or []


get_sorted_criteria = (args) -> 
  key = 'criteria_sort'
  fetch key # subscribe 
  args ||= {}

  if args.update_dirty || !_saved_sorts[key]
    items = fetch("/point_root/#{fetch('forum').forum}-criteria").children or []
    sort = fetch key

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


dom.MULTICRITERIA = -> 
  options = fetch(@props.options).children or []
  criteria = fetch(@props.criteria) 

  return SPAN null if @loading()

  for option in options
    sync_option_with_criteria
      option: option 
      criteria: criteria

  leaveFocus = => 
    active = fetch 'active_cells'
    active.col = null
    active.row = null
    save active 

  DIV null,
    
    GRAB_CURSOR()



    DIV 
      ref: 'table'
      style: 
        width: table_width(options.length)

      onMouseLeave: leaveFocus
      onBlur: leaveFocus


      for idx in [0,1]
        HEADER_ROW
          ref: if idx == 0 then 'header'
          options: @props.options
          isFixed: idx == 1

      for criterion, row_idx in get_sorted_criteria()
        EVALUATION_ROW
          key: criterion
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

  if !@local.bound_to_scroll? && @refs.table 
    @local.bound_to_scroll = true 

    window.addEventListener 'scroll', (e) =>  

      if !@requested 
        @requested = true   
        requestAnimationFrame => 
          scroll = fetch 'scroll'
          scroll.left = document.body.scrollLeft 
          scroll.top = document.body.scrollTop
          save scroll

          moored_headers = fetch('moored_headers')

          @requested = false

          # header row
          el = @refs.header.getDOMNode()
          parent_offset = 0
          parent_offset_left = 0 
          while el && !isNaN(el.offsetTop) 
            parent_offset += el.offsetTop #- el.scrollTop
            if el != document.body 
              parent_offset_left += el.offsetLeft #- el.scrollTop
            el = el.offsetParent

          if document.body.scrollTop > parent_offset #+ @refs.header.getDOMNode().offsetHeight
            moored_headers.header_row_unmoored = true 
            moored_headers.first_col_unmoored = parent_offset_left - document.body.scrollLeft
            save moored_headers         
          else if moored_headers.header_row_unmoored
            moored_headers.header_row_unmoored = false 
            moored_headers.first_col_unmoored = parent_offset_left - document.body.scrollLeft
            save moored_headers

          # first col 
          if document.body.scrollLeft > parent_offset_left
            moored_headers.first_col_unmoored = document.body.scrollLeft # parent_offset_left #+ document.body.scrollLeft
            save moored_headers 
          else if moored_headers.first_col_unmoored
            moored_headers.first_col_unmoored = false 
            save moored_headers



dom.REFRESH_SORT_ORDER = -> 
  criteria_sort = fetch 'criteria_sort'
  options_sort = fetch 'options_sort'

  get_sorted_options 
    update_dirty: true 
  get_sorted_criteria   
    update_dirty: true 

  resort = -> 
    get_sorted_options 
      update_dirty: true     
      freshen: true
    get_sorted_criteria
      update_dirty: true     
      freshen: true

  if !@initialized && !@loading()
    resort()
    @initialized = !@loading()

  dirty = options_sort.dirty || criteria_sort.dirty


  BUTTON 
    onClick: resort 
    onKeyPress: (e) -> 
      if e.which in [32,13]
        e.preventDefault()
        resort()
    style: 
      color: '#999'
      backgroundColor: 'transparent'
      border: 'none'
      fontSize: 12
      opacity: if !dirty then 0.0 else 1.0
      position: 'absolute'
      left: -10
      top: 10
      cursor: 'pointer'

    refresh_button
      width: 40
      fill: '#bbb'


dom.HEADER_ROW = -> 
  options = fetch(@props.options).children or []

  add_option = => 
    pnt = create_point 
      parent: fetch(@props.options)
      text: ''

  active = fetch 'active_cells'

  setFocus = (idx) => 
    active.col = idx
    active.row = null
    save active 

  leaveFocus = => 
    active.col = null
    save active 

  scroll = fetch 'scroll'

  moored_headers = fetch('moored_headers')
  unmoored = moored_headers.header_row_unmoored
  unmoored_x = moored_headers.first_col_unmoored
  
  style = extend {}, (@props.style or {})



  if !@props.isFixed && unmoored
    extend style, 
      visibility: if !@props.isFixed && unmoored then 'hidden'

  if @props.isFixed

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

    SPAN 
      style: 
        position: 'relative'
      REFRESH_SORT_ORDER()

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
          style: extend {}, item_style, 
            verticalAlign: 'bottom'
            maxWidth: fickle.cell_width

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



dom.EVALUATION_ROW = -> 
  criterion = fetch(@props.criterion)

  options = fetch(@props.options).children or []

  active = fetch 'active_cells'
  setFocus = => 
    active.row = @props.row_idx 
    active.col = null
    save active 

  leaveFocus = => 
    active.row = null
    save active 

  moored_headers = fetch('moored_headers')
  unmoored_x = moored_headers.first_col_unmoored

  scroll = fetch 'scroll'

  DIV 
    style: 
      backgroundColor: if @props.row_idx % 2 == 0 then '#f8f8f8'

    for idx in [0,1]
      sty_col = 
        textAlign: 'right'
        width: fickle.cell_width
        backgroundColor: if @props.row_idx % 2 == 0 then '#f8f8f8' else 'white'

      if idx == 0 && unmoored_x
        extend sty_col, 
          visibility: 'hidden'
      else if idx == 1
        extend sty_col, 
          position: 'fixed'
          left: 0
          top: @local.top
          transform: "translate(0, #{-scroll.top}px)"
          height: @local.height
          zIndex: 999
          visibility: if !unmoored_x then 'hidden'

      DIV 
        style: extend {}, option_header_style, sty_col

        onMouseEnter: setFocus
        #onMouseLeave: leaveFocus
        onFocus: setFocus
        #onBlur: leaveFocus

        EDITABLE_POINT
          point: criterion
          style: extend {}, item_style, 
            textAlign: 'right'
            verticalAlign: 'middle'


    OPINION_CELL
      pnt: criterion 
      saturation: 0
      lightness: (val) -> 60 - (40 * val) 
      row: @props.row_idx 
      col: 0 

    for option, idx in get_sorted_options() 
      option = fetch option 
      for evaluation in (option.children or []) when fetch(evaluation).ref == criterion.key
        OPINION_CELL
          key: evaluation.key or evaluation
          pnt: evaluation
          criterion: criterion
          style: extend {}, cell_style
          row: @props.row_idx
          col: idx + 1
          hue: (val) -> 4 + (96-4) * val 

    DIV # dummy for add option
      style: 
        width: fickle.cell_width

dom.EVALUATION_ROW.refresh = -> 
  top = @getDOMNode().offsetTop
  height = @getDOMNode().offsetHeight

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

  moored_headers = fetch('moored_headers')
  unmoored_x = moored_headers.first_col_unmoored
  scroll = fetch 'scroll'

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

  active = fetch 'active_cells'
  setFocus = => 
    active.row = 9999
    active.col = null
    save active 

  leaveFocus = => 
    active.row = null
    save active 

  return SPAN null if options.length == 0




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
        hue: (val) -> 4 + (96-4) * val 
        row: 9999 
        col: col_idx + 1

    DIV # dummy for add option
      style: 
        width: fickle.cell_width


dom.OPINION_CELL = -> 

  pnt = fetch @props.pnt
  criterion = @props.criterion
  if @props.criterion
    criterion = fetch @props.criterion
  return DIV null if @loading()
  sldr = fetch(pnt.sliders[0])
  return DIV null if @loading()

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

  active = fetch 'active_cells'

  setFocus = => 
    active.focused = md5 [@props.row, @props.col]

    if active.row? && active.row != @props.row 
      active.row = null

    if active.col? && active.col != @props.col 
      active.col = null 

    save active 

  leaveFocus = => 
    active.focused = false 
    save active


  cell_height = 30

  focused = active.focused == md5 [@props.row, @props.col]

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

    if focused || active.row == @props.row || active.col == @props.col 

      SLIDERGRAM
        sldr: sldr
        width: fickle.cell_width - 40
        height: 20
        no_label: true
        no_feedback: true
        read_only: !!pnt.auto_calc

    else if my_value > -1
      DIV  
        style: 
          fontSize: 14
          fontWeight: 700
          color: if lightness > 50 || saturation > 50 then 'black' else 'white'
          opacity: .5

        "#{(my_value * 10).toFixed(1)}"
    else 
      DIV  
        style: 
          opacity: .3

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
    style: style
    value: pnt.text 
    disabled: if !fetch('/current_user').logged_in then 'disabled'
    onInput: (e) => 
      pnt.text = e.target.value
      save pnt

    onKeyDown: (e) =>
      if e.which == 8 && pnt.text == '' # delete key on empty field     
        #if (pnt.children or []).length == 0
        delete_point pnt


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

  if @local.editing

    AUTOSIZEBOX extend @props,
      ref: 'editor'
      value: txt
      onBlur:  (e) => @local.editing = false; save @local; onBlur?(e) 
      style: editor_style

  else 
    DIV null, 
      STYLE """ 
         .text_editor:empty:before {
            content: attr(placeholder);
            display: block;
            color: #999;
            pointer-events: none;
          } """

      DIV extend {}, @props,
        className: 'text_editor' + (@props.className or '')
        dangerouslySetInnerHTML: __html: txt
        style: editor_style
        onClick: (e) => 
          @local.editing = true; save @local
          @local.focus_now = true
          onClick?(e)
          save @local 


dom.TEXT.refresh = ->
  if @local.focus_now && @refs.editor
    @local.focus_now = false    
    el = @refs.editor.getDOMNode()
    el.focus()


auto_calc_value_from_children = (pnt) ->
  pnt = fetch pnt 
  return if !pnt.sliders? || pnt.sliders.length == 0 

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

  console.log pnt.children
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


