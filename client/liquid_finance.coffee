DEFAULT_FLOW_VALUE = .01

dom.LIQUID_FINANCE_INDEX = ->
  networks = fetch '/liquid_networks'

  DIV null,
    H1 null, 
      "All Liquid Finance Flows"
    UL null,
      for network in networks.networks or []
        LI null,
          A 
            href: "/#{network.slug}"
            network.name or network.slug

dom.LIQUID_NETWORK  = ->
  network = fetch "/liquid_network#{@props.name}"

  # return SPAN null if !network.slug

  network.slug ?= @props.name.substring(1)

  DIV 
    maxWidth: 800
    fontSize: 16

    PROMPT
      network: network 

    YOUR_VALUE_ROUTER
      network: network


    TEXT 
      key: 'your_network'
      style: 
        margin: '24px 0'    
      obj: network
      attr: 'your_network'
      edit_permission: -> is_travis()
      autofocus: false
      html_WYSIWYG: 'markdown'
      disable_html: true


    if get_user()?.liquid?[network.slug]?.flows?.length > 0 

      DRAW_DAG
        network: network
        initial_selection: get_user()?.name
        hide_info: true
    else 
      DIV 
        style: 
          backgroundColor: "#f1f1f1"
          padding: '18px 24px'

        if fetch('/current_user').logged_in
          """Sorry, we can't show your network because you haven't added
             anyone yet. Please add some people above, or, I guess, just
             muddle on forward :-o"""
        else 
          """Sorry, we can't show your network because you haven't introduced yourself. 
             Please register an account above, first."""

    # DRAW_NETWORK
    #   network: network
    #   initial_selection: get_user()?.name

    TEXT 
      key: 'full_network_description'    
      style: 
        margin: '24px 0'    
      obj: network
      attr: 'full_network_description'
      edit_permission: -> is_travis()
      autofocus: false
      html_WYSIWYG: 'markdown'
      disable_html: true

    DRAW_DAG
      network: network

    # DRAW_NETWORK
    #   network: network

    TEXT 
      key: 'taps_and_springs'        
      style: 
        margin: '24px 0 12px 0'        
      obj: network
      attr: 'taps_and_springs'
      edit_permission: -> is_travis()
      autofocus: false
      html_WYSIWYG: 'markdown'
      disable_html: true


    TAP_OR_SPRING
      network: network

    DRAW_DAG
      network: network
      view_flows: true

    # DRAW_NETWORK
    #   network: network
    #   view_flows: true

    TEXT 
      key: 'postscript'            
      style: 
        margin: '24px 0'        
      obj: network
      attr: 'postscript'
      edit_permission: -> is_travis()
      autofocus: false
      html_WYSIWYG: 'markdown'
      disable_html: true



get_user = ->
  current_user = fetch('/current_user')
  if current_user.user 
    fetch current_user.user
  else 
    null

window.is_travis = ->
  get_user()?.email == "travis@consider.it"

get_my_config = (network) ->
  network = fetch(network)
  u = get_user()

  console.assert u && network.slug, u, network

  if !u.liquid? || !u.liquid[network.slug]
    u.liquid ?= {}
    u.liquid[network.slug] ?=
      flows: []
      tap:
        max: null 
        divert_percent: null
        used_for: ""
        sharing: ""
      spring: 
        min: null 
        max: null 
        match_percent: null
    save u

  conf = u.liquid[network.slug]
  conf
  


dom.YOUR_VALUE_ROUTER = ->

  #TODO: return a login first form here. 

  network = fetch @props.network 
  return SPAN null if !network.slug 

  user = get_user()

  logged_in = fetch('/current_user').logged_in

  if logged_in
    config = get_my_config network
    sorted = config.flows.slice()
    sorted.sort (a,b) -> fetch(b).value - fetch(a).value
    unsorted = JSON.stringify(sorted) != JSON.stringify(config.flows)  


  DIV null,
    DIV
      style: 
        height: 20
      if unsorted && logged_in
        BUTTON
          onClick: => 
            config.flows.sort (a,b) -> fetch(b).value - fetch(a).value
            save user 

          style: 
            fontSize: 12
          "Re-sort list"

    H2 
      style: 
        marginBottom: 0
        marginTop: 0
        display: 'inline-block'
        width: 400 + 20
        

      TEXT 
        obj: network
        attr: 'list_title'
        edit_permission: -> is_travis()
        autofocus: false
        html_WYSIWYG: 'markdown'
        disable_html: true
        style: 
          textDecoration: 'underline'


      # DIV 
      #   style: 
      #     fontSize: 14
      #     fontWeight: 300
      #     marginTop: -20

      #   "...of candidates and connectors"


    H2 
      style: 
        display: 'inline-block'
        marginBottom: 0
        marginTop: 0

      TEXT 
        obj: network
        attr: 'slider_instructions'
        edit_permission: -> is_travis()
        autofocus: false
        html_WYSIWYG: 'markdown'
        disable_html: true
        style: 
          textDecoration: 'underline'

      # DIV 
      #   style: 
      #     fontSize: 14
      #     fontWeight: 300
      #     marginTop: -20

      #   # "...in their knowledge of suitable candidates"
      #   "The value will automatically be normalized so everything adds up to 100%"

    DIV
      style: 
        height: 20


    if !fetch('/current_user').logged_in  

      DIV
        style: 
          backgroundColor: '#f1f1f1'
          padding: '24px 36px'
        INLINE_LOGIN
          add_submit_button: true
          intro_text: "Please introduce yourself to participate."
    else if (config.flows or []).length == 0

      DIV
        style: 
          # backgroundColor: '#f1f1f1'
          padding: '24px 36px'
          border: "3px dotted #ccc"
          margin: "12px 64px"
          borderRadius: 16

        """You haven't added anyone yet. Some ideas of who to name to get you started:"""
        UL
          style: 
            paddingLeft: 36

          LI null, "...a person who helped raise your awareness"
          LI null, "...an indigenous leader in your region"
          LI null, "...a podcast host who interviews relevant people"


    else 
      UL 
        style: 
          marginTop: 0
          paddingLeft: 20

        for flow, idx in config.flows

          LI 
            key: flow
            style: 
              backgroundColor: if idx % 2 then '#f7f7f7'
            FLOW
              network: network
              flow: flow 

    if fetch('/current_user').logged_in  
      EDITABLE_FLOW
        key: config.flows.length
        network: network


    # TAP_OR_SPRING
    #   network: network


normalize_sliders_relative_to = (flow, network) ->
  # return


  # normalize the other flows
  config = get_my_config network
  other_flows = config.flows.length - 1
  total_val = 0
  for f in config.flows 
    f = fetch f
    if flow != f
      total_val += f.value
  allocate_across = 1 - (flow?.value or 0) # normalize remaining flow values
  normalizer = allocate_across / total_val
  if isNaN(normalizer) || normalizer == Infinity || total_val == 0
    normalizer = 0
  for f in config.flows 
    f = fetch f
    if flow != f

      if isNaN(f.value)
        f.value = 0

      f.value *= normalizer
      save f

get_max_flow = (network) ->
  config = get_my_config network

  mmx = 0 
  for flow in config.flows
    if fetch(flow).value > mmx
      mmx = fetch(flow).value

  mmx


dom.FLOW = ->
  is_new = !@props.flow
  @local.editing ?= false
  network = fetch @props.network 

  user = get_user()

  if !is_new
    flow = fetch @props.flow

  DIV
    style: 
      display: 'flex'

    DIV 
      style: 
        width: 400

      if is_new || @local.editing 
        EDITABLE_FLOW
          network: network
          flow: flow
          save_callback: => @local.editing = false; save @local
      else 
        DIV 
          onDoubleClick: =>
            @local.editing = true
            save @local
          B null,
            flow.name

          DIV 
            style: 
              fontSize: 12
              color: '#444'
            flow.reason or '(no reason given)'

    if !is_new  && flow.name
      DIV null, 
        INPUT 
          style: 
            width: 200
          type: 'range'
          min: 0.001
          max: Math.min(1, get_max_flow(network) + .1)
          value: flow.value
          step: .001
          onChange: (e) ->
            flow.value = parseFloat e.target.value
            save flow

            normalize_sliders_relative_to(flow, network)

            




        SPAN 
          style: 
            display: 'inline-block'
            marginLeft: 8
            fontSize: 14
            fontWeight: 300

          # if flow.value < .33
          #   "High confidence"
          # else if flow.value < .66 
          #   "Considerable confidence"
          # else if flow.value < .99
          #   "Exceptional confidence"
          # else 
          #   "Screaming YES confidence"

          "#{Math.round(flow.value * 100)}%"


    if !is_new
      flows = get_my_config(network).flows
      DIV null, 

        BUTTON 
          style: 
            backgroundColor: 'transparent'
            border: 'none'
            color: '#666'
            fontSize: 12
            marginLeft: 36
            textDecoration: "underline"
          onClick: => 
            i = -1
            for ff,idx in flows or []
              if ff == flow.key
                i = idx
                break 
            get_my_config(network).flows.splice(i,1)
            save user

            normalize_sliders_relative_to(null, network)
          'delete'



dom.EDITABLE_FLOW = ->
  is_new = !@props.flow
  network = fetch @props.network
  if !is_new
    @flow = fetch @props.flow
  else 
    @flow ?= {
      name: null,
      reason: null,
      value: null
    }

  flow = @flow

  if !is_new && flow.name
    @local.name ?= flow.name

  user = get_user()

  flows = fetch("/liquid/#{network.slug}").flows

  return DIV null if !flows

  all_names = {}
  included_by_this_user = (fetch(f).name for f in (flows[user.key] or {}))
  for name, flows_for_user of (flows or {})
    u_name = fetch(name).name

    if (!@local.filtered || u_name.toLowerCase().indexOf(@local.filtered.toLowerCase()) > -1)
      all_names[u_name] = 1

    for f in flows_for_user
      n = f.name?.trim()
      if !@local.filtered || n?.toLowerCase().indexOf(@local.filtered.toLowerCase()) > -1
        all_names[n] = 1

  all_names = (u for u,__ of all_names when u not in included_by_this_user)
  all_names.sort()
  DIV 
    style:
      backgroundColor: '#f5f5f5'
      padding: '12px 24px'
      borderColor: '1px solid #eee'
      marginTop: 12

    LABEL null,
      DIV 
        style: 
          fontSize: 14

        "Name of the person (or project or organization)"

      DropMenu
        options: all_names
        open_menu_on: 'input'

        selection_made_callback: (name) =>
          flow.name = name
          document.getElementById(@local.key + '-name').value = name
          @local.filtered = null
          @local.name = flow.name          
          save @local

        render_anchor: (menu_showing) =>
          INPUT 
            id: @local.key + '-name'
            style: 
              width: 300

            type: 'text'
            placeholder: "Name"
            autoComplete: 'off'        
            defaultValue: flow.name or ""
            onChange: (e) =>
              flow.name = e.target.value
              @local.filtered = e.target.value
              @local.name = flow.name
              save @local

        render_option: (name) ->
          SPAN
            key: 'name' 
            style: 
              fontWeight: 600
            name 

        wrapper_style: 
          display: 'inline-block'
        menu_style: 
          backgroundColor: '#ddd'
          border: '1px solid #ddd'
          marginTop: 0
          paddingLeft: 0

        option_style: 
          padding: '4px 12px'
          fontSize: 14
          cursor: 'pointer'
          display: 'block'
          color: '#444'
          textDecoration: 'none'

        active_option_style:
          backgroundColor: '#eee'

    LABEL null,
      DIV 
        style: 
          fontSize: 14
          marginTop: 12
        "[optional] Why?"


      AUTOSIZEBOX
        style: 
          width: '100%'
          padding: '4px 8px'
        key: 'why'
        defaultValue: flow.reason or ""
        placeholder: "url, project(s) they work on, etc"
        onChange: (e) ->
          flow.reason = e.target.value

      DIV 
        style: 
          fontSize: 12
          marginBottom: 12          
        "You can write this as if you were introducing this person to someone else, if you want."


    LABEL
      style: 
        fontSize: 14
        marginTop: 12
        display: 'flex'
        alignItems: 'center'

      INPUT
        style: 
          marginRight: 12
          padding: '4px 8px'
        type: 'checkbox'
        key: 'candidate'
        defaultChecked: flow.candidate
        onChange: (e) ->
          flow.candidate = e.target.checked

      "Does relevant, possibly underfunded, work directly on the issue"

    LABEL 
      style: 
        fontSize: 14
        marginTop: 12
        display: 'flex'
        alignItems: 'center'



      INPUT
        style: 
          marginRight: 12
          padding: '4px 8px'
        type: 'checkbox'
        key: 'connector'
        defaultChecked: flow.connector
        onChange: (e) ->
          flow.connector = e.target.checked

      "Likely knows about good people working on this issue whom you don't"




    BUTTON 
      style: 
        display: 'block'
        marginTop: 12
        alignItems: 'center'

      disabled: !@local.name || @local.name.length < 2
      onClick: =>
        return if !flow.name || flow.name.length < 2

        if flow.name == get_user().name
          alert("Sorry, you can't add yourself. You'll have a chance later to say you're interested in receiving funding.")
          return

        flow.key ?= new_key 'flow', flow.name or ""
        if is_new 
          user.liquid[network.slug].flows.push flow.key
          save user
        flow.value = DEFAULT_FLOW_VALUE
        save flow


        normalize_sliders_relative_to(flow, network)

        @props.save_callback?()

      if is_new then 'Add' else 'Update'



set_style """
  [data-widget="TAP_OR_SPRING"] .details {
    padding-left: 30px;
  }
  [data-widget="TAP_OR_SPRING"] label {
    font-size: 18px;
    font-weight: 700;
    display: block;
  }
  [data-widget="TAP_OR_SPRING"] label input[type="checkbox"] {
    margin-right: 12px;
  }
  [data-widget="TAP_OR_SPRING"] input.percent {
    width: 50px;
    text-align: right
  }
  [data-widget="TAP_OR_SPRING"] input.money {
    width: 80px;
  }
  [data-widget="TAP_OR_SPRING"] input {
    font-size: 16px;
  }
"""

dom.TAP_OR_SPRING = -> 
  return SPAN null if !get_user() || !fetch(@props.network).slug

  DIV 
    style: 
      backgroundColor: "#f7f7f7"
      padding: "18px 24px"
      margin: "9px 0 18px 0"

    SPRING
      network: @props.network

    DIV 
      style: 
        marginTop: 12

      TAP
        network: @props.network


dom.SPRING = ->
  user = get_user() 
  network = fetch @props.network
  network_name = get_network_name(network)
  config = get_my_config(network)

  DIV null, 

    LABEL null, 
      INPUT 
        type: 'checkbox'
        defaultChecked: config.spring.activated
        onChange: (e) ->
          config = get_my_config(network)
          config.spring.activated = !config.spring.activated
          save user

      "I am a spring of money for #{network_name}"

    DIV
      className: 'details'

      "I will contribute $"

      INPUT 
        ref: "min"
        className: 'money'
        type: 'number' 
        min: 0
        step: 50
        defaultValue: if config.spring.min == null then 50 else config.spring.min        
        onChange: (e) =>
          config = get_my_config(network)
          config.spring.min = parseInt e.target.value
          # maxx = @refs.max.getDOMNode()
          # if config.spring.min > parseInt(maxx.value)
          #   config.spring.max = maxx.value = config.spring.min

          console.assert config.spring.min == user.liquid[network.slug].spring.min
          save user


      " per month." 

      # ", while matching "

      # INPUT
      #   ref: "match"
      #   className: 'percent'      
      #   type: 'number'
      #   min: 0       
      #   step: 10         
      #   defaultValue: if config.spring.match_percent == null then 5 else config.spring.match_percent
      #   onChange: (e) => 
      #     config = get_my_config(network)          
      #     config.spring.match_percent = parseInt(e.target.value)
      #     save user

      # "% of any money flowing by me, up to a maximum of $"

      # INPUT 
      #   ref: "max"
      #   type: 'number'
      #   className: 'money'
      #   min: 0        
      #   step: 50        
      #   defaultValue: if config.spring.max == null then 100 else config.spring.max
      #   onChange: (e) =>
      #     config = get_my_config(network)
      #     config.spring.max = parseInt(e.target.value)
      #     minn = @refs.min.getDOMNode()
      #     if config.spring.max < parseInt(minn.value)
      #       config.spring.min = minn.value = config.spring.max
      #     save user


      # " per month."


dom.TAP = -> 
  user = get_user() 
  network = fetch @props.network
  network_name = get_network_name(network)
  config = get_my_config(network)

  DIV null, 
    LABEL null, 
      INPUT 
        type: 'checkbox'
        defaultChecked: config.tap.activated
        onChange: (e) ->
          config = get_my_config(network)
          config.tap.divert_percent ?= 25
          config.tap.max ?= 1000
          config.tap.activated = !config.tap.activated
          console.log config.tap
          save user

      "I know how to put money to good use for #{network_name}" 

    DIV
      className: 'details'

      "I will tap "
      INPUT 
        ref: "percent_tap"
        type: 'number' 
        className: 'percent'      
        defaultValue: if config.tap.divert_percent == null then 25 else config.tap.divert_percent
        min: 0 
        onChange: (e) => 
          config = get_my_config(network)          
          config.tap.divert_percent = parseInt(e.target.value)
          console.log "TAPPING", e.target.value, config.tap.divert_percent, user.liquid[network.slug]?.earth_regeneration?.tap
          save user

      "% of the money flowing to me, up to a maximum of $"
      INPUT 
        ref: "max"
        type: 'number'
        defaultValue: if config.tap.max == null then 1000 else config.tap.max
        className: 'money'  
        min: 0    
        onChange: (e) => 
          config = get_my_config(network)          
          config.tap.max = parseInt(e.target.value)
          save user

      " per month. The remaining #{100 - (if config.tap.divert_percent == null then 25 else config.tap.divert_percent)}% flow can pass through to my downstream network."


      DIV 
        style: 
          marginTop: 8
        "I'll use the money I tap to:"

      GROWING_TEXTAREA 
        style: 
          display: 'block'
          width: '100%'
          minHeight: 28 * 3
          marginTop: 6
        ref: "use"
        type: 'text'
        rows: 3
        placeholder: "Share what you'd like about what you're up to and how money will help."
        DEFAULT_FLOW_VALUE: config.tap.used_for
        onChange: (e) => 
          config = get_my_config(network)          
          config.tap.used_for = e.target.value
          save user

      DIV 
        style: 
          marginTop: 8
        "I like to share my work by:"

      GROWING_TEXTAREA 
        style: 
          display: 'block'
          width: '100%'
          minHeight: 28 * 3
          marginTop: 6
        ref: "use"
        type: 'text'
        rows: 3
        placeholder: "Your homepage or blog, a Twitter account, link to Patreon, etc."
        DEFAULT_FLOW_VALUE: config.tap.sharing
        onChange: (e) => 
          config = get_my_config(network)          
          config.tap.sharing = e.target.value
          save user


get_network_name = (network) -> 
  network = fetch network
  (network.name or network.slug).split('_').join ' '

dom.PROMPT = -> 
  network = fetch @props.network
  name = get_network_name(network)

  attrs = ['title', 'description', 'list_title']

  ensure_set = (attr, default_val) ->
    if !network[attr]?
      network[attr + '_src'] = default_val
      network[attr] = marked?.marked? default_val
      save network


  ensure_set 'title', "Liquid finance for #{name}"
  ensure_set 'description', """
      Imagine a wealthy friend approaches you, concerned about #{name}, but with only rudimentary knowledge. 
      They're frustrated with past experiences financing causes only through well known 
      foundations and NGOs with glossy brochures, and would rather directly finance promising projects and people working on the edge. 

      They ask you who they should talk to as they try to figure out how to put their wealth to work. Who would you 
      recommend they talk to? And what confidence would you have that a particular recommendation would lead them to eventually
      find high leverage projects to fund and people to support? 

      * You don't need to know them.
      * They don't have to be doing great work directly on #{name}, rather they might just be well positioned 
        to help your wealthy friend identify who else to talk with. Perhaps you suspect they are 
        more well informed than you about good people and projects (like a podcast host), or more tapped into a 
        particular relevant network than you.
      * If you are excited about a person working directly on #{name}, go ahead and add them!
      * You don't have to just add people. You can list organizations. You can even list decision making bodies, like an annual competition with judges or a consensus-based group/process within a voluntary network.      
      * This isn't meant to be a comprehensive list.
      * This is just a snapshot. You would be able to change your recommendations over time.
    """

  ensure_set 'list_title', "Who do you recommend?"
  ensure_set 'slider_instructions', "Your Confidence"

  ensure_set 'your_network', """
      Here is a network visualization of your recommendations:
    """

  ensure_set 'full_network_description', """
      Now imagine that many people associated with #{name} completed this exercise, including the 
      people for whom you recommended your friend talk with. 

      We would then have a map of which people are perceived to hold knowledge about important underfunded efforts, as well as the people actually undertaking those projects (many of whom might only be known by a subset of insiders). In other words, this network gives us a snapshot of who the community of participants believes are "authorities" on who is doing good work that needs funding.

      This map can stay dynamic anyone can shift their weights or add or remove recommendations as they learn more or the world changes, money ebbing and pulsing as needs and opportunities shift.

      So here is the network created thus far by you and others. The size of each participant in the 
      network is correlated with the degree to which they are recommended by their peers, or 
      their peers' peers. In other words, an emergent "authority" (using the PageRank algorithm).
    """

  ensure_set 'taps_and_springs', """
      With this kind of network, potential funders can simply "ask the network" to spend their 
      money wisely on high-impact projects, starting from the recommendations of people they 
      trust. In other words, the network becomes "liquid" when money is made to flow through it. 


      To make money flow, we need to introduce two concepts: 
      - **springs** are places in the network where money enters (e.g. a monthly donation) 
      - **taps** are places in the network where money exits (e.g. a person on the frontline 
      takes out money flowing by them to pay for their housing). 


      Let's now add springs and flows to this prototype. From your position in your network, 
      you can set up a tap (if you want to irrigate a project or pay your bills) or become 
      a spring. Other people can do the same. The network visualization below shows the money flowing 
      through the network given the taps and springs throughout the network, including yours. [note: This is completely 
      disconnected from any real life monetary commitments. Go ahead and put in whatever you want.]

    """

  ensure_set 'postscript', """
    Feel free to modify your network to see how the flows change. 


    Anyway, overall, this type of system could be used to help these wealthier folks (e.g. white 
    collar professionals in the US) transparently fund the people working on riskier, high 
    leverage projects, without even having to specifically be aware of them. For example, adherents to the 
    donate 10% of your income philosophy could simply identify several causes they care about and people they trust with some knowledge, and then setup a spring of money that flows into the network. Participants closer to the center of the network would dynamically route the money to a changing set of worthwhile projects. 


    One area of design I'd like to explore is the possibility of emphasizing regions/bioregions 
    so that people can "discover" people and projects they can contribute to (money, volunteering, 
    other) that are nearby, by leveraging the insights of a global network. I'm embarrassed by 
    the number of times someone who lives halfway across the world tells me about an awesome 
    person living basically nextdoor to me or a project based nearby. Can we leverage the global network 
    to make regional engagement more visible and salient?


    Another area of inquiry is the ability for this mapping to give participants and funders 
    the tooling to identify underfunded areas of the network, by examining the differences 
    between the finance flows and the recommendation flows (i.e. who is actually getting money 
    vs who does the network things could use money). Lots of challenges with this one. 


    What do you think? There is some complexity, but I think a good UI could hide the complexity 
    well (while still allowing interested folks to learn more / dive deeper). Have you ever 
    come across other examples of a liquid or delegated giving system? 
    """    


  DIV 
    style: {}

    I null, 
      """This is a narrative prototype of an idea I had when asking myself "Can we create a
         network that can take in money from motivated but less 
         well-informed people on an issue and dynamically redistribute it to 
         underfunded folks & projects doing good work, without relying on proposal writing, group 
         decision making processes, formal organizations, and/or arduous research?" 
      """

    DIV 
      style: 
        marginTop: 12
        fontStyle: 'italic'
      """As a prototype, there are lots of bugs. Nothing guaranteed."""

    H1
      style: 
        marginBottom: 0

      TEXT 
        obj: network
        attr: 'title'
        edit_permission: -> is_travis()
        autofocus: false
        html_WYSIWYG: 'markdown'
        disable_html: true
        placeholder: "A title for your network (default=\"Liquid finance for #{name}\")"


    TEXT 
      obj: network
      attr: 'description'
      edit_permission: -> is_travis()
      autofocus: false
      html_WYSIWYG: 'markdown'
      disable_html: true