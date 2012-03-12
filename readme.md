# Cobuild for NodeJS

---

1. [Introduction](#intro)
2. [Basic Usage](#usage)
2. [Basic Methods](#basic)
3. [Build/Render Options](#options)
4. [Advanced Methods](#advanced)
5. [Creating Your Own Renderers](#renderers)
6. [Middleware](#middleware)

---

<h3 id="intro">Introduction</h3>

Cobuild isn't a build system, but it is a system that helps you build build systems faster. This asynchronous module allows you to pass one or more files through it to transform text-based content by sending it through one or more renderers based on their filetype. 

You can quickly process your CSS, compress your JS, run your HTML through a template parser, or process any other text document... all through a single interface.

Specifying the same destination for multiple text files will allow you to append multiple files onto a single file. If a renderer supports it, you can concatenate text files. Any files with unknown/unspecified content types are simply copied to their destinations, so you can pass in images and other files right alongside with your text files and they'll end up right where they belong.

All examples (as well as the module itself) are written in Coffeescript.

---

<h3 id="usage">Basic Usage</h3>

    # Load the cobuild module
    cobuild = require 'cobuild'

    # Create our builder and pass it our global configuration options
    builder = new cobuild 
      base_path:     "#{__dirname}/"
      renderer_path: "#{__dirname}/renderers/"
      eco:
        global:
          var1:      "foo"
          var2:      "bar"
      stylus:
        foo:         "bar"

    # Array of file description objects
    files = [{
        source:      'src/example.js'
        destination: 'release/example.js'
      }
      {
        source:      'src/example.styl'
        destination: 'release/example.css'
      }
      {
        source:      'src/example.html.eco'
        destination: 'release/example.html'
      }]

    # Options specific to the build we're going to run
    # In this case, we're overriding a global setting from above
    options = 
      stylus:
        foo: "foo"

    # Let's do it
    builder
      .add_renderer('styl', 'stylus_r')
      .add_renderer('js', 'uglifyjs_r')
      .add_renderer('eco', 'eco_r')
      .add_renderer('eco', 'uppercase_r')
      .build
          files:   files
          options: options
        , (err, result) ->
          console.log "Build successful" unless err
          return

---

<h3 id="basic">Basic Methods</h3>

#### constructor(`config`)

`config` is an object that contains the global configuration settings. Renderers have access to this object, so it's a good place to store global settings for those, too.

#### add_renderer(`type`, `path_to_render`)

Use this method to add a renderer to the file type specified by `type`. Renderers are loaded (via `require`) on first use (via one of the `build` methods below), and they are loaded from the renderer path specified in your config file, or from Cobuild's default render path. The build method will render each type in the order specified by successive calls to this method.

Returns `this` for chaining

#### build(`params`, `callback`)
Use Cobuild to transform the content based on what you pass in via the `params` object.

Render multiple files at once (or a single file you want to be saved after rendering):

    files: (array)     # An array of file objects (see below)
                       # E.g. [{ source: 'src/my_file.html', 
                       # destination: 'release/my_file.html' }]

Render one file at a time:

    file: (string)    # String containing a file path relative 
                      # to the base_path (single file)
                      # E.g. 'src/my_file.html'
                     
Render a single string:

    string: (string)   # String containing the text you want to transform
                       # E.g. 'Transform me!'

Force cobuild to render content as a certain type (required if rendering a string)

    type: (string)     # If a file is specified, the type is 
                       # automatically detected from the file extension,
                       # but if specifying a string (or if you want to force 
                       # files to be transformed as a certain type),
                       # E.g. 'html'
                       
Build-specific options. These will override any global settings you've already specified.
                     
    options: (object)  # Optional settings to be passed to the renderers. 
                       # E.g. { stylus: { foo: "bar" } } 
                       
If a renderer doesn't exist for the provided type, the method will copy the file to its destination (if specifying multiple files), or output the untransformed content when passing a single file or a string.

The callback function takes two arguments, `err` and `result`. 

`err` will contain any uncatchable errors (if any) that were encountered when rendering the files, and `result` will contain the results of the build. If you specified multiple files, `result` will be a boolean `true` or `false`, if you specified a single file or string, `result` will contain the transformed text.

---
		
<h3 id="options">Build/Render Options</h3>

The only three build-related options are callbacks that are ran on pre and post processing of content, and an option to replace files instead of appending content when multiple files are specified with the same output destination. These options can be overriden on a per-file basis using the `build` method above.

    preprocess: [callback]   # Process the content before it hits the 
                             # rendering chain so you can strip metadata,
                             # or do other transforms 
                               
    postprocess: [callback]  # Process the content after its been rendered
                             # Last chance to make changes before it's saved/output
                               
    replace: false           # Specifies whether cobuild should replace files 
                             # or append to them when in 
  
Callbacks specified for preprocess/postprocess should be in the form of:

    postprocess: (content, type, options, callback) -> ...

Where `content` is a string containing content being rendered, `type` is the type of content being rendered, `options` are the build-specific options passed to the current build process, and `callback` is the function you need to call after you're finished processing the content to continue the render process.  

The signature for this callback is:

    callback = (`err`, `processed_content`) -> ...

---

<h3 id="advanced">Advanced Methods</h3>

#### render(`content`, `renderer`, `options`)

This method is called if you want to render a string (`content`) and pass in your own `renderer` that's already been initialized. `renderer` must be an instance of an object that implements the render method as outlined below. The `build` method above uses this internally to render any content/files passed to it.

Returns `string`

#### remove_renderer(`type`, `path_to_render (optional)`)

Use this method to remove all renderers from the file type specified by `type`.  Optionally, if you only want to remove a specific renderer, you can pass the same path you used to add the renderer for this method to remove just that renderer.

Returns `this` for chaining

---

<h3 id="renderers">Creating Your Own Renderers</h3>

This is where Cobuild really shines as it's easy to create pluggable renderers with very little code. Renderers are just objects that implement the render method:

    render = (`content`, `type`, `options`, `callback`) -> ...

It's your responsiblity to a return the string value of any transformations you make via the provided callback. 

    callback = (`err`, `rendered_content`) -> ...

If you want to make any parts of your renderer user-configurable, you can just include those options when calling `build` and they'll be made available to your renderer via the `options` parameter. In addition, any configuration options set via the cobuild configuration will be included and available under `options.config` If a file is passed to the build method (whether build is called with a single file or multiple files), an object describing the current file being processed (that includes the source, destination, etc.) will be available at `options.file`.

By including your renderer in your `renderer_path` (specified in the configuration file you passed to Cobuild during initialization), Cobuild will use your renderer when you pass it to the `add_renderer` method. The renderer itself will be initialized when it's first used, and it's instance will persist until it's been removed; this lets you do things like track statistics and thi if you want.

To keep naming consistent and make renderers easily identifiable, the official renderers will always have an `_r` suffix at the end of them. I recommend you do the same with your renderers.

---

### Example Renderer

You can always view the renderers in the lib/renderers folder for reference (there are renderers for eco, stylus, and tidy), but here is a quick example of a renderer (in CoffeeScript):

    module.exports = class Stylus_r 

      render: (content, type, options, callback) ->
        styl_opts = options.stylus || {}
        styl_opts.filename = options.file?.source || ''
        stylus.render content, styl_opts, callback

---

<h3 id="middleware">Middleware</h3>

Cobuild includes a middleware component that allows you to render assets on demand. When a request is made, cobuild checks to see if the URI matches the destination of any of the files passed to it. If it finds a match, it loads the source, renders it, and then saves the output back to the destination.

The middleware component requires a different initialization object that specifies not only the configuration options (note that you need to specify the `server_path` in addition to everything else), but also all of the files cobuild needs to monitor for, and what rendererers need to be set up.

Example of using the middleware:

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

