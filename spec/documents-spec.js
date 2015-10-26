"use babel"

let fs = require("fs")
let Documents = require("../lib/documents")
let {rmdirRecursive} = require("./fs-helpers")

describe("Documents", ()=>{
  var testDataPath = `${__dirname}/../testdata`
  var tmpFilePath = `${testDataPath}/foo.md`
  var tmpSearchIndexPath = `${__dirname}/tmp-index`
  var options = {indexPath: tmpSearchIndexPath, recursive: true}
  var documents
  var documentsLoaded = false

  beforeEach(()=>{
    documents = new Documents(testDataPath, options)
    documents.on("ready", ()=>{
      documentsLoaded = true
    })

    waitsFor(()=>{
      return documentsLoaded
    })
  })

  afterEach(()=>{
    waitsForPromise(()=>{
      return documents.close()
    })

    runs(()=>{
      rmdirRecursive(tmpSearchIndexPath)
      documentsLoaded = false
    })
  })

  describe("search", ()=>{
    it("returns results for existing documents", ()=>{
      waitsForPromise(()=>{
        return documents.search("atom free").then((results)=>{
          expect(results.length).toEqual(1)
        })
      })
    })

    it("returns updated results as files are added, updated, and removed", ()=>{
      var fileAdded = false
      var fileUpdated = false
      var fileRemoved = false

      waitsForPromise(()=>{
        return documents.search("foo").then((results)=>{
          expect(results.length).toEqual(0)
        })
      })

      runs(()=>{
        documents.on("added", ()=>{
          fileAdded = true
        })
        fs.writeFileSync(tmpFilePath, "# Foo")
      })

      waitsFor(()=>{
        return fileAdded
      })

      waitsForPromise(()=>{
        return documents.search("foo").then((results)=>{
          expect(results.length).toEqual(1)
        })
      })

      waitsForPromise(()=>{
        return documents.search("bar").then((results)=>{
          expect(results.length).toEqual(0)
        })
      })

      runs(()=>{
        documents.on("updated", ()=>{
          fileUpdated = true
        })
        fs.appendFileSync(tmpFilePath, "## Bar")
      })

      waitsFor(()=>{
        return fileUpdated
      })

      waitsForPromise(()=>{
        return documents.search("bar").then((results)=>{
          expect(results.length).toEqual(1)
        })
      })

      runs(()=>{
        documents.on("removed", ()=>{
          fileRemoved = true
        })
        fs.unlinkSync(tmpFilePath)
      })

      waitsFor(()=>{
        return fileRemoved
      })

      waitsForPromise(()=>{
        return documents.search("foo").then((results)=>{
          expect(results.length).toEqual(0)
        })
      })

      waitsForPromise(()=>{
        return documents.search("bar").then((results)=>{
          expect(results.length).toEqual(0)
        })
      })
    })
  })

  describe("recent", ()=>{
    it("returns documents sorted by updated timestamp", ()=>{
      waitsForPromise(()=>{
        return documents.recent().then((recentDocuments)=>{
          expect(recentDocuments.length).toEqual(4)
        })
      })
    })
  })
})
