local = false
port = 8106

require('dotenv').config 
  path: 'confs/traviskriplean.env'


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
    private_key: 'certs/traviskriplean-com/private-key'
    certificate: 'certs/traviskriplean-com/certificate'
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
      # bus.dirty "all_posts/#{obj.forum}"
      if !obj.slug
        obj.slug = slugify(obj.title)

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

      # if pst.forum
      #   bus.dirty "all_posts/#{pst.forum}"
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


# Get an RSS pubDate from a Javascript Date instance
pubDate = (date) -> 
  pieces     = date.toString().split(' ')
  offsetTime = pieces[5].match(/[-+]\d{4}/)
  offset     = (offsetTime) ? offsetTime : pieces[5]
  parts      = [
        pieces[0] + ',',
        pieces[2],
        pieces[1],
        pieces[3],
        pieces[4],
        offset
  ]

  parts.join(' ')

bus.http.get '/feed', (r,res) => 
  root = bus.fetch "post/blog_root"
  posts = (bus.fetch(deslash(p)) for p in root.children)
  published_posts = (p for p in posts when p.published)

  items = ""

  latest_date = null 

  for post in published_posts
    url = "https://traviskriplean.com/#{post.key.split('/')[1]}"

    continue if !post.edits || post.edits.length < 1

    earliest_edit = new Date(post.edits[0].time)
    last_edit = new Date(post.edits[post.edits.length - 1].time)

    latest_date ||= last_edit

    items += """
        <item>
          <title>#{post.title}</title>
          <link>#{url}</link>
          <guid>#{url}</guid>
          <pubDate>#{pubDate(last_edit)}</pubDate>
        </item>
      """

    if last_edit > latest_date
      latest_date = last_edit


  html = """
    <?xml version="1.0" encoding="utf-8"?>
    <rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
        <channel>
            <title>Travis Kriplean's Blog</title>
            <link>http://www.flickr.com/photos/luxagraf/</link>
            <description>Where I share my thoughts. The topics will likely touch upon dialogue, collaboration, listening, regeneration, ecological crises, parenting, open source, collectives, decentralized organization, and cultural evolution. I will also use this space to demonstrate new inventions.</description>
            <pubDate>#{pubDate(latest_date)}</pubDate>
            <lastBuildDate>#{pubDate(latest_date)}</lastBuildDate>
            <atom:link href="https://traviskriplean.com/feed" rel="self" type="application/rss+xml" />
            #{items}
        </channel>
    </rss>
    """

  res.set('Content-Type', 'application/rss+xml')
  res.send(html)




bus.http.get '/*', (r,res) => 

  paths = r.url.split('/')
  paths.shift() if paths[0] == ''

  if local
    prefix = ''
    server = "statei://localhost:#{port}"
    static_prefix = "/static"
  else 
    prefix = "https://traviskriplean.com:#{port}"
    static_prefix = "https://ddbjipgwr13mk.cloudfront.net/static"
    server = "state://traviskriplean.com:#{port}"

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
    <script src="#{static_prefix}/vendor/md5.js"></script>
    <script src="#{static_prefix}/vendor/d3.quadtree.js"></script>
    <script src="#{static_prefix}/vendor/cassowary.js"></script>
    <script src="#{static_prefix}/vendor/linkify.min.js"></script>
    <script src="#{static_prefix}/vendor/emoji.js"></script>
    <script src="#{static_prefix}/vendor/emojione.js"></script>

    <link href="#{static_prefix}/vendor/normalize.css" rel="stylesheet">

    <script src="#{static_prefix}/vendor/trix.js"></script>
    <link href="#{static_prefix}/vendor/trix.css" rel="stylesheet">


    <!----
    <script src="#{static_prefix}/vendor/quill.min.js"></script>
    <link href="#{static_prefix}/vendor/quill.snow.css" rel="stylesheet">

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
    <link rel="stylesheet" href="#{static_prefix}/fonts/cool script/cool script.css"/>

    ----->

    <link rel="stylesheet" href="#{static_prefix}/fonts/Brandon Grotesque/brandon.css"/>

    <link href="https://fonts.googleapis.com/css?family=Raleway:300,400,400i,500,700" rel="stylesheet">


    <!----
    <link rel="stylesheet" href="#{static_prefix}/fonts/freight/freight.css"/>    
    <link rel="stylesheet" href="#{static_prefix}/fonts/Brandon Grotesque/brandon-light.css"/>
    <link rel="stylesheet" href="#{static_prefix}/fonts/cool script/cool script.css"/>
    <link rel="stylesheet" href="#{static_prefix}/css" type="text/css"/>
    <link rel="stylesheet" href="#{static_prefix}/fonts/computer modern/Upright Italic/cmun-upright-italic.css"/>
    <link rel="stylesheet" href="#{static_prefix}/fonts/computer modern/Sans/cmun-sans.css"/>
    <link rel="stylesheet" href="#{static_prefix}/fonts/computer modern/Serif/cmun-serif.css"/>
    <link rel="stylesheet" href="#{static_prefix}/fonts/computer modern/Bright/cmun-bright.css"/>
    <link rel="stylesheet" href="#{static_prefix}/fonts/computer modern/Sans Demi-Condensed/cmun-sans-demicondensed.css"/>
    <link rel="stylesheet" href="#{static_prefix}/fonts/computer modern/Concrete/cmun-concrete.css"/>
    <link rel="stylesheet" href="#{static_prefix}/fonts/computer modern/Typewriter/cmun-typewriter.css"/>
    <link href="https://fonts.googleapis.com/css?family=Montserrat" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css?family=Roboto+Condensed" rel="stylesheet">


    ---->

    <script>
      (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
      (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
      m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
      })(window,document,'script','https://www.google-analytics.com/analytics.js','ga');

      ga('create', 'UA-55365750-5', 'auto');
      ga('send', 'pageview');

    </script>

    <link rel="apple-touch-icon" sizes="180x180" href="/static/blog/apple-touch-icon.png">
    <link rel="icon" type="image/png" sizes="32x32" href="/static/blog/favicon-32x32.png">
    <link rel="icon" type="image/png" sizes="16x16" href="/static/blog/favicon-16x16.png">
    <link rel="manifest" href="/static/blog/site.webmanifest">
    
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

