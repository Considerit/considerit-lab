

dom.DRAW_NETWORK = ->

  network = fetch @props.network
  flows = fetch("/liquid/#{network.slug}").flows

  return DIV null if !flows

  @size = defaults {}, (@props.size or {}), 
    height: 400 
    width: 800

  # register dependencies. why is statebus not doing this for me?
  for user, ff of flows
    fetch(user)
    for f in ff
      fetch f

  DIV null,

    DIV 
      style: 
        width: @size.width
        height: @size.height
        border: '1px solid #eee'
      ref: 'graph'

dom.DRAW_NETWORK.refresh = ->
  network = fetch @props.network
  liquid = fetch("/liquid/#{network.slug}")
  flows = liquid.flows
  taps = liquid.taps
  springs = liquid.springs

  return if !flows || Object.keys(flows).length == 0

  if !@local.selection? && @props.initial_selection
    @local.selection = @props.initial_selection

  fingerprint = JSON.stringify(flows) + JSON.stringify(@local.selection)

  return if @local.initialized && fingerprint == @local.last_fingerprint

  network_data = build_network_data network
  data_for_forcegraph = 
    nodes: Object.values network_data.nodes
    links: Object.values network_data.links

  view_flows = @props.view_flows
  console.log {data_for_forcegraph}

  @imgs ?= {}

  get_node_size = (n, additional) ->
    additional ?= 0
    if view_flows
      s = additional + Math.max n.total_outflow, n.total_inflow - n.diverting
      Math.sqrt(1 + s) + 10
    else
      100 * n.rank + 1

  get_link_width = (l) -> 
    if view_flows
      Math.sqrt l.flow_amount + 1
    else
      Math.round(10 * l.value) #+ 1

  max_link_strength = 0
  for l in data_for_forcegraph.links 
    str = get_link_width(l)
    if str > max_link_strength
      max_link_strength = str

  linkStrength = (l) ->
    .3 + .7 * get_link_width(l) / max_link_strength

  if @graph
    @graph.graphData(data_for_forcegraph)
  else 
    @graph = ForceGraph()(@refs.graph.getDOMNode())
      .width(@size.width)
      .height(@size.height)
      .graphData(data_for_forcegraph)
      # .dagMode('radialout')
      .dagMode('lr')
      .onDagError (segment) -> 
        console.log 'Dag error, cycle encountered', segment
      .dagLevelDistance 100

      # .d3Force('collide', d3.forceCollide(2))
      # .d3Force('link', null)

      .onBackgroundClick (e) =>
        if @local.selection 
          @local.selection = null
          save @local
      .onNodeClick (n, e) =>
        if @local.selection == n.name 
          @local.selection = null
        else 
          @local.selection = n.name
        save @local

      .nodeLabel (n) => 
        label = n.name 
        if n.diverting
          conf = taps[n.user] or {used_for: "...dunno. This person has yet to add their recommendations, so we're just assuming for now that they're fully tapping."}
          label += "\nDiverting $#{n.diverting.toFixed(2)}/month"
          if conf.used_for
            label += " for #{conf.used_for}"
        if n.springing
          label += "\nSpringing $#{n.springing.toFixed(2)}/month into the network"

        label

      .nodeAutoColorBy('name')
      .nodeRelSize(2)
      .nodeVal (n) =>
        if view_flows
          2 * get_node_size n, n.diverting + n.springing
        else 
          get_node_size n

      .nodeCanvasObject (n, ctx, scale) =>
        size = get_node_size(n)

        # draw diverting
        if view_flows && n.diverting
          ctx.save()
          ctx.beginPath()

          divert_size =  get_node_size(n, n.springing + n.diverting)
          ctx.arc(n.x, n.y, divert_size / 2, 0, Math.PI * 2)
          ctx.fillStyle = irrigate_color
          ctx.fill() 
          ctx.restore()

        # draw springing
        if view_flows && n.springing
          ctx.save()
          ctx.beginPath()

          spring_size = get_node_size(n, n.springing)
          ctx.arc(n.x, n.y, spring_size / 2, 0, Math.PI * 2)
          ctx.fillStyle = water_color
          ctx.fill() 
          ctx.restore()


        # draw avatar (or colored node)
        ctx.save()

        backgrounded = @local.selection && @local.selection != n.id && !links_to(network_data.nodes[@local.selection], n, network_data)

        ctx.beginPath()
        ctx.arc(n.x, n.y, size / 2, 0, Math.PI * 2)
        if n.pic
          if !@imgs[n.pic]
            img = new Image()
            img.src = n.pic
            @imgs[n.pic] = img
          else 
            img = @imgs[n.pic]

          if backgrounded
            ctx.globalAlpha = .1

          ctx.clip()
          ctx.drawImage(img, n.x - size / 2, n.y - size / 2, size, size)  
        else 
          if backgrounded
            ctx.fillStyle = "rgb(240, 240, 240)"
          else 
            ctx.fillStyle = "rgb(150, 150, 150)"
          ctx.fill() 
        ctx.restore()
        ############

      .linkLabel (l) =>
        if view_flows
          label = "#{l.source.name} flowing $#{l.flow_amount.toFixed(2)} to #{l.target.name}"
        else 
          label = "#{l.source.name} flowing #{Math.round(l.value * 100)}% to #{l.target.name}"

        reason = fetch(l.flow).reason
        if reason 
          label = "#{label} because \"#{reason}\""
        label

      .linkCurvature (l) =>
        .25

      .linkDirectionalArrowLength (l) =>
        if view_flows 
          0
        else 
          if @local.selection && @local.selection != l.source.id
            5
          else 
            5 + get_link_width(l)

      .linkDirectionalArrowRelPos(.5)

      .linkDirectionalParticles (l) => 
        if view_flows
          Math.round Math.log 1 + l.flow_amount
        else  
          0


      .linkDirectionalParticleWidth (l) => 
        # get_link_width l
        if view_flows 
          1 + Math.log 1 + l.flow_amount
        else 
          0


      .linkDirectionalParticleColor (l) => 
        if @local.selection && @local.selection != l.source.id
          "rgba(200, 200, 200, 1)"
        else 
          "rgba(29, 155, 240, 1)"

      .linkColor (l) => 
        if (@local.selection && @local.selection != l.source.id) || (view_flows && l.flow_amount == 0)
          "rgba(240, 240, 240, 1)"
        else 
          "rgba(114, 194, 247, 1)"

      .linkWidth (l) =>
        if @local.selection && @local.selection != l.source.id
          1
        else         
          if view_flows 
            1
          else 
            get_link_width l

      .linkDirectionalParticleSpeed .005

    @graph.d3Force('charge').strength -500
    @graph.d3Force('link').strength(linkStrength)

  @graph.onEngineStop => 
    @graph.enableZoomInteraction(true)
    @graph.zoomToFit(400)
    @graph.enableZoomInteraction(false)


  @local.initialized = true 
  @local.last_fingerprint = fingerprint


