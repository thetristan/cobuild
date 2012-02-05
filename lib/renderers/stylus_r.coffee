_       = require 'underscore'
stylus  = require 'stylus'
fs      = require 'fs'


    
    
###
* Stylus class for Cobuild NodeJS build system
*
* @author Tristan Blease
* @version 0.0.0
* 
###

module.exports = class Stylus_r 

  constructor: ->

  render: (content, type, options) ->
    styl_opts = options.stylus || {}
    styl_opts.filename = options.file?.source || ''

    console.log styl_opts

    stylus.render content, styl_opts, (err,css)->
      console.log "FOOIZZLE: #{css}"