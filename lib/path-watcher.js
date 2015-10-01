"use babel"

let chokidar = require("chokidar")
let path = require("path")

class PathWatcher {
  constructor(documents) {
    this.emit = (...args)=>{
      documents.emit(...args)
    }

    this.watcher = chokidar.watch(null, {
      depth: documents.options.recursive ? undefined : 0,
      persistent: true,
      ignored: (watchedPath, fileStats)=>{
        if(!fileStats) return false
        if(fileStats.isDirectory()) return false
        return !(documents.options.extensions.indexOf(path.extname(watchedPath)) > -1)
      }
    })

    this.watcher.on("add", (path, stat)=>{
      this.emit("watcher:added", {path: path, stat: stat})
    })

    this.watcher.on("change", (path, stat)=>{
      this.emit("watcher:updated", {path: path, stat: stat})
    })

    this.watcher.on("unlink", (path)=>{
      this.emit("watcher:deleted", {path: path})
    })

    this.watcher.on("ready", ()=>{
      documents.emit("watcher:loaded")
    })

    this.watcher.add(this.tilde(documents.path))
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

  close() {
    this.watcher.close()
  }
}

module.exports = PathWatcher
