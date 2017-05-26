###########################################################
# FICKLE: A statebus library for responsive variables
# The MIT License (MIT)
# Copyright (c) Travis Kriplean, Consider.it LLC
# 
#
# Define & recompute shared variables based upon viewport changes, such as a 
# resize of a window. 

# To use, just include this file. 

# If you want to have more than just window_width and window_height defined, 
# define a function that calculates the custom responsive variables. 
# This function takes a single argument, the upstream variables like window 
# width and height that have already been calculated. For example: 

# fickle.register (upstream_vars) -> 
#     single_col: upstream_vars.window_width < 500
#     gutter: if upstream_vars.window_width > 1000 then 80 else 10

# Any of your components can register their own responsive variables using the 
# same method. 

# All variables are made available on fickle. E.g. fickle.window_width. 
# Any component that has accessed a responsive variable on fickle will 
# be re-rendered if the variable changes. For example: 

# DIV 
#   style: 
#     width: fickle.single_col
#     padding: fickle.gutter

# Beneath the surface, all variables are at fetch("fickle_vars"), and a getter 
# is used to facilitate the direct variable access while subscribing callers 
# to changes. 

window.fickle = 
  register: (funk) -> 
    registered_funks.push funk 
    new_funks = true 
    i = setInterval -> 
      if document.body 
        be_responsive()
        clearInterval i 
    , 1

    
be_responsive = -> 
  
  # the basic responsive variables
  responsive_vars = 
    window_width: window.innerWidth
    window_height: window.innerHeight
    document_width: document.body.clientWidth
    document_height: document.body.clientHeight

  # Compute the custom variables that the programmer wants defined
  for funk in registered_funks
    derived = funk(responsive_vars)
    for k,v of derived 
      responsive_vars[k] = v 

  # only update state if we have a change
  vars = fetch('fickle_vars')
  changed = false
  for own k,v of responsive_vars
    if vars[k] != v
      changed = true
      vars[k] = v

  # Convenience method for programmers to access variables.
  for lvar in Object.keys(vars)
    if !prop_defined[lvar]
      do (lvar) ->
        prop_defined[lvar] = true
        Object.defineProperty fickle, lvar,
          get: -> 
            fetch('fickle_vars')[lvar]

  save(vars) if changed
  vars


registered_funks = []
prop_defined = {}

# Trigger recomputation of variables on appropriate events. 
# Currently only responding to window resize events. 
for ev in ['resize']
  window.addEventListener ev, be_responsive

