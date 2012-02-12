    # Load the cobuild module
    cobuild = require 'cobuild'

    # Create our builder and pass it our global configuration options
    builder = new cobuild 
      base_path:     "#{__dirname}/"
      renderer_path: "#{__dirname}/renderers/"
      eco:
        global:
          var1:      "foo"
          var2:      "bar"
      stylus:
        minify:      true

    # Array of file description objects
    files = [{
        source:      'src/example.js'
        destination: 'release/example.js'
      }
      {
        source:      'src/example.styl'
        destination: 'release/example.css'
      }
      {
        source:      'src/example.html.eco'
        destination: 'release/example.html'
      }]

    # Options specific to the build we're going to run
    # In this case, we're overriding a global setting from above
    options = 
      stylus:
        minify: false

    # Let's do it
    builder
      .add_renderer('styl', 'stylus_r')
      .add_renderer('js', 'uglifyjs_r')
      .add_renderer('eco', 'eco_r')
      .add_renderer('eco', 'uppercase_r')
      .build
          files:   files
          options: options
        , (err, result) ->
          console.log "Build successful" unless err
          return

