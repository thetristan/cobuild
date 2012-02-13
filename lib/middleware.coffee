cobuild = require './cobuild'

exports = (options)->
  
  build = new cobuild options

  return (req,res,next) ->

    # Only service GET/HEAD requests
    if req.method != 'GET' && req.method != 'HEAD'
      return next()
    



