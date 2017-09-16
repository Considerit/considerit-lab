set_style """
  [data-widget="BODY"]  {
    font-family: 'Raleway', Georgia,Cambria,"Times New Roman",Times,serif; // Helvetica Neue, Segoe UI, Helvetica, Arial, sans-serif; 
    font-size: 16px;
    color: black;
    line-height: 1.4;
    font-weight: normal;
    font-weight: 300;
    -webkit-font-feature-settings: 'liga' 1;
    -moz-font-feature-settings: 'liga' 1;  
    text-rendering: optimizeLegibility;  
  } 

  * {box-sizing: border-box;}
  html, body {margin: 0; padding: 0;}
  p {margin: 16px 0; }
  button, a {
    cursor: pointer;
  }

  textarea, input[type='text'], input[type='email'], button {
    font-size: inherit;
    font-weight: inherit;
    line-height: inherit;
    font-family: inherit;
    letter-spacing: inherit;
  }

  button[disabled], input[type='submit'][disabled] {
    opacity: .25;
  }

""", 'main-style'


dom.BODY = -> 


  DIV null,

    DIV 
      style:         
        padding: '120px 40px'


      DIV 
        style: 
          textAlign: 'center'
          width: 620
          position: 'relative'
          margin: 'auto'


        SVG 
          width: 620
          viewBox: "0 0 569 111"

          dangerouslySetInnerHTML: __html: """"
            <g id="logo" stroke="none" stroke-width="1" fill="none" fill-rule="evenodd">
                <g id="Artboard-Copy-8" transform="translate(-250.000000, -251.000000)">
                    <g id="Group" transform="translate(250.000000, 251.000000)">
                        <path d="M0.32,60 C0.32,45.96 10.64,34.8 23.96,34.8 C30.08,34.8 34.4,37.08 35.48,37.44 L35.48,2.28 C35.48,1.08 36.56,0 37.76,0 L44.72,0 C45.92,0 47,1.08 47,2.28 L47,81.72 C47,82.92 45.92,84 44.72,84 L41.12,84 C40.04,84 39.32,83.16 38.96,81.96 L38,78.48 C38,78.48 32.24,85.2 22.76,85.2 C10.04,85.2 0.32,73.8 0.32,60 Z M11.48,60 C11.48,68.04 16.52,74.88 24.2,74.88 C31.52,74.88 35,69 35.6,67.68 L35.6,48.12 C35.6,48.12 31.4,45.24 25.16,45.24 C17.12,45.24 11.48,51.84 11.48,60 Z M89.12,60 C89.12,46.44 98.72,34.8 113.12,34.8 C125.6,34.8 135.2,44.16 135.2,57 C135.2,57.84 135.08,59.4 134.96,60.24 C134.84,61.44 133.88,62.28 132.8,62.28 L100.16,62.28 C100.52,68.76 106.16,75.12 113.96,75.12 C118.28,75.12 122.24,73.2 124.64,71.64 C126.08,70.8 126.92,70.32 127.88,71.52 L131.24,76.08 C132.08,77.04 132.44,78 131,79.2 C127.52,82.2 121.28,85.2 113.24,85.2 C98.72,85.2 89.12,73.8 89.12,60 Z M100.76,54.72 L124.04,54.72 C123.68,48.96 118.88,44.04 113,44.04 C106.52,44.04 101.48,48.72 100.76,54.72 Z M174.56,80.28 C177.08,82.32 182.36,85.2 190.4,85.2 C201.08,85.2 208.16,78.6 208.16,71.16 C208.16,62.16 200.96,58.44 192.2,54.6 C187.52,52.56 184.52,51.24 184.52,48.12 C184.52,46.32 185.84,44.52 189.92,44.52 C194.48,44.52 199.76,47.04 199.76,47.04 C200.72,47.52 202.28,47.16 202.88,46.08 L205.04,42 C205.76,40.8 205.16,39.24 204.08,38.52 C201.68,36.96 196.64,34.8 189.92,34.8 C178.4,34.8 173.48,42 173.48,48 C173.48,55.92 179.72,60.48 187.16,63.72 C193.76,66.72 196.4,68.28 196.4,71.52 C196.4,74.16 194.12,75.6 190.52,75.6 C184.64,75.6 179.36,72.48 179.36,72.48 C178.16,71.76 176.84,72.12 176.36,73.08 L173.84,77.76 C173.36,78.72 173.84,79.8 174.56,80.28 Z M249.68,81.72 C249.68,82.92 250.76,84 251.96,84 L258.8,84 C260,84 261.08,82.92 261.08,81.72 L261.08,2.28 C261.08,1.08 260,0 258.8,0 L251.96,0 C250.76,0 249.68,1.08 249.68,2.28 L249.68,81.72 Z M312.2,110.44 C316.16,110.44 319.28,107.32 319.28,103.48 C319.28,99.52 316.16,96.4 312.2,96.4 C308.36,96.4 305.36,99.52 305.36,103.48 C305.36,107.32 308.36,110.44 312.2,110.44 Z M306.68,81.72 C306.68,82.92 307.76,84 308.96,84 L315.8,84 C317,84 318.08,82.92 318.08,81.72 L318.08,38.28 C318.08,37.08 317,36 315.8,36 L308.96,36 C307.76,36 306.68,37.08 306.68,38.28 L306.68,81.72 Z M360.2,60 C360.2,45.96 370.52,34.8 383.84,34.8 C389.96,34.8 394.28,37.08 395.36,37.44 L395.36,2.28 C395.36,1.08 396.44,0 397.64,0 L404.6,0 C405.8,0 406.88,1.08 406.88,2.28 L406.88,81.72 C406.88,82.92 405.8,84 404.6,84 L401,84 C399.92,84 399.2,83.16 398.84,81.96 L397.88,78.48 C397.88,78.48 392.12,85.2 382.64,85.2 C369.92,85.2 360.2,73.8 360.2,60 Z M371.36,60 C371.36,68.04 376.4,74.88 384.08,74.88 C391.4,74.88 394.88,69 395.48,67.68 L395.48,48.12 C395.48,48.12 391.28,45.24 385.04,45.24 C377,45.24 371.36,51.84 371.36,60 Z M449,60 C449,46.44 458.6,34.8 473,34.8 C485.48,34.8 495.08,44.16 495.08,57 C495.08,57.84 494.96,59.4 494.84,60.24 C494.72,61.44 493.76,62.28 492.68,62.28 L460.04,62.28 C460.4,68.76 466.04,75.12 473.84,75.12 C478.16,75.12 482.12,73.2 484.52,71.64 C485.96,70.8 486.8,70.32 487.76,71.52 L491.12,76.08 C491.96,77.04 492.32,78 490.88,79.2 C487.4,82.2 481.16,85.2 473.12,85.2 C458.6,85.2 449,73.8 449,60 Z M460.64,54.72 L483.92,54.72 C483.56,48.96 478.76,44.04 472.88,44.04 C466.4,44.04 461.36,48.72 460.64,54.72 Z M536.6,81.72 C536.6,82.92 537.68,84 538.88,84 L544.64,84 C546.56,84 547.88,83.76 547.88,81.72 L547.88,51.24 C548.36,50.4 551.72,45.36 558.68,45.36 C560.24,45.36 562.04,45.84 562.76,46.2 C563.84,46.68 565.04,46.44 565.64,45.12 L568.52,39.24 C569.84,36 564.32,34.8 559.76,34.8 C551,34.8 546.56,40.56 545.72,41.76 L544.4,37.68 C544.16,36.72 543.2,36 542.36,36 L538.88,36 C537.68,36 536.6,37.08 536.6,38.28 L536.6,81.72 Z" id="deslider" fill="#000000"></path>
                        <path d="M1.5,104 L567.5,104" id="Line" stroke="#000000" stroke-width="2" stroke-linecap="square"></path>
                    </g>
                </g>
            </g>"""

        DIV 
          style: 
            position: 'absolute'
            right: 0
            top: -5
            fontSize: 24
          'alpha'

        DIV 
          style: 
            fontSize: 24
            # letterSpacing: .39
            marginTop: 24
            fontWeight: 400

          'multi-criteria decision making for individuals and groups'


        DIV 
          style: 
            marginTop: 120
            fontSize: 24
            marginBottom: 16
            fontWeight: 400

          'What are you trying to decide?'

        INPUT 
          ref: 'decision'
          style: 
            fontSize: 24
            padding: '6px 12px'
            border: '1px solid #979797'
            width: '100%'

          onInput: (e) =>
            @local.decision_about = e.target.value
            save @local

        do => 
          submit = => 
            slug = slugify(@local.decision_about) + '-' + Math.random().toString(36).substring(7)

            window.location = "/#{slug}?decision=#{encodeURI(@local.decision_about)}"


          BUTTON 
            disabled: if !(@local.decision_about?.length > 0) then true
            style: 
              backgroundColor: 'black'
              color: 'white'
              border: 'none'
              fontWeight: 'bold'
              width: '100%'
              padding: '12px 12px'
              fontSize: 24
              marginTop: 16
              borderRadius: 16
              cursor: if !(@local.decision_about?.length > 0) then 'default'

            onClick: submit 
            onKeyPress: (e) =>
              if e.which in [32,13]
                e.preventDefault()
                submit() 

            'Start desliding'



    DIV 
      style: 
        marginTop: 100
      LAB_FOOTER() 



dom.BODY.refresh = -> 
  if !@loading() && !@local.initialized?
    @local.initialized = true
    @refs.decision.getDOMNode().focus()
