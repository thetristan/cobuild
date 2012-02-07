_         = require 'underscore'
path      = require 'path'
async     = require 'async'
util      = require './util'


###
* 
* Cobuild NodeJS build system
*
* @author Tristan Blease
* @version 0.0.0
* 
###



module.exports = class Cobuild

  constructor: (@config) ->

    # Load our configuration
    throw new Error 'Config options must be specified to use cobuild.' unless @config
    @renderers        = {}
    @files_rendered   = []

    @clean_up_config()

    @default_opts =
      preprocess:   null
      postprocess: null
      replace:     false
      config:      @config




  # -------------------------------------------
  # Config validation and cleanup

  clean_up_config: ->

    @config.base_path = path.resolve(@config.base_path) + '/'




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

    # If it's a valid type, let's do our transform
    if @validate_type type

      # Load up our content
      util.load_files source, 
        (err, file)=>


          # If we're appending, is this the first time we're writing to this file? 
          # If so, log it and turn off the append feature for our first write
          if !params.options.replace && _.indexOf(@files_rendered, params.file.source) == -1 
            params.options.replace = true
            
          @files_rendered.push params.file.source

          @render file.content, type, params.options, 
            (err, content)->
              
              util.save_file destination, content, params.options.replace, callback
              return

          return
    
    
    # Otherwise, copy the file to its destination
    else
      util.copy_file source, destination, params.options.replace, callback

    return @




  _build_multiple_files: (params, callback) ->

    # Build each file
    async.forEachSeries params.files, 
      (f, next)=>
        
        @build { file: f, type: params.type, options: params.options }, ->
          next()
        return
      (err)->
        
        callback err
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
            curr_renderer?.render? curr_content, type, opts, cb
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
