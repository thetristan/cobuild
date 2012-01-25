 Cobuild for NodeJS

## Documentation

### Methods

---

#### constructor(`config`)

`config` is the path (relative or absolute) to the project config file cobuild requires. See examples/project.config.coffee for an example.

---

#### build(`content`, `type`, `options`)
Use Cobuild to render the string `content` using the renderer specified in `type`. `options` is an object containing any extra options that you want passed to the renderer. If a renderer doesn't exist for the provided type, the method will return `false`.

Returns `string`|`boolean`

---

#### build(`file`, `type`, `options`)
Use Cobuild to load and render`file` using the renderer specified for `type`. `options` is an object containing any extra options that you want passed to the renderer. If a renderer doesn't exist for the provided type, the method will return `false`.

Returns `string`|`boolean`

---

#### build(`file`, `options`)
Use Cobuild to load and render`file`. The renderer to be used will be chosen based on the file extension of `file`. `options` is an object containing any extra options that you want passed to the renderer. If a renderer doesn't exist for the provided type, the method will return `false`.

Returns `string`|`boolean`

---

#### build(`files`, `type`, `options`)
Use Cobuild to load, render, and save, all `files` that are passed to the method. `files` is an array of objects that should be formatted as such:

	{
		// Required – where to load the file source from
		source: 'src/file.html'
		
		// Required – where to save the rendered file to
		destination: 'release/file.html'
		
		// Optional – render with a specific type; overrides the type passed above
		type: 'template'
		
		// Optional – render with specific options; overrides the options passed above
		options: { tidy: true } 
	}
	
`options` is an object containing any extra options that you want passed to the renderer. If a renderer doesn't exist for the provided type, the method will replace the destination file with the source without doing any processing.

Returns `this` for chaining

---

#### build(files, options)
 Use Cobuild to load, render, and save, all `files` that are passed to the method. `files` is an array of objects that should be formatted as such:

	{
		// Required – where to load the file source from
		source: 'src/file.html'
		
		// Required – where to save the rendered file to
		// If you specify the same destination for one or more files, they will 
		// be concatenated together in the order they are specified
		destination: 'release/file.html'
		
		// Optional – render with a specific type; overrides the type passed above
		type: 'template'
		
		// Optional – render with specific options; overrides the options passed above
		options: { ... } 
	}
	
The renderer to be used will be chosen based on the file extension of `file`.  If a renderer doesn't exist for the provided filetype, the method will replace the destination file with the source file without doing any processing.

Returns `this` for chaining

---

### Advanced Usage

---

#### render(`content`, `renderer`, `options`)

This method is called if you want to render a string (`content`) and pass in your own `renderer` that's already been initialized. `renderer` must be an instance of an Object that inherits CobuildRenderer; these objects are only required to implement the render and type methods as outlined below. The `build` method above uses this internally to render any content/files passed to it.

Returns `string`

---

#### add_renderer(`type`, `path_to_render`)

Use this method to add a renderer to the file type specified by `type`. Renderers are loaded (via `require`) on first use, and are loaded from the renderer path sepcified in your config file. . The build method will render each type in the order specified by successive calls to this method.

Returns `this` for chaining

---

#### remove_renderer(`type`, `path_to_render`)

Use this method to remove a renderer from the file type specified by `type`. You must pass the same path you used to add the renderer for this method to remove it

Returns `this` for chaining

---

#### remove_renderer(`type`)

Use this method to remove all renderers from the file type specified by `type`. 

Returns `this` for chaining

---

### Example usage

    var cobuild = require('cobuild'),
        release = new cobuild('./config.json'),  // this is loaded via require so you can pass json, raw, js... whatever you need!
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
        minify: true, 
        preprocess: function(content, type, options) { 
          return content;  
        }  
      });
		
		
### Build/Render Options

The only three build-related options are callbacks that are ran on pre and post processing of content, and an option to replace files instead of appending content when multiple files are specified with the same output destination. 

	{
		// These take the form of: 
		// function(content, options) { 
		//    ... 
		//    return content;
		// } 
		preprocess: [callback],
		postprocess: [callback],
		
		
		// Replace files or 
		replace: false (default) | true
	}
	