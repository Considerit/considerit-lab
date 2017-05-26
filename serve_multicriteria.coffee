local = false

port = 3666
bus = require('statebus').serve({
  file_store: 
    filename: 'db/multicriteria'
    backup_dir: 'db/backups/multicriteria'
  certs: if !local then 'certs/considerit-us'
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
})

# get all users who have given an opinion in this forum
bus('users/*').to_fetch = (k, rest) -> 
  forum = rest
  point_in_forum = (pnt) -> 
    return false if !pnt 
    pnt = bus.fetch(deslash(pnt.key or pnt))
    
    if pnt.parent?.match( "/point_root/#{forum}-options") || pnt.parent?.match( "/point_root/#{forum}-criteria")
      return true 
    else if pnt.parent
      point_in_forum(pnt.parent)

  users = {}
  for k,v of bus.cache
    if k.match(/slider\//) && v.anchor? && v.anchor.match(/\/point\//) && point_in_forum(v.anchor)
      for vv in (v.values or [])
        users[vv.user] = 1

  { users: Object.keys(users) }




bus.honk = false
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


# serve everything else as a named forum
prototypes = ['multicriteria']

bus.http.get '/*', (r,res) => 

  paths = r.url.split('/')
  paths.shift() if paths[0] == ''

  if paths[0] in prototypes
    prototype = paths[0]
    forum = paths[1].split('?')[0]
  else 
    prototype = null
    forum = paths[0].split('?')[0]


  if local
    prefix = ''
    server = "statei://localhost:#{port}"
  else 
    prefix = "https://considerit.us:#{port}"
    server = "state://considerit.us:#{port}"

  html = """
    <script type="coffeedom">
    bus.honk = false
    #</script><script src="#{prefix}/node_modules/statebus/client.js" server="#{server}"></script>
    <script src="#{prefix}/client/fickle.coffee"></script>
    <script src="#{prefix}/client/shared.coffee"></script>
    <script src="#{prefix}/client/avatar.coffee" default-path="#{prefix}/static/uploads"></script>
    <script src="#{prefix}/client/earl.coffee" history-aware-links root="#{prototype or ''}#{if prototype then '/' else ''}#{forum}"></script>      
    <script src="#{prefix}/client/tooltips.coffee"></script>      
    <script src="#{prefix}/client/slidergrams.coffee"></script>
    <script src="#{prefix}/client/state_dash.coffee"></script>
    <script src="#{prefix}/client/auth.coffee"></script>

    <script src="#{prefix}/client/multicriteria.coffee"></script>

    <script src="#{prefix}/client/presence.coffee"></script>
    <script src="#{prefix}/client/facepile.coffee"></script>

    <script src="#{prefix}/client/app_multicriteria.coffee"></script>
    <script src="#{prefix}/static/vendor/md5.js"></script>
    <script src="#{prefix}/static/vendor/d3.quadtree.js"></script>


    <link href="https://cdnjs.cloudflare.com/ajax/libs/normalize/6.0.0/normalize.min.css" rel="stylesheet">

    <!----
    <link href="https://maxcdn.bootstrapcdn.com/bootstrap/3.2.0/css/bootstrap.min.css" rel="stylesheet">
    <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/adapterjs/0.14.1/adapter.min.js"></script>
    <script src="https://tawk.space/janus.js"></script>
    <script src="https://code.jquery.com/jquery-2.1.4.min.js"></script>
    <script src="https://code.jquery.com/ui/1.11.4/jquery-ui.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jqueryui-touch-punch/0.2.3/jquery.ui.touch-punch.min.js"></script>
    <script src="https://tawk.space/node_modules/hark/hark.bundle.js"></script>
    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.2.0/js/bootstrap.min.js"></script>
    <script src="#{prefix}/client/tawk.coffee"></script>
    ----->

    <link rel="stylesheet" href="#{prefix}/static/css" type="text/css"/>
    <link rel="stylesheet" href="#{prefix}/static/fonts/computer modern/Serif/cmun-serif.css"/>
    <link rel="stylesheet" href="#{prefix}/static/fonts/computer modern/Bright/cmun-bright.css"/>
    <link rel="stylesheet" href="#{prefix}/static/fonts/computer modern/Sans/cmun-sans.css"/>

    <link rel="stylesheet" href="#{prefix}/static/fonts/cool script/cool script.css"/>

    <!----
    <link rel="stylesheet" href="#{prefix}/static/fonts/computer modern/Typewriter/cmun-typewriter.css"/>
    <link rel="stylesheet" href="#{prefix}/static/fonts/computer modern/Upright Italic/cmun-upright-italic.css"/>
    <link rel="stylesheet" href="#{prefix}/static/fonts/computer modern/Concrete/cmun-concrete.css"/>
    ---->

    <script>
      document.title = "Considerit prototype"
      window.forum = "#{forum}"
      window._cur_prototype = "#{prototype}"
    </script>

      """

  res.send(html)


