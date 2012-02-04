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

class Template_helpers

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

module.exports = class Template 

  constructor: (@content, @global_vars, @base_path) ->

  render: () ->
    context = _.extend new Template_helpers @global_vars, @base_path
    eco.render @content, context

  

