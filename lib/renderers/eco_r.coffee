_      = require 'underscore'
eco    = require 'eco'
fs     = require 'fs'

###
* 
* Template helper class for Cobuild NodeJS build system
*
* @author Tristan Blease
* @version 0.0.0
* 
###

class Eco_helpers

  constructor: (@global, @base_path) ->

  partial: (template, context) =>
    context = _.extend @, context
    content = fs.readFileSync "#{@base_path}#{template}", 'utf-8'
    eco.render content, context
   
    
    
###
* 
* Template builder class for Cobuild NodeJS build system
*
* @author Tristan Blease
* @version 0.0.0
* 
###

module.exports = class Eco_r

  constructor: ->

  render: (content, type, options, callback) ->
    globals = options.config.eco.global_vars || {} 
    context = new Eco_helpers(globals, options.config.base_path)
    callback null, eco.render content, context

  

