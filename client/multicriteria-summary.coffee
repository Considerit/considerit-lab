dom.MULTICRITERIA_SUMMARY = -> 
  options = fetch(@props.options).children
  criteria = fetch(@props.criteria).children 

  return SPAN null if @loading()

  DIV 
    style: 
      padding: 20
      marginTop: 40
    GRAB_CURSOR()

    TABLE 
      style:
        margin: 'auto'
      TBODY null, 

        CRITERIA_ROW {criteria}

        for option,idx in options 
          OPTION_ROW 
            key: option.key or option 
            option: option
            idx: idx

dom.CRITERIA_ROW = -> 
  TR 
    style: 
      background: 'linear-gradient(to bottom, rgba(136,191,232,1) 0%,rgba(112,176,224,1) 100%)'

    TH 
      style: 
        fontWeight: 700
        padding: '8px 12px'
        textAlign: 'right'
        verticalAlign: 'bottom'
        #backgroundColor: 'white'
        color: 'white'
        borderBottom: '1px solid #5FA9DD'

      #'Project'

    TH 
      style: 
        fontWeight: 600
        padding: '8px 8px'
        textAlign: 'center'
        verticalAlign: 'top'
        maxWidth: 120
        color: 'white'
        # borderRight: '1px solid #5FA9DD'
        borderBottom: '1px solid #5FA9DD'
        #boxShadow: '-1px 0px 1px white'

      'Overall (autocomputed)'


    for criterion in @props.criteria 
      criterion = fetch criterion
      continue if @loading()

      TH 
        style: 
          fontWeight: 600
          padding: '8px 8px'
          textAlign: 'center'
          verticalAlign: 'bottom'
          color: 'white'
          # borderRight: '1px solid #5FA9DD'
          borderBottom: '1px solid #5FA9DD'
          #boxShadow: '-1px 0px 1px white'

        DIV 
          style: 
            paddingBottom: 12

          dangerouslySetInnerHTML: __html: criterion.text

        SLIDERGRAM
          sldr: criterion.sliders[0]
          width: 100
          height: 40
          no_label: true
          no_feedback: true
          slider_color: 'white'

# currently assumes that option.children are ordered
# the same as criteria
dom.OPTION_ROW = -> 
  option = fetch @props.option
  return TR null if @loading()

  if option.auto_calc
    auto_calc_value_from_children option

  TR null,
      
    TD 
      style: 
        fontWeight: 600
        textAlign: 'right'
        padding: '12px 12px 0 12px'
        minWidth: 200
        borderRight: '1px solid #5FA9DD'
        # borderBottom: '1px solid #5FA9DD'

      DIV 
        style: 
          paddingBottom: 12

        dangerouslySetInnerHTML: __html: option.text
        

    TD 
      style: 
        padding: '8px 8px 0 8px'
        verticalAlign: 'middle'
        backgroundColor: '#f7f7f7'

      SLIDERGRAM
        sldr: option.sliders[0]
        width: 100
        height: 20
        no_label: true
        no_feedback: true
        read_only: !!option.auto_calc
        # slider_color: '#5FA9DD'

    for evaluation,idx in (option.children or [])
      evaluation = fetch evaluation
      continue if @loading()
      
      if evaluation.auto_calc
        auto_calc_value_from_children evaluation

      TD 
        style: 
          padding: '8px 8px 0 8px'
          # borderRight: '1px solid #5FA9DD'
          verticalAlign: 'middle'
          # borderBottom: '1px solid #5FA9DD'
          backgroundColor: if idx % 2 == 1 then '#f7f7f7'

        SLIDERGRAM
          sldr: evaluation.sliders[0]
          width: 100
          height: 20
          no_label: true
          no_feedback: true
          read_only: !!evaluation.auto_calc
          #slider_color: '#5FA9DD'

