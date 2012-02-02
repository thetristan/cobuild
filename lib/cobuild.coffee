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

  #CobuildConfig:   require './config'
  @CobuildRenderer: require './renderer'

  constructor: (@config) ->

    # Load our configuration
    throw new Error 'Config file must be specified to use cobuild.' unless @config
    @config = require @config
    @renderers = {}
    @files_rendered = []

    @default_opts =
      preprocess: null
      postprocess: null
      replace: false

    # TODO: Add config validation


  # Build one or more files with 
  build: (file, type, opts) ->

    # Use a preset type or attempt to detect it?
    single_type = _.isString type

    # Load a single file or an array of files?
    single_file = _.isString(file) and @get_type(file) != ""

    # Maybe we're just loading a string to transform?
    single_string = _.isString(file) and @get_type(file) == ""

    # We can use the second param as our options if we didn't specify a type string
    opts or= type unless type instanceof String
    opts or= {}

    _.defaults opts, @default_opts


    # Done cleaning up, let's build out some files
    if single_string
      throw new Error 'You must specify a type if passing a string to the build method' unless single_type
      
      # Render our content
      return @render file, type, opts

    else
      if single_file  

        # Single-file mode
        content = util.load_file("#{@config.base_path}/#{file}").content
        type = @get_type(file) unless single_type
        return @render content, type, opts
        
      else

        # Did we get an array?
        if _.isArray(file) and file.length > 1

          # Build each file
          _.each file, (f)=>

            @build f, type, opts
            return

          return @

        # Single file as an object, let's do this
        else
                  
          @validate_file file

          # Load up our content
          content = util.load_files("#{@config.base_path}#{file.source}").content
          
          # Determine the type
          type = @get_type(file) unless single_type

          # Do we have any file-specific overrides?
          if file.type != undefined && _.isString file.type
            type = file.type
          if file.options != undefined && _.isObject file.options
            opts = _.extend {}, opts, file.options

          # If we're appending, is this the first time we're writing to this file? 
          # If so, log it and turn off the append feature for our first write
          if !opts.replace && _.indexOf(@files_rendered, file.source) == -1 
            opts.replace = true
            
          @files_rendered.push file.source
  
          util.save_file "#{@config.base_path}#{file.destination}", @render(content, type, opts), opts.replace
    
    return



  # Render text via one of our preset renderers
  render: (content, type, opts) -> 
    
    renderers = @get_renderers type

    # Do we need to preprocess content?
    if opts.preprocess instanceof Function
        content = opts.preprocess content, type, opts
    
    # Process content
    content = _.reduce renderers, (current_content, current_renderer)->
      current_renderer?.render? current_content, opts
    , content

    # Do we need to postprocess content?
    if opts.postprocess instanceof Function
        content = opts.postprocess content, type, opts
    
    content




  # Attempt to detect the file type
  get_type: (file) ->
    
    if _.isString file
      return path.extname(file).replace('.','')

    if _.isObject file
      return path.extname(file.source).replace('.','')

    ''


  # Add a custom renderer
  add_renderer: (type, renderer) ->
    @renderers[type] or= []
    @renderers[type].push renderer
    @

  
  # Remove a renderer
  remove_renderer: (type, renderer) ->
    if renderer
      @renderers[type] = _.reject @renderers[type], (r)->
        r == renderer
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
        if !(r instanceof Cobuild.CobuildRenderer)
          r = @load_renderer r
          renderers.push new r() unless r == null
    
    renderers

  # Validate file to make sure it contains all the needed items.
  validate_file: (file) ->
    
    throw new Error 'Source is a required field' unless file.source and _.isString file.source
    throw new Error 'Destination is a required field' unless file.destination and _.isString file.destination
    throw new Error 'Type must be specified as a string' if file.type and !_.isString file.type
    throw new Error 'Options must be specified as an object' if file.options and !_.isObject file.options

    true