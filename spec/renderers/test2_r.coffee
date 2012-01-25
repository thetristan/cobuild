CobuildRenderer = require('../../lib/cobuild').CobuildRenderer

module.exports = class Test2_r extends CobuildRenderer

  constructor: ()->

  render: (content, options) ->
    content.toLowerCase()