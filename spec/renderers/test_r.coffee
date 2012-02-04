module.exports = class Test_r

  constructor: ()->

  render: (content, type, options, callback) ->
    callback null, 'TEST_' + content + '_TEST'