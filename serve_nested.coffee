local = false 

port = 3006
global.upload_dir = 'static/uploads/'
require('dotenv').config 
  path: 'confs/consideritus.env'

slidergram_client_handlers = require('./server/slidergrams.coffee')
require './server/email'
auth_server = require './server/auth_server'


bus = require('statebus').serve({
  port: port
  file_store: 
    filename: 'db/nested'
    backup_dir: 'db/backups/nested'
  certs: if !local then {
    private_key: 'certs/considerit-us/private-key'
    certificate: 'certs/considerit-us/certificate'
  }
  
  client: (client) ->
    slidergram_client_handlers(bus, client)
    auth_server(bus, client)    

    client('point/*').to_delete = (key, t) ->
      pnt = bus.fetch key

      for sel in (pnt.selections or [])
        bus.delete deslash(sel)

      # delete children
      for child in (pnt.children or [])
        bus.delete deslash(child)

      if pnt.parent 
        parent = bus.fetch(deslash(pnt.parent))
        i = parent.children.findIndex (p) -> pnt.key == deslash(p)

        if i > -1
          parent.children.splice(i, 1)
          bus.save(parent)

      bus.delete key
      t.done()

    client.shadows(bus)
})

deslash = (key) -> 
  if key?[0] == '/'
    key = key.substr(1)
  else 
    key

for k,v of bus.cache
  if k.match 'user/'
    if v.pic?.match 'uploads'
      v.pic = v.pic.replace('uploads', 'static')


bus.honk = false 

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
      console.log v, v.children?[0], bus.cache[v.children?[0]]
      if v.children?.length > 0 && (v.text && v.text != '' || v.children.length > 1 || bus.cache[deslash(v.children[0])].children?.length > 0)
        forum = k.split('_')[0]
        html += "<li><a target='_blank' href='#{forum}'>#{forum}</a></li>"

  html += '</ul>'

  res.send(html)


# server everything else as a named forum
bus.http.get '/*', (r,res) => 
  local = r.host.indexOf('localhost') > -1

  if local
    prefix = ''
    server = "statei://localhost:#{port}"
  else 
    prefix = "https://considerit.us:#{port}"
    server = "state://considerit.us:#{port}"

  forum = r.url.split('/')[1]

  html = """
      <script type="coffeedom">
      bus.honk = false
      window.forum = "#{forum}"
      #</script><script src="/node_modules/statebus/client.js" server="state://#{r.host}:#{port}"></script>

      <script src="#{prefix}/node_modules/statebus/extras/react.js" charset="utf-8"></script>
      <script src="#{prefix}/node_modules/statebus/extras/sockjs.js" charset="utf-8"></script>
      <script src="#{prefix}/node_modules/statebus/extras/coffee.js" charset="utf-8"></script>
      <script src="#{prefix}/node_modules/statebus/statebus.js" charset="utf-8"></script>


      <script src="#{prefix}/client/fickle.coffee"></script>
      <script src="#{prefix}/client/shared.coffee"></script>
      <script src="#{prefix}/client/avatar.coffee" default-path="#{prefix}/static/uploads"></script>
      <script src="#{prefix}/client/earl.coffee" history-aware-links root="#{forum}"></script>      
      <script src="#{prefix}/client/tooltips.coffee"></script>      
      <script src="#{prefix}/client/slidergrams.coffee"></script>
      <script src="#{prefix}/client/state_dash.coffee"></script>
      <script src="#{prefix}/client/auth.coffee"></script>
      <script src="#{prefix}/client/presence.coffee"></script>

      <script src="/client/discussion-nested.coffee"></script>
      <script src="/client/app_nested.coffee"></script>



      <script src="#{prefix}/static/vendor/md5.js"></script>
      <script src="#{prefix}/static/vendor/d3.quadtree.js"></script>
      <script src="#{prefix}/static/vendor/emojione.js"></script>
      
      <script>
        (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
        (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
        m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
        })(window,document,'script','https://www.google-analytics.com/analytics.js','ga');

        ga('create', 'UA-55365750-3', 'auto');
        ga('send', 'pageview');

      </script>

      <script>
        document.title = \"#{r.url.split('/')[1]}\"
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

