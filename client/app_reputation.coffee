# Deep inquiry nested points prototype
#
#
# Requires: 
#
#   - avatar.coffee
#   - shared.coffee
#   - auth.coffee
#   - tooltips.coffee
#   - slidergrams.coffee
#   - fickle.coffee


#subs = ['all', 'bitcoin', 'bitcoinclassic', 'dao', 'rupaul', 'WSFFN', 'Svalin', 'HALA', 'livingvotersguide']
# subs = ['bitcoin', 'bitcoinclassic', 'dao', 'rupaul', 'WSFFN', 'Svalin', 'HALA', 'livingvotersguide']

#subs = ['all', 'rupaul', 'WSFFN', 'Svalin']

subs = ['Svalin']
subs = ['all', 'bitcoin', 'bitcoinclassic', 'dao']
subs = ['all', 'bitcoin', 'bitcoinclassic', 'dao', 'rupaul', 'WSFFN', 'Svalin']
subs = ['all', 'newblueplan']


has_parent = (pnt, root) -> 
  p = bus.cache[pnt]
  while p?.parent 
    p = bus.cache[p.parent]

  return p && p.key == root

window.reputation = (sub) ->
  users = {}

  for k,sldr of bus.cache

    if k.match('/slider/') && sldr.point && (sub == 'all' || has_parent(sldr.point, "/#{sub}_root"))
      fetch k

      pnt = fetch sldr.point

      user = pnt.user.key or pnt.user 
      if !users[user]?
        users[user] = 0 

      tot = 0 
      cnt = 0 
      values = sldr.values or []
      for slide in values 
        if slide.user != pnt.user 
          tot += slide.value
          cnt += 1
      avg = tot / (cnt or 1)

      users[user] += avg * tot

  sorted_rep = ([k,v] for k,v of users when v > 0)
  sorted_rep.sort (a,b) -> a[1] - b[1]
  sorted_rep


dom.PEOPLE_RANK = ->
  walk_tree = (pnt) ->
    pnt = fetch pnt 
    for child in (pnt.children or [])
      walk_tree child 
    for sldr in (pnt.sliders or [])
      fetch sldr

  roots = if @props.sub == 'all' 
            subs 
          else 
            [@props.sub]

  for sub in roots
    walk_tree "/#{sub}_root"   

  rep = reputation @props.sub
  return SPAN null if @loading() || !rep || rep.length == 0
  biggest = rep[rep.length - 1][1]

  abs = 120


  factor = abs / Math.sqrt(biggest)


  UL 
    style: 
      width: 100000 
      height: abs + 20


    for user in rep 
      AVATAR 
        key: user[0]
        user: user[0]
        style: 
          display: 'inline-block'
          width: Math.sqrt(user[1]) * factor
          height: Math.sqrt(user[1]) * factor
          verticalAlign: 'bottom'
          borderRadius: '50%'
          border: 'none'

dom.PEOPLE_RANK_PACK = ->
  walk_tree = (pnt) ->
    pnt = fetch pnt 
    for child in (pnt.children or [])
      walk_tree child 
    for sldr in (pnt.sliders or [])
      fetch sldr

  roots = if @props.sub == 'all' 
            subs 
          else 
            [@props.sub]

  for sub in roots
    walk_tree "/#{sub}_root"   

  rep = reputation @props.sub
  return SPAN null if @loading() || !rep || rep.length == 0
  biggest = rep[rep.length - 1][1]

  abs = 120


  factor = abs / (Math.sqrt(biggest) + 1)

  col = -> 
    height = 0 
    avatars = []
    while rep.length > 0 
      avatar = rep[0]
      a_height = Math.sqrt(avatar[1]) * factor

      break if height + a_height > abs 
      height += a_height 
      avatars.push rep.shift()

    LI 
      style: 
        width: Math.sqrt(avatars[avatars.length - 1][1]) * factor
        display: 'inline-block'
        verticalAlign: 'bottom'

      UL 
        style: 
          verticalAlign: 'bottom'
          listStyle: 'none'

        for user in avatars
          LI 
            style: 
              verticalAlign: 'bottom'
            AVATAR 
              key: user[0]
              user: user[0]
              style: 
                display: 'block'
                width: Math.sqrt(user[1]) * factor
                height: Math.sqrt(user[1]) * factor
                verticalAlign: 'bottom'
                borderRadius: '50%'
                border: 'none'


  UL 
    style: 
      width: 100000 
      height: abs + 20
      listStyle: 'none'

    while rep.length > 0 
      col()


dom.PEOPLE_REP_HISTO_FINESSE = ->
  walk_tree = (pnt) ->
    pnt = fetch pnt 
    for child in (pnt.children or [])
      walk_tree child 
    for sldr in (pnt.sliders or [])
      fetch sldr

  roots = if @props.sub == 'all' 
            subs 
          else 
            [@props.sub]

  for sub in roots
    walk_tree "/#{sub}_root"   

  rep = reputation @props.sub
  return SPAN null if @loading() || !rep || rep.length == 0

  rep_view = fetch "reputation_finesse_#{@props.sub}"
  abs = 120

  cols = get_cols @props.sub
  total = 0 
  for col in cols 
    total += col[0]



  width = Math.min total, fickle.document_width - 100

  HISTOGRAM
    width: width
    height: abs + 20
    sldr: rep_view


get_cols = (sub) -> 
  rep = reputation sub

  return if !rep || rep.length == 0 


  biggest = rep[rep.length - 1][1]
  abs = 120
  factor = abs / (Math.sqrt(biggest) + 1)

  cols = []

  while rep.length > 0 
    height = 0 
    avatars = []
    while rep.length > 0 
      avatar = rep[0]
      a_height = Math.sqrt(avatar[1]) * factor

      break if height + a_height > abs 
      height += a_height 
      avatars.push rep.shift()

    cols.push [Math.sqrt(avatars[avatars.length - 1][1]) * factor, avatars]

  cols

dom.PEOPLE_REP_HISTO_FINESSE.refresh = -> 
  rep = reputation @props.sub

  return if @loading() || !rep || rep.length == 0 

  biggest = rep[rep.length - 1][1]
  abs = 120
  factor = abs / (Math.sqrt(biggest) + 1)

  cols = get_cols @props.sub
  values = []

  w = fickle.document_width - 100
  increasing = false 

  cur_loc = 0

  total = 0 
  for col in cols 
    total += col[0]

  for col in cols 

    target = (cur_loc + col[0] / 2) / total 

    for user in col[1]
      values.push 
        user: user[0]
        value: target
        r: Math.sqrt(user[1]) * factor / 2

    cur_loc += col[0]

  rep_view = fetch "reputation_finesse_#{@props.sub}"
  if md5(values) != md5(rep_view.values)
    rep_view.values = values 
    rep_view.dirty_opinions = true
    save rep_view





dom.PEOPLE_REP_HISTO = ->
  walk_tree = (pnt) ->
    pnt = fetch pnt 
    for child in (pnt.children or [])
      walk_tree child 
    for sldr in (pnt.sliders or [])
      fetch sldr

  roots = if @props.sub == 'all' 
            subs 
          else 
            [@props.sub]

  for sub in roots
    walk_tree "/#{sub}_root"   

  rep = reputation @props.sub
  return SPAN null if @loading() || !rep || rep.length == 0

  rep_view = fetch "reputation_#{@props.sub}"

  biggest = rep[rep.length - 1][1]
  abs = 120

  values = []

  factor = abs / Math.sqrt(biggest)
  total = 0 
  for user in rep 
    total += Math.sqrt(user[1]) * factor



  #width = Math.min total, fickle.document_width - 100
  width = fickle.document_width - 100

  HISTOGRAM
    width: width
    height: abs + 20
    sldr: rep_view


dom.PEOPLE_REP_HISTO.refresh = -> 
  rep = reputation @props.sub

  return if @loading() || !rep || rep.length == 0 


  biggest = rep[rep.length - 1][1]
  abs = 120

  rep_view = fetch "reputation_#{@props.sub}"
  values = []

  factor = abs / Math.sqrt(biggest)

  w = fickle.document_width - 100
  cur_target = w
  increasing = false 
  for user in rep by -1 
    r = Math.sqrt(user[1]) * factor / 2

    if increasing 
      cur_target += r 
    else 
      cur_target -= r

    if !increasing && cur_target < 0
      cur_target = 0 
      increasing = true 
    else if increasing && cur_target > w 
      increasing = false 
      cur_target = w

    values.push 
      user: user[0]
      value: cur_target / w 
      r: r

    if increasing 
      cur_target += r
    else 
      cur_target -= r 

  if md5(values) != md5(rep_view.values)
    rep_view.values = values 
    rep_view.dirty_opinions = true
    save rep_view




# BODY is the entry point for the prototype. Trace from here
# to see how everything works. 
dom.body = ->
  ARTICLE 
    style: 
      width: fickle.document_width + 400
      backgroundColor: '#eee'
      fontFamily: '"helvetica neue",Arial,helvetica,sans-serif'
    
    STYLE """
        body {margin: 0;}
        a { 
          cursor: pointer; 
          text-decoration: underline;
        }
      """

    DIV 
      style: 
        padding: "20px #{fickle.outer_gutter}px"
        width: fickle.document_width

      DIV 
        style: 
          padding: fickle.doc_padding
          backgroundColor: 'white'
          boxShadow: '0 1px 2px rgba(0,0,0,.2)'
          minHeight: '100%'
          #margin: 'auto'          

        H1 null,

          'Reputation visuals for some existing considerit forums'

        for sub in subs 
          root = fetch "/#{sub}_root"

          DIV null,
            H1 
              style: 
                backgroundColor: 'purple'
                color: 'white'
                padding: 10
                marginTop: 30
              sub + (if sub == 'all' then '' else '.consider.it')

            H3 null,
              'Ranked from least to most, no attempt to fit' 

            PEOPLE_RANK
              sub: sub 

            H3 null,
              'Ranked from least to most, packed layout' 

            PEOPLE_RANK_PACK
              sub: sub 

            H3 null,
              'Put into histogram, size ~ reputation, target x position ~ rank' 

            PEOPLE_REP_HISTO
              sub: sub 

            H3 null,
              'Another histo strategy, with target x position based on packed layout'

            PEOPLE_REP_HISTO_FINESSE
              sub: sub

      TOOLTIP()


fickle.register (vars) -> 
  outer_gutter = 10
  doc_padding = 50
  slidergram_points_gutter = 50

  doc_width = Math.max 550, vars.window_width - outer_gutter * 2 - doc_padding * 2
  slidergram_width = 250 #Math.min(250, doc_width * .35)
  points_width = Math.min 750, doc_width - slidergram_width - slidergram_points_gutter - 1

  return {
    outer_gutter: outer_gutter
    doc_padding: doc_padding
    points_width: points_width
    slidergram_points_gutter: slidergram_points_gutter
    slidergram_height: 24
    slidergram_width: slidergram_width
  }

