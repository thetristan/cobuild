Cobuild = require './lib/cobuild'
express = require 'express'
http    = require 'http'
app     = express.createServer()
port    = 9999


# We need a special config object to pass to our middleware constructor
test_config = 
  options:
    base_path:      "#{__dirname}/"
    renderer_path:  "spec/renderers/"
    server_path:    "spec/output/web/"
  files: [{
      source:      'spec/samples/test1.html'
      destination: 'spec/output/web/test1.html'
    }
    {
      source:      'spec/samples/test1.html'
      destination: 'spec/output/web/test0.html'
    }]
  renderers:
    'html': [
        "test2_r"
        "test_r"
      ]

# Configure the server with stylus and browserify middleware
app.configure ->
  app.use app.router
  app.use Cobuild.middleware test_config
  app.use express.static "#{__dirname}/spec/output/web/"

# Start the server
app.listen port

