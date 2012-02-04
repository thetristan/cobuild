module.exports = class Test2_r

  constructor: ()->

  render: (content, type, options, callback) ->
    callback null, content.toLowerCase()