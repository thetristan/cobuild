# Cobuild for NodeJS

Cobuild isn't a build system, but it is a system that helps you build build systems faster. The module is fully synchronous and allows you to pass one or more files through it to transform text-based content by sending it through one or more renderers based on filetype. 

You can quickly process your CSS, compress your JS, and even run your HTML through a template parser through a single interface.

Specifying the same destination for multiple text files will allow you to append multiple files onto a single file. If a renderer supports it, you can concatenate text files. Any files with unknown/unspecified content types are simply copied to their destinations, so you can pass images and other files right alongside with your text files and they'll end up right where they belong.

---

### Basic Usage

    var cobuild = require('cobuild'),
        release = new cobuild('./config.json'),
        files = [{ 
          source:      'src/example.js',
          destination: 'release/example.js' 
        },{
          source:      'src/example2.js',    // example2.js will be appended onto this
          destination: 'release/example.js'  // file since we already created it above
        },{
          source:      'src/example.styl',
          destination: 'release/example.css'
        }];

    release 
      .add_renderer('styl','stylus_r')
      .add_renderer('js', 'uglify_r')     // Stack multiple renderers on the same file type;
      .add_renderer('js', 'uppercase_r')  // content will be rendered in the order you specify
      .build(files, { 
        minify: true,                     // Specify options to be passed to renderers
        preprocess: function(content, type, options) { 
          return content;  
        }  
      });

---

### Basic Methods

#### constructor(`config`)

`config` is the path (relative or absolute) to the project config file cobuild requires.  This is loaded at runtime with `require`, so it can be a JS or JSON file. See examples/config.coffee and examples/config.json for examples.

#### add_renderer(`type`, `path_to_render`)

Use this method to add a renderer to the file type specified by `type`. Renderers are loaded (via `require`) on first use (via one of the `build` methods below), and they are loaded from the renderer path specified in your config file, or from one of 	. The build method will render each type in the order specified by successive calls to this method.

Returns `this` for chaining

#### build(`content (string)`, `type`, `options`)
Use Cobuild to render the string `content` using the renderer specified in `type`. `options` is an object containing any extra options that you want passed to the renderer.  If a renderer doesn't exist for the provided type, the method will throw an exception.

Returns `string`

#### build(`file (string)`, `type`, `options`)
Use Cobuild to load and render `file` using the renderer specified for `type`. `options` is an object containing any extra options that you want passed to the renderer. If a renderer doesn't exist for the provided type, the method will throw an exception.

Returns `string`

#### build(`file (string)`, `options`)
Use Cobuild to load and render`file`. The renderer to be used will be chosen based on the file extension of `file`. `options` is an object containing any extra options that you want passed to the renderer. If a renderer doesn't exist for the provided type, the method will throw an exception.

Returns `string`

#### build(`files (array)`, `type`, `options`)
Use Cobuild to load, render, and save, all `files` that are passed to the method. `files` is an array of objects that should be formatted as such:

	{
		// Required – where to load the file source from
		source: 'src/file.html'
		
		// Required – where to save the rendered file to
		destination: 'release/file.html'
		
		// Optional – render with a specific type; overrides the type passed above
		type: 'template'
		
		// Optional – render with specific options; overrides the options passed above
		options: { ... } 
	}
	
`options` is an object containing any extra options that you want passed to the renderer. If a renderer doesn't exist for the provided type, unlike the string/single file methods above, this method will copy the source file to the destination without doing any processing.

If a file object is missing any required information, the method will throw an exception.

Returns `this` for chaining

#### build(`files (array)`, `options`)
 Use Cobuild to load, render, and save, all `files` that are passed to the method. `files` is an array of objects that should be formatted as such:

	{
		// Required – where to load the file source from
		source: 'src/file.html'
		
		// Required – where to save the rendered file to
		// If you specify the same destination for one or more files, they will 
		// be concatenated together in the order they are specified
		destination: 'release/file.html'
		
		// Optional – render with a specific type
		type: 'template'
		
		// Optional – render with specific options; overrides the options passed above
		options: { ... } 
	}
	
`options` is an object containing any extra options that you want passed to the renderer. If a renderer doesn't exist for the provided type, unlike the string/single file methods above, this method will copy the source file to the destination without doing any processing.

If a file object is missing any required information, the method will throw an exception.

Returns `this` for chaining

---
		
### Build/Render Options

The only three build-related options are callbacks that are ran on pre and post processing of content, and an option to replace files instead of appending content when multiple files are specified with the same output destination. These options can be overriden on a per-file basis using the `build` method above.

	{
		// These take the form of: 
		// function(content, type, options) { 
		//    ... 
		//    return content;
		// } 
		preprocess: [callback],
		postprocess: [callback],
		
		
		// Replace files or append (text-based files), 
		replace: false (default) | true
	}
	
---

### Advanced Methods

#### render(`content`, `renderer`, `options`)

This method is called if you want to render a string (`content`) and pass in your own `renderer` that's already been initialized. `renderer` must be an instance of an Object that inherits CobuildRenderer; these objects are only required to implement the render and type methods as outlined below. The `build` method above uses this internally to render any content/files passed to it.

Returns `string`

#### remove_renderer(`type`)

Use this method to remove all renderers from the file type specified by `type`. 

Returns `this` for chaining

#### remove_renderer(`type`, `path_to_render`)

Use this method to remove a specific renderer from the file type specified by `type`. You must pass the same path you used to add the renderer for this method to remove it.

Returns `this` for chaining

---

### Creating Your Own Renderers

This is where Cobuild really shines as it's easy to create pluggable renderers with very little code. Renderers are just objects that implement the render method:

    render(`content`,`options`) {  ...  }

It's your responsiblity to a return the string value of any transformations you make to `content`. If you want to make any parts of your renderer user-configurable, you can just include those options when calling `build` and they'll be made available to your renderer via the `options` parameter. In addition, any configuration options set via the cobuild configuration will be included 

By including your renderer in your `renderer_path` (specified in the configuration file you passed to Cobuild during initialization), Cobuild will use your renderer when you pass it to the `add_renderer` method. The renderer itself will be initialized when it's first used, and it's instance will persist until it's been removed so you can do things like track statistics

To keep naming consistent and make renderers easily identifiable, the official renderers will always have an `_r` suffix at the end of them to. I recommend you do the same with your renderers.

### Example Renderer

You can always view the renderers in the lib/renderers folder for reference (there are renderers for eco, stylus, and uglify), but here is a quick example of a renderer (in CoffeeScript):

    module.exports = class Test2_r
      constructor: ()->
      render: (content, options) ->
        content.toLowerCase()