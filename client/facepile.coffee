#####
# Facepile
# A pile of avatar faces
# Props:
#   users: list of user keys (or objects) to be shown in the pile
#   avatar_style: style object passed onto Avatar
#   offset[X/Y]: how to offset each respective avatar in each direction
# TODO: improve interface for facepile
dom.FACEPILE = -> 
  s =
    rows: 80
    dx: @props.offsetX
    dy: @props.offsetY
    col_gap: 8

  # Now we'll go through the list from back to front
  i = @props.users.length

  DIV 
    style: 
      display: 'inline-block'
      position: 'relative'
      height: @props.avatar_style.height + Math.min(s.rows, i) * s.dy 
      width: @props.avatar_style.width

    for user in @props.users
      i -= 1
      curr_column = Math.floor(i / s.rows)
      side_offset = curr_column * s.col_gap + i * s.dx
      top_offset = (i % s.rows) * s.dy 
      left_right = 'right'

      style = 
        top: top_offset
        position: 'absolute'

      for k,v of @props.avatar_style
        style[k] = v

      style[left_right] = side_offset

      # Finally draw the guys
      AVATAR
        key: user.key or user
        user: user
        key: i
        style: style

