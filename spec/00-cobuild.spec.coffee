
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
* Cobuild NodeJS tests
*
* @author Tristan Blease
* @version 0.1.0
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


# -------------------------------------------

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


# -------------------------------------------

describe 'Cobuild log utils', ->


  beforeEach ->
    reset()

  it 'should create a new log when running a new build', ->
    cobuild._reset_build_log()
    expect(cobuild._build_log.length).toEqual(0)

  it 'should return 0 for a destination that hasn\'t been logged yet', ->
    expect(cobuild._log_file_count_by_dest 'foobar').toEqual 0

  it 'should return count for all destinations', ->
    cobuild._log_file 'foo', 'bar'
    cobuild._log_file 'bar', 'bar'
    cobuild._log_file 'foobar', 'foo'
    expect(cobuild._log_file_count_by_dest 'foo').toEqual 1
    expect(cobuild._log_file_count_by_dest 'bar').toEqual 2


describe 'Cobuild core utils', ->

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

    try
      cobuild.get_renderers('test')
    catch err
      # Error caught


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

  it 'should throw an error when loading an unknown renderer', ->
    try
      r = expect cobuild.load_renderer 'foo'
    catch err
      expect(err.message).toEqual "Couldn't load renderer 'foo'"

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
    renderer.render 'foo', '', {}, (err, data)->
      expect(data).toEqual 'TEST_foo_TEST'

  it 'should remove all renderers on a type when calling remove_renderer but not specifying a path', ->
    result = cobuild.remove_renderer 'test'

    renderer = cobuild.get_renderers 'test'
    r = expect renderer.length
    r.toEqual 0

    r = expect result
    r.toEqual cobuild


# -------------------------------------------


describe 'Cobuild build system', ->


  beforeEach ->
    reset()
    cobuild
      .add_renderer('test', "test_r")
      .add_renderer('html', "test_r")
      .add_renderer('foo', "test3_r")
    return

  it 'should render a string with "render" with multiple renderers', ->
    cobuild
      .add_renderer('test', "test2_r")
      .render 'foo', 'test', {},
        (err, data)->
          expect(data).toEqual 'test_foo_test'

  it 'should render a string and use a preprocess if specified', ->

    complete = false
    result = ''

    runs ->
      reset()
      opts =
        preprocess: (c,t,o, next) ->
          next null, c.toUpperCase()
          return

      cobuild
        .add_renderer('test','test_r')
        .render 'foo', 'test', opts,
          (err, data)=>
            result = data
            complete = true

    waitsFor ->
        complete
      , 'callback didn\'t fire', 500


    runs ->
      expect(result).toEqual 'TEST_FOO_TEST'
      return

    return


  it 'should render a string and use a postprocess if specified', ->

    runs ->
      reset()
      opts =
        postprocess: (c,t,o, next) ->
          next null, c.charAt(5)
          return

      cobuild
        .add_renderer('test','test_r')
        .render 'foo', 'test', opts,
          (err, data)=>
            expect(data).toEqual 'f'
            return

      return
    return


  it 'should render a single file', ->
    cobuild.build { file: 'spec/samples/test1.html', type: 'test' },
      (err, data)->
        expect(data).toEqual 'TEST_<html>foo</html>_TEST'
        return
    return


  it 'should render a single file w/o specifying a type', ->

    complete = false

    runs ->
      cobuild.build { file: 'spec/samples/test1.html' },
        (err,data)=>
          complete = true
          @data = data
          return
      return

    waitsFor ->
        complete
      , 'callback didn\'t fire', 500

    runs ->
      expect(@data).toEqual 'TEST_<html>foo</html>_TEST'
      return

    return

  it 'should fail to render a single file w/ an invalid type', ->

    complete = false

    runs ->
      cobuild.build { file: 'spec/samples/foo.gif' },
        (err, data)=>
          complete = true
          @err = err
          return
      return

    waitsFor ->
        complete
      , 'callback didn\'t fire', 500


    runs ->
      expect(@err).toEqual "No valid renderers added for 'gif' files"
      return

    return

  it 'should render an array of files', ->

    complete = false

    runs ->
      files = [{
        source:      'spec/samples/test1.html'
        destination: 'spec/output/test1.html'
      }
      {
        source:      'spec/samples/test2.html'
        destination: 'spec/output/test2.html'
      }]


      result = cobuild.build { files: files, type: 'test' },
        (err, data)->
          complete = true
          return

      expect(result).toEqual cobuild

      return

    waitsFor ->
        complete
      , 'Callback never called', 500

    runs ->

      r = expect fs.readdirSync("#{__dirname}/output/").length
      r.toEqual 2

      r = expect fs.readFileSync("#{__dirname}/output/test1.html", 'utf8')
      r.toEqual "TEST_<html>foo</html>_TEST"

      r = expect fs.readFileSync("#{__dirname}/output/test2.html", 'utf8')
      r.toEqual "TEST_<html>bar</html>_TEST"

      return

    return



  it 'should render an array of files w/o specifying a type', ->

    complete = false

    runs ->
      files = [{
          source:      'spec/samples/test1.html'
          destination: 'spec/output/test3.html'
        }
        {
          source:      'spec/samples/test2.html'
          destination: 'spec/output/test4.html'
        }]

      result = cobuild.build { files: files }, ->
        complete = true
        return

      expect(result).toEqual cobuild

      return


    waitsFor ->
        complete
      , 'Callback never called', 500

    runs ->
      r = expect fs.readdirSync("#{__dirname}/output/").length
      r.toEqual 4

      r = expect fs.readFileSync("#{__dirname}/output/test3.html", 'utf8')
      r.toEqual "TEST_<html>foo</html>_TEST"

      r = expect fs.readFileSync("#{__dirname}/output/test4.html", 'utf8')
      r.toEqual "TEST_<html>bar</html>_TEST"

      return



  it 'should render an array of files w/ a file-specific type override', ->

    complete = false

    runs ->
      files = [{
          source:      'spec/samples/test1.html'
          destination: 'spec/output/test5.html'
        }
        {
          source:      'spec/samples/test2.html'
          destination: 'spec/output/test6.html'
          type: 'foo'
        }]

      result = cobuild.build { files: files }, ->
        complete = true
        return

      expect(result).toEqual cobuild

      return

    waitsFor ->
        complete
      , 'Callback never called', 500

    runs ->
      r = expect fs.readdirSync("#{__dirname}/output/").length
      r.toEqual 6

      r = expect fs.readFileSync("#{__dirname}/output/test5.html", 'utf8')
      r.toEqual "TEST_<html>foo</html>_TEST"

      r = expect fs.readFileSync("#{__dirname}/output/test6.html", 'utf8')
      r.toEqual "FOO"

      return


  it 'should render an array of files w/ a file-specific options override', ->

    complete = false

    runs ->

      files = [{
        source:      'spec/samples/test1.html'
        destination: 'spec/output/test7.html'
        options:
          preprocess: (c,t,o, next) ->
            next null, c.toUpperCase()
          postprocess: (c,t,o, next) ->
            next null, c.charAt(11)
      }
      {
        source:      'spec/samples/test2.html'
        destination: 'spec/output/test8.html'
      }]

      result = cobuild.build { files: files }, ->
        complete = true
        return

      expect(result).toEqual cobuild

      return

    waitsFor ->
        complete
      , 'Callback never called', 500

    runs ->

      r = expect fs.readdirSync("#{__dirname}/output/").length
      r.toEqual 8

      r = expect fs.readFileSync("#{__dirname}/output/test7.html", 'utf8')
      r.toEqual "F"

      r = expect fs.readFileSync("#{__dirname}/output/test8.html", 'utf8')
      r.toEqual "TEST_<html>bar</html>_TEST"

      return



  it 'should copy files it has no idea what else to do with', ->

    complete = false
    data = null

    runs ->
      files = [{
        source:      'spec/samples/foo.gif'
        destination: 'spec/output/bar.gif'
        }]

      cobuild.build { files: files }, (err, result)->
        complete = true
        data = result
        return

      return

    waitsFor ->
        complete
      , 'callback never fired', 500

    runs ->

      expect(path.existsSync "#{__dirname}/output/bar.gif").toBeTruthy()

      r = expect fs.statSync("#{__dirname}/output/bar.gif").size
      r.toEqual fs.statSync("#{__dirname}/samples/foo.gif").size

      expect(data[0].status).toEqual Cobuild.COPIED

      return



  it 'should replace files that it has already copied if specified again', ->

    complete = false

    runs ->
      files = [
        source:      'spec/samples/foo2.gif'
        destination: 'spec/output/bar.gif'
        ]

      cobuild.build { files: files }, ->
        complete = true
        return

      return

    waitsFor ->
        complete
      , 'callback never fired', 500


    runs ->

      r = expect path.existsSync "#{__dirname}/output/bar.gif"
      r.toBeTruthy()

      r = expect fs.statSync("#{__dirname}/output/bar.gif").size
      r.toEqual fs.statSync("#{__dirname}/samples/foo2.gif").size

      return



  it "should return an array containing the status of each file built", ->

    complete = false
    data = null

    runs ->
      files = [{
        source:      'spec/samples/test1.html'
        destination: 'spec/output/test-status-ok.html'
      }
      {
        source:      'spec/samples/test1.html'
        destination: 'spec/output/test-status-ok2.html'
      }
      {
        source:      'spec/samples/test1.html'
        destination: 'spec/output/'
      }]

      result = cobuild.build { files: files, type: 'test' },
        (err, result)->
          complete = true
          data = result
          return

      return

    waitsFor ->
        complete
      , 'Callback never called', 500

    runs ->
      expect(data).toBeDefined()
      expect(data[0].status).toEqual Cobuild.OK
      expect(data[1].status).toEqual Cobuild.OK
      expect(data[2].status).toEqual Cobuild.ERR
      return

    return




  it "shouldn't attempt to build files that haven't changed since the last build", ->

    complete = false
    data = null

    runs ->

      #Set the mtime on the file to now to force a r
      files = [{
        source:      'spec/samples/test1.html'
        destination: 'spec/output/test-mtime-skip.html'
      }
      {
        source:      'spec/samples/test1.html'
        destination: 'spec/output/test-mtime-skip.html'
      }
      {
        source:      'spec/samples/test1.html'
        destination: 'spec/output/test-mtime-replace.html'
      }
      {
        source:      'spec/samples/test1.html'
        destination: 'spec/output/test-mtime-replace.html'
        options:
          force: true
      }]

      result = cobuild.build { files: files, type: 'test' },
        (err, result)->
          complete = true
          data = result
          return

      return

    waitsFor ->
        complete
      , 'Callback never called', 500

    runs ->
      expect(data[1].status).toEqual Cobuild.SKIPPED
      expect(data[3].status).toEqual Cobuild.OK

      return

    return



