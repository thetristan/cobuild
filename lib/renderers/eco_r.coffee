_      = require 'underscore'
eco    = require 'eco'
fs     = require 'fs'

###
*
* Eco/template helper class for Cobuild NodeJS build system
*
* @author Tristan Blease
* @version 0.1.5
*
###

class Eco_helpers

  constructor: (@global, @base_path) ->

  partial: (template, context) =>
    try
      context = _.extend @, context
      content = fs.readFileSync "#{@base_path}#{template}", 'utf-8'
      eco.render content, context
    catch err
      "<div class='error'>Fatal error: #{err.message}</div>"


###
*
* Eco/template builder class for Cobuild NodeJS build system
*
* @author Tristan Blease
* @version 0.0.1.1
*
###

module.exports = class Eco_r

  constructor: ->

  render: (content, type, options, callback) ->
    try
      global  = options.config.eco?.global || {}
      context = new Eco_helpers(global, options.config.base_path)
      callback null, eco.render content, context
    catch err
      callback null, "Fatal error: #{err.message}"



