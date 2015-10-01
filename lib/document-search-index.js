"use babel"
let SearchIndex = require("search-index")

class DocumentSearchIndex {
  constructor(documents) {
    this.emit = (...args)=>{
      documents.emit(...args)
    }
    this.batch = []
    this.index = SearchIndex({
      indexPath: documents.options.indexPath,
      logLevel: "error"
    })

    documents.emit("index:loaded")
  }

  addToBatch(document) {
    this.batch.push(document)
    this.emit("index:documentAddedToBatch")

    if(this.batch.length > 19) this.processBatch()
  }

  processBatch() {
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
          this.emit("index:batchProcessed")
          resolve()
        }
      })
    })
  }

  search(query) {
    return new Promise((resolve, reject)=>{
      this.index.search({query: {"*": [query]}}, (err, results)=>{
        if(err) {
          reject(err)
        }else{
          this.emit("index:searchComplete", results)
          resolve(results)
        }
      })
    })
  }

  get(relativePath) {
    return new Promise((resolve, reject)=>{
      this.index.get(relativePath, (err, result)=>{
        if(err) {
          reject(err)
        }else{
          this.emit("index:getComplete", result)
          resolve(result)
        }
      })
    })
  }

  close() {
    var promise = new Promise((resolve, reject)=>{
      this.index.close((err)=>{
        if(err) {
          reject(err)
        }else{
          this.emit("index:closed")
          resolve()
        }
      })
    })

    return promise
  }
}

module.exports = DocumentSearchIndex
