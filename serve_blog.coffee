local = false
port = 8106

if local
  prefix = ''
  server = "statei://localhost:#{port}"
  static_prefix = "/static"
else 
  prefix = "https://traviskriplean.com:#{port}"
  static_prefix = "https://ddbjipgwr13mk.cloudfront.net/static"
  server = "state://traviskriplean.com:#{port}"



require('dotenv').config 
  path: 'confs/traviskriplean.env'

fs = require('fs')
{ exec } = require('child_process')


global.upload_dir = 'static/uploads/'
media_dir = 'static/media/'

require('dotenv').config 
  path: 'confs/consideritus.env'
require './server/email'
auth_server = require './server/auth_server'

slidergram_client_handlers = require('./server/slidergrams.coffee')
liquid_finance_handlers = require('./server/liquid_finance.coffee')


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
    auth_server(bus, client)
    slidergram_client_handlers(bus, client)
    liquid_finance_handlers(bus, client)


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
      if obj.parent
        parent = bus.fetch(deslash(obj.parent))
        if !obj.slug 
          try 
            send_email 
              subject: "[traviskriplean.com] A new post!"
              text: "A new post to #{parent.title}. https://traviskriplean.com/#{parent.key.split('/')[1]}"
              html: "A new post to #{parent.title}. https://traviskriplean.com/#{parent.key.split('/')[1]}"
              recipient: "tkriplean@gmail.com"
          catch e 
            console.log "Could not send update email"

      obj.slug ?= slugify(obj.title)

      bus.save obj

      if obj.parent
        if (parent.children or []).indexOf('/' + obj.key) == -1
          parent.children ||= []
          parent.children.push '/' + obj.key
          bus.save parent


    client('post/*').to_delete = (key, t) ->
      pst = bus.fetch key

      # for sel in (pst.selections or [])
      #   bus.delete deslash(sel)

      # # delete children
      # for child in (pst.children or [])
      #   bus.delete deslash(child)

      if pst.parent 
        parent = bus.fetch(deslash(pst.parent))
        i = parent.children.findIndex (p) -> pst.key == deslash(p)

        if i > -1
          parent.children.splice(i, 1)
          bus.save(parent)

      # if pst.forum
      #   bus.dirty "all_posts/#{pst.forum}"
      # bus.delete key
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

bus.honk = false


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


# For uploading files
bus.express.post '/upload', (req, res, next) ->
  console.log 'Processing upload', req.headers['content-filename']

  res.setHeader('Content-Type', 'application/json')

  c = bus.fetch('current_user')

  # if !c.logged_in || bus.fetch('permissions')['/' + c.user?.key] != 'admin'
  #   res.statusCode = 403
  #   res.end JSON.stringify {status: "error", description: "Permission denied"}
  #   return

  contentLength = parseInt(req.headers['content-length'])
  if isNaN(contentLength) || contentLength <= 0
    res.statusCode = 411
    res.end JSON.stringify {status: "error", description: "No File"}
    return

  filename = req.headers['content-filename']
  if filename == null
    filename = "file.#{req.headers['content-type'].split('/')[1]}"

  upload_directory = "#{__dirname}/#{media_dir}"
  if !fs.existsSync(upload_directory)
    fs.mkdirSync(upload_directory)
  subdirectory = req.headers['content-directory']
  path = "#{upload_directory}#{if subdirectory then "#{subdirectory}/" else ''}"
  if !fs.existsSync(path)
    fs.mkdirSync(path)

  filestream = fs.createWriteStream "#{path}/#{filename}"

  filestream.on "error", (error) ->
    console.error(error)
    res.statusCode = 400
    res.write JSON.stringify {status: "error", description: error}
    res.end()

  # Write data as it comes
  req.pipe filestream

  req.on 'end', ->
    filestream.close ->
      res.end JSON.stringify {status: "success"}

      # use shell script to process video & upload to AWS
      child = exec "#{__dirname}/ops/upload_media".replace(' ', '\\ '), (err, stdout, stderr) ->
        if err
          console.error(err)
        else
         console.log("stdout: #{stdout}");
         console.log("stderr: #{stderr}");



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
            <link>http://traviskriplean.com</link>
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







compile_coffee = (filename, source) ->

  try 
    compiled = require('coffee-script').compile source, 
      filename: filename      
      bare: true
      sourceMap: true
  catch e
    if (!bus.loading())
      console.error('Could not compile ' + filename + ': ', e)
    return ''

  source_map = JSON.parse(compiled.v3SourceMap)
  compiled = 'window.dom = window.dom || {}\n' + compiled.js

  # btoa = (s) -> new Buffer(s.toString(),'binary').toString('base64')
  # source_map.sourcesContent = source

  # # Base64 encode it
  # compiled += '\n'
  # compiled += '//# sourceMappingURL=data:application/json;base64,'
  # compiled += btoa(JSON.stringify(source_map)) + '\n'
  # compiled += '//# sourceURL=' + source_filename
  compiled


compile_javascript = (files) ->
  if MODE == 'production'
    javascript = ""
    for filename in files
      source = bus.read_file(filename)
      if filename.match(/\.coffee$/)
        source = compile_coffee(filename, source)
      javascript = "#{javascript}// #{filename}\n\n\n#{source}\n\n\n"

    """
    <script type="application/javascript">
    #{javascript}
    </script>
    """
  else 
    """
      <script src="#{prefix}/node_modules/statebus/extras/react.js"></script>
      <script src="#{prefix}/node_modules/statebus/extras/sockjs.js"></script>
      <script src="#{prefix}/node_modules/statebus/extras/coffee.js"></script>
      <script src="#{prefix}/node_modules/statebus/statebus.js"></script>
      <script src="#{prefix}/node_modules/statebus/client.js"></script>

      <script src="#{prefix}/client/fickle.coffee"></script>
      <script src="#{prefix}/client/shared.coffee"></script>

      <script src="#{prefix}/client/earl.coffee"></script>      
      <script src="#{prefix}/client/tooltips.coffee"></script>

      <script src="#{prefix}/client/avatar.coffee"></script>
      <script src="#{prefix}/client/presence.coffee"></script>

      <script src="#{prefix}/client/slidergram-textanchor.coffee"></script>
      <script src="#{prefix}/client/statement.coffee"></script>
      <script src="#{prefix}/client/bubblemouth.coffee"></script>

      <script src="#{prefix}/client/modal.coffee"></script>

      <script src="#{prefix}/client/auth.coffee"></script>
      <script src="#{prefix}/client/logo.coffee"></script>

      <script src="#{static_prefix}/vendor/md5.js"></script>

      <script src="#{prefix}/client/app_blog.coffee"></script>

      <script src="#{prefix}/client/liquid_graph.coffee"></script>
      <script src="#{prefix}/client/liquid_finance.coffee"></script>
      <script src="#{prefix}/client/drop_menu.coffee"></script>

    """

# development or production
MODE = 'production' 

inline_js = [
  "node_modules/statebus/statebus.js"
  "node_modules/statebus/client.js"
  "node_modules/statebus/extras/sockjs.js"
  "node_modules/statebus/extras/react.js"
  # "node_modules/statebus/extras/coffee.js"
  "client/fickle.coffee"
  "client/shared.coffee"
  "client/avatar.coffee"
  "client/presence.coffee"
  "client/earl.coffee"
  "client/tooltips.coffee"
  "client/slidergram-textanchor.coffee"
  "client/statement.coffee"
  "client/bubblemouth.coffee"
  "client/modal.coffee"
  "client/auth.coffee"
  "client/logo.coffee"
  "client/app_blog.coffee"
  "client/liquid_graph.coffee"  
  "client/liquid_finance.coffee"
  "client/drop_menu.coffee"
  "static/vendor/md5.js"
]

if MODE == 'production'
  blocking_javascript = compile_javascript inline_js

normalize_css = "#{bus.read_file('static/vendor/normalize.css')}\n"

bus.http.get '/*', (r,res) => 

  paths = r.url.split('/')
  paths.shift() if paths[0] == ''

  key = paths[0].split('?')[0]

  post = bus.fetch "post/#{key}"
  if !post.title 
    post = bus.fetch 'root_point'


  if post?.title
    meta = """
       <title>#{post.title}</title>
       <meta name="description" content="#{post.description}">
       <meta property="og:title" content="#{post.title}">
       <meta property="og:description" content="#{post.description}">
       <meta property="og:image" content="#{post.image}">
       <meta property="og:url" content="#{r.url}">

       <meta name="twitter:card" content="summary_large_image">
       <meta name="twitter:image" content="#{post.image}">
       <meta property="twitter:title" content="#{post.title}">
       <meta property="twitter:description" content="#{post.description}">
    """
  else 
    meta = "<link href='blah.com' rel=\"#{post.key} #{key}\" />"

  preloaded_resources = ""
  if post.key == 'post/an-informal-curriculum-for-hom-fx1md'
    preloaded_resources += "<link rel=\"preload\" href=\"#{static_prefix}/media/an-informal-curriculum-for-hom-fx1md/IMG_1769 3.mp4\" as=\"video\" type=\"video/mp4\">"

  if MODE == 'development'
    blocking_javascript = compile_javascript inline_js
  


  html = """
    <!DOCTYPE html>
    <html>
    <head>

    #{meta}

    <script type="application/javascript">
      window.statebus_server="#{server}";
      window.presence_no_updates=true;
      window.history_aware_links=true;
      window.avatar_default_path="#{prefix}/static/uploads";
      window.try_gravatar='retro';
    </script>

    #{blocking_javascript}


    <!----
    <script src="#{prefix}/client/state_dash.coffee"></script>

    <script src="#{prefix}/client/facepile.coffee"></script>
    <script src="#{prefix}/client/slidergrams.coffee"></script>

    <script src="#{static_prefix}/vendor/md5.js"></script>
    <script src="#{static_prefix}/vendor/d3.quadtree.js"></script>
    <script src="#{static_prefix}/vendor/cassowary.js"></script>

    <script src="#{static_prefix}/vendor/linkify.min.js"></script>
    <script src="#{static_prefix}/vendor/emoji.js"></script>
    <script src="#{static_prefix}/vendor/emojione.js"></script>

    <link href="#{static_prefix}/vendor/normalize.css" rel="stylesheet">

    <script src="https://cdn.jsdelivr.net/npm/vanilla-lazyload@17.5.0/dist/lazyload.min.js"></script>


    ----->





    <style>
    "#{normalize_css}"
    </style>


    <link rel='preload' href="#{static_prefix}/vendor/easymde.min.css" as='style' onload="this.onload=null;this.rel='stylesheet'">

    <script defer src="#{static_prefix}/vendor/easymde.min.js"></script>
    <script defer src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>

    <script src="https://unpkg.com/d3-dag@0.8.2"></script>
    <script src="https://d3js.org/d3.v7.min.js"></script>


    <link rel="preload" as="font" href="#{static_prefix}/fonts/Brandon Grotesque/BrandonGrotesque-Black.woff" type="font/woff" crossorigin="anonymous">
    <link rel="preload" as="font" href="#{static_prefix}/fonts/Brandon Grotesque/BrandonGrotesque-Bold.woff" type="font/woff" crossorigin="anonymous">
    <link rel="preload" as="font" href="#{static_prefix}/fonts/Brandon Grotesque/BrandonGrotesque-Regular.woff" type="font/woff" crossorigin="anonymous">
    <link rel="preload" as="font" href="#{static_prefix}/fonts/Brandon Grotesque/BrandonGrotesque-Light.woff" type="font/woff" crossorigin="anonymous">
    <link rel="preload" as="font" href="#{static_prefix}/fonts/Brandon Grotesque/BrandonGrotesque-Medium.woff" type="font/woff" crossorigin="anonymous">
    <link rel="stylesheet" href="#{static_prefix}/fonts/Brandon Grotesque/brandon.css"/>


    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>

    <link href="https://fonts.googleapis.com/css2?family=Montserrat:ital,wght@0,300;0,400;0,500;0,600;0,700;0,800;0,900;1,300;1,400;1,500;1,600;1,700&display=swap" rel="stylesheet">

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
    

    #{preloaded_resources}
    </head> 
    <body data-static-prefix=\"#{static_prefix}\">

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

