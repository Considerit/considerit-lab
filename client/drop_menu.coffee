dom.DropMenu = ->
  @local.active_option ?= -1
  open_menu_on = @props.open_menu_on or 'focus' #other option is 'activation'

  wrapper_style = defaults {}, @props.wrapper_style, 
    position: 'relative'

  if !@props.anchor_class_name
    anchor_style = defaults {}, @props.anchor_style,
      position: 'relative'
      background: 'transparent'
      border: 'none'
      cursor: 'pointer'
      fontSize: 'inherit'
      padding: 0
      fontWeight: 400
  else 
    anchor_style = defaults {}, @props.anchor_style

  anchor_when_open_style = defaults {}, @props.anchor_open_style, anchor_style
  
  menu_style = defaults {}, @props.menu_style,
    listStyle: 'none'
    position: 'absolute'
    zIndex: 999999

  menu_when_open_style = defaults {}, @props.menu_when_open_style, menu_style


  option_style = defaults {}, @props.option_style,
    cursor: 'pointer'
    outline: 'none'
  active_option_style = defaults {}, @props.active_option_style, option_style

  options = @props.options

  render_anchor = @props.render_anchor
  render_option = @props.render_option

  set_active = (idx) => 
    idx = -1 if !idx?
    if @local.active_option != idx 
      @local.active_option = idx 
      save @local 
      if idx != -1
        setTimeout =>
          if idx == @local.active_option
            @refs["menuitem-#{idx}"]?.getDOMNode()?.focus()           
        , 0


  trigger = (e) => 
    selection = options[@local.active_option]

    @props.selection_made_callback? selection

    if selection.href 
      e.currentTarget.click()

    close_menu()
    e.stopPropagation()
    e.preventDefault()


  close_menu = =>    
    document.activeElement.blur()
    @local.show_menu = false
    save @local
    @props.close_callback?()

  # wrapper
  DIV 
    className: 'dropmenu-wrapper'
    ref: 'menu_wrap'
    key: 'dropmenu-wrapper'
    style: wrapper_style

    onTouchEnd: => 
      @local.show_menu = !@local.show_menu
      save @local

    onMouseLeave: (e) =>
      return if open_menu_on == 'input'
      close_menu()

    onBlur: (e) => 
      setTimeout => 
        # if the focus isn't still on an element inside of this menu, 
        # then we should close the menu
        if @refs.menu_wrap && !closest(document.activeElement, (node) => node == @refs.menu_wrap?.getDOMNode())
          @local.show_menu = false; save @local
      , 0

    onKeyDown: (e) => 
      @props.onKeyDown?(e)
      if e.which == 13 || e.which == 27 # ENTER or ESC
        close_menu()
        e.preventDefault()            
      else if e.which == 38 || e.which == 40 # UP / DOWN ARROW
        @local.active_option = -1 if !@local.active_option?
        if e.which == 38
          @local.active_option--
          if @local.active_option < 0 
            @local.active_option = options.length - 1
        else 
          @local.active_option++
          if @local.active_option > options.length - 1
            @local.active_option = 0 
        set_active @local.active_option
        e.preventDefault() # prevent window from scrolling too


    # anchor

    BUTTON 
      key: 'drop-anchor'
      tabIndex: 0
      'aria-haspopup': "true"
      'aria-owns': "dropMenu-#{@local.key}"
      style: if @local.show_menu then anchor_when_open_style else anchor_style
      className: "dropMenu-anchor #{if @props.anchor_class_name then @props.anchor_class_name else ''}"

      onMouseEnter: if open_menu_on == 'focus' then (e) => 
              @local.show_menu = true
              set_active(-1)
              save @local 

      onClick: if open_menu_on == 'click' then (e) => 
              @local.show_menu = !@local.show_menu
              set_active(-1) if @local.show_menu
              save @local

      onKeyDown: (e) => 
        if e.which == 13

          @local.show_menu = !@local.show_menu
          if @local.show_menu
            set_active(0) 
          save @local
          e.preventDefault()
          e.stopPropagation() 
        else if open_menu_on == 'input' && !@local.show_menu
          @local.show_menu = !@local.show_menu
          set_active(-1) if @local.show_menu
          save @local


      render_anchor @local.show_menu 

    # drop menu

    UL
      key: 'dropMenu-menu'
      className: 'dropmenu-menu'
      id: "dropMenu-#{@local.key}" 
      role: "menu"
      'aria-hidden': !@local.show_menu
      hidden: !@local.show_menu
      style: if @local.show_menu then menu_when_open_style else menu_style

      for option, idx in options
        do (option, idx) =>
          LI 
            key: option.label
            role: "presentation"

            A
              ref: "menuitem-#{idx}"
              role: "menuitem"
              tabIndex: if @local.active_option == idx then 0 else -1
              href: option.href #optional
              key: "#{option.label}-activate" 
              'data-action': option['data-action'] #optional
              className: if @local.active_option == idx then 'active-menu-item'

              style: if @local.active_option == idx then active_option_style else option_style

              onClick: (e) => 
                if @local.active_option != idx 
                  set_active idx 
                trigger(e)

              onTouchEnd: (e) =>
                if @local.active_option != idx 
                  set_active idx 
                trigger(e)

              onKeyUp: (e) => 
                if e.which == 13 
                  trigger(e)

              onFocus: (e) => 
                if @local.active_option != idx 
                  set_active idx
                e.stopPropagation()

              onMouseEnter: => 
                if @local.active_option != idx   
                  set_active idx

              onBlur: (e) => 
                if @local.active_option == idx 
                  @local.active_option = -1 
                  save @local  

              onMouseExit: (e) => 
                @local.active_option = -1 
                save @local
                e.stopPropagation()

              render_option option, @local.active_option == idx