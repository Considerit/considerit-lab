local = false 

port = 4321
global.upload_dir = 'static/liquid_finance/uploads/'
require('dotenv').config 
  path: 'confs/consideritus.env'

require './server/email'
auth_server = require './server/auth_server'

liquid_finance_handlers = require('./server/liquid_finance.coffee')


bus = require('statebus').serve({
  port: port
  file_store: 
    filename: 'db/liquid_finance'
    backup_dir: 'db/backups/liquid_finance'
  certs: if !local then {
    private_key: 'certs/considerit-us/private-key'
    certificate: 'certs/considerit-us/certificate'
  }
  
  client: (client) ->
    auth_server(bus, client)    
    liquid_finance_handlers(bus, client)

    client.shadows(bus)
})

deslash = (key) -> 
  if key?[0] == '/'
    key = key.substr(1)
  else 
    key



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
      if v.children?.length > 0 && (v.text && v.text != '' || v.children.length > 1 || bus.cache[deslash(v.children[0])].children?.length > 0)
        forum = k.split('_')[0]
        html += "<li><a target='_blank' href='#{forum}'>#{forum}</a></li>"

  html += '</ul>'

  res.send(html)


# serve everything else as a named forum
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
    #</script>

    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Montserrat:ital,wght@0,300;0,400;0,500;0,600;0,700;0,800;0,900;1,300;1,400;1,500;1,600;1,700&display=swap" rel="stylesheet">

    <script type="application/javascript">
      window.statebus_server="#{server}";
      window.presence_no_updates=true;
      window.history_aware_links=true;      
    </script>

    <script src="#{prefix}/node_modules/statebus/extras/react.js"></script>
    <script src="#{prefix}/node_modules/statebus/extras/sockjs.js"></script>
    <script src="#{prefix}/node_modules/statebus/extras/coffee.js"></script>
    <script src="#{prefix}/node_modules/statebus/statebus.js"></script>
    <script src="#{prefix}/node_modules/statebus/client.js"></script>


    <script src="#{prefix}/client/fickle.coffee"></script>
    <script src="#{prefix}/client/shared.coffee"></script>
    <script src="#{prefix}/client/avatar.coffee" default-path="#{prefix}/#{global.upload_dir}"></script>
    <script src="#{prefix}/client/earl.coffee" history-aware-links root="#{forum}"></script>      
    <script src="#{prefix}/client/tooltips.coffee"></script>   

    <script src="#{prefix}/client/modal.coffee"></script>
       
    <script src="#{prefix}/client/auth.coffee"></script>
    <script src="#{prefix}/client/presence.coffee"></script>
    <script src="#{prefix}/client/logo.coffee"></script>
    <script src="#{prefix}/client/drop_menu.coffee"></script>

    <script src="#{prefix}/client/liquid_finance.coffee"></script>    
    <script src="#{prefix}/client/liquid_graph.coffee"></script>

    <script src="#{prefix}/client/app_liquid_finance.coffee"></script>

    <script src="#{prefix}/client/slidergram-textanchor.coffee"></script>
    <link rel='preload' href="#{prefix}/static/vendor/easymde.min.css" as='style' onload="this.onload=null;this.rel='stylesheet'">
    <script defer src="#{prefix}/static/vendor/easymde.min.js"></script>
    <script defer src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>


    <script src="#{prefix}/static/vendor/md5.js"></script>


    <script src="//unpkg.com/d3-dsv"></script>
    <script src="//unpkg.com/d3-quadtree"></script>
    <script src="//unpkg.com/d3-force"></script>
    <script src="https://unpkg.com/d3-dag@0.8.2"></script>
    <script src="https://d3js.org/d3.v7.min.js"></script>

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

  if !migrate.move
    migrate.move = true 
    for k,user of bus.cache 
      if k.match 'user/' && user.flows && !user.liquid
        user.liquid = {}
        for network, flows of user.flows 
          user.liquid[network] = {flows}
        bus.save user 
    bus.save migrate

migrate_data()

