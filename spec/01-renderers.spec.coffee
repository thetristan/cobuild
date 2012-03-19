
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
* Cobuild Renderer tests
*
* @author Tristan Blease
* @version 0.1.1
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

cobuild = null

reset = ->
  cobuild = new Cobuild test_config

describe 'Built-in eco renderer', ->

  beforeEach ->
    reset()  
    cobuild
      .add_renderer('eco', "eco_r")

  it 'should render an eco template with a global variable', ->
    complete = false
    
    runs ->
      cobuild.build { string: 'A <%= @global.test_var %> tastes great with milk.', type: 'eco' }, 
        (err,data)=>
          complete = true
          @data = data
          return
      return

    waitsFor ->
        complete
      , 'callback never fired', 500

    runs ->
      r = expect @data
      r.toEqual 'A foobar tastes great with milk.'


  it 'should render an partial template', ->
    complete = false
    
    runs ->
      cobuild.build { string: 'However, a <%= @global.test_var_2 %> does not taste great with milk. <%- @partial "spec/samples/test4.eco", { sample_var: "foo" } %>.', type: 'eco' }, 
        (err,data)=>
          complete = true
          @data = data
          return
      return

    waitsFor ->
        complete
      , 'callback never fired', 500

    runs ->
      r = expect @data
      r.toEqual 'However, a raboof does not taste great with milk. <h1>foo</h1>.'


# -------------------------------------------


describe 'Built-in stylus renderer', ->

  beforeEach ->
    reset()  
    cobuild
      .add_renderer('styl', "stylus_r")

  it 'should render a stylus template', ->
    complete = false

    stylus_css    = '''
                    body
                      h1
                        width 500px
                    '''
    stylus_result = "body h1 {\n  width: 500px;\n}\n"

    result = cobuild.build { string: stylus_css, type: 'styl' }, (err,data)=>
      complete = true
      @data = data
      return

    waitsFor ->
        complete
      , 'callback never fired', 500

    runs ->
      r = expect @data
      r.toEqual stylus_result


