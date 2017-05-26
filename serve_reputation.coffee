
port = 3439
bus = require('statebus').serve

  file_store: 
    filename: 'db/reputation'
    backup_dir: 'db/backups/reputation'
  certs: 'certs/considerit-us'
  upload_dir: '/static/uploads'

  port: port
  client: (client) ->

    client('slider/*').to_save = (obj) ->
      u = client.fetch('current_user')

      old = bus.fetch(obj.key)

      if old 
        # prevent clobbering of slides
        missing = []

        for oldslide in (old.values or [])        
          found = false 

          for slide in (obj.values or [])
            if slide.user == oldslide.user 
              found = true 
              break 
          if !found 
            missing.push oldslide 

        if missing.length > 0 
          obj.values ||= []  
          
          for slide in missing 
            # only the current user is allowed to delete their slide
            if deslash(slide.user) != u.user.key
              obj.values.push slide

      bus.save obj

    client.shadows(bus)

deslash = (key) -> 
  if key?[0] == '/'
    key = key.substr(1)
  else 
    key

for k,v of bus.cache
  if k.match 'user/'
    if v.pic?.match 'uploads'
      v.pic = v.pic.replace('uploads', 'static')

express = require('express')

bus.http.use('/static', express.static('static'))
bus.http.use('/node_modules', express.static('node_modules'))

# get an index of all nested point lists
bus.http.get '/all', (r,res) => 
  html = """
      <script>
        document.title = 'All Nested Docs'
      </script>

      <ul>"""

  for k,v of bus.cache
    
    if k.match '_root' 
      if v.children?.length > 0 && (v.text && v.text != '' || v.children.length > 1 || bus.cache[deslash(v.children[0])].children?.length > 0)
        forum = k.split('_')[0]
        html += "<li><a target='_blank' href='#{forum}'>#{forum}</a></li>"

  html += '</ul>'

  res.send(html)


bus.http.get '/import_v1/*', (r, res) ->
  sub = r.url.split('/').pop()
  console.log 'IMPORTING', sub

  http_fetch "/subdomain?subdomain=#{sub}", sub
  http_fetch "/application", sub
  http_fetch "/users", sub
  http_fetch '/proposals?all_points', sub


# server everything else as a named forum
bus.http.get '/*', (r,res) => 
  #local = r.host.indexOf('localhost') > -1
  local = false

  if local
    prefix = ''
    server = "statei://localhost:#{port}"
  else 
    prefix = "https://considerit.us:#{port}"
    server = "state://considerit.us:#{port}"

  html = """
      <script type="coffeedom">
      bus.honk = false
      window.forum = "#{r.url.split('/')[1]}"
      #</script><script src="#{prefix}/node_modules/statebus/client.js" server="#{server}"></script>
      <script src="#{prefix}/client/fickle.coffee"></script>
      <script src="#{prefix}/client/shared.coffee"></script>
      <script src="#{prefix}/client/avatar.coffee" default-path="#{prefix}/static/uploads"></script>
      <script src="#{prefix}/client/tooltips.coffee"></script>      
      <script src="#{prefix}/client/slidergrams.coffee"></script>
      <script src="#{prefix}/client/app_reputation.coffee"></script>
      <script src="#{prefix}/static/vendor/md5.js"></script>
      <script src="#{prefix}/static/vendor/d3.quadtree.js"></script>

      <script>
        document.title = \"#{r.url.split('/')[1]}\"
      </script>

      """

  res.send(html)

















save_if_changed = (obj, props) ->
  changed = false 

  for k,v of props
    if JSON.stringify(obj[k]) != JSON.stringify(v)
      obj[k] = v
      changed = true

  if changed 
    bus.save obj 
    #console.log "SAVING", obj.key

  changed 





request = require('request')
request_queue = []

sending = false 
local = false 

http_fetch = (key, subdomain) -> 
  if sending 
    request_queue.push [key, subdomain]
  else 
    console.log "REQUESTING", "#{domain}#{key}" + (if local then (if key.indexOf('?') > -1 then '&' else "?") + "domain=#{subdomain}" else '')

    domain = if !local then "https://#{subdomain}.consider.it" else "http://localhost:3000"
    sending = true 
    request
      url: "#{domain}#{key}" + (if local then (if key.indexOf('?') > -1 then '&' else "?") + "domain=#{subdomain}" else '')
      headers: 
        Accept: 'application/json'
        'X-Requested-With': 'XMLHttpRequest'
      (err, response, body) -> 
        console.log "FETCH RETURNED ", subdomain, key

        try 
          objs = JSON.parse(body)
        catch e 
          console.log 'ERROR parsing body!!!', body, e

        if objs.key 
          import_obj objs 
        else 
          for obj in objs 
            import_obj obj


        sending = false 

        if request_queue.length > 0 
          req = request_queue.shift()
          http_fetch req[0], req[1]


processed = {}
root = asset_host = null

import_obj = (obj) -> 
  
  # console.log "IMPORTING", obj
  return if (processed[obj.key] && obj.key != '/subdomain') || obj.imported
  processed[obj.key] = obj


  # console.log "*************\n\n"
  # console.log obj.key, 'published'


  

  if obj.key.match '/application'
    asset_host = '//d2rtgkroh5y135.cloudfront.net'  #obj.asset_host

  else if obj.key.match '/proposals'
    for p in obj.proposals 
      import_obj p 

    for pnt in obj.points
      import_obj(pnt)


  else if obj.key.match '/users'
    for u in obj.users 
      import_obj u

  else if obj.key.match '/subdomain'
    key = "#{obj.name}_root"

    name = obj.name 

    if name == 'bitcoinclassic' 
      summary = "Bitcoin Classic"
    else if name == 'bitcoin'
      summary = "Bitcoin Consensus Census"
    else
      summary = name
    
    sub = 
      key: key
      created_at: obj.created_at
      imported: true
      text: summary
      children: []
      user: "/user/tkriplean"

    root = sub 
    bus.save sub


  else if obj.key.match "/proposal/"

    key = proposal_key obj
    proposal = bus.fetch key 

    opinions = []
    for o in (obj.opinions or [])
      try 
        user_key o.user
      catch e
        continue 

      opinions.push 
        user: '/' + user_key o.user
        value: (o.stance + 1) / 2
        updated: 1487184436120

    return if !obj.name
    return if obj.name == 'Consider.it can help me' && opinions.length < 2 && opinions[0]?.stance == .5
    return if !obj.user

    sldr =
      key: "slider/#{slugify(obj.name).substring(0,12)}_#{obj.id}"
      point: '/' + key 
      values: opinions
      poles: ['-','+']
    
    bus.save sldr 


    bus.save 
      key: key
      imported: true       
      text: obj.name + (if obj.description then "<div style='margin-top:4px;font-size:12px'>#{obj.description}</div>" else '')
      parent: '/' + root.key 
      children: []
      user: '/' + user_key obj.user 
      created_at: obj.created_at      
      sliders: ['/' + sldr.key]

    root.children ||= []
    keyd = '/' + key 
    if root.children.indexOf(keyd) < 0
      root.children.push keyd
      bus.save root

  else if obj.key.match "/point/" 
    return if obj.hide_name

    try 
      user_key obj.user
    catch e
      return 

    proposal = bus.fetch proposal_key obj.proposal
    user = user_key obj.user 

    opinions = []
    for o in (obj.includers or [])
      try 
        user_key o
      catch e
        continue 

      opinions.push 
        user: '/' + user_key o
        value: Math.random() / 2 + .4
        updated: 1487184436120

    key = point_key obj

    sldr =
      key: "slider/#{slugify(obj.nutshell).substring(0,12)}_#{obj.id}"
      point: '/' + key 
      values: opinions
      poles: ['-','+']
    
    bus.save sldr 

    #console.log "SAVING!!", obj.key, key, proposal.key
    # old_point = fetch(key)
    # if !old_point.imported && obj.comment_count > 0 && !processed["/comments/#{obj.id}"]
    #   http_fetch "/comments/#{obj.id}", subdomain.__old_name

    point = 
      key: key
      created_at: obj.created_at
      imported: true
      text: "<div style='font-size:14px'>" + (if obj.is_pro then '#pro ' else '#con ') + obj.nutshell + '</div>'
      parent: '/' + proposal.key
      children: []
      user: '/' + user
      sliders: ['/' + sldr.key]

    #changed = save_if_changed point
    bus.save point 

    proposal.children ||= []
    if proposal.children.indexOf(point.key) < 0
      #console.log "ADDED #{point.key} to #{proposal.key} #{proposal.imported}"
      proposal.children.push '/' + point.key
      bus.save proposal


  # else if obj.key.match "/comment/"
  #   old = fetch(obj.point)
  #   return if !old || !old.nutshell
  #   point = fetch point_key old
  #   user = user_key obj.user 

  #   point_type = fetch point.type 
  #   comment_type = get_type 'Comments', point_type

  #   if obj.body.length > 140 
  #     summary = obj.body.substring(0, 140)
  #     desc = obj.body.substring(140)
  #   else 
  #     summary = obj.body 
  #     desc = null

  #   key = comment_key obj 

  #   new_comment =
  #     key: key 
  #     created_at: obj.created_at
  #     summary: summary
  #     parent: point.key
  #     type: comment_type.key
  #     children: []
  #     creator: user
  #     description: if desc then desc
  #     imported: true 
  #     sliders: [{
  #         key: "/slider/#{slugify(summary).substring(0,12)}"
  #         parent: comment_type.sliders[0].key
  #         opinions: []
  #         imported: true
  #       }]

  #   changed = save_if_changed fetch(key), new_comment

  #   if changed 
  #     comment_type.type_children ||= []
  #     if comment_type.type_children.indexOf(new_comment.key) < 0
  #       comment_type.type_children.push new_comment.key
  #       save comment_type

  #     point.children ||= []
  #     if point.children.indexOf(new_comment.key) < 0
  #       point.children.push new_comment.key
  #       save point

  # users
  else if obj.key.match '/user/'
    key = user_key obj
    u = bus.fetch key 
    save_if_changed u, 
      name: if obj.name?.length > 0 then obj.name else 'anonymous'
      pic: if obj.avatar_file_name then u.avatar = "https://#{asset_host}/system/avatars/#{obj.key.split('/user/')[1]}/large/#{obj.avatar_file_name}"
      imported: true 
      pass: 'hello'
      email: "#{if obj.name?.length > 0 then obj.name else 'anonymous'}@test.dev"


extend = (obj) ->
  obj ||= {}
  for arg, idx in arguments 
    if idx > 0
      for own name,s of arg
        if !obj[name]? || obj[name] != s
          obj[name] = s
  obj

new_key = (type, desc) ->
  type ||= 'point'
  if desc
    slug = slugify(desc) 
    slug += "-" + Math.random().toString(36).substring(7)
  else 
    slug = Math.random().toString(36).substring(7)
  type + '/' + slug

slugify = (text) -> 
  text.toString().toLowerCase()
    .replace(/\s+/g, '-')           # Replace spaces with -
    .replace(/[^\w\-]+/g, '')       # Remove all non-word chars
    .replace(/\-\-+/g, '-')         # Replace multiple - with single -
    .replace(/^-+/, '')             # Trim - from start of text
    .replace(/-+$/, '')             # Trim - from end of text
    .substring(0, 30)


uniq = (arr) ->
  unique = []
  for el in arr
    if unique.indexOf(el) == -1
      unique.push el 

  unique 

crypto = require('crypto')
md5 = (obj) -> crypto.createHash('md5').update(JSON.stringify(obj)).digest("hex")

user_key = (obj) -> 
  obj = processed[(obj.key or obj)]
  deslash(obj.key + slugify(obj.name or 'anon').substring(0,12))
proposal_key = (obj) -> 
  obj = processed[(obj.key or obj)]
  "point/#{obj.slug}" + obj.key.split('/proposal/')[1]
point_key = (obj) -> 
  obj = processed[(obj.key or obj)]
  "point/" + slugify(obj.nutshell.substring(0,12)) + obj.key.split('/point/')[1]
comment_key = (obj) -> 
  obj = processed[(obj.key or obj)]
  "point/" + slugify(obj.body.substring(0,12)) + obj.key.split('/comment/')[1]

