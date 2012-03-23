_         = require 'underscore'
path      = require 'path'
fs        = require 'fs'
async     = require 'async'
util      = require './util'


###
*
* Cobuild NodeJS build system
*
* @author Tristan Blease
* @version 0.1.3
*
###



module.exports = class Cobuild

  constructor: (@config) ->

    # Load our configuration
    throw new Error 'Config options must be specified to use cobuild.' unless @config
    @renderers        = {}
    @files_rendered   = []


    # -------------------------------------------
    # Status messages used in the results we're returning back

    @OK     = 'File built successfully'
    @COPY   = 'File copied'
    @SKIP   = 'File skipped'
    @ERR    = 'Error building file'

    # -------------------------------------------
    # Middleware for connect

    @middleware = require './middleware'

    @clean_up_config()

    @default_opts =
      preprocess:  null
      postprocess: null
      force:       false
      config:      @config




  # -------------------------------------------
  # Config validation and cleanup

  clean_up_config: ->

    @config.base_path = path.resolve(@config.base_path) + '/'




  # -------------------------------------------
  # Build log handling
  # This log gets returned for all multi-file builds

  # Reset the log (done with each build)
  _reset_build_log: ->
    @_build_log = []
    return


  # Log a file and return the item we just added
  _log_file: (source, destination, status = null) ->

    if !@_build_log then @_reset_build_log()

    log_item =
      source:      source
      destination: destination
      status:      status

    @_build_log.push log_item

    log_item

  # Get the count per destination
  _log_file_count_by_dest: (destination) ->
    _.reduce @_build_log,
      (count, log_item) ->
        count + (log_item.destination == destination ? 1 : 0)
      , 0


  # -------------------------------------------
  # Build+render methods

  _build_string: (params, callback) ->

    if !params.type?
      callback 'You must specify a type if passing a string to the build method', null
      return @
    if !@validate_type params.type
      callback "No valid renderers added for '#{params.type}' files", null
      return @

    # Render our content
    @render params.string, params.type, params.options, callback
    return @




  _build_single_file: (params, callback) ->

    # Determine the type
    type = params.type if params.type?
    type or= @get_type(params.file)

    if !@validate_type type
      callback "No valid renderers added for '#{type}' files", null
      return @

    params.options.file =
      source: params.file
      destination: null
      type: type
      options: params.options

    util.load_file "#{@config.base_path}/#{params.file}",
      (err, file)=>
        @render file.content, type, params.options, callback
        return

    return @




  _build_single_file_object: (params, callback) ->

    @validate_file params.file

    # Determine the type
    type = params.type if params.type?
    type or= @get_type(params.file)

    # Do we have any file-specific overrides?
    if params.file.type? and _.isString params.file.type
      type = params.file.type
    if params.file.options? and _.isObject params.file.options
      params.options = _.extend {}, params.options, params.file.options

    params.options.file = params.file
    source      = "#{@config.base_path}#{params.file.source}"
    destination = "#{@config.base_path}#{params.file.destination}"

    # Log it for later
    log_item = @_log_file params.file.source, params.file.destination

    # Check the mtime between the source and the destination (if our destination already exists)
    # if we're going to be replacing this file
    if !params.options.force
      destination_mtime = null
      source_mtime      = null

      if path.existsSync(destination)
        destination_stat  = fs.statSync destination
        destination_mtime = destination_stat.mtime.toString() if destination_stat.isFile()

      if path.existsSync(source)
        source_stat  = fs.statSync source
        source_mtime = source_stat.mtime.toString() if source_stat.isFile()

      # Skip it for now
      if destination_mtime == source_mtime
        log_item.status = 'File skipped'
        callback()
        return

    # If it's not a valid type, let's copy and bail out
    if !@validate_type type
      util.copy_file source, destination, callback
      log_item.status = 'File copied'
      return

    # Load up our content
    util.load_files source,
      (err, file)=>
        @render file.content, type, params.options,
          (err, content)->
            util.save_file destination, content, (err) ->
              if err
                log_item.status = 'Error building file'
              else
                log_item.status = 'File built successfully'

              # Update mtimes so we don't rerender this later needlessly
              source_mtime = fs.statSync(source).mtime.toString()
              fs.utimesSync destination, source_mtime, source_mtime

              callback err

        return

    return @




  _build_multiple_files: (params, callback) ->

    # Reset our build log
    @_reset_build_log()

    # Build each file
    async.forEachSeries params.files,
      (f, next)=>

        @build { file: f, type: params.type, options: params.options }, ->
          next()
        return

      (err)=>
        callback err, @_build_log
        return

    return @




  # Build one or more files
  build: (params, callback) ->

    single_string    = params.string?
    single_file      = params.file? and _.isString params.file
    single_file_obj  = params.file? and !_.isString params.file
    multi_file       = params.files? and _.isArray params.files

    params.options or= {}
    _.defaults params.options, @default_opts

    callback or= ->

    # Single-string mode
    if single_string
      return @_build_string params, callback

    # Single-file as a string mode
    if single_file
      return @_build_single_file params, callback

    # Multiple file objects passed as an array
    if multi_file
      return @_build_multiple_files params, callback

    # Single file as an object
    if single_file_obj
      return @_build_single_file_object params, callback

    return @




  # Render text via one of our preset renderers
  render: (content, type, opts, callback) ->

    renderers = @get_renderers type

    async.waterfall [

      # Preprocesing?
      (next)->
        if _.isFunction opts.preprocess
          opts.preprocess content, type, opts, next
        else
          next null, content

      # Main rendering loop
      (content, next)->
        async.reduce renderers, content,
          (curr_content, curr_renderer, cb)->
            result = curr_renderer?.render? curr_content, type, opts, cb
            if result == null then cb null, curr_content
            return
          next

      # Postprocessing?
      (content, next)->
        if _.isFunction opts.postprocess
          content = opts.postprocess content, type, opts, next
        else
          next null, content

    ], callback

    return




  # -------------------------------------------
  # File detection/handling

  # Validate that we have a renderer for a given type
  validate_type: (type) ->
    type != '' and @renderers[type]?




  # Attempt to detect the file type
  get_type: (file) ->

    if !_.isString file
      file = file.source

    # Check for illegal characters
    illegals = ['?','<','>','\\',':','*','|','”']
    has_illegals = _.any file.split(''), (p)->
      _.include illegals, p

    if has_illegals then return ''

    return path.extname(file).replace('.','')




  # Validate file to make sure it contains all the needed items.
  validate_file: (file) ->

    throw new Error 'Source is a required field' unless file.source and _.isString file.source
    throw new Error 'Destination is a required field' unless file.destination and _.isString file.destination
    throw new Error 'Type must be specified as a string' if file.type and !_.isString file.type
    throw new Error 'Options must be specified as an object' if file.options and !_.isObject file.options

    true




  # -------------------------------------------
  # Renderer-handling

  # Add a custom renderer
  add_renderer: (type, renderer) ->
    @renderers[type] or= []
    @renderers[type].push { name: renderer, renderer: null }
    @


  # Add multiple renderers {'ext': [ 'renderers', ... ]}
  add_renderers: (renderers) ->
    _.each renderers, (val, key) =>
      _.each val, (renderer) =>
        @add_renderer key, renderer
    @


  # Remove a renderer
  remove_renderer: (type, renderer) ->
    if renderer
      @renderers[type] = _.reject @renderers[type], (r,i)->
        r.name == renderer
    else
      @renderers[type] = []
    @




  # Attempt to load a renderer, or return null if it can't be loaded
  load_renderer: (renderer) ->
    # Probably a cleaner way to do this...
    result = null
    try
      current_path = "#{@config.base_path}#{@config.renderer_path}#{renderer}"
      result = require current_path
    catch err
      try
        current_path = "#{__dirname}/renderers/#{renderer}"
        result = require current_path
      catch err
        throw new Error "Couldn't load renderer '#{renderer}'"
        return null

    result




  # Load and initialize the renderer we want to use
  get_renderers: (type) ->
    renderers = []

    _.each @renderers[type], (r, i)=>
      # If we've already initialized a renderer, skip this
      if _.isFunction r.renderer?.render
        renderers.push r.renderer
      else
        renderer = @load_renderer r.name
        r.renderer = new renderer() unless renderer == null

        renderers.push r.renderer

    renderers



# -------------------------------------------
# Middleware for connect

module.exports.middleware = require './middleware'

module.exports.OK     = 'File built successfully'
module.exports.COPY   = 'File copied'
module.exports.SKIP   = 'File skipped'
module.exports.ERR    = 'Error building file'

