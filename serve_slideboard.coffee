port = 3015
global.upload_dir = 'static/uploads/'

local = false 
require('dotenv').config 
  path: 'confs/slideboard.env'

require './server/email'
auth_server = require './server/auth_server'


bus = require('statebus').serve({
  port: port
  file_store: 
    save_delay: 10000
    filename: './db/slideboard'
    backup_dir: './db/backups/slideboard'
  certs: if !local then {
    private_key: 'certs/slider-chat/private-key'
    certificate: 'certs/slider-chat/certificate'
  }
  
  client: (client) ->
    auth_server(bus, client)

    # client('slider/*').to_save = (obj) ->
    #   u = client.fetch('current_user')

    #   old = bus.fetch(obj.key)

    #   if old 
    #     # prevent clobbering of slides
    #     missing = []

    #     for oldslide in (old.values or [])        
    #       found = false 

    #       for slide in (obj.values or [])
    #         if slide.user == oldslide.user 
    #           found = true 
    #           break 
    #       if !found 
    #         missing.push oldslide 

    #     if missing.length > 0 
    #       obj.values ||= []  
          
    #       for slide in missing 
    #         # only the current user is allowed to delete their slide
    #         if deslash(slide.user) != u.user.key
    #           obj.values.push slide

    #   bus.save obj

    client('post/*').to_delete = (key) ->
      pst = bus.fetch key
      if pst.channel 
        channel = pst.channel
        if !channel
          console.error("Can't delete post because it doesn't have a channel set")

        idx = bus.fetch messages_key(channel)
        i = idx.posts.findIndex (p) -> p == pst || pst.key == p

        if i > -1
          idx.posts.splice(i, 1)
          bus.save(idx)


      for sel in (pst.selections or [])
        bus.delete deslash(sel)

      # delete children
      for child in (pst.children or [])
        bus.delete child

      if pst.parent 
        parent = bus.fetch(deslash(pst.parent))
        i = parent.children.findIndex (p) -> p == pst || pst.key == p

        if i > -1
          parent.children.splice(i, 1)
          bus.save(parent)

      # bus.del(pst)

    client('selection/*').to_delete = (key) -> 
      sel = bus.fetch(key)
      # delete sliders
      for sldr in (sel.sliders || [])
        bus.delete sldr

      # delete from parent post
      parent = bus.fetch(deslash(sel.post))
      i = parent.selections.indexOf(sel.key)
      if i > -1
        parent.selections.splice(i, 1)
        bus.save(parent)

      # bus.del(sel)


    client.shadows(bus)
})

bus.honk = false

express = require('express')
bus.http.use('/static', express.static('static'))
bus.http.use('/node_modules', express.static('node_modules'))

deslash = (key) -> 
  if key?[0] == '/'
    key = key.substr(1)
  else 
    key


bus('post/*').to_save = (obj, t) ->
  
  # For new posts, need to add to post tree
  if !obj.parent
    channel = obj.channel
    all = bus.fetch(messages_key(channel))
    all.posts ||= []
    if !(all.posts.find((p) -> p.key == obj.key) )
      all.posts.unshift obj
      bus.save all 
  else 
    parent = bus.fetch(deslash(obj.parent))
    parent.children ||= []
    if !(parent.children.find((p) -> p.key == obj.key))
      parent.children.push obj
      bus.save parent

  t.done obj





bus('index/*').to_fetch = (k, rest) -> 
  console.time('index')
  channel = rest
  posts = bus.clone(bus.fetch(messages_key(channel)))

  users = (p.user for p in (posts.posts or []) when p.user).filter (value, index, self) -> 
    self.indexOf(value) == index

  all = {
    posts: ('/' + p.key for p in (posts.posts or []))
    preload: (p for p in (posts.posts or []).slice(0,5))
    users: (bus.fetch(deslash(u)) for u in users)
  }
  console.timeEnd('index')
  all

bus('seen/*').to_save = (obj, t, json) -> 
  channel = deslash json.namespace
  user = deslash json.user 

  seen = bus.fetch "#{user}/seen/#{channel}"

  mark_seen = (obj_or_key) -> 
    k = activity_key(obj_or_key)
    seen[k] = (new Date()).getTime()

  if typeof obj.saw == 'string'
    obj.saw = [obj.saw]

  for saw in obj.saw 
    mark_seen saw 

  bus.save seen

  t.done {}

bus('recent/*').to_fetch = (k, json) ->
  console.time('recent')
  channel = deslash json.namespace
  user = deslash json.user 

  unseen = {}

  data_for_thread = (posts) -> 
    posts ||= []
    posts.sort (a,b) -> a.edits[0].time - b.edits[0].time

    post_data = []
    for pst in posts 
      post_data.push data_for_post(pst)

    slides = []
    for p in post_data
      slides = slides.concat(p.slides)
    slides.sort (a,b) -> b.updated - a.updated

    last_activity = Math.max((slides[0]?.updated or 0), \
                              posts[posts.length - 1].edits[0].time)

    seen_all_listens = true 
    seen_all_posts = true 
    for p in post_data 
      if !p.seen 
        unseen['/' + p.post.key] = last_activity
        seen_all_posts = false
      seen_all_listens &&= p.seen_all_listens

    {
      posts: post_data
      first_activity: posts[0].edits[0].time
      last_activity
      seen_all_posts
      seen_all_listens
      slides
    }

  data_for_post = (pst) -> 
    pst = bus.fetch(pst)

    slides = get_ordered_slides(pst)

    last_activity = Math.max((slides[0]?.updated or 0), \
                              pst.edits[0].time)

    seen_all_listens = true
    for slide in slides 
      ts = (slide.updated or pst.edits[0].time + 1000)
      if !has_seen(pst, ts) && !has_seen(slide.slider, ts)
        unseen['/' + slide.slider] = ts
        seen_all_listens = false 
    {
      post: '/' + pst.key
      last_activity
      seen: has_seen(pst, pst.edits[0].time)
      seen_all_listens
      slides
    }

  get_ordered_slides = (pst) -> 
    pst = bus.fetch(pst)
    slides = []
    for key in (pst.selections or [])
      key = deslash key
      sel = bus.fetch(key)
      if !sel || !sel.sliders?
        continue
      for sldr in sel.sliders 
        sldr = deslash sldr
        sldr = bus.fetch(sldr)
        for v in (sldr.values or [])
          v.slider = sldr.key
          slides.push v
    slides.sort (a,b) -> b.updated - a.updated
    slides 

  has_seen = (obj_or_key, ts) -> 
    if user 
      key = activity_key(obj_or_key.key or obj_or_key)
      seen = bus.fetch "#{user}/seen/#{channel}"
      found = seen[key]? && seen[key] >= ts
      return true if found
      # compatibility with old
      key = activity_key_old(obj_or_key.key or obj_or_key)
      seen[key]? && seen[key] >= ts
    else 
      true

  posts = bus.clone(bus.fetch(messages_key(channel)))

  data = []

  for pst in (posts.posts or [])
    thread = data_for_thread [pst].concat((pst.children or []))
    data.push thread
  data.sort (a, b) -> b.last_activity - a.last_activity

  preload = []
  for thread in data.slice(0,20)
    for post in (thread.posts or [])
      pst = bus.fetch(deslash(post.post))
      preload.push pst

  console.timeEnd('recent')
  {
    posts: data
    unseen: unseen
    preload: preload
  }

activity_key = (obj) -> "_#{bus.fetch(obj).key}"
activity_key_old = (obj) -> "_/#{bus.fetch(obj).key}"

messages_key = (channel) -> 
  switch channel
    when 'cheeseboard'
      'cheesemail'
    when 'considerit'
      'email'
    else 
      "#{channel}mail"



# Disallow search indexing
bus.http.get '/robots.txt', (req, res) ->
    res.type('text/plain')
    res.send("User-agent: *\nDisallow: /")

# serve everything else as a named forum
bus.http.get '/*', (r,res) => 
  local = r.host.indexOf('localhost') > -1

  server = if local then "http://localhost:#{port}" else "state://#{r.host}:#{port}"

  if local
    prefix = ''
    server = "statei://localhost:#{port}"
  else 
    prefix = "https://slider.chat:#{port}"
    server = "state://slider.chat:#{port}"

  channel = r.url.split('/')[1]
  channel = channel.replace(/\/Statebus$/, '/statebus')
  html = """
      <script type="coffeedom">
      bus.honk = false
      window.forum = "#{channel}"
      #</script><script src="#{prefix}/node_modules/statebus/client.js" server="#{server}"></script>

      <script src="#{prefix}/node_modules/statebus/extras/react.js" charset="utf-8"></script>
      <script src="#{prefix}/node_modules/statebus/extras/sockjs.js" charset="utf-8"></script>
      <script src="#{prefix}/node_modules/statebus/extras/coffee.js" charset="utf-8"></script>
      <script src="#{prefix}/node_modules/statebus/statebus.js" charset="utf-8"></script>

      <script src="#{prefix}/static/vendor/md5.js"></script>
      <script src="#{prefix}/static/vendor/d3.quadtree.js"></script>
      <script src="#{prefix}/static/vendor/cassowary.js"></script>
      <script src="#{prefix}/static/vendor/linkify.min.js"></script>
      <script src="#{prefix}/static/vendor/emoji.js"></script>

      <script src="#{prefix}/client/shared.coffee"></script>
      <script src="#{prefix}/client/auth.coffee"></script>
      <script src="#{prefix}/client/tooltips.coffee"></script>
      <script src="#{prefix}/client/avatar.coffee" default-path="static/uploads"></script>
      <script src="#{prefix}/client/presence.coffee"></script>
      <script src="#{prefix}/client/state_dash.coffee"></script>

      <script src="#{prefix}/client/slidergram-textanchor.coffee"></script>
      <script src="#{prefix}/client/slidergrams.coffee"></script>

      <script src="#{prefix}/client/facepile.coffee"></script>
      <script src="#{prefix}/client/app_slideboard.coffee"></script>


      <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/adapterjs/0.14.1/adapter.min.js"></script>
      <script src="https://tawk.space/janus.js"></script>
      <script src="https://code.jquery.com/jquery-2.1.4.min.js"></script>
      <script src="https://code.jquery.com/ui/1.11.4/jquery-ui.min.js"></script>
      <script src="https://cdnjs.cloudflare.com/ajax/libs/jqueryui-touch-punch/0.2.3/jquery.ui.touch-punch.min.js"></script>
      <script src="https://tawk.space/node_modules/hark/hark.bundle.js"></script>      
      <script src="#{prefix}/client/tawk.coffee"></script>

      <script>
        document.title = "#{channel}"
      </script>

      """

  res.send(html)







#########
# Data migration

# port_users = false 
# slim_db = false 


# prefixes = {}
# whitelist = ['users', 'recent', 'user', 'email', 'cheesemail', 'selection', 'slider', 'post']
# if slim_db 

#   if port_users 
#     try 
#       bus.cache['users/passwords'] = {
#         key: 'users/passwords'
#       }
#       bus.cache['users'].all = []
#     catch 
#       console.log 'here'

#   setTimeout ->
#     for k,v of bus.cache
#       prefix = k.split('/')[0]

#       if (whitelist.indexOf(prefix) == -1 && prefix.indexOf('mail') == -1) || (prefix == 'user' && k.split('/').length > 2 && k.indexOf('seen') == -1 ) || (prefix == 'slider' && v.pos)
#         prefixes[prefix] ||= 0
#         prefixes[prefix] += 1

#         console.log 'deleting', k
#         bus.del k
#         # delete bus.cache[k]
#     console.log prefixes

#   , 100



# if port_users
#   setTimeout -> 
#     users = {all: [], key: 'users'}
#     passes = {key: 'users/passwords'}
#     for k,v of bus.cache
#       if k.match('user/') && !k.match('recent/') && !k.match('/seen/') && !k.match('/seen_for')
#         console.log 'matched', k

#         v.display_name = v.name 
#         v.name = k.split('/')[1]
#         v.pic = v.avatar
#         v.pass = require('bcrypt-nodejs').hashSync('pass')
#         v.email = v.name + "@test.ghost"
#         #bus.save v
#         users.all.push v 
#     bus.save users 
#     bus.save passes
#   , 1000


migrate_data = -> 
  migrate = bus.fetch('migrations')

  if !migrate.make_login_email
    console.warn 'MIGRATING to email login!'

    for key, usr of bus.cache
      if key.match('user/') && key.split('/').length == 2 && usr.email
        usr.login = usr.email
        bus.save usr

    migrate.make_login_email = true
    bus.save migrate 

migrate_data()

