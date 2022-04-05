fickle.register (vars) -> 
  outer_gutter = 10
  doc_padding = 50
  slidergram_points_gutter = 50

  doc_width = Math.max 550, vars.window_width - outer_gutter * 2 - doc_padding * 2
  slidergram_width = 250 #Math.min(250, doc_width * .35)
  points_width = Math.min 750, doc_width - slidergram_width - slidergram_points_gutter - 1

  return {
    points_width: points_width
    slidergram_height: 24
    slidergram_width: slidergram_width
    subpoint_indentation: 30
  }

dom.DISCUSSION = ->
  # forum is spit out in the html file served by server.coffee...ugly!
  root = fetch @props.root
  return SPAN null if @loading()

  ARTICLE 
    style: {}

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

    VIEW_SELECTOR()

    ROOT
      key: root.key 
      point: root


# Renders the top level of the discussion tree
dom.ROOT = -> 
  pnt = fetch @props.point

  if !pnt.children 
    pnt.children = []
    save pnt 

  if pnt.children.length == 0 
    create_point
      parent: pnt
      after: true
    save pnt

  if !@local.initialized
    set_focus pnt
    @local.initialized = true 

  DIV 
    style: 
      position: 'relative'


    # Points area      
    DIV 
      style: 
        width: fickle.points_width
        display: 'inline-block'
        verticalAlign: 'top'
        position: 'relative'

      DIV 
        style: 
          minHeight: fickle.slidergram_height * (pnt.sliders or []).length          

        EDITABLE_POINT
          point: pnt 
          depth: 0

    # children
    LIST 
      parent: pnt 
      depth: 0


# Renders an indented list of subpoints
dom.LIST = -> 
  parent = fetch @props.parent
  children = sorted_children parent.children, @props.depth

  UL 
    style: 
      listStyle: 'none'
      paddingTop: 12
      paddingLeft: if @props.depth > 0 then fickle.subpoint_indentation else 18

    for child in (children or [])
      LI 
        key: child.key or child
        style: 
          position: 'relative'
        POINT
          key: child
          point: child  
          depth: @props.depth + 1



# Renders a Point and children
dom.POINT = -> 
  pnt = fetch @props.point

  DIV 
    style: 
      position: 'relative'


    # Points area      
    DIV 
      style: 
        width: fickle.points_width - (if @props.depth > 0 then 18 else 0) - (if @props.depth > 1 then 44 * (@props.depth - 1) else 0)
        display: 'inline-block'
        verticalAlign: 'top'
        position: 'relative'

      # bullet
      if @props.depth > 0 

        DIV 
          style: 
            borderRadius: '50%'
            width: 4
            height: 4
            backgroundColor: 'black'
            position: 'absolute'
            left: -12
            top: 6

      DIV 
        style: 
          minHeight: fickle.slidergram_height * (pnt.sliders or []).length
          backgroundColor: '#f2f2f2' if @local.hovering
          

        EDITABLE_POINT
          point: pnt 
          depth: @props.depth
      

    # Slidergrams area
    DIV 
      style: 
        display: 'inline-block'
        verticalAlign: 'top'
        width: fickle.slidergram_width
        marginLeft: 30

      onMouseEnter: (e) => @local.hovering = true; save @local
      onMouseLeave: (e) => @local.hovering = false; save @local

      for slider in (pnt.sliders or [])
        SLIDERGRAM
          sldr: slider
          width: fickle.slidergram_width
          height: fickle.slidergram_height
          one_sided: true

    # children
    LIST 
      parent: pnt 
      depth: @props.depth 





# All the interactions with the text of a Point
dom.EDITABLE_POINT = ->
  pnt = fetch @props.point
  fetch 'point_with_focus'

  if !@local.text? || !@local.has_focus
    @local.text = pnt.text or ''

  cursor_position = =>
    # code for testing before/after from http://stackoverflow.com/questions/7451468
    el = @refs.editor.getDOMNode()
    range = window.getSelection().getRangeAt(0)
    pre_range = document.createRange()
    pre_range.selectNodeContents el
    pre_range.setEnd(range.startContainer, range.startOffset)
    this_text = pre_range.cloneContents()
    at_start = this_text.textContent.length == 0
    post_range = document.createRange()
    post_range.selectNodeContents el
    post_range.setStart(range.endContainer, range.endOffset)
    next_text = post_range.cloneContents()
    at_end = next_text.textContent.length == 0
    at_start &&= !at_end
    [at_start, at_end]

  txt = if @local.has_focus then @local.text else pnt.text

  props = 
    ref: 'editor'
    contentEditable: !@local.html_edit_mode
    initial_height: 18
    style:
      padding: 0
      margin: 0
      width: '100%'
      minHeight: 18
      fontSize: 16
      border: 'none'
      outline: 'none'   
      display: 'inline-block'
      fontSize:  if @props.depth == 0 then 24 else 16
      fontWeight: 700 if @props.depth == 0 

    onKeyDown: (e) => 

      # create new point on newline 
      if e.which == 13 

        # if the cursor is at the beginning, and there's text, create a new point before it
        # if the cursor is at the end, create new point after

        [at_start, at_end] = cursor_position()

        if at_end || at_start 
          create_point
            parent: pnt.parent
            sibling: if @props.depth > 0 then pnt
            after: at_end 

          e.preventDefault()

      # indent/dedent when appropriate
      else if e.which == 9 

        if e.shiftKey
          parent = fetch(pnt.parent)
          if parent.key != "/#{forum}_root"
            grandparent = fetch parent.parent
            idx = grandparent.children.indexOf parent.key 
            parent.children.splice parent.children.indexOf(pnt.key), 1
            grandparent.children.splice idx + 1, 0, pnt.key
            pnt.parent = grandparent.key 
            save pnt 
            save grandparent
            save parent
            @local.has_focus = false
            set_focus pnt

        else
          parent = fetch pnt.parent 
          idx = (parent.children or []).indexOf(pnt.key)
          # need a sibling to do this
          if idx > 0
            sibling = fetch parent.children[idx - 1]
            sibling.children ||= []
            sibling.children.push pnt.key 
            save sibling 
            parent.children.splice idx, 1
            save parent 
            pnt.parent = sibling.key 
            save pnt

            @local.has_focus = false
            set_focus pnt


        e.preventDefault()

      else if e.which == 8 && (!pnt.text || pnt.text == '') && (pnt.children or []).length == 0
        delete_point pnt

      else if e.which == 72 && e.ctrlKey # cntrl - H toggles html editing mode
        @local.text = pnt.text
        @local.html_edit_mode = !@local.html_edit_mode
        save @local
        e.preventDefault()
        e.stopPropagation()

      # This turns out to be more complex than I thought, because the current sorting order of children
      # needs to be accommodated
      # else if e.which in [38, 40] # UP / DOWN
      #   [at_start, at_end] = cursor_position()
      #   return if !(at_start || at_end)

      #   # if we press up at start or end of line, change focus, with these priorities:
      #   #    - last child of previous sibling
      #   #    - previous sibling of the parent
      #   #    - parent
      #   if e.which == 38
      #     parent = fetch pnt.parent 
      #     idx = parent.children.indexOf pnt.key 
      #     if idx > 0
      #       sibling = fetch parent.children[idx - 1]
      #       if sibling.children?.length > 0
      #         set_focus sibling.children[sibling.children.length - 1]
      #       else 
      #         set_focus sibling
      #     else 
      #       set_focus parent

      #   # if we press down at start or end of line, change focus, with these priorities:
      #   #    - first child
      #   #    - next sibling
      #   #    - next sibling of the parent
      #   else if e.which == 40
      #     if pnt.children?.length > 0
      #       set_focus pnt.children[0]
      #     else 
      #       found = false 
      #       target = pnt
      #       while target.parent 
      #         parent = fetch target.parent 
      #         idx = parent.children.indexOf target.key 
      #         if idx < parent.children.length - 1
      #           set_focus parent.children[idx + 1]
      #         else if parent.parent
      #           grandparent = fetch parent.parent
      #           idx = grandparent.children.indexOf parent.key
      #           if idx < grandparent.children.length - 1
      #             set_focus grandparent.children[idx + 1]
      #         target = parent 

    onInput: (e) => 

      if @local.html_edit_mode
        new_text = e.currentTarget.value
      else 
        new_text = @refs.editor.getDOMNode().textContent
      
      pnt.text = new_text
      save(pnt)

    onBlur: =>
      @local.has_focus = false
      @local.html_edit_mode = false
      save @local

    onFocus: (e) => 
      @local.has_focus = true
      save @local


  if !@local.html_edit_mode
    DIV extend props,
      dangerouslySetInnerHTML: if !@local.html_edit_mode then {__html: txt} else null
  else 
    GROWING_TEXTAREA extend props,
      defaultValue: txt 
    

dom.EDITABLE_POINT.refresh = -> 
  focus = fetch 'point_with_focus'

  if focus.pnt == (@props.point.key or @props.point) 
    if !@local.has_focus
      el = @refs.editor.getDOMNode()
      el.focus()

      # set cursor position to the editor
      if typeof window.getSelection != "undefined" \
          && typeof document.createRange != "undefined"
        range = document.createRange()
        range.selectNodeContents(el)
        range.collapse(false)
        sel = window.getSelection()
        sel.removeAllRanges()
        sel.addRange(range)
      else if typeof document.body.createTextRange != "undefined"
        textRange = document.body.createTextRange()
        textRange.moveToElementText(el)
        textRange.collapse(false)
        textRange.select()

    focus.pnt = null 

# Hacky view selection widget. Currently only used for sort order.
dom.VIEW_SELECTOR = -> 
  views = [
    'by average'
    'by entry'
    'by you'
  ]

  view = fetch 'view'
  if !view.selected?
    view.selected = views[0]
    save view

  DIV 
    style: 
      textAlign: 'right'

    SPAN 
      style: 
        paddingRight: 4
      'Viewing'

    SELECT 
      style: 
        fontSize: 18
      value: view.selected
      onChange: (e) => 
        view.selected = e.target.value
        save view 

      for n,idx in views
        OPTION 
          value: n
          style: {}
          n

sorted_children = (children, depth) -> 
  
  children = children?.slice() or []

  # sort children
  view = fetch('view').selected
  if view != 'by entry'
    scores = {}
    prev_score = 0
    for child in children
      child = fetch child 
      score = 0
      slides = 0
      for sldr in (child.sliders or [])
        sldr = fetch sldr 
        for o in (sldr.values or [])
          if view == 'by average' or (view == 'by you' && o.user == your_key())
            score += o.value * 2 - 1
            slides += 1
      if slides > 0
        scores[child.key] = score / slides 
      # Rule: points without any drags immediately follow previous sibling. This 
      #       makes it much more clear when inserting a new point into a sorted list.
      else 
        scores[child.key] = prev_score - 0.0000000001
             # this won't quite work if inserting a new point into the first position

      if child.text?.indexOf('#done') > 0 
        scores[child.key] = -99999999
      prev_score = scores[child.key]


    children.sort (a,b) -> 
      scores[(b.key or b)] - scores[(a.key or a)]

create_point = (opt) -> 

  parent = opt.parent
  after = opt.after 
  return if !parent

  sibling = opt.sibling
  if sibling
    sibling = fetch sibling
  parent = fetch parent

  new_pnt = 
    key: new_key('point')
    parent: parent.key
    sliders: []
    text: ''
    user: your_key()


  if !sibling 
    parent.children.push new_pnt.key
  else 
    insert_at = parent.children.indexOf((sibling.key or sibling))
    if after 
      insert_at += 1
    parent.children.splice insert_at, 0, new_pnt.key

  save parent

  save new_pnt

  poles = null 
  if sibling && sibling.sliders?.length > 0 
    poles = fetch(sibling.sliders[0]).poles
    
  slidergram = create_slidergram
    anchor: new_pnt 
    poles: poles

  save new_pnt

  set_focus new_pnt

  new_pnt 


window.delete_point = (pnt) ->
  pnt = fetch pnt

  if pnt.parent # this should always execute, but sometimes data gets corrupted
    parent = fetch pnt.parent 
    idx = parent.children.indexOf(pnt.key)
    if idx > -1 
      parent.children.splice(idx, 1)
      save parent 

  for slider in (pnt.sliders or [])
    del slider

  del pnt

  if pnt.parent 
    if parent.children.length == 0 
      set_focus parent 
    else 
      set_focus parent.children[idx - 1]

set_focus = (pnt) ->
  return if !pnt 

  focus = fetch 'point_with_focus'
  focus.pnt = pnt.key or pnt 
  save focus

