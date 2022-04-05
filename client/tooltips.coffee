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

# dom.TOOLTIP = -> 
#   tooltip = fetch('tooltip')
#   return SPAN(null) if !tooltip.coords

#   coords = tooltip.coords
#   tip = tooltip.tip

#   style = if tooltip.style then tooltip.style else 
#     fontSize: 16
#     padding: '2px 4px'
#     borderRadius: 8
#     #whiteSpace: 'nowrap'
#     maxWidth: 200
#     color: '#999'
#     backgroundColor: '#f6f6f6'

#   size = sizeWhenRendered(tip, style)

#   # place the tooltip above the element, unless off screen
#   top = coords.top - size.height - 9
#   if top < 0
#     top = coords.top + coords.height 

#   DIV
#     style:  extend {}, style, 
#       top: top
#       left: coords.left - size.width / 2
#       pointerEvents: 'none'
#       zIndex: 9999
#       position: 'absolute'

#     dangerouslySetInnerHTML: {__html: tip}

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





# replacement for jquery's offset method
getOffset = (element) ->
  # return { top: 0, left: 0, width: 0, height: 0 } if !element.getClientRects().length

  rect = element.getBoundingClientRect()
  win = element.ownerDocument.defaultView

  offset = 
    top: rect.top + win.pageYOffset
    left: rect.left + win.pageXOffset
    width: rect.width
    height: rect.height
  offset 



set_style """

#tooltip .downward_arrow {
  width: 0; 
  height: 0; 
  border-left: 10px solid transparent;
  border-right: 10px solid transparent;  
  border-top: 10px solid black;
}
#tooltip .upward_arrow {
  width: 0; 
  height: 0; 
  border-left: 10px solid transparent;
  border-right: 10px solid transparent;  
  border-bottom: 10px solid black;
}

"""

window.clear_tooltip = ->
  tooltip = fetch('tooltip')
  tooltip.coords = tooltip.tip = tooltip.top = tooltip.positioned = null
  tooltip.offsetY = tooltip.offsetX = null 
  tooltip.rendered_size = false 
  save tooltip

toggle_tooltip = (e) ->
  tooltip_el = e.target.closest('[data-tooltip]')
  if tooltip_el?
    tooltip = fetch('tooltip')
    if tooltip.coords
      clear_tooltip()
    else 
      show_tooltip(e)

show_tooltip = (e) ->
  tooltip_el = e.target.closest('[data-tooltip]')
  if tooltip_el?
    name = tooltip_el.getAttribute('data-tooltip')
    tooltip = fetch 'tooltip'
    if tooltip.tip != name 

      tooltip.coords = getOffset(tooltip_el)
      tooltip.coords.left += tooltip.coords.width / 2
      tooltip.tip = name
      save tooltip
    e.preventDefault()
    e.stopPropagation()

tooltip = fetch 'tooltip'
hide_tooltip = (e) ->
  if e.target.getAttribute('data-tooltip')
    clear_tooltip()
    e.preventDefault()
    e.stopPropagation()

document.addEventListener "DOMContentLoaded", ->
  document.body.addEventListener "click", toggle_tooltip
  document.body.addEventListener "mouseover", show_tooltip, true
  document.body.addEventListener "mouseleave", hide_tooltip, true


# $('body').on 'focusin', '[data-tooltip]', show_tooltip
# $('body').on 'focusout', '[data-tooltip]', hide_tooltip

# focus/blur don't seem to work at document level
# document.addEventListener "focus", show_tooltip, true
# document.addEventListener "blur", hide_tooltip, true



dom.TOOLTIP = ->

  tooltip = fetch('tooltip')
  return SPAN(null) if !tooltip.coords

  coords = tooltip.coords
  tip = tooltip.tip

  style = defaults {}, (@props.style or {}), 
    fontSize: 14
    padding: '4px 8px'
    borderRadius: 8
    pointerEvents: 'none'
    zIndex: 999999999999
    color: 'white'
    backgroundColor: 'black'
    position: 'absolute'      
    boxShadow: '0 1px 1px rgba(0,0,0,.2)'
    maxWidth: 350



  if tooltip.top || !tooltip.top?
    # place the tooltip above the element
    extend style, 
      top: coords.top + (tooltip.offsetY or 0) - (tooltip.rendered_size?.height or 0) - 12
      left: if !tooltip.rendered_size then -99999 else coords.left + (tooltip.offsetX or 0) - tooltip.rendered_size?.width / 2
  else 
    # place the tooltip below the element
    extend style, 
      top: coords.top + (tooltip.offsetY or 0)
      left: if !tooltip.rendered_size then -99999 else coords.left + (tooltip.offsetX or 0) - (tooltip.rendered_size.width or 0)

  DIV
    id: 'tooltip'
    role: "tooltip"
    style: style


    DIV 
      dangerouslySetInnerHTML: {__html: tip}

    if tooltip.top || !tooltip.top?
      SPAN 
        className: 'downward_arrow'
        style: 
          position: 'absolute'
          bottom: -7
          left: if tooltip.positioned != 'right' then "calc(50% - 10px)" 
          right: if tooltip.positioned == 'right' then 7

    else   
      SPAN 
        className: 'upward_arrow'
        style: 
          position: 'absolute'
          left: if tooltip.positioned != 'right' then "calc(50% - 10px)" 
          top: -7
          right: if tooltip.positioned == 'right' then 7

dom.TOOLTIP.refresh = ->
  tooltip = fetch('tooltip')
  if !tooltip.rendered_size && tooltip.coords 
    tooltip.rendered_size = 
      width: @getDOMNode().offsetWidth
      height: @getDOMNode().offsetHeight
    save tooltip
