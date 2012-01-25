CobuildRenderer = require('../../lib/cobuild').CobuildRenderer

module.exports = class Test_r extends CobuildRenderer

  constructor: ()->

  render: (content, options) ->
    'TEST_' + content + '_TEST'