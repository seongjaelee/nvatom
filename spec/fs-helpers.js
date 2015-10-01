"use babel"
let fs = require("fs")



var fsHelpers = {
  // Recursive folder delete.
  // from https://gist.github.com/geedew/cf66b81b0bcdab1f334b
  rmdirRecursive: function(path) {
    if(fs.existsSync(path)) {
      fs.readdirSync(path).forEach(function(file, index) {
        var curPath = path + "/" + file

        if(fs.lstatSync(curPath).isDirectory()) { // recurse
          fsHelpers.rmdirRecursive(curPath)
        } else { // delete file
          fs.unlinkSync(curPath)
        }
      })

      fs.rmdirSync(path)
    }
  }
}

module.exports = fsHelpers
