"use babel"
let fs = require("fs")
let {rmdirRecursive} = require("./fs-helpers")
let DocumentSearchIndex = require("../lib/document-search-index")

describe("DocumentSearchIndex", ()=>{
  var index
  var documents
  var tmpSearchIndexPath = `${__dirname}/tmp`

  // setup some note fixture data
  var notes = [
    {
      id: "Christmas present ideas.md",
      title: "Christmas present ideas",
      body: "* radio flyer wagon\n* mini ipad",
      modifiedAt: new Date().getTime() - 3600000
    },
    {
      id: "favorites/Movies.md",
      title: "Movies",
      body: "* grosse point blank\n* star wars",
      modifiedAt: new Date().getTime() - 1800000
    },
    {
      id: "letters/2015-09-30_adalyn.md",
      title: "2015-09-30_adalyn",
      body: "Dear Adalyn, I can't wait until you can read this someday.",
      modifiedAt: new Date().getTime() - 900000
    }
  ]

  beforeEach(()=>{
    // build the mock documents object
    documents = {
      options: {
        indexPath: tmpSearchIndexPath
      },
      emit: jasmine.createSpy("emit")
    }

    // and finally create the index instance
    index = new DocumentSearchIndex(documents)
  })

  afterEach(()=>{
    waitsForPromise(()=>{
      return index.close()
    })

    runs(()=>{
      rmdirRecursive(tmpSearchIndexPath)
    })
  })

  it("is defined", ()=>{
    expect(DocumentSearchIndex).toBeDefined()
  })

  describe("addToBatch", ()=>{
    it("adds document to batch", ()=>{
      expect(index.batch.length).toEqual(0)
      index.addToBatch(notes[0])
      expect(index.batch.length).toEqual(1)
    })

    it("processes batch when it reaches 20", ()=>{
      spyOn(index, "processBatch")

      for(var n = 0; n < 20; n++) {
        index.addToBatch(notes[0])
      }

      expect(index.processBatch).toHaveBeenCalled();
    })
  })

  describe("processBatch", ()=>{
    var testResults

    beforeEach(()=>{
      index.addToBatch(notes[0])
      index.addToBatch(notes[1])
      index.addToBatch(notes[2])
    })

    it("indexes batch of documents", ()=>{
      waitsForPromise(()=>{
        return index.processBatch()
      })

      runs(()=>{
        expect(documents.emit).toHaveBeenCalledWith("index:batchProcessed")
      })
    })
  })

  describe("get", ()=>{
    beforeEach(()=>{
      index.addToBatch(notes[0])
      index.addToBatch(notes[1])
      index.addToBatch(notes[2])

      waitsForPromise(()=>{
        return index.processBatch()
      })
    })

    it("returns partial document from index", ()=>{
      waitsForPromise(()=>{
        return index.get("favorites/Movies.md").then((result)=>{
          testResults = result
        })
      })

      runs(()=>{
        expect(testResults.id).toEqual(notes[1].id)
        expect(testResults.title).toEqual(notes[1].title)
        expect(testResults.body).toEqual(notes[1].body)
        expect(testResults.modifiedAt).toEqual(notes[1].modifiedAt)
      })
    })
  })

  describe("search", ()=>{
    beforeEach(()=>{
      index.addToBatch(notes[0])
      index.addToBatch(notes[1])
      index.addToBatch(notes[2])

      waitsForPromise(()=>{
        return index.processBatch()
      })
    })

    it("returns search results", ()=>{
      waitsForPromise(()=>{
        return index.search("movies").then((results)=>{
          testResults = results
        })
      })

      runs(()=>{
        expect(testResults.totalHits).toEqual(1)
        expect(testResults.hits[0].id).toEqual("favorites/Movies.md")
      })
    })
  })
})
