# Tooltips
# 
# State: 
#   tooltip
#     coords = {x,y} global offset of element to tooltip
#     tip = html to put in the tooltip
#
# create_tooltip is a shortcut for creating a tooltip by passing
#    an DOM node
#
# clear_tooltip is a shortcut for removing the tooltip
#
# Requires shared.coffee

dom.TOOLTIP = -> 
  tooltip = fetch('tooltip')
  return SPAN(null) if !tooltip.coords

  coords = tooltip.coords
  tip = tooltip.tip

  style = if tooltip.style then tooltip.style else 
    fontSize: 16
    padding: '2px 4px'
    borderRadius: 8
    #whiteSpace: 'nowrap'
    maxWidth: 200
    color: '#999'
    backgroundColor: '#f6f6f6'

  size = sizeWhenRendered(tip, style)

  # place the tooltip above the element, unless off screen
  top = coords.top - size.height - 9
  if top < 0
    top = coords.top + coords.height 

  DIV
    style:  extend {}, style, 
      top: top
      left: coords.left - size.width / 2
      pointerEvents: 'none'
      zIndex: 9999
      position: 'absolute'

    dangerouslySetInnerHTML: {__html: tip}

window.create_tooltip = (tip, target, style) -> 
  pos = target.getBoundingClientRect()
  tooltip = fetch 'tooltip'
  tooltip.tip = tip 
  tooltip.coords = 
    top: pos.top + window.scrollY
    left: pos.left + pos.width / 2
    height: pos.height 
    width: pos.width
  if style 
    tooltip.style = style
  save tooltip 

window.clear_tooltip = ->
  tooltip = fetch 'tooltip'
  tooltip.coords = null
  tooltip.tip = null
  tooltip.style = null 
  save tooltip

