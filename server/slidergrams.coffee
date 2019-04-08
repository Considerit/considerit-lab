
add_slidergram_client_handlers = module.exports = (master, client) ->
  client ?= master # if client isn't supplied, then we'll add directly to the master bus
  client('slider/*').to_save = (obj, t) ->
    u = client.fetch('current_user')

    old = master.fetch(obj.key)

    if old 
      # prevent clobbering of slides
      missing = []

      for oldslide in (old.values or [])        
        found = false 

        for slide in (obj.values or [])
          if slide.user == oldslide.user 
            found = true 
            break 
        if !found 
          missing.push oldslide 

      if missing.length > 0 
        obj.values ||= []  
        
        for slide in missing 
          # only the current user is allowed to delete their slide
          if deslash(slide.user) != u.user.key
            obj.values.push slide

    master.save(obj, t)
    t.done(obj)


deslash = (key) -> 
  if key?[0] == '/'
    key = key.substr(1)
  else 
    key
