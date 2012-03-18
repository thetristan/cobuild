
fs       = require 'fs'
_        = require 'underscore'
path     = require 'path'

Cobuild  = require '../lib/cobuild'

test_config = 
  base_path:      "#{__dirname}/../"
  renderer_path:  "spec/renderers/"
  eco:
    global: 
      test_var:   'foobar'
      test_var_2: 'raboof'

###
* 
* Cobuild Middleware tests
*
* @author Tristan Blease
* @version 0.0.1.1 
* 
###


# CLEAN UP
if !path.existsSync "#{__dirname}/output/"
  fs.mkdir "#{__dirname}/output/"

clean_up = (dir_name)->
  _.each fs.readdirSync(dir_name), (f) ->
    current_path = "#{dir_name}#{f}"
    if fs.lstatSync(current_path).isDirectory()
      current_path = "#{current_path}/"
      clean_up current_path
      fs.rmdir current_path
    else
      fs.unlinkSync current_path
    return

clean_up "#{__dirname}/output/"

describe 'Connect middleware', ->

    complete = 0
    res_1    = ''
    res_2    = ''

    express = require 'express'

    http    = require 'http'
    app     = express.createServer()
    port    = 1111

    it 'should spawn an instance of a server and build on demand', ->

      runs ->

        # We need a special config object to pass to our middleware constructor
        test_config = 
          options:
            base_path:      "#{__dirname}/../"
            renderer_path:  "spec/renderers/"
            server_path:    "spec/output/web/"
          files: [{
                source:      'spec/samples/test1.html'
                destination: 'spec/output/web/test1.html'
              }
              {
                source:      'spec/samples/test1.html'
                destination: 'spec/output/web/test0.html'
              }]
          renderers:
            'html': [
                "test_r"
                "test2_r"
              ]

        # Configure the server with stylus and browserify middleware
        app.configure ->
          app.use app.router
          app.use Cobuild.middleware test_config
          app.use express.static "#{__dirname}/../spec/output/web/"

        # Start the server
        app.listen port

      waits 100

      #TODO Find out why this extra request is needed before connect middleware starts working
      runs ->
        r0 = http.get 
            port: port
            path: '/test0.html'

      waits 100

      runs ->

        r1 = http.get
            port: port
            path: '/test1.html'
          , (res)->
            res.setEncoding 'utf8'
            res.on 'data', (data)->
              res_1 = data
              complete++
            return

        r2 = http.get
            port: port
            path: '/test0.html'
          , (res)->
            res.setEncoding 'utf8'
            res.on 'data', (data)->
              res_2 = data
              complete++
            return


      waitsFor ->
        complete == 2
      , 'callback never fired', 1000

      runs ->
        expect(res_1).toEqual 'test_<html>foo</html>_test' #'foo'
        expect(res_2).toEqual 'test_<html>foo</html>_test' #'bar'
        app.close()
        return





