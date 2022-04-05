######################
# Data methods
#####################


#       root
#      /  |  \
#     /   v   \
#    /  ideas  \
#   /  .  |  .  \
#  / .    |    . \
# i1      |      i2
# |       v       |
# |     pros      |
# |   .      .    |
# | .           . |
# p1             p2

# This diagram illustrates three relationships that points can have to each other:

# (1) Parent / child. Each pro point (p1 and p2) is a child of each idea i1 and i2 respectively. And each idea is a child of root.

# (2) Type. i1 and i2 inherit type information from ideas. p1 and p2 inherit type information from pros. 

# (3) Suggests. The root point suggests children of type "ideas". "ideas" suggests children of type "pros".

# Structural data on a point reflects these three relationships: 

#   - parent / children
#   - type / type_children
#   - suggested_by / suggests

# A given point is unlikely to have all of these fields set on it.

# The programmer can decide to resolve a property up the type chain (e.g. "category" and "slider labels") or up the parent chain (e.g. "access control" and "user survey questions"). Or not look up the chain at all. 

# I made two methods that effectively implement prototype inheritance for getting the value of a property: 

#     resolve ( pnt, prop )            <====== looks up parent chain
#     resolve_type ( pnt, prop )  <====== looks up type chain

# The implementation felt more true. It is 400 lines shorter (50%). It's complexity could be reduced if we didn't care about cleanly deleting a point.

# Access the code at http://considerit.us/v2.html

# An updated data visualizer for this new structure is http://considerit.us/list_inspector_v2.html



####
# organize_children_by_type
#   - Sort children into lists
#   - Applies local overrides to point configuration
window.organize_children_by_type = (pnt) -> 
  pnt = fetch pnt
  types = {}

  for subpnt in (pnt.children or [])
    subpnt = fetch subpnt
    type = subpnt.type or subpnt.key
    types[type] ||= []
    types[type].push subpnt

  ordered_types = []
  for type in (resolve_type(pnt, 'suggests') or [])
    points = types[type] or []
    points = points.sort (a,b) -> 
      (b.sliders?[0].opinions or []).length - (a.sliders?[0].opinions or []).length
    ordered_types.push [type, points]

  ordered_types

# look up the parent chain for the prop
window.resolve = (obj, prop) -> 
  _resolve obj, 'parent', prop 

# look up the type chain for the prop
window.resolve_type = (obj, prop) -> 
  _resolve obj, 'type', prop

_resolve = (obj, inherit_prop, prop) -> 
  return null if !obj || ( typeof(obj) != 'string' && !obj.key)

  obj = fetch obj 

  if obj?[prop]
    obj[prop]
  else if obj[inherit_prop]
    _resolve obj[inherit_prop], inherit_prop, prop
  else 
    null 

window.apply_to_parent = (pnt, props) ->
  return if Object.keys(props).length == 0

  f = reactive_once -> 
    pnt = fetch pnt 
    if pnt.parent
      parent = fetch pnt.parent 
      return if f.loading()

      for own k,v of props 
        parent[k] = v
        delete pnt[k]

      save parent
      save pnt 

  f()

window.apply_to_type = (pnt, props) -> 
  return if Object.keys(props).length == 0

  f = reactive_once -> 
    pnt = fetch pnt 
    if pnt.type 
      type = fetch pnt.type 
      return if f.loading()

      for own k,v of props 
        type[k] = v 
        delete pnt[k]

      save type 
      save pnt

  f()


#######
# fork_type
# 
# Makes a local subtype of this type, and rewires things accordingly.
# Assumes everything is loaded.

window.fork_type = (pnt, local_points) -> 
  parent_type = fetch pnt

  new_type = create_point
    type: parent_type

  # instances of this point need to be converted to this new type
  # if they are part of the local tree
  for instance in (parent_type.type_children.slice() or [])
    instance = fetch instance
    if local_points[instance.key]
      instance.type = new_type.key 
      save instance 

      new_type.type_children ||= []
      new_type.type_children.push instance.key
      save new_type 

      array_remove parent_type.type_children, instance.key 
  
  save parent_type

  new_type 

window.create_point = (config) ->
  descriptor = config.summary or config.category
  key = new_key('point', descriptor)

  if config.suggests?
    suggests = []
    for suggest in (config.suggests or [])
      if typeof(suggest) != 'string' && !suggest.key 
        suggest.suggested_by ||= [key] 
        suggest = create_point suggest

      suggests.push suggest.key or suggest

    config.suggests = suggests

  if config.suggested_by && !type_is_array(config.suggested_by)
    config.suggested_by = [config.suggested_by]
  
  if config.parent
    config.parent = config.parent.key or config.parent

  if config.type
    config.type = config.type.key or config.type

  pnt = extend config,
    key: key
    creator: your_key()

  save pnt

  f = reactive_once -> 

    parent = fetch config.parent if config.parent
    type = fetch config.type if config.type

    return if f.loading()

    if parent
      parent.children ||= []
      parent.children.push pnt.key
      save parent 

    if type 
      type.type_children ||= []
      type.type_children.push pnt.key
      save type

  f()

  pnt 

####
# update_point
#
# Primarily for structural changes. For simple changes, just go ahead and save 
# them directly. This method assumes everything is properly loaded. Else, how 
# are you applying changes :-) 

window.update_point = (pnt, changes, apply_locally) -> 

  creating_new = typeof(pnt) != 'string' && !pnt.key 

  return create_point pnt if creating_new

  # otherwise, we're updating an existing point :-)

  original_pnt = pnt = fetch pnt 
  # make the requested changes to a local fork if needed
  if apply_locally
    pnt = fork_type pnt, apply_locally

  for own k,v of (changes[original_pnt.key] or {})

    if k in ['parent', 'children', 'type_children', 'type']
      # Setting these properties here without cleaning anything up would cause
      # problems. Disallow it until there is a need. 
      console.error "Unsupported change to #{pnt.key}: #{k}=#{v}"
      continue 

    else if k == 'suggests'
      suggests = v 
      old_suggests = resolve_type(pnt, 'suggests') or []
      new_suggests = ( (t.key or t) for t in suggests) or []
      if JSON.stringify(old_suggests) != JSON.stringify(new_suggests)
        
        suggestions = []
        for suggestion, idx in new_suggests
          if typeof(suggestion) == 'string' or suggestion.key 
            suggestion = update_point suggestion, changes, apply_locally
          else 
            suggestion.suggested_by = [pnt.key]
            suggestion = create_point suggestion
          suggestions.push suggestion 

        pnt.suggests = (t.key or t for t in suggestions)

        # remove points that have fallen from grace
        fallen = (t for t in old_suggests when t not in new_suggests)
        for unsuggested in (fallen or [])
          f = reactive_once -> 
            unsuggested = fetch unsuggested
            return if f.loading() 

            unsuggested.suggested_by ||= []
            if unsuggested.suggested_by.length == 0
              delete_point unsuggested
            else 
              array_remove unsuggested.suggested_by, type.key
              save unsuggested

          f()

    else 
      pnt[k] = v 

  save pnt 
  pnt 

window.delete_point = (pnt, to_delete) -> 
  originally = pnt.key or pnt
  f = reactive_once ->
    
    # prefetch all requirements
    visit_connected pnt
    return if f.loading()

    to_delete ||= _points_to_delete pnt

    pnt = fetch pnt

    # delete all type_children of this point (should already be fetched)
    for instance in (pnt.type_children?.slice() or [])
      delete_point instance, to_delete

    # delete all children of this point (should already be fetched)
    for subpnt,idx in (pnt.children?.slice() or [])
      delete_point subpnt, to_delete

    # remove this point from parent's children
    if pnt.parent && !to_delete[pnt.parent]?
      parent = fetch pnt.parent
      deleted = array_remove parent.children, pnt.key
      if deleted 
        console.info "REMOVED #{pnt.key} from children of #{parent.key}"        
        save parent
      else 
        console.error "#{parent.key} had untracked children"

    # remove this point from type's type_children
    if pnt.type && !to_delete[pnt.type]?
      type = fetch pnt.type
      deleted = array_remove type.type_children, pnt.key
      if deleted 
        console.info "REMOVED #{pnt.key} from type_children of #{type.key}"        
        save type
      else 
        console.error "#{type.key} had untracked type_children"

    # remove this point from places where it is suggested
    for suggests in (pnt.suggested_by or [])
      if !to_delete[(suggests.key or suggests)]?
        suggests = fetch suggests
        deleted = array_remove suggests.suggests, pnt.key
        if deleted 
          console.info "REMOVED #{pnt.key} from suggestor #{suggests.key}"
          save suggests
        else 
          console.error "#{suggests.key} had points think it suggested them"

    # delete this point
    console.info "DELETING", pnt.key
    del pnt 

  f()

_points_to_delete = (pnt, to_delete) -> 
  to_delete ||= {}
  pnt = fetch pnt

  to_delete[pnt.key] = 1

  # delete all type_children of this point (should already be fetched)
  for instance in (pnt.type_children or [])
    _points_to_delete instance

  # delete all children of this point (should already be fetched)
  for subpnt in (pnt.children or [])
    _points_to_delete subpnt

  to_delete

window.visit_connected = (pnt) -> 
  pnt = fetch pnt

  visit_ancestors pnt

  for suggests in (pnt.suggested_by or [])
    visit_connected suggests

  for subpnt in (pnt.children or [])
    visit_connected subpnt

  for instance in (pnt.type_children or [])
    visit_connected instance

window.visit_ancestors = (pnt) -> 
  return if !pnt.key && typeof pnt != 'string'

  pnt = fetch pnt
  ancestor = pnt
  while ancestor.parent
    ancestor = fetch ancestor.parent

  ancestor = pnt 
  while ancestor.type 
    ancestor = fetch ancestor.type







