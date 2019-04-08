local = false
port = 8106

global.upload_dir = 'static/uploads/'
require('dotenv').config 
  path: 'confs/consideritus.env'
require './server/email'
auth_server = require './server/auth_server'

slidergram_client_handlers = require('./server/slidergrams.coffee')


bus = require('statebus').serve({
  file_store: 
    filename: 'db/blog'
    backup_dir: 'db/backups/blog'
  certs: if !local then {
    private_key: 'certs/considerit-us/private-key'
    certificate: 'certs/considerit-us/certificate'
  } 

  port: port
  client: (client) ->
    slidergram_client_handlers(bus, client)

    # extend auth system to allow clients to save arbitrary
    # public and private data onto users
    client('current_user').to_save = (obj) -> 
      public_info = obj.public
      private_info = obj.private

      delete obj.public 
      delete obj.private

      update_custom_info = -> 
        current_user = client.fetch('current_user') 
        if current_user.logged_in && public_info
          user = current_user.user 
          for k,v of public_info
            user[k] = v 
          bus.save user 
        if current_user.logged_in && private_info 
          private_user = client.fetch current_user.user.key + '/private/'
          for k,v of private_info
            private_user[k] = v
          bus.save private_user

      if obj.logged_in
        update_custom_info()
      else      
        # wait to see if user successfully authenticates 
        setTimeout update_custom_info

    client('permissions').to_save = (obj) ->
      c = fetch('current_user')
      if !c.logged_in || bus.fetch('permissions')['/' + c.user.key] != 'admin'
        client.save.abort obj
      else
        bus.save obj


    client('post/*').to_fetch = (key) ->
      if bus.cache[key]?
        bus.fetch(key)
      else
        slug = key.split('/')
        slug = slug[slug.length - 1]
        for k,v of bus.cache when k.match(/post\//) && v.slug == slug
          return bus.fetch(k)



    client('post/*').to_save = (obj) ->
      bus.dirty "all_posts/#{obj.forum}"
      if !obj.slug
        obj.slug = slugify(obj.title)

      console.log 'SAVING', obj
      bus.save obj

      if obj.parent
        parent = bus.fetch(deslash(obj.parent))
        if (parent.children or []).indexOf('/' + obj.key) == -1
          parent.children ||= []
          parent.children.push '/' + obj.key
          bus.save parent

    client('post/*').to_delete = (key, t) ->
      pst = bus.fetch key

      for sel in (pst.selections or [])
        bus.delete deslash(sel)

      # delete children
      for child in (pst.children or [])
        bus.delete deslash(child)

      if pst.parent 
        parent = bus.fetch(deslash(pst.parent))
        i = parent.children.findIndex (p) -> pst.key == deslash(p)

        if i > -1

          parent.children.splice(i, 1)
          bus.save(parent)

      if pst.forum
        bus.dirty "all_posts/#{pst.forum}"
      bus.delete key
      t.done()


    client('selection/*').to_delete = (key, t) -> 
      sel = bus.fetch(key)
      # delete sliders
      for sldr in (sel.sliders || [])
        bus.delete deslash(sldr)

      # delete from parent post
      parent = bus.fetch(deslash(sel.post))
      i = parent.selections.indexOf( '/' + sel.key)
      if i > -1
        parent.selections.splice(i, 1)
        bus.save(parent)
      t.done()


    client('slider/*').to_delete = (obj, t) -> 

      sldr = obj

      anchor = bus.fetch deslash(sldr.anchor)
      idx = anchor.sliders.indexOf '/' + sldr.key 
      bus.del sldr

      if idx > -1 
        anchor.sliders.splice(idx, 1)

      if anchor.sliders.length == 0
        client.del anchor 
      else 
        client.save anchor

      t.done()

    client('mailing_list/*').to_fetch = (key) -> 
      return {key: key}

    client('mailing_list/*').to_save = (obj) -> 
      list = bus.fetch(obj.key)
      list.subscribers ||= []
      if obj.new_address
        list.subscribers.push obj.new_address
        bus.save list

    client.shadows(bus)

})


bus('*').to_delete = (t) -> t.done()

bus.honk = true
deslash = (key) -> 
  if key?[0] == '/'
    key = key.substr(1)
  else 
    key

slugify = (text) -> 
  text ||= ""
  text.toString().toLowerCase()
    .replace(/\s+/g, '-')           # Replace spaces with -
    .replace(/[^\w\-]+/g, '')       # Remove all non-word chars
    .replace(/\-\-+/g, '-')         # Replace multiple - with single -
    .replace(/^-+/, '')             # Trim - from start of text
    .replace(/-+$/, '')             # Trim - from end of text
    .substring(0, 30)

express = require('express')

bus.http.use('/static', express.static('static'))
bus.http.use('/node_modules', express.static('node_modules'))


bus.http.get '/*', (r,res) => 

  paths = r.url.split('/')
  paths.shift() if paths[0] == ''

  if local
    prefix = ''
    server = "statei://localhost:#{port}"
  else 
    prefix = "https://considerit.us:#{port}"
    server = "state://considerit.us:#{port}"

  html = """
    <!DOCTYPE html>
    <html>
    <head>
    <script type="coffeedom">
    bus.honk = true
    #</script>
    <script src="#{prefix}/node_modules/statebus/client.js" server="#{server}"></script>
    <script src="#{prefix}/client/fickle.coffee"></script>
    <script src="#{prefix}/client/shared.coffee"></script>
    <script src="#{prefix}/client/avatar.coffee" default-path="#{prefix}/static/uploads"></script>
    <script src="#{prefix}/client/earl.coffee" history-aware-links></script>      
    <script src="#{prefix}/client/tooltips.coffee"></script>   

    <script src="#{prefix}/client/slidergram-textanchor.coffee"></script>
    <script src="#{prefix}/client/slidergrams.coffee"></script>
    <script src="#{prefix}/client/statement.coffee"></script>
    <script src="#{prefix}/client/bubblemouth.coffee"></script>

    <script src="#{prefix}/client/state_dash.coffee"></script>
    <script src="#{prefix}/client/auth.coffee"></script>
    <script src="#{prefix}/client/logo.coffee"></script>

    <script src="#{prefix}/client/presence.coffee" no-updates></script>
    <script src="#{prefix}/client/facepile.coffee"></script>

    <script src="#{prefix}/client/app_blog.coffee"></script>
    <script src="#{prefix}/static/vendor/md5.js"></script>
    <script src="#{prefix}/static/vendor/d3.quadtree.js"></script>
    <script src="#{prefix}/static/vendor/cassowary.js"></script>
    <script src="#{prefix}/static/vendor/linkify.min.js"></script>
    <script src="#{prefix}/static/vendor/emoji.js"></script>
    <script src="#{prefix}/static/vendor/emojione.js"></script>

    <link href="#{prefix}/static/vendor/normalize.css" rel="stylesheet">

    <script src="#{prefix}/static/vendor/trix.js"></script>
    <link href="#{prefix}/static/vendor/trix.css" rel="stylesheet">


    <!----
    <script src="#{prefix}/static/vendor/quill.min.js"></script>
    <link href="#{prefix}/static/vendor/quill.snow.css" rel="stylesheet">

    <link href="https://maxcdn.bootstrapcdn.com/bootstrap/3.2.0/css/bootstrap.min.css" rel="stylesheet">
    <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/adapterjs/0.14.1/adapter.min.js"></script>
    <script src="https://tawk.space/janus.js"></script>
    <script src="https://code.jquery.com/jquery-2.1.4.min.js"></script>
    <script src="https://code.jquery.com/ui/1.11.4/jquery-ui.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jqueryui-touch-punch/0.2.3/jquery.ui.touch-punch.min.js"></script>
    <script src="https://tawk.space/node_modules/hark/hark.bundle.js"></script>
    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.2.0/js/bootstrap.min.js"></script>
    <script src="#{prefix}/client/tawk.coffee"></script>
    <link href="https://fonts.googleapis.com/css?family=Raleway:300,400,400i,600|Trocchi" rel="stylesheet">
    <link rel="stylesheet" href="#{prefix}/static/fonts/cool script/cool script.css"/>

    ----->

    <link rel="stylesheet" href="#{prefix}/static/fonts/Brandon Grotesque/brandon.css"/>
    <link href="https://fonts.googleapis.com/css?family=Raleway:300,400,400i,500,700" rel="stylesheet">


    <!----
    <link rel="stylesheet" href="#{prefix}/static/fonts/freight/freight.css"/>    
    <link rel="stylesheet" href="#{prefix}/static/fonts/Brandon Grotesque/brandon-light.css"/>
    <link rel="stylesheet" href="#{prefix}/static/fonts/cool script/cool script.css"/>
    <link rel="stylesheet" href="#{prefix}/static/css" type="text/css"/>
    <link rel="stylesheet" href="#{prefix}/static/fonts/computer modern/Upright Italic/cmun-upright-italic.css"/>
    <link rel="stylesheet" href="#{prefix}/static/fonts/computer modern/Sans/cmun-sans.css"/>
    <link rel="stylesheet" href="#{prefix}/static/fonts/computer modern/Serif/cmun-serif.css"/>
    <link rel="stylesheet" href="#{prefix}/static/fonts/computer modern/Bright/cmun-bright.css"/>
    <link rel="stylesheet" href="#{prefix}/static/fonts/computer modern/Sans Demi-Condensed/cmun-sans-demicondensed.css"/>
    <link rel="stylesheet" href="#{prefix}/static/fonts/computer modern/Concrete/cmun-concrete.css"/>
    <link rel="stylesheet" href="#{prefix}/static/fonts/computer modern/Typewriter/cmun-typewriter.css"/>
    <link href="https://fonts.googleapis.com/css?family=Montserrat" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css?family=Roboto+Condensed" rel="stylesheet">

    <script>
      (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
      (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
      m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
      })(window,document,'script','https://www.google-analytics.com/analytics.js','ga');

      ga('create', 'UA-55365750-5', 'auto');
      ga('send', 'pageview');

    </script>
    ---->
    
    </head>
    <body>
    </body>
    </html>
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

