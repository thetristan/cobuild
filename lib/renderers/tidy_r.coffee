spawn   = require('child_process').spawn

###
* Tidy class for Cobuild NodeJS build system
* Requires tidy to be installed
*
* @author Tristan Blease
* @version 0.1.5
*
###

module.exports = class Tidy_r

  constructor: ->

  render: (content, type, options, callback) ->

    tidied_content = ''

    config           = options.config.tidy || {}
    command          = config.command || 'tidy'
    command_options  = config.options || []

    tidy = spawn command, command_options

    tidy.stdout.on 'data', (data)->
      tidied_content = tidied_content + data.toString 'utf-8'
      return

    tidy.on 'exit', (code)->
      if tidied_content != ''
        content = tidied_content
      callback null, content
      return

    tidy.stdin.on 'error', (err)->
      if err.message.indexOf 'EPIPE' > -1
        console.error "Cobuild couldn't find '#{command}'; are you sure '#{command}' is installed? Skipping tidy... [Tidy_r]"

    tidy.stdin.write content
    tidy.stdin.end()

    return
