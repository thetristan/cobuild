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
    throw new Error 'Config file must be specified to use cobuild.' unless @config
    @config           = require @config
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
  # Build+render method

  # Build one or more files with 
  build: (file, type, opts = {}, callback) ->

    # Use a preset type or attempt to detect it?
    single_type = _.isString type & type != ''

    # Load a single file or an array of files? Or just loading a string to transform?
    single_file = _.isString(file) and (opts.file? or @get_type(file) != "")
    single_string = _.isString(file) and (!opts.file? or @get_type(file) == "")

    # We can use the second param as our options if we didn't specify a type string
    if _.isObject(type) and _.isFunction(opts) and !callback?
      callback  = opts
      opts      = type
      type      = ''

    # We can use the second param as our callback if we didn't specify a type or any options
    if _.isFunction(type) and !opts? and !callback?
      callback  = type
      opts      = {}
      type      = ''

    _.defaults opts, @default_opts

    # Done cleaning up, let's build out some files

    # Single-string mode
    if single_string
      
      callback('You must specify a type if passing a string to the build method', null) unless single_type    
      callback("No valid renderers added for '#{type}'", null) unless @validate_type type

      # Render our content
      @render file, type, opts, callback
      return @

    else

      # Single-file as a string mode
      if single_file  

        type = @get_type(file) unless single_type
        if !@validate_type type
          callback "No valid renderers added for '#{type}' files", null

        opts.file = 
          source: file
          destination: null
          type: type 
          options: opts

        util.load_file "#{@config.base_path}/#{file}", 
          (err, file)->
            @render file.content, type, opts, callback
            return @

        return


      # Multiple files or single-file as an object mode
      else

        # Multiple file objects passed as an array
        if _.isArray(file) 

          # Build each file
          async.forEachSeries file, 
            (f, next)=>
              @build f, type, opts, next
              return
            (err)->
              callback(err,results)

          return @


        # Single file as an object
        else
                  
          @validate_file file

          # Determine the type
          type = @get_type(file) unless single_type

          # Do we have any file-specific overrides?
          if file.type != undefined && _.isString file.type
            type = file.type
          if file.options != undefined && _.isObject file.options
            opts = _.extend {}, opts, file.options

          opts.file = file
          source      = "#{@config.base_path}#{file.source}"
          destination = "#{@config.base_path}#{file.destination}"

          # If it's a valid type, let's do our transform
          if @validate_type type

            # Load up our content
            util.load_files source, 
              (err, content)=>

                # If we're appending, is this the first time we're writing to this file? 
                # If so, log it and turn off the append feature for our first write
                if !opts.replace && _.indexOf(@files_rendered, file.source) == -1 
                  opts.replace = true
                  
                @files_rendered.push file.source

                @render content, type, opts, 
                  (err, content)->
                    util.save_file destination, content, opts.replace, callback
                    return

                return
          
          
          # Otherwise, copy the file to its destination
          else
            util.copy_file source, destination, opts.replace, callback




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
            current_renderer?.render? curr_content, type, opts, cb
          (err, result)->
            next err, result

      # Postprocessing?
      (content, next)->
        if _.isFunction opts.postprocess
          content = opts.postprocess content, type, opts, next

    ], callback

    return



  # -------------------------------------------
  # File detection/handling

  # Validate that we have a renderer for a given type
  validate_type: (type) ->
    type != '' and @renderers[type]?


  # Attempt to detect the file type
  get_type: (file) ->

    if _.isObject file
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
