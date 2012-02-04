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

  constructor: (@global_vars, @base_path) ->

  partial: (@template, context) =>
    context = _.extend @, @global_vars, context
    template = fs.readFileSync "#{@base_path}src/#{@template}"), 'utf-8'
    eco.render template, context
   
    
    
###
* 
* Template builder class for Cobuild NodeJS build system
*
* @author Tristan Blease
* @version 0.0.0
* 
###

module.exports = class Eco_r

  constructor: () ->

  render: (content, options) ->
    context = _.extend new Eco_helpers options.config.global_vars, options.config.base_path
    eco.render @content, context

  

