"use babel"

let {EventEmitter} = require("events")
let Chokidar = require("Chokidar")
let fs = require("fs-plus")
let Path = require("path")
let SearchIndex = require("search-index")
let _ = require("underscore-plus")

var createDoc = function(rootPath, filePath, fileStats) {
  var relativeFilePath = filePath.replace(new RegExp(`^${rootPath}`), "")
  var fileName = Path.basename(filePath)
  var fileExtension = Path.extname(fileName)
  var doc = {
    id: relativeFilePath,
    filePath: filePath
  }

  if(fs.existsSync(filePath)) {
    doc.fileName      = fileName
    doc.fileExtension = fileExtension
    doc.title         = Path.basename(fileName, fileExtension)
    doc.body          = fs.readFileSync(filePath, {encoding: "utf8"})
    doc.modifiedAt    = (fileStats || fs.statSync(filePath)).mtime.getTime()
  }

  return doc
}

class Documents extends EventEmitter {
  constructor(path, options={}) {
    // Must call super since this class extends EventEmitter
    super()

    // Set the documents path for easy access
    this.path = fs.normalize(path)

    // Documents will be added to this array and then processed by the search index
    this.batch = []

    // Recently edited documents
    this.recentDocuments = []

    // Is the initial load complete?
    this.loaded = false

    // Setup options with default options where needed
    this.options = {}
    this.options.recursive  = options.recursive  || false
    this.options.extensions = options.extensions || [".md", ".txt"]
    this.options.indexPath  = options.indexPath  || `${atom.config.configDirPath}/nvatom-search-index`

    // Internal count of how many documents are being watched
    this.count = 0

    // Setup the search index
    this.index = SearchIndex({indexPath: this.options.indexPath})

    // Setup path watcher and bind to watcher events
    this.watcher = Chokidar.watch(null, {
      depth: 0,
      persistent: this.options.recursive ? undefined : 0,
      ignored: (watchedPath, fileStats)=>{
        if(!fileStats) return false
        if(fileStats.isDirectory()) return false
        return !(this.options.extensions.indexOf(Path.extname(watchedPath)) > -1)
      }
    })
    // Fired when a new file (path) is detected.
    this.watcher.on("add", (documentPath, documentStat)=>{
      this.addDocument(createDoc(this.path, documentPath, documentStat))
    })
    // Fired when a file is updated.
    this.watcher.on("change", (documentPath, documentStat)=>{
      this.updateDocument(createDoc(this.path, documentPath, documentStat))
    })
    // Fired when a file is deleted.
    this.watcher.on("unlink", (documentPath)=>{
      this.removeDocument(createDoc(this.path, documentPath))
    })
    // Fired after every path being watched is announced via the "add" event
    // and the watcher is ready.
    this.watcher.on("ready", ()=>{
      // While loading each path being watched is added to a batch to be
      // indexed for search whenever the batch reaches 20 items. Calling
      // processBatch here processes the final batch of x items.
      this.processBatch().then(()=>{
        this.loaded = true
        this.emit("ready")
      })
    })

    this.watcher.add(this.path)
  }

  recent() {
    return new Promise((resolve, reject)=>{
      var retry = 10
      var resolver = setInterval(()=>{
        if(this.loaded) {
          clearTimeout(resolver)
          resolve(this.recentDocuments.slice(0, 20))
        }else if(retry > 0) {
          retry--
        }else{
          clearTimeout(resolver)
          reject("Timed out")
        }
      }, 1000)
    })
  }

  search(string) {
    return new Promise((resolve, reject)=>{
      var query = {query: {"*": string.split(" ")}}

      this.index.search(query, (err, results)=>{
        if(err) {
          reject(err)
        }else{
          resolve(results.hits.map((hit)=>{
            var doc = createDoc(this.path, `${this.path}/${hit.id}`)
            return doc
          }))
        }
      })
    })
  }

  close() {
    return new Promise((resolve, reject)=>{
      this.index.close((err)=>{
        if(err) {
          reject()
        }else{
          this.watcher.close()
          resolve()
        }
      })
    })
  }

  addDocument(doc) {
    // update internal counter
    this.count++

    // update recent
    this.updateRecent(doc)

    // add to search index
    this.addToBatch(doc)
    if(this.loaded) {
      this.processBatch().then(()=>{
        this.emit("added")
      })
    }
  }

  updateDocument(doc) {
    // update recent
    this.updateRecent(doc)

    // update search index
    this.addToBatch(doc)
    if(this.loaded) {
      this.processBatch().then(()=>{
        this.emit("updated")
      })
    }
  }

  removeDocument(doc) {
    // update internal counter
    this.count--

    // update recent
    this.recentDocuments.forEach((recentDoc, index)=>{
      if(recentDoc.filePath == doc.filePath) {
        this.recentDocuments.splice(index, 1)
      }
    })

    // remove from search index
    this.index.del(doc.id, ()=>{
      this.emit("removed")
    })
  }

  updateRecent(doc) {
    // push the doc onto the array
    this.recentDocuments.push(doc)
    // sort docs by modifiedAt descending
    this.recentDocuments = _.sortBy(this.recentDocuments, (value)=>{
      return -value.modifiedAt
    })
    // remove duplicates
    this.recentDocuments = _.uniq(this.recentDocuments, (value)=>{
      return value.id
    })
    // only keep 100 recent docs in memory
    if(this.recentDocuments.length > 100) {
      this.recentDocuments = this.recentDocuments.slice(0, 100)
    }
  }

  addToBatch(doc) {
    this.batch.push(doc)

    if(this.batch.length > 19) this.processBatch()
  }

  processBatch() {
    if(this.batch.length == 0) return Promise.resolve()

    var batch = this.batch
    this.batch = []

    return new Promise((resolve, reject)=>{
      this.index.add(batch, {}, (err)=>{
        if(err) {
          // add documents back to batch to get indexed in the future
          for(var n = 0; n < batch.length; n++) {
            this.batch.push(batch[n])
          }
          reject(err)
        }else{
          resolve()
        }
      })
    })
  }
}

module.exports = Documents
