module.exports = class Test_r

  constructor: ()->

  render: (content, type, options) ->
    'TEST_' + content + '_TEST'