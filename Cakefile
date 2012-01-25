exec = require('child_process').exec

task 'test', 'Run vows tests (TODO)', ()->
  exec 'vows tests/cobuild.coffee', (err,stdout,stderr)->
    if stdout then console.log stdout
    if stderr then console.error stderr
    return
