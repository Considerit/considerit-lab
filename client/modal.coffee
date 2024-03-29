
######
# Modal
#
# Mixin for handling some aspects of accessible modal forms
# Currently makes the first element with role=dialog exclusively focusable, unless there exists an @refs.dialog
# Will cancel on ESC if there exists a cancel button with @ref=cancel_dialog
# Code influenced by: 
#    - https://uxdesign.cc/how-to-trap-focus-inside-modal-to-make-it-ada-compliant-6a50f9a70700
#    - https://bitsofco.de/accessible-modal-dialog/
set_style """
#lightbox {
  position: fixed;
  top: 0;
  left: 0;
  background: rgba(244,95,115,1);

  
  width: 100vw;
  height: 100vh;
  z-index: 99999;
}
"""


window.makeModal = (DIALOG) ->


  DIALOG.accessibility_on_keydown = (e) ->
    # cancel on ESC if a cancel button has been defined
    if e.key == 'Escape' || e.keyCode == 27
      @refs.cancel_dialog?.getDOMNode().click()

    # trap focus
    is_tab_pressed = e.key == 'Tab' or e.keyCode == 9
    if !is_tab_pressed
      return
    if e.shiftKey
      # if shift key pressed for shift + tab combination
      if document.activeElement == @first_focusable_element
        @last_focusable_element.focus()
        # add focus for the last focusable element
        e.preventDefault()
    else
      # if tab key is pressed
      if document.activeElement == @last_focusable_element
        # if focused has reached to last focusable element then focus first focusable element after pressing tab
        @first_focusable_element.focus()
        # add focus for the first focusable element
        e.preventDefault()

    return


  DIALOG.ready = -> # componentWillMount 
    @scroll_Y = window.scrollY
    console.log @, @scroll_Y

  DIALOG.refresh = ->
    console.log "REFRESHING!"
    modal = @refs?.dialog?.getDOMNode() or document.querySelector '[role=dialog]'
    return if !modal || @mounted
    @mounted = true

    @focused_element_before_opening = document.activeElement

    ######################################
    # For capturing focus inside the modal
    # add all the elements inside modal which you want to make focusable
    focusable_elements = 'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'

    # select the modal by it's id
    @first_focusable_element = modal.querySelectorAll(focusable_elements)[0]
    # get first element to be focused inside modal
    focusable_content = modal.querySelectorAll(focusable_elements)
    @last_focusable_element = focusable_content[focusable_content.length - 1]

    # get last element to be focused inside modal
    document.addEventListener 'keydown', @accessibility_on_keydown

    try 
      modal.querySelector('input:not([disabled])').focus()
    catch e 
      console.error e

    #####################
    # For preventing scroll outside of the modal, and allowing scroll within, 
    # all while making it seem like the whole page is scrollable. 
    extend modal.style,
      position: 'fixed'
      top: "0px"
      left: "0px"
      width: '100vw'
      height: '100vh'
      overflow: 'auto'
      zIndex: 99999

    scroll_bar_width = window.innerWidth - document.body.offsetWidth
    extend document.body.style,
      marginRight: scroll_bar_width
      overflow: 'hidden'
      position: 'fixed'
      top: "-#{@scroll_Y}px"



  
  DIALOG.down = -> # componentWillUnmount
    # return the focus to the element that had focus when the modal was launched
    if @focused_element_before_opening && document.body.contains(@focused_element_before_opening)
      @focused_element_before_opening.focus()
    document.removeEventListener 'keydown', @accessibility_on_keydown

    extend document.body.style,
      marginRight: null
      overflow: null
      position: null
      top: 0

    # restore scroll position
    window.scroll(0, @scroll_Y)


