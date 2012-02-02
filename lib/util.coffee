fs   = require 'fs'
path = require 'path'
_    = require 'underscore'

# Prep the content or load the files
prep_content = (content)->
  # What kind of content are we working with today?
  if typeof content == 'string'
    content = [{ 
      file_name: "-"
      content: content
      }]
  
  if content instanceof Array
    content = load_files content

  content



# Load file contents from an array
load_files = (files) ->

  # Load file contents from a single file
  if typeof files == 'string'
    content = load_file files

  # Load file contents from multiple files
  if files instanceof Array
    content = []
    _.each files, (file_name) =>
      content.push load_file file_name

  content



# Load a single file
load_file = (file) ->

  # Check if the file exists first
  if !path.existsSync path.resolve file
    throw Error "File #{file} doesn't exist."

  # Load it up
  content =
    file_name: file
    content: fs.readFileSync file, 'utf-8'  

  content 



# Save text-based file
save_files = (files, content, replace = false) ->

  # Save a single file 
  if typeof files == 'string'
    save_file files, content, replace

  # Save multiple files
  if files instanceof Array
    _.each files, (file) ->
      save_file file.file_name, file.content, replace

  return




# Save a single file
save_file = (file, content, replace = false) ->

  # Check the path first and create any needed files
  check_fix_paths file
  
  file_mode = 'w'

  # Deal with existing files
  if path.existsSync file
    if replace
      fs.unlinkSync
    else
      file_mode = 'a'

  # Open the file and write the contents back to it
  fd = fs.openSync file, file_mode
  fs.writeSync fd, content
  fs.closeSync fd




# Check and fix any paths by creating directories as needed
check_fix_paths = (full_path)->

  current_path = '/'
  full_path    = path.dirname full_path
  path_parts   = full_path.split '/'
  
  for part in path_parts
    current_path += "#{part}/"
    if !path.existsSync current_path
      fs.mkdirSync current_path
  
  return



# Concatenate our files
concat_files = (files) ->
  concat_output = '';
  _.each files, (f) ->
    concat_output += f.contents
    
  concat_output


exports.concat_files  = concat_files
exports.load_files    = load_files
exports.load_file     = load_file
exports.prep_content  = prep_content
exports.save_files    = save_files
exports.save_file     = save_file
