# Deep inquiry nested points prototype
#
#
# Requires: 
#
#   - avatar.coffee
#   - shared.coffee
#   - auth.coffee
#   - tooltips.coffee
#   - slidergrams.coffee
#   - fickle.coffee

fickle.register (upstream_vars) -> 
  outer_gutter = 10
  doc_padding = 50

  content_width = Math.max 550, upstream_vars.window_width - outer_gutter * 2 - doc_padding * 2

  return {
    outer_gutter: outer_gutter
    doc_padding: doc_padding
    content_width: content_width
  }


# BODY is the entry point for the prototype. Trace from here
# to see how everything works. 
dom.body = ->
  current_user = fetch '/current_user'



  auth = fetch 'auth'

  ARTICLE 
    style: 
      width: fickle.document_width + 400
      backgroundColor: '#eee'
      fontFamily: '"helvetica neue",Arial,helvetica,sans-serif'
    
    STYLE """
        body {margin: 0;}
      """


    DIV 
      style: 
        padding: "20px #{fickle.outer_gutter}px"
        width: fickle.document_width

      TOP()

      DIV 
        style: 
          padding: fickle.doc_padding
          backgroundColor: 'white'
          boxShadow: '0 1px 2px rgba(0,0,0,.2)'
          minHeight: '100%'
          #margin: 'auto'

        DISCUSSION
          root: "/#{forum}_root"

      TOOLTIP()
      CURSORS()



    DIV 
      key: 'auth_overlay'
      style: 
        position: 'fixed'
        top: 0 
        zIndex: 9999
        width: '100%'
        # fontFamily: 'sans-serif'

      if !current_user.logged_in && auth.start
        AUTH
          login: auth.try_login or false
      else if auth.edit_profile
        EDIT_PROFILE()
      else if auth.set_avatar 
        SET_AVATAR()


dom.TOP = -> 
  auth = fetch 'auth'
  current_user = fetch '/current_user'
  HEADER 
    style: 
      position: 'relative' 

    DIV 
      key: 'auth'
      style: 
        textAlign: 'right'

      WHO_IS_HERE
        show_auth: true




