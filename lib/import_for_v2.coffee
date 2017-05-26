db = '../db/lists'

try 
  fs = require('fs')
  fs.unlink(db)
catch 
  console.log 'could not delete database'

bus = require('statebus').serve
  port: 9376
  file_store: 
    save_delay: 100000
    filename: db
    backup_dir: '../db/backups/lists'


bus.honk = false

asset_host = null 

deslash = (key) -> 
  if key?[0] == '/'
    key = key.substr(1)
  else 
    key

server_slash = (key) -> 
  if key[0] != '/'
    '/' + key 
  else 
    key



crypto = require('crypto')
md5 = (obj) -> crypto.createHash('md5').update(JSON.stringify(obj)).digest("hex")

user_key = (obj) -> 
  obj = bus.fetch obj
  deslash(obj.key + slugify(obj.name or 'anon').substring(0,12))
proposal_key = (obj) -> 
  obj = bus.fetch(obj)
  "point/#{obj.slug}" + obj.key.split('/proposal/')[1]
point_key = (obj_or_key) -> 
  obj = bus.fetch obj_or_key
  "point/" + slugify(obj.nutshell.substring(0,12)) + obj.key.split('/point/')[1]
comment_key = (obj) -> 
  obj = bus.fetch obj 
  "point/" + slugify(obj.body.substring(0,12)) + obj.key.split('/comment/')[1]

types = {}
get_type = (name, suggested_by) -> 
  if !types[name]
    type = 
      key: "point/#{slugify(name).substring(0,12)}"
      category: name
      icon: 'author'
      suggested_by: []
      imported: true

    if name == 'Comments'
      type.sliders = [{
          key: "slider/#{slugify(name).substring(0,12)}"
          labels: ['-', '+']
          imported: true
        }]        
    else if name in ['Pros', 'Cons']
      type.sliders = [{
          key: "slider/#{slugify(name).substring(0,12)}"
          labels: ['unimportant', 'important']
          imported: true          
        }]
    else 
      type.sliders = [{
        key: "slider/#{slugify(name).substring(0,12)}"
        labels: ['oppose', 'support']
        imported: true
      }]

    types[name] = type
    bus.save type 

  type = types[name]
  suggested_by.suggests ||= []
  if server_slash(type.key) not in suggested_by.suggests 
    suggested_by.suggests.push server_slash(type.key)

  if server_slash(suggested_by.key) not in type.suggested_by
    type.suggested_by.push server_slash(suggested_by.key)

  if name != 'Comments'
    if name in ['Pros', 'Cons']
      get_type 'Comments', type
    else
      get_type 'Pros', type 
      get_type 'Cons', type

  type


processed = {}

bus('*').on_save = (obj) -> 

  return if (processed[obj.key] && obj.key != '/subdomain') || obj.imported
  processed[obj.key] = true

  # console.log "*************\n\n"
  # console.log obj.key, 'published'


  if obj.subdomain_id
    subdomain = subdomains[obj.subdomain_id]

  if obj.key.match '/application'
    asset_host = obj.asset_host

  else if obj.key.match '/subdomains'
    for subdomain in obj.subs when subdomain.activity
      http_fetch "/subdomain", subdomain.name
      http_fetch "/users", subdomain.name
      http_fetch '/proposals?all_points', subdomain.name
      http_fetch '/all_comments', subdomain.name

  else if obj.key.match '/subdomain'
    key = "point/#{slugify(obj.name)}_#{obj.id}"

    return if root.children.indexOf(key) > -1

    name = obj.name 

    if name == 'bitcoinclassic' 
      summary = "Bitcoin Classic"
      desc = """
        <p>We are hard forking bitcoin to a 2 MB blocksize limit. Please join us.</p>
        <p>The <a href="https://docs.google.com/spreadsheets/d/1Cg9Qo9Vl5PdJYD4EiHnIGMV3G48pWmcWI3NFoKKfIzU/" target="_blank">data shows</a> consensus amongst miners for an immediate 2 MB increase, and <a href="https://bitcoin.consider.it/" target="_blank">demand</a> amongst users for 8 MB or more. We are writing the software that miners and users say they want. We will make sure that it solves their needs, help them deploy it, and gracefully upgrade the bitcoin network’s capacity together.</p>
        <p>We call our code repository Bitcoin Classic. It starts as a one-feature patch to bitcoin-core that increases the blocksize limit to 2 MB. We will have ports for master, 0.11.2, and -86, so that miners and businesses can upgrade to 2 MB blocks from any recent bitcoin software version they run.</p>
        """
    else if name == 'bitcoin'
      summary = "Bitcoin Consensus Census"
      desc = "Interested in running a node that mirrors consider.it data to provide an audit trail?"          
    else
      summary = name
      desc = ''

    category = subdomain_map[name] or 'Other'
    
    sub_type = types[category]
    if !sub_type
      sub_type = types[category] = extend {}, subdomain_type, 
        key: "point/#{category}_channels"
        category: category

      bus.save sub_type
      root.suggests.unshift server_slash(sub_type.key)
      bus.save root

    sub = 
      key: key
      created_at: obj.created_at
      imported: true
      summary: summary
      parent: server_slash(root.key)
      type: server_slash sub_type.key
      children: []
      creator: server_slash user_key(obj.roles.admin?[0] or "user/1701")
      treat_authorless: false
      description: desc
      __old_name: name
      sliders: [{
          key: "slider/#{slugify(name).substring(0,12)}_#{obj.id}"
          parent: server_slash(sub_type.sliders[0].key)
          values: []
          imported: true
        }]

    sub_type.type_children ||= []
    if sub_type.type_children.indexOf(server_slash(key)) < 0
      sub_type.type_children.push server_slash key
      bus.save sub_type

    subdomains[obj.id] = sub 
    bus.save sub

    root.children.push server_slash(sub.key)
    bus.save root 



  else if obj.key.match "/proposal/"

    key = proposal_key obj
    proposal = bus.fetch key 

    proposal_type = get_type (obj.cluster or 'Proposals'), subdomain

    opinions = []
    for o in (obj.opinions or [])
      opinions.push 
        user: server_slash(user_key(o.user))
        value: (o.stance + 1) / 2

    return if !obj.name
    return if obj.name == 'Consider.it can help me' && opinions.length < 2 && opinions[0]?.stance == .5
    return if !obj.user

    interest_slider = subdomain.sliders[0]
    interest_slider.values = ( {user: server_slash(u), value: .1 + .9 * Math.random()} for u in uniq ( (o.user for o in interest_slider.values.concat(opinions))))
    bus.save interest_slider  

    # TODO: account for collapsable proposal description fields

    changed = save_if_changed proposal, 
      key: key
      imported: true       
      summary: obj.name
      description: if obj.description then obj.description 
      parent: server_slash(subdomain.key)
      type: server_slash proposal_type.key
      children: []
      creator: server_slash user_key(obj.user) 
      created_at: obj.created_at      
      sliders: [{
        key: "slider/#{slugify(obj.name).substring(0,12)}_#{obj.id}"
        parent: server_slash(proposal_type.sliders[0].key) # TODO: create list!
        values: opinions
        imported: true
      }]

    if changed 
      proposal_type.type_children ||= []
      if proposal_type.type_children.indexOf(server_slash(key)) < 0
        proposal_type.type_children.push server_slash(key)
        bus.save proposal_type

      subdomain.children ||= []
      if subdomain.children.indexOf(server_slash(key)) < 0
        subdomain.children.push server_slash(key)
        bus.save subdomain


  else if obj.key.match "/point/" 
    old = bus.fetch(obj.proposal)
    return if !old 

    proposal = bus.fetch proposal_key old
    user = user_key obj.user 

    return if !proposal.type
    point_type = get_type (if obj.is_pro then 'Pros' else 'Cons'), bus.fetch(proposal.type)

    opinions = []
    for o in (obj.includers or [])
      opinions.push 
        user: server_slash user_key(o)
        value: .75

    key = point_key obj
    #console.log "SAVING!!", obj.key, key, proposal.key
    old_point = bus.fetch(key)
    # if !old_point.imported && obj.comment_count > 0 && !processed["/comments/#{obj.id}"]
    #   http_fetch "/comments/#{obj.id}", subdomain.__old_name

    point = 
      key: key
      created_at: obj.created_at
      imported: true
      summary: obj.nutshell
      parent: server_slash(proposal.key)
      type: server_slash point_type.key
      children: []
      creator: server_slash user
      description: if obj.text then obj.text
      sliders: [{
          key: "slider/#{slugify(obj.nutshell).substring(0,12)}_#{obj.id}"
          parent: server_slash(point_type.sliders[0].key)
          values: opinions
          imported: true
        }]

    # console.log 'CHANGED?', changed, md5(old_point), md5(point)

    changed = save_if_changed old_point, point

    if changed 
      point_type.type_children ||= []
      if point_type.type_children.indexOf(server_slash(point.key)) < 0
        point_type.type_children.push server_slash(point.key)
        bus.save point_type

      proposal.children ||= []
      if proposal.children.indexOf(server_slash(point.key)) < 0
        #console.log "ADDED #{point.key} to #{proposal.key} #{proposal.imported}"
        proposal.children.push server_slash(point.key)
        bus.save proposal


  else if obj.key.match "/comment/"
    old = bus.fetch(obj.point)
    return if !old || !old.nutshell
    point = bus.fetch point_key old
    user = user_key obj.user 

    point_type = bus.fetch point.type 
    comment_type = get_type 'Comments', point_type

    if obj.body.length > 140 
      summary = obj.body.substring(0, 140)
      desc = obj.body.substring(140)
    else 
      summary = obj.body 
      desc = null

    key = comment_key obj 

    new_comment =
      key: key 
      created_at: obj.created_at
      summary: summary
      parent: server_slash(point.key)
      type: server_slash comment_type.key
      children: []
      creator: server_slash user
      description: if desc then desc
      imported: true 
      sliders: [{
          key: "slider/#{slugify(summary).substring(0,12)}"
          parent: server_slash(comment_type.sliders[0].key)
          values: []
          imported: true
        }]

    changed = save_if_changed bus.fetch(key), new_comment

    if changed 
      comment_type.type_children ||= []
      if comment_type.type_children.indexOf(server_slash(new_comment.key)) < 0
        comment_type.type_children.push server_slash new_comment.key
        bus.save comment_type

      point.children ||= []
      if point.children.indexOf(server_slash(new_comment.key)) < 0
        point.children.push server_slash new_comment.key
        bus.save point

  # users
  else if obj.key.match '/user/'
    key = user_key obj
    u = bus.fetch key 
    save_if_changed u, 
      name: if obj.name?.length > 0 then obj.name else 'anonymous'
      pic: if obj.avatar_file_name then u.avatar = "https://#{asset_host}/system/avatars/#{obj.key.split('/user/')[1]}/large/#{obj.avatar_file_name}"
      imported: true 

  if obj.key[0] == '/'
    bus.delete obj



save_if_changed = (obj, props) ->
  changed = false 

  for k,v of props
    if JSON.stringify(obj[k]) != JSON.stringify(v)
      obj[k] = v
      changed = true


  if changed 
    bus.save obj 
    #console.log "SAVING", obj.key

  changed 


request = require('request')
request_queue = []

sending = false 
local = false 

http_fetch = (key, subdomain) -> 
  if sending 
    request_queue.push [key, subdomain]
  else 
    domain = if !local then "https://#{subdomain}.consider.it" else "http://localhost:3000"
    sending = true 
    request
      url: "#{domain}#{key}"
      headers: 
        Accept: 'application/json'
        'X-Requested-With': 'XMLHttpRequest'
      (err, response, body) -> 
        console.log "bus.fetch RETURNED ", subdomain, key

        try 
          bus.save.fire(JSON.parse(body))
        catch e 
          console.log 'ERROR parsing body!!!', body, e

        sending = false 

        if request_queue.length > 0 
          req = request_queue.shift()
          http_fetch req[0], req[1]


subdomains = {}

root = 
  key: "point/proto_root"
  summary: "Selectively imported data from *.consider.it"
  description: """
    <p>Welcome to the Considerit v2 prototype!</p>

    <p>I'm currently investigating how to visualize points, visualize hierarchy, and navigate amongst considerit points. I'd like to come out of this investigation with a sense that I can more easily understand the points that people are contributing in a dialogue. In considerit v1, I never felt that I could do this very effectively, especially given the awkwardness of navigation. </p>

    <p>If you'd like to mess around here and provide feedback, please do so! It would be cool to adopt the perspective of looking around, trying to learn new things from the considerit data that maybe you hadn't seen before.</p>

    <p>My planned design steps after this investigation: </p>
    <ol> 
    <li> Weighing/filtering opinions, and ranking points</li>
    <li> Making contributions. Creating points. Creating lists. Dragging sliders & opening points. Editing. I will also add open ended conversations.</li>
    <li> Url design, Earl, and domains</li>
    <li> Authentication and some access control</li>
    </ol>
  """
  suggests: []
  creator: server_slash 'user/1701travis-kripl'
  treat_authorless: false
  imported: true
  children: []

subdomain_type = 
  key: "point/channels"
  category: 'Channels'
  icon: 'author'
  suggested_by: [server_slash(root.key)]
  imported: true
  sliders: [{
      key: "slider/channels"
      labels: ['meh', 'interesting']
      imported: true
    }]

bus.save subdomain_type
root.suggests = [server_slash(subdomain_type.key)]
bus.save root


types = 
  Channels: subdomain_type

http_fetch "/subdomains", 'bitcoin'
http_fetch "/application", 'bitcoin'

subdomain_map =

  'grouphealth': 'Demos'
  'bitcoin-demo': 'Demos'
  'Relief-Demo': 'Demos'
  'GS-Demo': 'Demos'
  'ECAST-Demo': 'Demos'
  'Committee-Meeting': 'Demos'
  'SocialSecurityWorks': 'Demos'
  'impacthub-demo': 'Demos'
  'Airbdsm': 'Demos'
  'program-committee-demo': 'Demos'
  'Seattle-2035': 'Demos'
  'swotconsultants': 'Demos'
  'swotconsultants1': 'Demos'
  'CARCD-demo': 'Demos'
  'news': 'Demos'
  'amberoon': 'Demos'
  'economist': 'Demos'
  'Cattaca': 'Demos'
  'fun': 'Demos'
  'Schools': 'Demos'
  'PabloNGO': 'Demos'
  'lyftoff': 'Demos'
  'sosh': 'Demos'
  'design': 'Demos'
  'event': 'Demos'
  'librofm': 'Demos'
  'Noah-Slides': 'Demos'
  'washingtonpost': 'Demos'
  'MSNBC': 'Demos'
  'MsTimberlake': 'Demos'
  'RicardoisAwesome': 'Demos'
  'ANUP2015': 'Demos'
  'ITFeedback': 'Demos'
  'AMA-RFS': 'Demos'

  'us': 'Internal'
  'statebus': 'Internal'
  'toomim': 'Internal'
  'learn': 'Internal'
  'considerittesting': 'Internal'
  'consider': 'Internal'
  'kevin': 'Internal'
  '2035Test': 'Internal'
  'testing123': 'Internal'

  'rupaul': 'Awesome'
  'neuwrite': 'Awesome'

  'kamakakoi': 'Public Engagement'
  'tigard': 'Public Engagement'
  'gsacrd': 'Public Engagement'
  'ecastonline': 'Public Engagement'
  'arlingtoncountyfair': 'Public Engagement'
  'Seattle2035': 'Public Engagement'
  'HALA': 'Public Engagement'  
  'LewisCounty': 'Public Engagement'
  'cityoftigard': 'Public Engagement'
  'VillaGB': 'Public Engagement'
  'LewisCounty': 'Public Engagement'
  'engageseattle': 'Public Engagement'

  'bradywalkinshaw': 'Campaign'

  'D21': 'Civic Dialogue'
  'cir': 'Civic Dialogue'
  'livingvotersguide': 'Civic Dialogue'
  'cali': 'Civic Dialogue'
  'CapitolHillEcoDistrict': 'Civic Dialogue'


  'CARCD': 'Strategic Planning'
  'ynpn': 'Strategic Planning'
  'WSFFN': 'Strategic Planning'

  'bitcoin-ukraine': 'Crypto'
  'bitcoin-core': 'Crypto'
  'bitcoin': 'Crypto'
  'bitshares': 'Crypto'
  'dash': 'Crypto'
  'bitcoinclassic': 'Crypto'
  'monero': 'Crypto'
  'openbazaar': 'Crypto'
  'bitcoinunlimited': 'Crypto'
  'btc': 'Crypto'
  'bitcoincore': 'Crypto'
  'on-chain-conf': 'Crypto'
  'BitcoinWarrior': 'Crypto'
  'bitcoinpresident': 'Crypto'
  'Arcade_CitySwarmStorm': 'Crypto'
  'coinfund': 'Crypto'
  'DAO_Ideaproofoflocation': 'Crypto'
  'BitcoinMacroeconomics': 'Crypto'
  'lisk_orethbetter': 'Crypto'
  'Debitcoin': 'Crypto'
  'BTCfork': 'Crypto'
  'etc': 'Crypto'
  'Lisksharing': 'Crypto'
  'bitcoinall': 'Crypto'
  'DashClassic': 'Crypto'
  '21': 'Crypto'
  '42': 'Crypto'
  'bitcoinitalia': 'Crypto'
  'bitcointhrowback': 'Crypto'
  'existencelabs': 'Crypto'
  'bitcoinfoundation': 'Crypto'
  'dao': 'Crypto'
  'crowdfoundhub': 'Crypto'
  'synereo': 'Crypto'
  'safenetwork': 'Crypto'
  'hongcoin': 'Crypto'
  'divvy': 'Crypto'
  'Divvy_Debate': 'Crypto'
  'ethereumclassic': 'Crypto'
  'etcconsiderit': 'Crypto'
  'Ethereum_Classic': 'Crypto'
  'Ethereum_Fork': 'Crypto'

  'Masala': 'Cohousing'
  'Svalin': 'Cohousing'



extend = (obj) ->
  obj ||= {}
  for arg, idx in arguments 
    if idx > 0
      for own name,s of arg
        if !obj[name]? || obj[name] != s
          obj[name] = s
  obj

new_key = (type, desc) ->
  type ||= 'point'
  if desc
    slug = slugify(desc) 
    slug += "-" + Math.random().toString(36).substring(7)
  else 
    slug = Math.random().toString(36).substring(7)
  type + '/' + slug

slugify = (text) -> 
  text.toString().toLowerCase()
    .replace(/\s+/g, '-')           # Replace spaces with -
    .replace(/[^\w\-]+/g, '')       # Remove all non-word chars
    .replace(/\-\-+/g, '-')         # Replace multiple - with single -
    .replace(/^-+/, '')             # Trim - from start of text
    .replace(/-+$/, '')             # Trim - from end of text
    .substring(0, 30)


uniq = (arr) ->
  unique = []
  for el in arr
    if unique.indexOf(el) == -1
      unique.push el 

  unique 




