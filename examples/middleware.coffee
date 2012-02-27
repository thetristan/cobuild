cobuild = require '.cobuild'
express = require 'express'
http    = require 'http'
app     = express.createServer()
port    = 9999

# We need a special config object to pass to our middleware constructor
middleware_config = 
  options:
    base_path:      "#{__dirname}/"
    renderer_path:  "renderers/"
    server_path:    "output/web/"
  files: [{
      source:      'source/foo.html'
      destination: 'output/web/foo.html'
    }
    {
      source:      'source/bar.html'
      destination: 'output/web/bar.html'
    }]
  renderers:
    'html': [
        "eco_r"
        "tidy_r"
      ]

# Configure the server with our middleware
app.configure ->
  app.use app.router
  app.use cobuild.middleware middleware_config
  app.use express.static "#{__dirname}/output/web/"

# Start the server
app.listen port