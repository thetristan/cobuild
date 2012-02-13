cobuild = require './cobuild'

exports = (options)->
  build = new cobuild options
  return (req,res,next) ->
    

