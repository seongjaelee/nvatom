"use babel"
let fs = require("fs")
let {rmdirRecursive} = require("./fs-helpers")
let PathWatcher = require("../lib/path-watcher")

describe("PathWatcher", ()=>{
  var watcher
  var documents
  var tmpDirPath = `${__dirname}/tmp`
  var tmpFilePath = `${tmpDirPath}/foo.md`
  var tmpSubFilePath = `${tmpDirPath}/bar/baz.md`
  var watcherLoaded

  beforeEach(()=>{
    // this will get set to true when the "watcher:loaded" event fires and then
    // get reset on each test run
    watcherLoaded = false

    // setup some temporary fixture data
    fs.mkdirSync(tmpDirPath)
    fs.mkdirSync(`${tmpDirPath}/bar`)
    fs.writeFileSync(tmpSubFilePath, "# bar baz")

    // build the mock documents object
    documents = {
      path: tmpDirPath,
      options: {
        recursive: true,
        extensions: [".md", ".txt"]
      },
      emit: jasmine.createSpy("emit").andCallFake(function(event) {
        if(event == "watcher:loaded") watcherLoaded = true
      })
    }

    // and finally create the watcher instance
    watcher = new PathWatcher(documents)
  })

  afterEach(()=>{
    // close the watcher
    watcher.close()

    // remove the temporary fixture data
    if(fs.existsSync(tmpDirPath)) rmdirRecursive(tmpDirPath)
  })

  it("is defined", ()=>{
    expect(PathWatcher).toBeDefined()
  })

  it("watcher:added event fires when a file is added", ()=>{
    waitsFor(()=>{
      return watcherLoaded
    })

    runs(()=>{
      fs.writeFileSync(tmpFilePath, "# Foo")
    })

    waitsFor(()=>{
      return documents.emit.mostRecentCall.args[0] == "watcher:added"
    })

    runs(()=>{
      expect(documents.emit.mostRecentCall.args[1].path).toEqual(tmpFilePath)
    })
  })

  it("watcher:updated event fires when a file is updated", ()=>{
    waitsFor(()=>{
      return watcherLoaded
    })

    runs(()=>{
      fs.appendFileSync(tmpSubFilePath, "\nThe bar baz project is :sparkles:")
    })

    waitsFor(()=>{
      return documents.emit.mostRecentCall.args[0] == "watcher:updated"
    })

    runs(()=>{
      expect(documents.emit.mostRecentCall.args[1].path).toEqual(tmpSubFilePath)
    })
  })

  it("watcher:deleted event fires when a file is deleted", ()=>{
    waitsFor(()=>{
      return watcherLoaded
    })

    runs(()=>{
      fs.unlinkSync(tmpSubFilePath)
    })

    waitsFor(()=>{
      return documents.emit.mostRecentCall.args[0] == "watcher:deleted"
    })

    runs(()=>{
      expect(documents.emit.mostRecentCall.args[1].path).toEqual(tmpSubFilePath)
    })
  })

  describe("tilde", ()=>{
    it("expands path", ()=>{
      var watcher = new PathWatcher(documents)
      var homeDir = process.env[(process.platform == 'win32') ? 'USERPROFILE' : 'HOME']

      expect(homeDir.length).toBeGreaterThan(0)
      expect(watcher.tilde("~/")).toEqual(homeDir)
      expect(watcher.tilde("~/foo/bar")).toMatch(`${homeDir}/foo/bar`)
      expect(watcher.tilde("~/foo bar/baz")).toMatch(`${homeDir}/foo bar/baz`)
    })
  })
})
