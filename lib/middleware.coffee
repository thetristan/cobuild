url     = require 'url'
path    = require 'path'
fs      = require 'fs'
_       = require 'underscore'
Cobuild = require './cobuild'



module.exports = (options) ->

  throw new Error 'cobuild.middleware() requires a Cobuild configuration' unless options.options
  throw new Error 'cobuild.middleware() requires all renderers to be predefined' unless options.renderers
  throw new Error 'cobuild.middleware() requires an array of file objects to watch' unless options.files

  # The actual middleware 
  return (req,res,next) ->

    # Create our builder
    build = new Cobuild options.options

    if options.renderers
      _.each options.renderers, (val, key)->
        _.each val, (renderer)->
          build.add_renderer key, renderer
        return

    # Only service GET/HEAD requests
    if req.method != 'GET' && req.method != 'HEAD'
      return next()

    real_path = url.parse(req.url).pathname.substring 1

    error = (err) ->
      next if 'ENOENT' == err.code then null else err

    source = _.reduce options.files, (memo,file)->
        #console.log 'Checking:', file.destination, "#{options.options.server_path}#{real_path}"
        if !memo
          if file.destination == "#{options.options.server_path}#{real_path}"
            return file.source 
          else
            false
        else
          memo
      , false

    if !source
      return next()

    files_to_build = [
          source:      source
          destination: "#{options.options.server_path}#{real_path}"
        ]

    build.build
      files: files_to_build
      , (err, result)->
        return next()



