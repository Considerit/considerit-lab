######
# Draws a bubble mouth svg. 
# 
#           
#          p3
#         .  
#       /  \ 
#     (     \_
#     \       `\___
#  p1  `.          `- . p2
#
#       <-^----------->
#       apex =~ .15
#
# Props:
#  width: width of the element
#  height: height of the element
#  svg_w: controls the viewbox width
#  svg_h: controls the viewbox height
#  skew_x: the amount the mouth juts out to the side
#  skew_y: the focal location of the jut
#  apex_xfrac: see diagram. The percent between the p1 & p2 that p3 is. 
#  fill, stroke, stroke_width, dash_array, box_shadow


dropShadow = (props) -> 
  FILTER 
    id: props.id

    FEOFFSET
      in: "SourceAlpha"          
      dx: props.dx
      dy: props.dy
      result: "offsetblur" 

    FEGAUSSIANBLUR
      in: 'offsetblur'
      stdDeviation: props.stdDeviation #how much blur
      result: 'blur2'

    FECOLORMATRIX
      in: 'blur2'
      result: 'color'
      type: 'matrix'
      values: """
        0 0 0 0  0
        0 0 0 0  0 
        0 0 0 0  0 
        0 0 0 #{props.opacity} 0"""


    FEMERGE null,
      FEMERGENODE 
        in: 'color'
      FEMERGENODE 
        in: 'SourceGraphic'



Bubblemouth = (props) -> 

  # width/height of bubblemouth in svg coordinate space
  defaults = 
    svg_w: 85
    svg_h: 100
    skew_x: 15
    skew_y: 80
    apex_xfrac: .5
    fill: 'white', 
    stroke: 'white', 
    stroke_width: 10
    dash_array: "none"   
    box_shadow: null

  for k,v of defaults 
    if !props[k]?
      props[k] = v

  full_width = props.svg_w + 4 * props.skew_x * Math.max(.5, Math.abs(.5 - props.apex_xfrac))

  if !props.width? 
    props.width = full_width
  if !props.height?
    props.height = props.svg_h

  apex = props.apex_xfrac
  svg_w = props.svg_w
  svg_h = props.svg_h
  skew_x = props.skew_x
  skew_y = props.skew_y

  cx = skew_x + svg_w / 2

  [x1, y1]   = [  skew_x - apex * skew_x,              svg_h ] 
  [x2, y2]   = [  skew_x + apex * svg_w,                   0 ]
  [x3, y3]   = [      x1 + svg_w + skew_x,             svg_h ]

  [qx1, qy1] = [ -skew_x + apex * ( cx + 2 * skew_x), skew_y ] 
  [qx2, qy2] = [  qx1 + cx,                           skew_y ]                           

  bubblemouth_path = """
    M  #{x1}  #{y1}
    Q #{qx1} #{qy1}
       #{x2}  #{y2}
    Q #{qx2} #{qy2}
       #{x3}  #{y3}
    
  """

  id = "x#{md5(JSON.stringify(props))}"

  SVG 
    version: "1.1" 
    xmlns: "http://www.w3.org/2000/svg"
    width: props.width
    height: props.height
    viewBox: "-4 0 #{full_width} #{svg_h}"
    preserveAspectRatio: "none"
    style: if props.style then props.style

    DEFS null,

      # # enforces border drawn exclusively inside
      # CLIPPATH
      #   id: id
      #   PATH
      #     strokeWidth: props.stroke_width * 2
      #     d: bubblemouth_path

      if props.box_shadow
        dropShadow extend {}, props.box_shadow, 
          id: "#{id}-shadow"

    if props.box_shadow
      # can't apply drop shadow to main path because of 
      # clip path. So we'll apply it to a copy. 
      PATH
        key: 'shadow'
        fill: props.box_shadow.fill or props.fill
        style: 
          filter: "url(##{id}-shadow)"
        d: bubblemouth_path
        
    PATH
      key: 'stroke'
      fill: props.fill
      stroke: props.stroke
      strokeWidth: props.stroke_width * 2
      clipPath: "url(##{id})"
      strokeDasharray: props.dash_array
      d: bubblemouth_path
