url     = require 'url'
cobuild = require './cobuild'

exports = (options)->

  throw new Error 'cobuild.middleware() requires a Cobuild configuration' unless options.options
  throw new Error 'cobuild.middleware() requires all renderers to be predefined' unless options.renderers
  throw new Error 'cobuild.middleware() requires an array of file objects to watch' unless options.files
  
  # Create our builder
  build = new cobuild options.options

  if @config.renderers
    _.each @config.renderers, (val, key)->
      @add_renderer key, val
      return

  # The actual middleware 
  return (req,res,next) ->

    # Only service GET/HEAD requests
    if req.method != 'GET' && req.method != 'HEAD'
      return next()

    path = url.parse(req.url).pathname;


    



