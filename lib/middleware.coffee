url     = require 'url'
path    = require 'path'
fs      = require 'fs'
_       = require 'underscore'
async   = require 'async'
Cobuild = require './cobuild'
util    = require './util'


module.exports = (options) ->

  throw new Error 'cobuild.middleware() requires a Cobuild configuration' unless options.options
  throw new Error 'cobuild.middleware() requires all renderers to be predefined' unless options.renderers
  throw new Error 'cobuild.middleware() requires the output_path to be predefined' unless options.middleware.output_path

  # Serve files directly?
  direct = false

  # Require paths if we're serving up content right from the folder
  # and not specifying a file mapping
  if !options.files?
    throw new Error 'cobuild.middleware() requires the source_path to be predefined when not passing an array of file objects' unless options.middleware.source_path
    direct = true



  get_file_to_build = (path_to_check) ->


    # Are we accessing directly?
    if direct
      # Return right away if our path exists
      return path_to_check if path.existsSync "#{options.options.base_path}#{path_to_check}"

      # Otherwise, check to see if we need to find the path w/ an alternate extension
      extension = path.extname(path_to_check).replace '.', ''

      return false if !options.middleware.extensions[extension]?

      # Loop through available extensions
      for ext in options.middleware.extensions[extension]
        new_path = path_to_check.replace new RegExp("#{extension}$"), ext
        return new_path if path.existsSync "#{options.options.base_path}#{new_path}"

      false

    else

      # Convert source path to destination
      path_to_check = path_to_check.replace options.middleware.source_path, options.middleware.output_path

      # Check to see if a mapping exists
      return  _.reduce options.files, (memo,file)->
          return memo if memo
          return file.source if file.destination == "#{path_to_check}"
        , false


  # Create our builder
  build = new Cobuild options.options

  # Add our renderers
  build.add_renderers options.renderers

  # The actual middleware 
  return (req,res,next) ->

    # Only service GET/HEAD requests
    if req.method != 'GET' && req.method != 'HEAD'
      return next()

    real_path = url.parse(req.url).pathname.substring 1
    destination = "#{options.middleware.output_path}#{real_path}"
    source = get_file_to_build "#{options.middleware.source_path}#{real_path}"

    if !source
      return next()

    files_to_build = [
          source:      source
          destination: destination
        ]

    build.build
      files: files_to_build
      , (err, result)->
        return next()



