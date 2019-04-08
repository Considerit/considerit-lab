local = false 
port = 3606
global.upload_dir = 'static/uploads/'

require('dotenv').config 
  path: 'confs/consideritus.env'

slidergram_client_handlers = require('./server/slidergrams.coffee')
require './server/email'
auth_server = require './server/auth_server'

bus = require('statebus').serve({
  file_store: 
    filename: 'db/discuss'
    backup_dir: 'db/backups/discuss'
  certs: if !local then {
    private_key: 'certs/considerit-us/private-key'
    certificate: 'certs/considerit-us/certificate'
  }

  port: port
  client: (client) ->
    slidergram_client_handlers(bus,client)
    auth_server(bus, client)    
    client.shadows(bus)

})


bus.honk = false

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
  #local = r.host.indexOf('localhost') > -1
  local = false

  paths = r.url.split('/')
  paths.shift() if paths[0] == ''

  if paths[0] in prototypes
    prototype = paths[0]
    forum = paths[1].split('?')[0]
  else 
    prototype = null
    forum = paths[0].split('?')[0]

  if prototype
    app = "app_discuss"
    dis = "discussion"
  else 
    app = 'app_discuss'
    dis = 'discussion'

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

    <script src="#{prefix}/client/#{dis}.coffee"></script>
    <script src="#{prefix}/client/multicriteria-summary.coffee"></script>

    <script src="#{prefix}/client/presence.coffee"></script>

    <script src="#{prefix}/client/#{app}.coffee"></script>
    <script src="#{prefix}/static/vendor/md5.js"></script>
    <script src="#{prefix}/static/vendor/d3.quadtree.js"></script>
    <script src="#{prefix}/static/vendor/emojione.js"></script>

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

