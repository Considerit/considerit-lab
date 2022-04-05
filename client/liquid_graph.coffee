
get_link_key = (src, dest) -> 
  src = src.data or src 
  dest = dest.data or dest
  "#{src.id or src}===>#{dest.id or dest}"

links_to = (src, dest, network) ->
  get_link_key(src,dest) of network.links


dom.DRAW_DAG = ->

  network = fetch @props.network
  flows = fetch("/liquid/#{network.slug}").flows

  if @local.selection == undefined && @props.initial_selection
    @local.selection = @props.initial_selection

  return DIV null if !flows

  @size = defaults {}, (@props.size or {}), 
    height: 620 
    width: 950

  # register dependencies. why is statebus not doing this for me?
  for user, ff of flows
    fetch(user)
    for f in ff
      fetch f


  drawAvatar = (name, size) =>
    existing = fetch("/user/#{name}")
    size ?= 25
    if existing.name
      AVATAR 
        user: existing
        hide_tooltip: false
        style: 
          width: size
          height: size
          borderRadius: '50%'
          margin: '0 8px'
    else if @colorMap
      SPAN 
        style: 
          width: size
          height: size
          display: 'inline-block'
          borderRadius: '50%'
          backgroundColor: @colorMap.get(name)
          margin: '0 8px'

  DIV 
    style: 
      position: 'relative'
      width: '100vw'

    if @local.selection
      

      DIV 
        style: 
          position: 'absolute'
          width: @size.width
          top: 4
          display: 'flex'
          alignItems: 'center'
          fontSize: 14
          justifyContent: 'center'

        "Selected: "

        DIV 
          style: 
            backgroundColor: '#f1f1f1'
            padding: '4px 8px'
            borderRadius: 8
            display: 'flex'
            alignItems: 'center'

          drawAvatar(@local.selection)

          @local.selection




    SVG 
      style: 
        width: @size.width
        height: @size.height
        border: '1px solid #eee'
        display: 'inline-block'
      id: "svg-#{@local.key}".replace('/', '__')

    if !@props.hide_info 

      DIV
        style: 
          width: 250
          display: 'inline-block'
          maxHeight: @size.height
          overflowY: 'scroll'
          marginLeft: 18

        if @network_data

          if !@props.view_flows
            nodes = Object.values(@network_data.nodes)
            nodes.sort(  (a,b) -> b.rank - a.rank )

            UL 
              style: 
                listStyle: 'none'
                padding: 0

              for node in nodes
                LI 
                  style: 
                    marginBottom: 10
                    fontSize: 12
                    display: 'flex'
                    alignItems: 'center'
                    cursor: 'pointer'
                  onClick: do(node) => =>
                    if @local.selection == node.id 
                      @local.selection = null 
                    else 
                      @local.selection = node.id
                    save @local


                  drawAvatar(node.name, 15)

                  node.name
          else 
            fellows = Object.values(@network_data.nodes).filter( (n) -> n.diverting > 0 )
            fellows.sort(  (a,b) -> b.diverting - a.diverting )

            funders = Object.values(@network_data.nodes).filter( (n) -> n.springing > 0 )
            funders.sort(  (a,b) -> b.springing - a.springing )

            connectors = Object.values(@network_data.nodes).filter( (n) -> n.total_outflow - (n.springing or 0) > 0 )
            connectors.sort(  (a,b) -> b.total_outflow - (b.springing or 0) - (a.total_outflow - (a.springing or 0) ) )

            groups = [{nodes: fellows, header: "Fellows", amt: (n) -> n.diverting}, {nodes: funders, header: "Funders", amt: (n) -> n.springing}, {nodes: connectors, header: "Connectors", amt: (n) -> n.total_outflow - (n.springing or 0)}]


            for {nodes, header, amt} in groups
              DIV 
                style: 
                  maxHeight: @size.height / groups.length
                  overflowY: 'scroll'

                H3 
                  style: {}
                  header

                UL 
                  style: 
                    listStyle: 'none'
                    padding: 0

                  for node in nodes
                    LI 
                      style: 
                        marginBottom: 10
                        fontSize: 12
                        display: 'flex'
                        alignItems: 'center'
                        cursor: 'pointer'
                      onClick: do(node) => =>
                        if @local.selection == node.id 
                          @local.selection = null 
                        else 
                          @local.selection = node.id
                        save @local


                      drawAvatar(node.name, 15)

                      node.name

                      SPAN 
                        style: 
                          paddingLeft: 8

                        "$#{Math.round(amt(node))} / mo"
            














dom.DRAW_DAG.refresh = ->
  network = fetch @props.network
  liquid = fetch("/liquid/#{network.slug}")
  flows = liquid.flows
  taps = liquid.taps
  springs = liquid.springs

  gravatars = fetch('/gravatars')


  return if !flows || Object.keys(flows).length == 0 || !gravatars.gravatars


  fingerprint = JSON.stringify(flows) + JSON.stringify(springs) + JSON.stringify(taps) + JSON.stringify(@local.selection)

  return if fingerprint == @local.last_fingerprint
  @local.last_fingerprint = fingerprint

  @network_data = network_data = build_network_data network
  console.log @network_data

  view_flows = @props.view_flows

  @imgs ?= {}




  get_link_data = (src, target) -> 
    network_data.links[get_link_key(src.data or src, target.data or target)]

  get_node_size = (node, additional) ->
    n = node.data
    additional ?= 0
    if view_flows
      s = additional + Math.max n.total_outflow, n.total_inflow # - n.diverting
      4 * Math.log(1 + s) + 4
    else
      100 * (n.rank or 0) + 1

  get_link_width = (l) -> 
    if view_flows
      2 * Math.log(l.flow_amount + 1) + 1
    else
      Math.round(2 * l.value) + 1

  get_link_label = ({source, target}) =>
    if (@local.selection && @local.selection != source.data.id)
      return null

    data = get_link_data source, target

    if view_flows
      label = "<b>#{source.data.name}</b> routes <b>$#{data.flow_amount.toFixed(2)}</b> to <b>#{target.data.name}</b>. That's <b>#{Math.round(data.value * 100)}%</b> of their outflow."
    else 
      label = "<b>#{source.data.name}</b> suggests <b>#{target.data.name}</b>" #" with <b>#{Math.round(data.value * 100)}%</b> of their normalized total confidence."

    reason = fetch(data.flow).reason
    if reason 
      label = "<div>#{label}</div><i>Reason: \"#{reason}\"</i>"
    label

  get_node_label = (node) =>
    n = node.data or node

    if @local.selection && @local.selection != n.id && !links_to(network_data.nodes[@local.selection], n, network_data)
      return null

    label = "<div style='font-size:20px'><b>#{n.name}</b></div>"

    for link in n.inflows or []
      if link.flow.reason 
        label += "<div style='font-size:13px;margin-left:12px;'><span style='font-style:italic'>\"#{link.flow.reason}\"</span><span style='padding-left:6px; white-space:nowrap'>- #{link.source.name}</span></div>"

    if n.inflows 
      label += "<br>"

    if view_flows 
      if n.diverting
        conf = taps[n.user] or {used_for: "This person has not used this prototype. For sake of demonstration, we pretend they use all money flowing to them."}
      
        label += "<div style=''><span style='background-color:green'>Diverting <span style='font-weight:bold'>$#{n.diverting.toFixed(2)}/month</span></span> Used for: #{conf.used_for or 'Not given'}</div>"
      if n.springing
        label += "<div style='background-color:rgb(52, 142, 225)'>Springing <span style='font-weight:bold'>$#{n.springing.toFixed(2)}/month</span> into the network</div>"
      if n.total_outflow > 0 
        out = n.total_outflow - (n.springing or 0)
        label += "<div style='background-color:rgb(225, 142, 52)'>Routing <span style='font-weight:bold'>$#{out.toFixed(2)}/month</span> downstream from others</div>"


    label

  reverse_cycles = (decycled_data) ->
    reversed_links = {}
    removed_links = {}    


    has_cycle = (path) ->
      first_occurrance = {}
      the_cycle = null
      found_cycle = false
      for id, idx in path
        if id of first_occurrance
          found_cycle = true
          the_cycle = path.slice first_occurrance[id], idx
          break 
        else 
          first_occurrance[id] = idx

      return the_cycle

    visit = (visiting, current_path) ->
      current_path.push visiting.id
      a_cycle = has_cycle current_path

      return a_cycle if a_cycle

      for link in visiting.outflows
        # console.log "#{visiting.name} ==> #{link.target.name} $#{flowing} (#{weight} * #{$outflow})"
        cycle_here = visit link.target, current_path.slice()
        return cycle_here if cycle_here
      return false


    remove_link = (link, arr) ->
      lx = 0
      found = false
      for ll,lx in arr
        if link.flow.key == ll.flow.key
          found = true
          break 
      console.assert found, "could not remove link because it wasn't in the array", {arr, link}
      arr.splice lx, 1


    resolve_cycle = (cycle) ->
      links = []

      # reverse a link at random
      attempts = 0
      success = false 
      while attempts < 1000 && !success
        idx = Math.floor( Math.random() * (cycle.length - 1))
        src = decycled_data.nodes[cycle[idx]]
        if idx == cycle.length - 1
          target_idx = 0 
        else 
          target_idx = idx + 1
        target = decycled_data.nodes[cycle[target_idx]]

        l_key = get_link_key src, target
        other_way = get_link_key target, src
        if l_key not of reversed_links && other_way not of reversed_links

          link = decycled_data.links[l_key]
          link.target = src
          link.source = target

          remove_link link, src.outflows
          remove_link link, target.inflows

          src.inflows.push link 
          target.outflows.push link

          reversed_links[other_way] = true
          success = true

      console.assert success, "Could not find a cycle to resolve in ", {cycle, reversed_links, decycled_data}


    # resolve multidirectional links
    bidirectional_links = {}
    for link_key, link of decycled_data.links
      reversed_key = get_link_key link.target, link.source
      if reversed_key of decycled_data.links && reversed_key not of bidirectional_links && link_key not of bidirectional_links
        bidirectional_links[link_key] = [link, decycled_data.links[reversed_key]]

    for __, bi of bidirectional_links
      # choose one of the links to remove
      if bi[0].source.rank > bi[1].source.rank
        to_remove = bi[0]
      else 
        to_remove = bi[1]

      # note the removal
      link_key = get_link_key(to_remove.source, to_remove.target)
      removed_links[link_key] = to_remove

      # remove it from decycled_data
      delete decycled_data.links[link_key]
      remove_link to_remove, to_remove.source.outflows
      remove_link to_remove, to_remove.target.inflows


    # resolve n > 2 cycles
    cycles_detected = true
    while cycles_detected
      cycles_detected = false
      # Reverse the link between the two nodes in the cycle that have the least 
      # difference between node rank (conserving authority); an attempt to minimize 
      # the impact on the layout of reversing links.
      # TODO: this can be infinite if the reversal creates another cycle, and we just 
      #       cycle between reversing the same links. 
      # TODO: handle cycle between oneself (or just ensure no one can add a link to themself)

      # TODO: don't visit all the nodes! super inefficient and unncessary
      for name, node of decycled_data.nodes
        a_cycle = visit node, []
        if a_cycle
          cycles_detected = true 
          resolve_cycle a_cycle
          break 

    {reversed_links, removed_links, decycled_data}


  {reversed_links, decycled_data, removed_links} = reverse_cycles build_network_data(network) # clone the data
  # console.log {reversed_links, decycled_data, removed_links}

  convert_data_for_d3_dag = (network_data) ->   
    data_for_dag = Object.values network_data.nodes

    find_node = (n) ->
      for nd in data_for_dag
        if n.id == nd.id
          return nd
      throw "could not find #{JSON.stringify(n)}"

    for node in data_for_dag
      node.parentIds ?= []
    for name, link of network_data.links
      link.target.parentIds.push link.source.id

      #find_node(link.target).push link.source.id
    data_for_dag


  @data_for_dag = data_for_dag = convert_data_for_d3_dag(decycled_data)


  try 
    dag = d3.dagStratify()(data_for_dag)
  catch e
    console.log 'error:', e.message

  water_color = "rgb(29, 155, 240)" 
  irrigate_color = "rgb(70, 109, 29)"


  baseRadius = 5
  layout = d3
    .sugiyama() # base layout
    # .decross(d3.decrossOpt()) # minimize number of crossings
    .decross(d3.decrossTwoLayer().order(d3.twolayerAgg())) # minimize number of crossings 
    .layering(d3.layeringSimplex()) #d3.layeringLongestPath()  ) # d3.layeringTopological() ) # d3.layeringCoffmanGraham())   # default: d3.layeringSimplex()
    .nodeSize (node) => 
      return [0, 0] if !node
      [5 * get_node_size(node), 6 * get_node_size(node)] # set node size instead of constraining to fit

  # console.time('stratify')
  { width, height } = layout(dag)
  # console.timeEnd('stratify')

  svgSelection = d3.select "svg#svg-#{@local.key}".replace('/', '__')
  svgSelection.attr("viewBox", [0, 0, width, height].join(" "))

  svgSelection.selectAll("svg > *").remove()  

  defs = svgSelection.append("defs") # For gradients

  steps = dag.size()
  interp = d3.interpolateRainbow
  @colorMap = colorMap = new Map()

  dag_iterable = dag.idescendants().entries().base
  while entry = dag_iterable.next()
    break if entry.done
    [idx, node] = entry.value
    colorMap.set(node.data.id, interp(idx / steps))


  svgSelection
    .on "click", (e) => 
      if @local.selection && !@props.hide_info
        @local.selection = null
        save @local

  # How to draw edges
  line = d3
    .line()
    .curve(d3.curveCatmullRom)
    .x((d) => d.x)
    .y((d) => d.y)

  links = dag.links()

  # now that it is laid out, let's reintroduce any cycles we had reversed
  for link in links 
    key = get_link_key link.source, link.target
    if key of reversed_links
      console.log "REVERSING", link.source.data.id, link.target.data.id
      tmp = link.source
      link.source = link.target
      link.target = tmp
      link.points.reverse()

  # ...and we'll add back in any bidirectional links we had removed
  for link_key, removed_link of removed_links
    # find the corresponding link
    corresponding_link = null
    for existing_link in links 
      if removed_link.source.id == existing_link.target.data.id && \
         removed_link.target.id == existing_link.source.data.id
        corresponding_link = existing_link
        break 
    console.assert corresponding_link, "Could not find a corresponding link", {links, removed_link}

    # copy over positioning for the nodes (in case it didn't already happen)
    removed_link.source.x = corresponding_link.target.x
    removed_link.source.y = corresponding_link.target.y
    removed_link.target.x = corresponding_link.source.x
    removed_link.target.y = corresponding_link.source.y

    removed_link.source.data = removed_link.source
    removed_link.target.data = removed_link.target

    # add the link 
    links.push removed_link

    # create new control points (for the edge), for each direction, based on the 
    # control points created for the corresponding link in the dag layout algorithm
    points = corresponding_link.points

    if points.length == 2
      first = points[0]
      last = points[1]
      central = 
        x: first.x + (last.x - first.x) / 2
        y: first.y + (last.y - first.y) / 2
      points = [first, central, last]

    ctx = Math.floor points.length / 2
    first = points[ctx - 1]
    central = points[ctx]
    last = points[ctx + 1]

    perc_rise = (first.y - last.y) / point_distance(first, last)
    perc_run = (first.x - last.x) / point_distance(first, last)

    separation = 2 * Math.max get_link_width( removed_link ), get_link_width( decycled_data.links[get_link_key(existing_link.source, existing_link.target)] )
    
    new_centers = [ {
        x: central.x - perc_run  * separation / 2
        y: central.y + perc_rise * separation / 2
      }, {
        x: central.x + perc_run  * separation / 2
        y: central.y - perc_rise * separation / 2
      }      
    ]

    corresponding_link.points = points.slice()
    corresponding_link.points[ctx] = new_centers[0]

    removed_link.points = points.slice()
    removed_link.points[ctx] = new_centers[1]    
    removed_link.points.reverse()








  if view_flows 
    ##########################
    # Plot node taps -- as pulsing dots
    # animation adapted from http://samherbert.net/svg-loaders/

    duration = 3
    num_stars = 100

    # greens
    colors = ['#25523B', '#62BD69', '#358856', '#5AAB61', '#62BD69', '#30694B', '#0C3823', '#62BD69',] 
    colors = ['#5AAB61', '#62BD69', '#62BD69', '#62BD69', '#358856'] 

    # oranges
    # colors = ['#FFDB01', '#FFC212', '#FEA923', '#FE9033', '#FD7744', '#FD5E55']

    my_data = ({x,y,data} for {x,y,data} in dag.descendants() when data.diverting > 0)
    for d in my_data 
      d.data =
        id: d.data.id + " - tap"
        diverting: d.data.diverting
        total_outflow: d.data.total_outflow
        total_inflow: d.data.total_inflow

    svg_taps = svgSelection
      .append("g")
      .selectAll("g")
      .data(my_data)
      .enter()
        .filter (node) =>
          n = node.data or node
          !(@local.selection && @local.selection != n.id && !links_to(network_data.nodes[@local.selection], n, network_data))

        .append("g")
          .attr "transform", ({x, y}) -> 
            "translate(#{x}, #{y})"

    
    for ray_id in [0..num_stars]


      angles_per_node = {}
      for n in my_data 
        theta = Math.random() * 360
        angles_per_node[n.id] = 
          xx: Math.cos( theta * Math.PI / 180)
          yy: Math.sin( theta * Math.PI / 180)
      
      color = colors[ray_id % colors.length]

      stars = svg_taps
        .append("circle")
          .filter (n) ->  n.data.diverting > 0 && Math.log(n.data.diverting + 1) * 5 >= ray_id

          .attr "cx", (n) -> 
            r = get_node_size(n)
            angles_per_node[n.id].xx * (Math.random() * 4 * Math.log(n.data.diverting) + r + 4)

          .attr "cy", (n) -> 
            r = get_node_size(n)
            angles_per_node[n.id].yy * (Math.random() * 4 * Math.log(n.data.diverting) + r + 4)

          .attr "r", (n) ->
            Math.random() * 1.5 * Math.log( n.data.diverting + 1) + 1

          .attr "fill", color
          .attr "stroke", 'none'

      stars 
        .append "animate"
          .attr 'attributeName', 'fill-opacity'
          .attr 'begin', "#{Math.random() * duration + 1}s"
          .attr 'dur', "#{duration + Math.random() * duration + 1}s"
          .attr 'values', "1; 0; 1"
          .attr 'keyTimes', "0; 0.75; 1"
          .attr 'keySplines', '0.3, 0.61, 0.355, 1'
          .attr 'repeatCount', 'indefinite'





  # Plot edges
  edge_selection = svgSelection
    .append("g")
    .selectAll("path")
    .data(links)
    .enter()

  local_key = @local.key
  path = edge_selection
    .append("path")
      .attr "d", ({ points }) => 
        line(points)
      .attr("fill", "none")
      .attr "stroke-width", ({source, target}) =>
        l = get_link_data source, target
        get_link_width(l)
      .attr "stroke", ({source, target}) -> 
        len = this.getTotalLength()
        # encodeURIComponents for spaces
        gradId = md5 "#{local_key} #{get_link_key(source.data,target.data)}"
        grad = defs
          .append("linearGradient")
            .attr("id", gradId)
            .attr("gradientUnits", "userSpaceOnUse")
            .attr("x1", source.x)
            .attr("x2", target.x)
            .attr("y1", source.y)
            .attr("y2", target.y)

        color1 = colorMap.get(source.data.id)
        color2 = colorMap.get(target.data.id)

        src_size = get_node_size source 
        target_size = get_node_size target
        start_offset = src_size / len
        end_offset = 1 - target_size / len

        behind_node_color = "rgba(0,0,0,0.0)"
        stop0 = grad
          .append("stop")
            .attr("offset", "#{Math.max(0, start_offset * 100 - 5)}%")
            .attr("stop-color", color1)
            .attr("stop-opacity", "0")

        stop1 = grad
          .append("stop")
            .attr("offset", "#{start_offset * 100}%")
            .attr("stop-color", color1)
            .attr("stop-opacity", "1")

        stop2 = grad
          .append("stop")
            .attr("offset", "#{end_offset * 100}%")
            .attr("stop-color", color2)
            .attr("stop-opacity", "1")

        stop3 = grad
          .append("stop")
            .attr("offset", "#{Math.min(100, end_offset * 100 + 5)}%")
            .attr("stop-color", color2)
            .attr("stop-opacity", "0")

        if !view_flows
          stop1.append "animate"
            .attr "attributeName", "stop-color"
            .attr "values", "#{color1}; #{color2}; #{color1}"
            .attr "dur", "4s"
            .attr "repeatCount", "indefinite"
          stop2.append "animate"
            .attr "attributeName", "stop-color"
            .attr "values", "#{color2}; #{color1}; #{color2}"
            .attr "dur", "4s"
            .attr "repeatCount", "indefinite"

        "url(##{gradId})"

      .attr "stroke-dasharray", ({source, target}) =>
        if !view_flows
          "19.8 .2"
        else 
          "0"
      .attr "stroke-dashoffset", ({source, target}) =>
        if !view_flows
          "0"
        else 
          "0"

      .style "opacity", ({source, target}) =>
        if (@local.selection && @local.selection != source.data.id)
          .01
        else
          1

  path
    .append "animate"
      .attr "attributeName", 'stroke-dashoffset'
      .attr "values", "20;0"
      .attr "dur", "5s"
      .attr "repeatCount", 'indefinite'
  
  path
    .attr "data-tooltip", get_link_label


  if @local.selection && !network_data.nodes?[@local.selection]
    console.log @local.selection, "Network data for selection isn't present"
    return 
  # console.log @local.selection, "network data is present"
  
  
  # Select nodes
  nodes = svgSelection
    .append("g")
    .selectAll("g")
    .data(dag.descendants())
    .enter()
      .filter (node) =>
        n = node.data or node
        !(@local.selection && @local.selection != n.id && !links_to(network_data.nodes[@local.selection], n, network_data))

      .append("g")
        .attr "transform", ({x, y}) -> 
          "translate(#{x}, #{y})"

        .attr "data-tooltip", get_node_label

  if view_flows
    ##########################
    # Plot node springs
    # animation adapted from http://samherbert.net/svg-loaders/
    nodes
      .append("circle")
        .filter (n) ->  n.data.springing > 0      
        .attr "r", (n) -> 
          get_node_size(n)

        .attr "fill", "none"
        .attr "stroke", water_color # (n) -> colorMap.get(n.data.id) # water_color
        .attr "stroke-width", (n) ->
          if !n.data.springing
            return "0"
          Math.log(n.data.springing) # / Math.log(10)

    duration = 4
    num_rings = 3

    for ring_start in ("#{(i + 1) * duration / num_rings}s" for i in [0..num_rings]) 
      springs = nodes
        .append("circle")
          .filter (n) ->  n.data.springing > 0

          .attr "r", (n) -> 
            with_spring = get_node_size(n, 10000000 * (n.data.springing or 0)) + 1
            no_spring = get_node_size(n)
            no_spring

          .attr "fill", "none"
          .attr "stroke", water_color # (n) -> colorMap.get(n.data.id) # water_color
          .attr "stroke-width", (n) ->
            if !n.data.springing
              return "0"
            Math.log(n.data.springing) # / Math.log(10)

      springs 
        .append "animate"
          .attr 'attributeName', 'r'
          .attr 'begin', ring_start
          .attr 'dur', "#{duration}s"
          .attr 'values', (n) ->
            with_spring = get_node_size(n, 10000000 * (n.data.springing or 0)) + 1
            no_spring = get_node_size(n)
            "#{no_spring}; #{with_spring}"
          .attr 'keyTimes', "0; 1"
          .attr 'keySplines', '0.165, 0.84, 0.44, 1'
          .attr 'repeatCount', 'indefinite'

      springs 
        .append "animate"
          .attr 'attributeName', 'stroke-opacity'
          .attr 'begin', ring_start
          .attr 'dur', "#{duration}s"
          .attr 'values', "1; 0"
          .attr 'keyTimes', "0; 1"
          .attr 'keySplines', '0.3, 0.61, 0.355, 1'
          .attr 'repeatCount', 'indefinite'





  if view_flows && false 
    ##########################
    # Plot node taps -- as radiating lines
    # animation adapted from http://samherbert.net/svg-loaders/

    duration = 6
    num_rays = 120

    angle = 360 / num_rays

    # greens
    colors = ['#25523B', '#62BD69', '#358856', '#5AAB61', '#62BD69', '#30694B', '#0C3823', '#62BD69',] 

    # oranges
    # colors = ['#FFDB01', '#FFC212', '#FEA923', '#FE9033', '#FD7744', '#FD5E55']

    
    for ray_id in [0..num_rays]
      color = colors[ray_id % colors.length]
      theta = angle * ray_id
      ray_start = "#{Math.random() * duration}s"
      springs = nodes
        .append("line")
          .filter (n) ->  n.data.diverting > 0

          .attr "x1", ({x}) -> 0 
          .attr "y1", ({y}) -> 0 

          .attr "fill", "none"
          .attr "stroke", color
          .attr "stroke-width", (n) ->
            if !n.data.diverting
              return "0"
            return Math.random() * 9 + 1

      springs 
        .append "animate"
          .attr 'attributeName', 'x2'
          .attr 'begin', ray_start
          .attr 'dur', "#{duration}s"
          .attr 'values', (n) ->
            r = get_node_size(n)
            {x,y} = n
            length = Math.sqrt( 3 * n.data.diverting)
            unit = Math.cos( theta * Math.PI / 180)
            "#{r * unit}; #{(r + length) * unit}; #{r * unit}"
          .attr 'keyTimes', "0; 0.5; 1"
          .attr 'keySplines', '0.165, 0.84, 0.44, 1'
          .attr 'repeatCount', 'indefinite'

      springs
        .append "animate"
          .attr 'attributeName', 'y2'
          .attr 'begin', ray_start
          .attr 'dur', "#{duration}s"
          .attr 'values', (n) ->
            r = get_node_size(n)
            {x,y} = n
            length = Math.sqrt( 3 * n.data.diverting)

            unit = Math.sin( theta * Math.PI / 180)
            "#{r * unit}; #{(r + length) * unit}; #{r * unit}"
          .attr 'keyTimes', "0; 0.5; 1"
          .attr 'keySplines', '0.165, 0.84, 0.44, 1'
          .attr 'repeatCount', 'indefinite'
      # springs 
      #   .append "animate"
      #     .attr 'attributeName', 'stroke-opacity'
      #     .attr 'begin', ray_start
      #     .attr 'dur', "#{duration}s"
      #     .attr 'values', "1; 0"
      #     .attr 'keyTimes', "0; 1"
      #     .attr 'keySplines', '0.3, 0.61, 0.355, 1'
      #     .attr 'repeatCount', 'indefinite'



  ####################
  # Plot node circles
  nodes
    .append("circle")
      .attr "r", get_node_size

      .attr "fill", (n) => 
        if n.data.pic || gravatars.gravatars[n.data.user]
          "url(#img-#{md5(n.data.id)})"
        else 
          colorMap.get(n.data.id)
        

      # .style "opacity", (node) => 
      #   n = node.data
      #   backgrounded = @local.selection && @local.selection != n.id && !links_to(network_data.nodes[@local.selection], n, network_data)
      #   if backgrounded
      #     .01
      #   else 
      #     1

      .on "click", (e, n) =>
        return if @props.hide_info
        if @local.selection == n.data.name 
          @local.selection = null
        else 
          @local.selection = n.data.name
        e.stopPropagation()
        e.preventDefault()

        save @local

  # Images
  nodes
    .selectAll("circle[fill*=\"url(\"]").each (n) ->
      defs.append "pattern"
        .attr("id", "img-#{md5(n.data.id)}")
        .attr("height", "100%")
        .attr("width", "100%")
        .attr("patternContentUnits", "objectBoundingBox")

        .append("image")
          .attr("xlink:href", "#{n.data.pic or gravatars.gravatars[n.data.user] + "&d=#{window.try_gravatar}"}")
          .attr("width", "1")
          .attr("height", "1")
          .attr "preserveAspectRatio", "none"


  if view_flows && false
    ##########################
    # Plot node tapping, soil absorbsion
    # animation adapted from http://samherbert.net/svg-loaders/

    shuffleArray = (array) ->
      i = array.length - 1
      while i > 0
        j = Math.floor(Math.random() * (i + 1))
        temp = array[i]
        array[i] = array[j]
        array[j] = temp
        i--
      return array

    duration = 4
    num_circles = 3
    spacing = 0.05

    flash_order = {}

    for col in [0..num_circles-1]
      for row in [0..num_circles-1]
        continue if !(row % 2) && col == num_circles - 1


        tap = nodes
          .append("circle")
            .filter (n) ->  n.data.diverting > 0
              .attr "r", (n) -> 
                s = get_node_size(n)
                space = spacing * s
                s / num_circles - space

              .attr "cx", (n) ->
                s = get_node_size(n)
                (col + if !(row % 2) then 1 else .5) * 2 * s / num_circles - s

              .attr "cy", (n) ->
                s = get_node_size(n)
                (row + .5) * 2 * s / num_circles - s

              .attr "fill", "white"
              .attr "fill-opacity", '0'

              .attr "pointer-events", "none"

              .append 'animate'
                .attr 'attributeName', 'fill-opacity'
                .attr 'begin', (n) ->
                  key = n.data.id
                  if !flash_order[key]
                    flash_order[key] = shuffleArray (i for i in [0..num_circles * num_circles - 1])

                  order = flash_order[key]
                  idx = row + row * col
                  "#{order[idx] * duration / (num_circles * num_circles)}s"


                .attr 'dur', "#{duration}s"
                .attr 'values', (n) ->
                  perc_diverting = n.data.diverting / (n.data.total_inflow + (n.data.springing or 0)) 
                  "#{.6 * perc_diverting};0;#{.6 * perc_diverting}"
                .attr 'calcMode', 'linear'
                .attr 'repeatCount', 'indefinite'






  if view_flows
    # water flowing through network
    flow_selection = svgSelection
      .append("g")
      .selectAll("path")
      .data(links)
      .enter()
      .filter ({source}) =>
        !(@local.selection && @local.selection != source.data.id)        

    flow_selection
      .append("circle")
        .style "opacity", ({source, target}) =>
            if (@local.selection && @local.selection != source.data.id)
              .01
            else
              1      
        .attr "r", ({source, target}) =>
          l = get_link_data source, target
          get_link_width(l) # / 2
        .attr "fill", ({source, target}) => 
          #color = colorMap.get(source.data.id)

          color = water_color
          grad_id = "lum-#{md5 @local.key + get_link_key(source.data,target.data)}"
          grad = defs
                  .append("linearGradient")
                  .attr "id", grad_id
          grad.append("stop")
            .attr("offset", "0%")
            .attr("stop-color", color)
            .attr("stop-opacity", '0.0')

          grad.append("stop")
            .attr("offset", "50%")
            .attr("stop-color", color)
            .attr("stop-opacity", '1.0')


          "url(##{grad_id})"

        .append "animateMotion"
          .attr "dur", "5s"
          .attr "repeatCount", "indefinite"
          .attr "path", ({ points }) => line(points)
          .attr "rotate", "auto"

    # leading white arc
    # flow_selection
    #   .append("path")
    #     .attr "d", ({source, target}) =>
    #       l = get_link_data source, target
    #       r = get_link_width(l) / 2
    #       d=" M 0 -#{r} A #{r} #{r} 270 0 1 0 #{r}"

    #     .attr "stroke", "white"
    #     .attr "stroke-width", 1
    #     .attr "stroke-opacity", 1
    #     .attr "fill", 'none'

    #     .append "animateMotion"
    #       .attr "dur", "5s"
    #       .attr "repeatCount", "indefinite"
    #       .attr "path", ({ points }) => line(points)
    #       .attr "rotate", "auto"











#####################################################
# Constructs the nodes and links based on user flows
#####################################################
build_network_data = (network) ->
  network = fetch network

  if network.slug 
    liquid = fetch("/liquid/#{network.slug}")
    taps = liquid.taps
    flows = liquid.flows
    springs = liquid.springs

  return {nodes: {}, links: {}} if !network.slug || !flows 

  init_or_update_node = (id, user) ->
    if id of nodes
      n = nodes[id]
      n.user ?= user?.key or user
    else 
      n =       
        id: id 
        name: user?.name or id
        user: user?.key or user
        val: 1
        inflows: []
        outflows: []

    if user && !n.pic && fetch(user)?.pic 
      n.pic = "#{pics_path}#{if pics_path[pics_path.length - 1] != '/' then '/' else ''}#{fetch(user).pic}"

    return n 

  nodes = {}
  links = {}


  for user, user_flows of flows
    link_value_total = 0

    u = fetch(user)
    id = name = u.name?.trim()
    source = nodes[id] = init_or_update_node id, u 

    my_links = []
    for flow in user_flows
      dest_id = flow.name?.trim()
      dest = nodes[dest_id] = init_or_update_node dest_id

      link = 
        source: source 
        target: dest
        value: flow.value
        flow: flow

      link_value_total += link.value 

      dest.inflows.push link
      source.outflows.push link

      links[get_link_key(source, dest)] = link
      my_links.push link 

    for link in my_links 
      link.value = link.value / link_value_total

  data = {nodes, links}

  compute_rank(data)
  compute_flows(network, data)

  data




#########################################
# Computes the authority of network nodes
# using PageRank
#########################################
window.compute_rank = (network_data) -> 
  PageRank.reset()

  for __, link of network_data.links when link.source != link.target
    PageRank.link link.source.id, link.target.id, link.flow.value
  PageRank.rank 0.85, 0.000001, (node, rank) ->
    node.rank = rank
    network_data.nodes[node].rank = rank
    # console.log {node, rank}


##############################################
# Computes the flow of money, assigning 
# springs and taps according to configurations
##############################################
window.compute_flows = (network, network_data) ->
  network = fetch network
  return if !network.slug

  liquid = fetch("/liquid/#{network.slug}")
  taps = liquid.taps
  flows = liquid.flows
  springs = liquid.springs

  return if !flows || !taps || !springs 

  network_data ?= build_network_data(flows)

  # reset values
  for user, node of network_data.nodes 
    node.diverting = 0 # amount tapped 
    node.springing = 0 # amount contributed
    node.total_outflow = 0 # amount flowing out 
    node.total_inflow = 0 # amount flowing in

  for __, link of network_data.links 
    link.flow_amount = 0 # amount flowing on this link per month

  remove_cycles = (path) ->
    first_occurrance = {}

    for id, idx in path
      if id of first_occurrance
        has_cycle = true
        delete_after = first_occurrance[id]
        break 
      else 
        first_occurrance[id] = idx

    if has_cycle
      path.splice delete_after + 1
    else 
      path

  divert = (inflow, source) ->
    # assume for now that all referenced users not yet in the system fully tap all their resource
    # if source.name == 'Joe Brewer'
    return inflow if !source.user

    return 0 if !source.user || !taps[source.user]
    Math.max 0, taps[source.user].divert_percent / 100 * Math.min(inflow - source.diverting, taps[source.user].max - source.diverting)

  visit = ($spring, $inflow, visiting, paths_traveled, current_path) ->
    console.assert $inflow >= 0, "flow can't be negative", {$inflow, visiting, paths_traveled}

    return if $inflow < 0.001
    current_path.push visiting.id

    no_cycles = remove_cycles current_path

    cycle_key = JSON.stringify([$inflow, no_cycles])
    return if cycle_key of paths_traveled
    paths_traveled[cycle_key] = true 

    $tap = if current_path.length > 1 then divert($inflow, visiting) else 0 # the spring doesn't divert from itself
    visiting.diverting += $tap
    $outflow = $inflow - $tap

    if visiting.outflows.length > 0 
      weight_total = 0
      for link in visiting.outflows
        weight = link.value
        weight_total += weight
      console.assert Math.round(weight_total * 1000) == 1000 

    # console.log "#{visiting.name} is tapping $#{$tap} (#{visiting.diverting} total)", visiting.diverting, taps[visiting.user]

    if $outflow > 0
      for link in visiting.outflows
        weight = link.value
        flowing = $outflow * weight
        link.flow_amount += flowing
        # link.flow_amount = Math.min link.flow_amount, $spring
        # console.log "#{visiting.name} ==> #{link.target.name} $#{flowing} (#{weight} * #{$outflow})"
        visit $spring, flowing, link.target, paths_traveled, no_cycles.slice()

  for user, spr of springs
    spring = network_data.nodes[fetch(user).name?.trim()]
    $spring = spr.min
    spring.springing += $spring
    visit($spring, $spring, spring, {}, [])

  for user, node of network_data.nodes 
    for l in node.inflows
      node.total_inflow += l.flow_amount
    for l in node.outflows
      node.total_outflow += l.flow_amount



###############################################
# Pagerank
# from https://github.com/alixaxel/pagerank.js

forIn = (object, callback) ->
  if typeof object == 'object' and typeof callback == 'function'
    for key of object
      if callback(key, object[key]) == false
        break
  return

forOwn = (object, callback) ->
  forIn object, (key, value) ->
    if object.hasOwnProperty(key) == true
      return callback(key, value)
    return
  return

PageRank = do ->
  self = 
    count: 0
    edges: {}
    nodes: {}

  self.link = (source, target, weight) ->
    if isFinite(weight) != true or weight == null
      weight = 1
    weight = parseFloat(weight)
    if self.nodes.hasOwnProperty(source) != true
      self.count++
      self.nodes[source] =
        weight: 0
        outbound: 0
    self.nodes[source].outbound += weight
    if self.nodes.hasOwnProperty(target) != true
      self.count++
      self.nodes[target] =
        weight: 0
        outbound: 0
    if self.edges.hasOwnProperty(source) != true
      self.edges[source] = {}
    if self.edges[source].hasOwnProperty(target) != true
      self.edges[source][target] = 0
    self.edges[source][target] += weight
    return

  self.rank = (alpha, epsilon, callback) ->
    delta = 1
    inverse = 1 / self.count
    forOwn self.edges, (source) ->
      if self.nodes[source].outbound > 0
        forOwn self.edges[source], (target) ->
          self.edges[source][target] /= self.nodes[source].outbound
          return
      return
    forOwn self.nodes, (key) ->
      self.nodes[key].weight = inverse
      return
    while delta > epsilon
      leak = 0
      nodes = {}
      forOwn self.nodes, (key, value) ->
        nodes[key] = value.weight
        if value.outbound == 0
          leak += value.weight
        self.nodes[key].weight = 0
        return
      leak *= alpha
      forOwn self.nodes, (source) ->
        forOwn self.edges[source], (target, weight) ->
          self.nodes[target].weight += alpha * nodes[source] * weight
          return
        self.nodes[source].weight += (1 - alpha) * inverse + leak * inverse
        return
      delta = 0
      forOwn self.nodes, (key, value) ->
        delta += Math.abs(value.weight - (nodes[key]))
        return
    forOwn self.nodes, (key) ->
      callback key, self.nodes[key].weight
    return

  self.reset = ->
    self.count = 0
    self.edges = {}
    self.nodes = {}
    return

  self