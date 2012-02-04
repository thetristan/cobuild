
fs       = require 'fs'
_        = require 'underscore'
colorize = require 'colorize'
path     = require 'path'

Cobuild  = require '../lib/cobuild'


###
* 
* Cobuild NodeJS tests
*
* @author Tristan Blease
* @version 0.0.0
* 
###

console.log "Cobuild NodeJS tests"
console.log "----------------------------------"

# CLEAN UP
console.log "\nCleaning up from previous tests..."

_.each fs.readdirSync("#{__dirname}/output/"), (f) ->
  console.log colorize.ansify "#green[  removing #{__dirname}/output/#{f}]"
  fs.unlinkSync "#{__dirname}/output/#{f}"
  return

cobuild = null

reset = ->
  cobuild = new Cobuild "#{__dirname}/config.coffee"




# START TESTS
describe 'Cobuild file detection', ->

  beforeEach ->
    reset()

  it 'should return "html" when detecting the type of a file named "testfile.html"', ->
    r = expect cobuild.get_type 'testfile.html'
    r.toEqual 'html'

  it 'should return nothing when detecting the type of a file w/o an extension', ->
    r = expect cobuild.get_type 'testfile'
    r.toEqual ''




describe 'Cobuild render system', ->
  
  beforeEach ->
    reset()  
    cobuild
      .add_renderer('test', "test_r")
      .add_renderer('test', "test2_r")

    @addMatchers
      toContainRendererNamed: (expected)->
        _.any @actual, (a)->
          true if a.name == expected


  it 'should add three new renderers to the "test" type, but only two should work', ->
    result = cobuild
      .add_renderer('test', "foo_r")      
    
    cobuild.get_renderers('test')

    r = expect result
    r.toEqual cobuild

    r = expect cobuild.renderers['test']
    r.toContainRendererNamed 'test_r'
    r.toContainRendererNamed 'test2_r'
    r.toContainRendererNamed 'foo_r'
    
    r = expect cobuild.renderers['test'].length
    r.toEqual 3

  it 'should have only one renderer if we remove the second two', ->
    result = cobuild
      .remove_renderer('test', 'test2_r')
      .remove_renderer('test', 'foo_r')
      
    cobuild.get_renderers('test')

    r = expect result
    r.toEqual cobuild

    r = expect cobuild.renderers['test']
    r.toContainRendererNamed 'test_r'
    r = expect cobuild.renderers['test'].length
    r.toEqual 1

  it 'should return null loading an unknown renderer', ->
    r = expect cobuild.load_renderer 'foo'
    r.toEqual null

  it 'should return a function back if the loader exists', ->
    renderer = cobuild.load_renderer 'test2_r'
    r = expect renderer instanceof Function
    r.toBeTruthy()

  it 'should return an instance of CobuildRenderer back if the loader exists', ->
    renderer = cobuild.get_renderers('test')[0]
    r = expect renderer.render instanceof Function
    r.toBeTruthy()

  it 'should return "TEST_foo_TEST" when directly rendering "foo" via "test_r"', ->
    renderer = cobuild.get_renderers('test')[0]
    r = expect renderer.render 'foo'
    r.toEqual 'TEST_foo_TEST'

  it 'should remove all renderers on a type when calling remove_renderer but not specifying a path', ->
    result = cobuild.remove_renderer 'test'

    renderer = cobuild.get_renderers 'test'
    r = expect renderer.length
    r.toEqual 0

    r = expect result
    r.toEqual cobuild




describe 'Cobuild build system', ->  

  beforeEach ->
    reset()  
    cobuild
      .add_renderer('test', "test_r")
      .add_renderer('html', "test_r")
      .add_renderer('foo', "test3_r")

  it 'should render a string with "render" with multiple renderers', ->
    r = expect cobuild
      .add_renderer('test', "test2_r")
      .render 'foo', 'test', {}
    r.toEqual 'test_foo_test'

  it 'should render a string and use a preprocess if specified', ->
    reset()
    result = cobuild
      .add_renderer('test','test_r')
      .render 'foo', 'test',
        preprocess: (c,t,o) ->
          c.toUpperCase()
    r = expect result
    r.toEqual 'TEST_FOO_TEST'

  it 'should render a string and use a postprocess if specified', ->
    reset()
    result = cobuild
      .add_renderer('test','test_r')
      .render 'foo', 'test',
        postprocess: (c,t,o) ->
          c.charAt(5)
    r = expect result
    r.toEqual 'f'

  it 'should render a single file', ->
    r = expect cobuild.build 'spec/samples/test1.html', 'test'
    r.toEqual 'TEST_<html>foo</html>_TEST'

  it 'should render a single file w/o specifying a type', ->
    r = expect cobuild.build 'spec/samples/test1.html'
    r.toEqual 'TEST_<html>foo</html>_TEST'

  it 'should fail to render a single file w/ an invalid type', ->
    try
      cobuild.build 'spec/samples/foo.gif'
    catch err
      r = expect err.message
      r.toEqual "No valid renderers added for 'gif' files"


  it 'should render an array of files', ->
    result = cobuild.build [{
        source:      'spec/samples/test1.html'
        destination: 'spec/output/test1.html'
      }
      {
        source:      'spec/samples/test2.html'
        destination: 'spec/output/test2.html'
      }], 'test'

    r = expect result
    r.toEqual cobuild

    r = expect fs.readdirSync("#{__dirname}/output/").length
    r.toEqual 2

    r = expect fs.readFileSync("#{__dirname}/output/test1.html", 'utf-8')
    r.toEqual "TEST_<html>foo</html>_TEST"

    r = expect fs.readFileSync("#{__dirname}/output/test2.html", 'utf-8')
    r.toEqual "TEST_<html>bar</html>_TEST"


  it 'should render an array of files w/o specifying a type', ->
    result = cobuild.build [{
        source:      'spec/samples/test1.html'
        destination: 'spec/output/test3.html'
      }
      {
        source:      'spec/samples/test2.html'
        destination: 'spec/output/test4.html'
      }]

    r = expect result
    r.toEqual cobuild

    r = expect fs.readdirSync("#{__dirname}/output/").length
    r.toEqual 4

    r = expect fs.readFileSync("#{__dirname}/output/test3.html", 'utf-8')
    r.toEqual "TEST_<html>foo</html>_TEST"

    r = expect fs.readFileSync("#{__dirname}/output/test4.html", 'utf-8')
    r.toEqual "TEST_<html>bar</html>_TEST"

  it 'should render an array of files w/ a file-specific type override', ->
    result = cobuild.build [{
        source:      'spec/samples/test1.html'
        destination: 'spec/output/test5.html'
      }
      {
        source:      'spec/samples/test2.html'
        destination: 'spec/output/test6.html'
        type: 'foo'
      }]

    r = expect result
    r.toEqual cobuild

    r = expect fs.readdirSync("#{__dirname}/output/").length
    r.toEqual 6

    r = expect fs.readFileSync("#{__dirname}/output/test5.html", 'utf-8')
    r.toEqual "TEST_<html>foo</html>_TEST"

    r = expect fs.readFileSync("#{__dirname}/output/test6.html", 'utf-8')
    r.toEqual "FOO"


  it 'should render an array of files w/ a file-specific options override', ->
    result = cobuild.build [{
        source:      'spec/samples/test1.html'
        destination: 'spec/output/test7.html'
        options:
          preprocess: (c,t,o) ->
            c.toUpperCase()
          postprocess: (c,t,o) ->
            c.charAt(11)
      }
      {
        source:      'spec/samples/test2.html'
        destination: 'spec/output/test8.html'
      }]

    r = expect result
    r.toEqual cobuild

    r = expect fs.readdirSync("#{__dirname}/output/").length
    r.toEqual 8

    r = expect fs.readFileSync("#{__dirname}/output/test7.html", 'utf-8')
    r.toEqual "F"

    r = expect fs.readFileSync("#{__dirname}/output/test8.html", 'utf-8')
    r.toEqual "TEST_<html>bar</html>_TEST"


  it 'should append content when files share the same destination unless replace is specified', ->
    result = cobuild.build [{
        source:      'spec/samples/test1.html'
        destination: 'spec/output/test9.html'
        options:
          replace: true
      }
      {
        source:      'spec/samples/test2.html'
        destination: 'spec/output/test9.html'
        options:
          replace: true
      }
      {
        source:      'spec/samples/test1.html'
        destination: 'spec/output/test10.html'
      }
      {
        source:      'spec/samples/test2.html'
        destination: 'spec/output/test10.html'
      }]

    r = expect result
    r.toEqual cobuild

    r = expect fs.readdirSync("#{__dirname}/output/").length
    r.toEqual 10

    r = expect fs.readFileSync("#{__dirname}/output/test9.html", 'utf-8')
    r.toEqual "TEST_<html>bar</html>_TEST"

    r = expect fs.readFileSync("#{__dirname}/output/test10.html", 'utf-8')
    r.toEqual "TEST_<html>foo</html>_TESTTEST_<html>bar</html>_TEST"


  it 'should copy files it has no idea what else to do with', ->
    result = cobuild.build {
      source:      'spec/samples/foo.gif'
      destination: 'spec/output/bar.gif' 
      }

    r = expect path.existsSync "#{__dirname}/output/bar.gif"
    r.toBeTruthy()

    r = expect fs.statSync("#{__dirname}/output/bar.gif").size
    r.toEqual fs.statSync("#{__dirname}/samples/foo.gif").size


  it 'should replace files that it has already copied if replace is specified', ->
    result = cobuild.build [{
      source:      'spec/samples/foo2.gif'
      destination: 'spec/output/bar.gif'
      options:
        replace:   true
      }]

    r = expect path.existsSync "#{__dirname}/output/bar.gif"
    r.toBeTruthy()

    r = expect fs.statSync("#{__dirname}/output/bar.gif").size
    r.toEqual fs.statSync("#{__dirname}/samples/foo2.gif").size


  it 'shouldn\'t replace files that it has already copied if replace isn\'t specified', ->
    try 
      result = cobuild.build [{
        source:      'spec/samples/foo.gif'
        destination: 'spec/output/bar2.gif'
        }
        {
        source:      'spec/samples/foo2.gif'
        destination: 'spec/output/bar2.gif'
        }]
    catch err
      r = expect err.message
      r.toEqual "File already exists"

    r = expect path.existsSync "#{__dirname}/output/bar2.gif"
    r.toBeTruthy()

    r = expect fs.statSync("#{__dirname}/output/bar2.gif").size
    r.toEqual fs.statSync("#{__dirname}/samples/foo.gif").size




describe 'Built-in eco renderer', ->

  beforeEach ->
    reset()  
    cobuild
      .add_renderer('eco', "eco_r")

  it 'should render an eco template', ->
    result = cobuild.get_renderers 'eco'
    r = expect result
    console.log result
