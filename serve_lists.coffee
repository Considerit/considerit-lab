
local = false

port = 9376
global.upload_dir = 'static/uploads/'
require('dotenv').config 
  path: 'confs/consideritus.env'

bus = require('statebus').serve
  port: port
  file_store: 
    filename: 'db/lists'
    backup_dir: 'db/backups/lists'
  certs: if !local then {
    private_key: 'certs/considerit-us/private-key'
    certificate: 'certs/considerit-us/certificate'
  }

bus.honk = true


cache = (key_or_object) -> 
  bus.cache[ (key_or_object.key or key_or_object) ]


bus('/all/point/*').on_fetch = (key) ->
  objs = {}

  process_type = (pnt) -> 
    return if !pnt.type || objs[pnt.type]

    type = cache pnt.type
    objs[pnt.type] = type

  process_sliders = (pnt) -> 
    return unless pnt.sliders?.length > 0

    for sldr in (pnt.sliders or [])
      sldr = cache sldr 

      if sldr.parent 
        objs[sldr.parent] = cache sldr.parent

      for o in (sldr.opinions or [])
        if !objs[o.user]
          objs[o.user] = cache o.user

  root = cache key.substring(4)

  return {} if !root 

  objs[root.creator] = cache root.creator
  objs[root.key] = root 
  
  process_sliders root 
  process_type root 

  # if root.parent 
  #   objs[root.parent] = cache root.parent

  for suggestion in (root.suggests or [])
    objs[suggestion] = cache suggestion

  for child in (root.children or [])
    child = cache child
    objs[child.key] = child 
    objs[child.creator] = cache child.creator
    process_type child
    process_sliders child 

  return {
    key: key
    objs: (obj for key,obj of objs when obj)
  }

express = require('express')

bus.http.use('/static', express.static('static'))
bus.http.use('/vendor', express.static('vendor'))
bus.http.use('/node_modules', express.static('node_modules'))
bus.http.use('/computer modern', express.static('computer modern'))


# server everything else as a named forum
prototypes = []

bus.http.get '/*', (r,res) => 
  #local = r.host.indexOf('localhost') > -1

  paths = r.url.split('/')
  paths.shift() if paths[0] == ''

  if paths[0] in prototypes
    prototype = paths[0]
    forum = paths[1].split('?')[0]
  else 
    prototype = null
    forum = paths[0].split('?')[0]

  if prototype
    app = "app_lists_#{prototype}"
  else 
    app = 'app_lists'

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
    <script src="#{prefix}/client/types.coffee"></script>

    <script src="#{prefix}/client/#{app}.coffee"></script>
    <script src="#{prefix}/static/vendor/md5.js"></script>
    <script src="#{prefix}/static/vendor/d3.quadtree.js"></script>

    <link href="https://cdnjs.cloudflare.com/ajax/libs/normalize/6.0.0/normalize.min.css" rel="stylesheet">
    
    <!----
    <script src="#{prefix}/client/presence.coffee"></script>
    
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
    <link rel="stylesheet" href="#{prefix}/static/computer modern/Serif/cmun-serif.css"/>
    <link rel="stylesheet" href="#{prefix}/static/computer modern/Bright/cmun-bright.css"/>
    <link rel="stylesheet" href="#{prefix}/static/computer modern/Concrete/cmun-concrete.css"/>
    <link rel="stylesheet" href="#{prefix}/static/computer modern/Sans/cmun-sans.css"/>
    <link rel="stylesheet" href="#{prefix}/static/computer modern/Typewriter/cmun-typewriter.css"/>
    <link rel="stylesheet" href="#{prefix}/static/computer modern/Upright Italic/cmun-upright-italic.css"/>

    <script>
      document.title = "Considerit prototype"
      window.forum = "#{forum}"
    </script>

      """

  res.send(html)
