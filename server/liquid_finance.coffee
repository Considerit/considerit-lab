
add_liquid_finance_handlers = module.exports = (bus, client) ->


  client('liquid_networks').to_fetch = (key, rest) -> 
    networks = []
    for k,v of bus.cache 
      if k.match 'liquid_network/'
        if v.name
          client.fetch k
          networks.push k

    { networks }

  client('liquid/*').to_fetch = (k, rest) ->
    forum = rest
    flows = {}
    taps = {}
    users = {}
    springs = {}

    current_user = client.fetch('current_user')
    if current_user?.user 
      client.fetch(current_user.user) 

    for user,data of bus.cache
      if user.match('user/') && data.liquid?[rest] && data.liquid[rest].flows?.length > 0
        user = client.fetch user 

        dedupped = {}
        for f in data.liquid[rest].flows
          dedupped[f] = true
        dedupped = Object.keys(dedupped)

        if dedupped.length != data.liquid[rest].flows.length 
          console.log "Duplicates found for #{user.name}:", dedupped, data.liquid[rest].flows.length
          data.liquid[rest].flows = dedupped
          bus.save data

        flows['/' + user.key] = (client.fetch(deslash(f)) for f in data.liquid[rest].flows)

        if data.liquid[rest].tap?.activated
          taps['/' + user.key] = data.liquid[rest].tap

        if data.liquid[rest].spring?.activated
          springs['/' + user.key] = data.liquid[rest].spring

        users[user.key] = user

    { flows, taps, springs, users }


deslash = (key) -> 
  if key?[0] == '/'
    key = key.substr(1)
  else 
    key


