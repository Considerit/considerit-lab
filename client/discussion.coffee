orange = '#e89e00'

fickle.register (upstream_vars) -> 
  outer_gutter = fickle.outer_gutter or 10
  doc_padding = fickle.doc_padding or 50
  slidergram_points_gutter = 50

  doc_width = Math.max 550, upstream_vars.window_width - outer_gutter * 2 - doc_padding * 2
  if (fetch('forum').forum or forum) in ['wa_infoaccess', 'sac', 'socioenactive']
    doc_width = Math.min 600, doc_width

  slidergram_width = 200 #Math.min(250, doc_width * .35)
  points_width = Math.min 600, doc_width - slidergram_width - slidergram_points_gutter - 1

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

  root.children ||= []

  template = @props.template or {}
  template[0] = defaults {}, template[0], 
    no_replies: true

  ARTICLE 
    style: extend {}, @props.style,
      paddingTop: 40
      width: fickle.points_width + fickle.slidergram_width + 60
      margin: 'auto'
      
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

    AUTH_FIRST()

    VIEW_SELECTOR
      hide: true

    ROOT
      key: root.key 
      point: root
      template: template

    TOOLTIP()


# Renders the top level of the discussion tree
dom.ROOT = -> 
  pnt = fetch @props.point
  current_user = fetch '/current_user'

  DIV 
    style: 
      position: 'relative'

    # Add a top-level post
    DIV 
      style: 
        position: 'relative'   
        left: fickle.subpoint_indentation
        display: if !current_user.logged_in then 'none'
      NEW_POST
        always_posting: true 
        parent: pnt 
        template: @props.template?[0] or {}
        fontSize: 24
        editor_width: fickle.points_width

    # Divider
    DIV 
      style: 
        position: 'relative'
        paddingBottom: 24

      DIV 
        style: 
          boxShadow: '0px 4px 5px rgba(0, 0, 0, 0.1)'
          borderBottom: '1px solid #dadada'
          width: fickle.window_width * 1.75
          pointerEvents: 'none'
          position: 'absolute'
          height: 5
          top: -5
          left: -fickle.window_width
          display: 'block'

    # children 
    LIST 
      parent: pnt 
      depth: 0
      template: @props.template

# Renders an indented list of subpoints
dom.LIST = -> 
  current_user = fetch '/current_user'

  parent = fetch @props.parent

  template = @props.template?[@props.depth] or {}

  if template.no_sort 
    children = parent.children 
  else 
    children = sorted_children parent.children, @props.depth


  # children 
  UL 
    key: "children_#{parent.key}"
    style: 
      listStyle: 'none'
      paddingLeft: fickle.subpoint_indentation
      paddingBottom: 4
      paddingTop: 8

    [
      if !template.no_replies && current_user.logged_in
        LI 
          key: 'add_post'
          style: 
            position: 'relative'

          NEW_POST
            key: "add_post_#{parent.key}"
            parent: parent
            template: template
            editor_width: fickle.points_width - fickle.subpoint_indentation * @props.depth

      for child in (children or [])
        LI 
          key: child.key or child
          style: 
            position: 'relative'

          POINT
            key: child
            point: child  
            depth: @props.depth + 1
            template: @props.template

    ]

# Renders a Point and children
dom.POINT = -> 
  pnt = fetch @props.point
  
  template = @props.template[@props.depth] or {}

  # ensure has the criteria subpoints

  if template.criteria

    missing = []
    for criterion in (fetch(template.criteria).children or [])
      found = false 
      for child in (pnt.children or [])
        if fetch(child).ref == (criterion.key or criterion)
          found = true; break 
      missing.push(fetch(criterion)) if !found 
    return SPAN null if @loading() 
    for criterion in missing 
      s = create_point
        parent: pnt 
        text: criterion.text
        ref: criterion.key
    if !pnt.auto_calc
      pnt.auto_calc = template.criteria
      save pnt 


  fontSize = template.style?.fontSize or 16
  avatar_size = 1.25 * fontSize

  DIV 
    style: 
      position: 'relative'

    # Points area
    DIV 
      style: 
        display: 'inline-block'
        verticalAlign: 'top'
        position: 'relative'
      
      if !template.hide_avatar
        AVATAR 
          user: pnt.user or your_key()
          style: 
            width: avatar_size
            height: avatar_size
            position: 'absolute'
            left: -avatar_size - 10
            borderRadius: '50%'
            zIndex: 2
            top: if @props.depth == 0 then 2
                  

      EDITABLE_POINT
        point: pnt 
        style: defaults {}, (template.style or {}),
          fontSize: fontSize
          width: fickle.points_width - fickle.subpoint_indentation * @props.depth
          backgroundColor: '#f2f2f2' if @local.hovering
          minWidth: 40
          minHeight: 20

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
        if pnt.auto_calc
          auto_calc_value_from_children pnt

        SLIDERGRAM
          sldr: slider
          width: fickle.slidergram_width
          height: fickle.slidergram_height
          read_only: !!pnt.auto_calc

    # children 
    LIST 
      parent: pnt 
      depth: @props.depth
      template: @props.template  


dom.NEW_POST = -> 
  fontSize = @props.fontSize or 16
  avatar_size = fontSize * 1.25
  template = @props.template or {}

  if @props.always_posting || @local.posting
    DIV 
      style: 
        position: 'relative'
        paddingBottom: 6
        paddingTop: 6
        marginBottom: 3

      DIV 
        style: 
          borderLeft: "2px dotted #{orange}"
          position: 'absolute'
          height: '103%'
          left: -avatar_size/2 - 10
          top: '-3%'

      AVATAR 
        style: 
          width: avatar_size
          height: avatar_size
          position: 'absolute'
          left: -avatar_size - 10
          borderRadius: '50%'
          zIndex: 2

        user: your_key()

      DIV 
        style: 
          position: 'relative'
          paddingBottom: 8

        NEW_POINT
          template: template 
          parent: @props.parent
          onSubmit: => @local.posting = false; save @local # oops, callback!
          end: => @local.posting = false; save @local # oops, callback!
          style: 
            fontSize: fontSize
            width: @props.editor_width

  else 
    BUTTON 
      onClick: => 
        @local.posting = true
        save @local 
      onKeyPress: (e) -> 
        if e.which in [13, 32]
          @local.posting = true  
          save @local 

      style: 
        backgroundColor: 'transparent'
        cursor: 'pointer'
        border: 'none'
        fontSize: 12
        padding: 0
        color: '#999'
        position: 'relative'
        verticalAlign: 'top'
        left: -fickle.subpoint_indentation
        
      template.new_post_label or 'reply'


dom.NEW_POINT = ->
  @local.text ||= ''

  template = defaults (@props.template or {}),
    placeholder: 'Say something'
    auto_subpoints: []

  DIV null,

    TEXT 
      value: @local.text 
      placeholder: template.placeholder

      onInput: (e) => 
        @local.text = e.target.value
        submit_enabled = @local.text.length > 0 
        if submit_enabled && template.validate
          submit_enabled = template.validate(@local.text)

        if @local.submit_enabled != submit_enabled
          @local.submit_enabled = submit_enabled
        
        save @local 

      onEmpty: (e) => 
        if e.which == 8 && @local.text == '' # delete key on empty field        
          @props.end?() # yuck

    if @local.submit_enabled
      submit = => 
        pnt = create_point 
          parent: @props.parent
          text: @local.text

        for subpoint in template.auto_subpoints
          s = create_point
            parent: pnt 
            text: subpoint 

        @local.text = null
        @local.submit_enabled = false 
        save @local

        @props.onSubmit?()

      BUTTON 
        onClick: submit 
        onKeyPress: (e) =>
          if e.which in [18,32]
            submit(e)
        style: 
          backgroundColor: orange
          color: 'white'
          fontSize: 16
          fontWeight: 600
          padding: '4px 8px'
          border: 'none'
          borderRadius: 8
          display: 'inline-block'
          position: 'relative'
          left: 8
          marginTop: 4
          cursor: 'pointer'
          verticalAlign: 'bottom'
        'Done'


dom.EDITABLE_POINT = -> 
  pnt = fetch @props.point

  pnt.text ||= ''

  TEXT 
    style: @props.style or {}
    value: pnt.text 
    disabled: if !fetch('/current_user').logged_in then 'disabled'
    onInput: (e) => 
      pnt.text = e.target.value
      save pnt

    onKeyDown: (e) =>
      if e.which == 8 && pnt.text == '' # delete key on empty field     
        if (pnt.children or []).length == 0
          delete_point pnt


dom.TEXT = ->
  txt = @props.value

  onBlur = @props.onBlur 
  onClick = @props.onClick

  editor_style = defaults (@props.style or {}),
    padding: 0
    margin: 0
    width: '100%'
    border: 'none'
    outline: 'none'   
    fontSize:  16
    display: 'inline-block'
    verticalAlign: 'top'

  if false || @local.editing

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
      display: if @props.hide then 'none'


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
      else 
        if depth == 0
          scores[child.key] = Infinity
        else
          scores[child.key] = 0 


    children.sort (a,b) -> 
      scores[(b.key or b)] - scores[(a.key or a)]

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
  pnt = fetch pnt
  parent = fetch pnt.parent 
  idx = parent.children.indexOf(pnt.key)
  if idx > -1 
    parent.children.splice(idx, 1)
    save parent 

  for slider in (pnt.sliders or [])
    del slider

  del pnt

auto_calc_value_from_children = (pnt) -> 
  pnt = fetch pnt 
  sldr = fetch pnt.sliders[0]

  ratings = []
  for child in pnt.children 
    child = fetch child 
    continue if !child.sliders or child.sliders.length == 0 
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
