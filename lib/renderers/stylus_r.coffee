stylus  = require 'stylus'
    
    
###
* Stylus class for Cobuild NodeJS build system
*
* @author Tristan Blease
* @version 0.0.1 
###

module.exports = class Stylus_r 

  constructor: ->

  render: (content, type, options, callback) ->
    styl_opts = options.stylus || {}
    styl_opts.filename = options.file?.source || ''
    stylus.render content, styl_opts, callback