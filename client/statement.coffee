POINT_MOUTH_WIDTH = 40

dom.BUBBLE_WRAP = ->

  left_or_right = 'right' 
  ioffset = -10
  user = @props.user 

  w = @props.width
  mouth_w = (@props.mouth_style or {}).width or POINT_MOUTH_WIDTH

  mouth_style = defaults {}, (@props.mouth_style or {}),
    top: 8
    position: 'absolute'
    left: -mouth_w - 3
    transform: 'rotate(270deg) scaleX(-1)'
  
  DIV
    style: defaults {}, @props.wrapper_style, 
      position: 'relative'
      listStyle: 'none outside none'
      marginBottom: '0.5em'
      boxSizing: 'content-box'


    if user
      AVATAR
        key: user
        user: user
        style: defaults {}, (@props.avatar_style or {}),
          position: 'absolute'
          top: 0
          width: 50
          height: 50
          left: -64
        hide_tooltip: false 
        anonymous: @props.anon

    DIV 
      style : defaults {}, (@props.bubble_style or {}),
        width: w
        borderWidth: 3
        borderStyle: 'solid'
        borderColor: 'transparent'
        position: 'relative'
        zIndex: 1
        outline: 'none'
        padding: 8
        borderRadius: 16
        backgroundColor: considerit_gray
        boxShadow: '#777 0 1px 1px 0px' #'#b5b5b5 0 1px 1px 0px'
        boxSizing: 'border-box'

      DIV 
        style: crossbrowserfy mouth_style, 'transform'

        Bubblemouth 
          apex_xfrac: 0
          width: mouth_w
          height: mouth_w
          fill: @props.bubble_style?.backgroundColor or considerit_gray
          stroke: 'none'
          box_shadow: defaults {}, (@props.mouth_shadow or {}),   
            dx: 3
            dy: 0
            stdDeviation: 2
            opacity: .5


      @props.children



dom.STATEMENT = ->
  title = @props.title 
  body = @props.body

  DIV 
    style: 
      wordWrap: 'break-word'

    DIV 
      style: @props.title_style or {}

      className: 'statement'

      title

    if body 

      DIV 
        className: "statement"

        style: defaults {}, (@props.body_style or {}),
          wordWrap: 'break-word'
          marginTop: '0.5em'
          fontWeight: 300

        dangerouslySetInnerHTML:{__html: body}
