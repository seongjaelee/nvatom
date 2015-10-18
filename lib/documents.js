"use babel"

let {EventEmitter} = require("events")
let Chokidar = require("Chokidar")
let fs = require("fs")
let Path = require("path")
let SearchIndex = require("search-index")

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
    this.path = this.tilde(path)

    // Documents will be added to this array and then processed by the search index
    this.batch = []

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
        this.emit("documents:loaded")
        this.log("documents: loaded")
      })
    })

    this.watcher.add(this.path)
  }

  tilde(path) {
    if(path && path[0] == "~") {
      var homeDir = process.env[(process.platform == 'win32') ? 'USERPROFILE' : 'HOME'];

      if(path == "~/") {
        return homeDir
      }else{
        return path.replace(/^~/, homeDir)
      }
    }else{
      return path
    }
  }

  // get recent() {
  //   return Promise.resolve(recentDocuments.slice(0, 20))
  // }

  search(string) {
    return new Promise((resolve, reject)=>{
      var query = {query: {"*": string.split(" ")}}

      this.index.search(query, (err, results)=>{
        if(err) {
          this.log("search: failed")
          reject(err)
        }else{
          this.log(`search: '${string}' returned ${results.totalHits} hits`)
          resolve(results.hits)
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
          this.log("close:")
          resolve()
        }
      })
    })
  }

  addDocument(doc) {
    // update internal counter
    this.count++

    // update recent
    // this.recentDocuments.add(document)

    this.log(`addDocument: ${doc.title}`)
    // add to search index
    this.addToBatch(doc)
    if(this.loaded) {
      this.processBatch().then(()=>{
        this.emit("documents:added")
      })
    }
    // emit event
  }

  updateDocument(doc) {
    // update recent
    // this.recentDocuments.update(doc)

    // update search index
    this.log(`updateDocument: ${doc.title}`)
    this.addToBatch(doc)
    if(this.loaded) {
      this.processBatch().then(()=>{
        this.emit("documents:updated")
      })
    }
    // emit event
  }

  removeDocument(doc) {
    // update internal counter
    this.count--

    // update recent
    // this.recentDocuments.remove(document)
    this.log(`removeDocument: ${doc.title}`)
    this.index.del(doc.id, ()=>{
      this.emit("documents:removed")
    })

    // remove from search index
    // emit event
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
          this.log("processBatch: failed")
          reject(err)
        }else{
          this.log(`processBatch: successfully processed ${batch.length} documents`)
          resolve()
        }
      })
    })
  }

  log(string) {
    console.log(string)
  }
}

module.exports = Documents
