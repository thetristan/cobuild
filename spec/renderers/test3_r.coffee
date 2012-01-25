CobuildRenderer = require('../../lib/cobuild').CobuildRenderer

module.exports = class Test3_r extends CobuildRenderer

  constructor: ()->

  render: (content, options) ->
    "FOO"