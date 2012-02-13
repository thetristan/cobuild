_      = require 'underscore'
eco    = require 'eco'
fs     = require 'fs'

###
* 
* Eco/template helper class for Cobuild NodeJS build system
*
* @author Tristan Blease
* @version 0.0.1 
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
* Eco/template builder class for Cobuild NodeJS build system
*
* @author Tristan Blease
* @version 0.0.1 
* 
###

module.exports = class Eco_r

  constructor: ->

  render: (content, type, options, callback) ->
    global = options.config.eco?.global || {} 
    context = new Eco_helpers(global, options.config.base_path)
    callback null, eco.render content, context

  

