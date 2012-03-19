fs     = require 'fs-extra'
path   = require 'path'
_      = require 'underscore'
async  = require 'async'


###
*
* Cobuild utility library
*
* @author Tristan Blease
* @version 0.1.0
*
###


# --------------------------------------------------


# Prep the content or load the files
prep_content = (content, callback)->
  # What kind of content are we working with today?
  if _.isString content
    callback null, [
        file_name: "-"
        content: content
      ]

  if _.isArray content
    load_files content, callback

  return


# --------------------------------------------------


# Load file contents from an array
load_files = (files, callback) ->



  # Load file contents from a single file
  if _.isString files

    content = load_file files, callback

  # Load file contents from multiple files
  if _.isArray files

    content = []

    async.forEachSeries files,
      (file, next) ->

        load_file file,
          (err, data)->
            content.push data
            next()
            return
        return
      (err) ->
        callback err, content
        return

  return


# Load a single file
load_file = (file, callback) ->

  file = path.resolve file

  # Check if the file exists first
  path.exists file,
    (exists)->
      if !exists
        callback "File #{file} doesn't exist.", null
      else

        fs.readFile file, 'utf8',
          (err, data)->


            callback err,
              file_name: file
              content: data
            return
      return

  return


# --------------------------------------------------


# Copy a file
copy_file = (source, destination, callback) ->

  source      = path.resolve source
  destination = path.resolve destination

  async.series [
      (next)->
        check_fix_paths destination, next

      (next)->
        path.exists destination, (exists)->
          if exists
              fs.unlink destination, next
              return
          else
            next()
            return

      (next)->
        fs.copyFile source, destination, next

    ],
    (err)->
      callback err

  return




# --------------------------------------------------


# Save text-based file
save_files = (files, content, callback) ->

  # Save a single file
  if _.isString files
    save_file files, content, callback

  # Save multiple files
  if _.isArray files

    # Save 'em all
    async.forEachSeries files,
      (file, next) ->
        save_file file.file_name, file.content, next

      (err)->
        callback err

  return



# Save a single file
save_file = (file, content, callback) ->


  file_mode = 'w'

  async.series [

    # Check the path first and create any needed directories
    (next)->
      check_fix_paths file, next

    # Deal with any existing files that need to be replaced
    (next)->
      path.exists file, (exists)->
        if exists
          fs.unlink file, next
          return
        else
          next()

    # Open the file and write the contents back to it
    (next)->

      fs.open file, file_mode, (err, fd)->

        if (err)
          next(err)

        buffer = new Buffer(content, 'utf8')
        fs.write fd, buffer, 0, buffer.length, null, (err, written)->
          if (err)
            next(err)
          fs.close fd, (err)->
            next(err)
  ],
  (err)->
    callback err
    return

  return


# --------------------------------------------------


# Check and fix any paths by creating directories as needed
check_fix_paths = (full_path, callback)->

  current_path = ''
  full_path    = path.dirname full_path
  path_parts   = full_path.split '/'

  async.forEachSeries path_parts,
    (part, next) ->
      current_path += "#{part}/"
      path.exists current_path, (exists)->
        if !exists
          fs.mkdir current_path, '0777', next
        else
          next()
        return

    (err)->
      callback(err)
      return

  return


# --------------------------------------------------


# Concatenate our files
concat_files = (files) ->
  concat_output = '';
  _.each files, (f) ->
    concat_output += f.contents

  concat_output


exports.copy_file     = copy_file
exports.concat_files  = concat_files
exports.load_files    = load_files
exports.load_file     = load_file
exports.prep_content  = prep_content
exports.save_files    = save_files
exports.save_file     = save_file
