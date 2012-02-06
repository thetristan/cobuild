_         = require 'underscore'
path      = require 'path'
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
    single_type = _.isString type

    # Load a single file or an array of files?
    single_file = !_.isArray(file) and _.isString(file) and @get_type(file) != ""

    # Maybe we're just loading a string to transform?
    single_string = !_.isArray(file) and _.isString(file) and @get_type(file) == ""

    # We can use the second param as our options if we didn't specify a type string
    opts or= type unless _.isString type

    _.defaults opts, @default_opts

    # Done cleaning up, let's build out some files

    # Single-string mode
    if single_string
      
      throw new Error 'You must specify a type if passing a string to the build method' unless single_type    
      throw new Error "No valid renderers added for '#{type}'" unless @validate_type type

      # Render our content

    else

      # Single-file as a string mode
      if single_file  

        type = @get_type(file) unless single_type
        if !@validate_type type
          throw new Error "No valid renderers added for '#{type}' files"

        opts.file = 
          source: file
          destination: null
          type: type 
          options: opts

        content = util.load_file("#{@config.base_path}/#{file}").content
        return @render content, type, opts


      # Multiple files or single-file as an object mode
      else

        # Multiple file objects passed as an array
        if _.isArray(file) 

          # Build each file
          _.each file, (f)=>

            @build f, type, opts
            return

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

          # If it's a valid type, let's do our transform
          if @validate_type type

            # Load up our content
            content = util.load_files("#{@config.base_path}#{file.source}").content

            # If we're appending, is this the first time we're writing to this file? 
            # If so, log it and turn off the append feature for our first write
            if !opts.replace && _.indexOf(@files_rendered, file.source) == -1 
              opts.replace = true
              
            @files_rendered.push file.source

            util.save_file "#{@config.base_path}#{file.destination}", @render(content, type, opts), opts.replace
          
          
          # Otherwise, copy the file to its destination
          else
            util.copy_file "#{@config.base_path}#{file.source}", "#{@config.base_path}#{file.destination}", opts.replace

    callback(err,result)


  # Render text via one of our preset renderers
  render: (content, type, opts, callback) -> 
    
    renderers = @get_renderers type

    # Do we need to preprocess content?
    if opts.preprocess instanceof Function
        content = opts.preprocess content, type, opts
    
    # Process content
    content = _.reduce renderers, (current_content, current_renderer)->
      current_renderer?.render? current_content, type, opts
    , content

    # Do we need to postprocess content?
    if opts.postprocess instanceof Function
        content = opts.postprocess content, type, opts
    
    content




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
      if r.renderer?.render instanceof Function
        renderers.push r.renderer
      else
        renderer = @load_renderer r.name
        r.renderer = new renderer() unless renderer == null

        renderers.push r.renderer

    renderers
