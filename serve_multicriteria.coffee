local = false

port = 3666
global.upload_dir = 'static/uploads/'

slidergram_client_handlers = require('./server/slidergrams.coffee')

bus = require('statebus').serve({
  file_store: 
    filename: 'db/multicriteria'
    backup_dir: 'db/backups/multicriteria'
  certs: if !local then {
    private_key: 'certs/deslider.com/private-key'
    certificate: 'certs/deslider.com/certificate'
  }

  port: port
  client: (client) ->
    client.honk = false
    slidergram_client_handlers(bus, client)
    client.shadows(bus)
})

# get all users who have given an opinion in this forum
bus('all_users/*').to_fetch = (k, rest) -> 
  forum = rest
  users = {}

  # walk the tree from root
  walk_from = (pnt) -> 

    pnt = bus.fetch( deslash(pnt.key or pnt) )
    users[(pnt.user.key or pnt.user)] = 1 if pnt.user 
    for sldr in (pnt.sliders or [])
      sldr = bus.fetch( deslash(sldr))
      for o in (sldr.values or [])
        users[o.user] = 1
    for child in (pnt.children or [])
      walk_from(child)

  walk_from "point_root/#{forum}-options"
  walk_from "point_root/#{forum}-criteria"

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


# Use CORS so I can access e.g. deslider.com:3666/fonts from deslider.com
bus.http.use (req, res, next)  -> 
  res.header('Access-Control-Allow-Origin', req.get('Origin') || '*')
  res.header('Access-Control-Allow-Credentials', 'true')
  res.header('Access-Control-Allow-Methods', 'GET,HEAD,PUT,PATCH,POST,DELETE')
  res.header('Access-Control-Expose-Headers', 'Content-Length')
  res.header('Access-Control-Allow-Headers', 'Accept, Authorization, Content-Type, X-Requested-With, Range')
  if req.method == 'OPTIONS'
    return res.send(200)
  next()


express = require('express')

bus.http.use('/static', express.static('static'))
bus.http.use('/node_modules', express.static('node_modules'))





# serve everything else as a named forum

bus.http.get '/', (r,res) => 

  paths = r.url.split('/')
  paths.shift() if paths[0] == ''

  forum = ""

  if local
    prefix = ''
    server = "statei://localhost:#{port}"
  else 
    prefix = "https://deslider.com:#{port}"
    server = "state://deslider.com:#{port}"

  html = """
    <!DOCTYPE html>
    <html>
    <head>      
    <script type="coffeedom">
    bus.honk = false
    bus.render_when_loading = false
    #</script><script src="#{prefix}/node_modules/statebus/client.js" server="#{server}"></script>

    <script src="#{prefix}/node_modules/statebus/extras/react.js" charset="utf-8"></script>
    <script src="#{prefix}/node_modules/statebus/extras/sockjs.js" charset="utf-8"></script>
    <script src="#{prefix}/node_modules/statebus/extras/coffee.js" charset="utf-8"></script>
    <script src="#{prefix}/node_modules/statebus/statebus.js" charset="utf-8"></script>

    <script src="#{prefix}/client/shared.coffee"></script>
    <script src="#{prefix}/client/logo.coffee"></script>
    <script src="#{prefix}/client/productpage_deslider.coffee"></script>




    <script>
      document.title = "Deslider"
      window.forum = "#{forum}"
    </script>


    <!--- from https://cdnjs.cloudflare.com/ajax/libs/normalize/6.0.0/normalize.min.css ---->
    <style> 
      /*! normalize.css v6.0.0 | MIT License | github.com/necolas/normalize.css */html{line-height:1.15;-ms-text-size-adjust:100%;-webkit-text-size-adjust:100%}article,aside,footer,header,nav,section{display:block}h1{font-size:2em;margin:.67em 0}figcaption,figure,main{display:block}figure{margin:1em 40px}hr{box-sizing:content-box;height:0;overflow:visible}pre{font-family:monospace,monospace;font-size:1em}a{background-color:transparent;-webkit-text-decoration-skip:objects}abbr[title]{border-bottom:none;text-decoration:underline;text-decoration:underline dotted}b,strong{font-weight:inherit}b,strong{font-weight:bolder}code,kbd,samp{font-family:monospace,monospace;font-size:1em}dfn{font-style:italic}mark{background-color:#ff0;color:#000}small{font-size:80%}sub,sup{font-size:75%;line-height:0;position:relative;vertical-align:baseline}sub{bottom:-.25em}sup{top:-.5em}audio,video{display:inline-block}audio:not([controls]){display:none;height:0}img{border-style:none}svg:not(:root){overflow:hidden}button,input,optgroup,select,textarea{margin:0}button,input{overflow:visible}button,select{text-transform:none}[type=reset],[type=submit],button,html [type=button]{-webkit-appearance:button}[type=button]::-moz-focus-inner,[type=reset]::-moz-focus-inner,[type=submit]::-moz-focus-inner,button::-moz-focus-inner{border-style:none;padding:0}[type=button]:-moz-focusring,[type=reset]:-moz-focusring,[type=submit]:-moz-focusring,button:-moz-focusring{outline:1px dotted ButtonText}legend{box-sizing:border-box;color:inherit;display:table;max-width:100%;padding:0;white-space:normal}progress{display:inline-block;vertical-align:baseline}textarea{overflow:auto}[type=checkbox],[type=radio]{box-sizing:border-box;padding:0}[type=number]::-webkit-inner-spin-button,[type=number]::-webkit-outer-spin-button{height:auto}[type=search]{-webkit-appearance:textfield;outline-offset:-2px}[type=search]::-webkit-search-cancel-button,[type=search]::-webkit-search-decoration{-webkit-appearance:none}::-webkit-file-upload-button{-webkit-appearance:button;font:inherit}details,menu{display:block}summary{display:list-item}canvas{display:inline-block}template{display:none}[hidden]{display:none}/*# sourceMappingURL=normalize.min.css.map */    
    </style> 

    <link href="https://fonts.googleapis.com/css?family=Raleway:300,400,400i,500,700" rel="stylesheet">


    <link rel="icon" type="image/png" href="#{prefix}/static/favicon.ico">


    </head>
    <body>
    </body>
    </html>
      """

  res.send(html)



# serve everything else as a named forum
bus.http.get '/*', (r,res) => 

  paths = r.url.split('/')
  paths.shift() if paths[0] == ''

  forum = paths[0].split('?')[0]


  forum ||= ''

  if local
    prefix = ''
    server = "statei://localhost:#{port}"
  else 
    prefix = "https://deslider.com:#{port}"
    server = "state://deslider.com:#{port}"

  html = """
    <!DOCTYPE html>
    <html>
    <head>      
    <script type="coffeedom">
    bus.honk = false
    bus.render_when_loading = false
    #</script><script src="#{prefix}/node_modules/statebus/client.js" server="#{server}"></script>

    <script src="#{prefix}/node_modules/statebus/extras/react.js" charset="utf-8"></script>
    <script src="#{prefix}/node_modules/statebus/extras/sockjs.js" charset="utf-8"></script>
    <script src="#{prefix}/node_modules/statebus/extras/coffee.js" charset="utf-8"></script>
    <script src="#{prefix}/node_modules/statebus/statebus.js" charset="utf-8"></script>

    <script src="#{prefix}/client/fickle.coffee"></script>
    <script src="#{prefix}/client/shared.coffee"></script>
    
    <script src="#{prefix}/client/presence.coffee"></script>    

    <script src="#{prefix}/client/logo.coffee"></script>
    <script src="#{prefix}/client/avatar.coffee" default-path="#{prefix}/static/uploads"></script>
    <script src="#{prefix}/client/earl.coffee" history-aware-links root="#{forum}"></script>      
    <script src="#{prefix}/client/tooltips.coffee"></script>      
    <script src="#{prefix}/client/slidergrams.coffee"></script>
    <script src="#{prefix}/client/state_dash.coffee"></script>
    <script src="#{prefix}/client/auth.coffee"></script>


    <script src="#{prefix}/client/multicriteria.coffee"></script>

    <script src="#{prefix}/client/facepile.coffee"></script>

    <script src="#{prefix}/static/vendor/md5.js"></script>
    <script src="#{prefix}/static/vendor/d3.quadtree.js"></script>

    <script src="#{prefix}/client/app_multicriteria.coffee"></script>



    <script>
      document.title = "#{forum.replace('_', ' ')}"
      window.forum = "#{forum}"
    </script>




    <!--- from https://cdnjs.cloudflare.com/ajax/libs/normalize/6.0.0/normalize.min.css ---->
    <style> 
      /*! normalize.css v6.0.0 | MIT License | github.com/necolas/normalize.css */html{line-height:1.15;-ms-text-size-adjust:100%;-webkit-text-size-adjust:100%}article,aside,footer,header,nav,section{display:block}h1{font-size:2em;margin:.67em 0}figcaption,figure,main{display:block}figure{margin:1em 40px}hr{box-sizing:content-box;height:0;overflow:visible}pre{font-family:monospace,monospace;font-size:1em}a{background-color:transparent;-webkit-text-decoration-skip:objects}abbr[title]{border-bottom:none;text-decoration:underline;text-decoration:underline dotted}b,strong{font-weight:inherit}b,strong{font-weight:bolder}code,kbd,samp{font-family:monospace,monospace;font-size:1em}dfn{font-style:italic}mark{background-color:#ff0;color:#000}small{font-size:80%}sub,sup{font-size:75%;line-height:0;position:relative;vertical-align:baseline}sub{bottom:-.25em}sup{top:-.5em}audio,video{display:inline-block}audio:not([controls]){display:none;height:0}img{border-style:none}svg:not(:root){overflow:hidden}button,input,optgroup,select,textarea{margin:0}button,input{overflow:visible}button,select{text-transform:none}[type=reset],[type=submit],button,html [type=button]{-webkit-appearance:button}[type=button]::-moz-focus-inner,[type=reset]::-moz-focus-inner,[type=submit]::-moz-focus-inner,button::-moz-focus-inner{border-style:none;padding:0}[type=button]:-moz-focusring,[type=reset]:-moz-focusring,[type=submit]:-moz-focusring,button:-moz-focusring{outline:1px dotted ButtonText}legend{box-sizing:border-box;color:inherit;display:table;max-width:100%;padding:0;white-space:normal}progress{display:inline-block;vertical-align:baseline}textarea{overflow:auto}[type=checkbox],[type=radio]{box-sizing:border-box;padding:0}[type=number]::-webkit-inner-spin-button,[type=number]::-webkit-outer-spin-button{height:auto}[type=search]{-webkit-appearance:textfield;outline-offset:-2px}[type=search]::-webkit-search-cancel-button,[type=search]::-webkit-search-decoration{-webkit-appearance:none}::-webkit-file-upload-button{-webkit-appearance:button;font:inherit}details,menu{display:block}summary{display:list-item}canvas{display:inline-block}template{display:none}[hidden]{display:none}/*# sourceMappingURL=normalize.min.css.map */    
    </style> 

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

    <link rel="stylesheet" href="#{prefix}/static/css" type="text/css"/>

    ----->

    <link rel="stylesheet" href="#{prefix}/static/fonts/Brandon Grotesque/brandon.css"/>
    <link href="https://fonts.googleapis.com/css?family=Raleway:300,400,400i,500,700" rel="stylesheet">
    <link rel="stylesheet" href="#{prefix}/static/fonts/cool script/cool script.css"/>


    <link rel="icon" type="image/png" href="#{prefix}/static/favicon.ico">




    </head>
    <body>
    </body>
    </html>
      """

  res.send(html)


