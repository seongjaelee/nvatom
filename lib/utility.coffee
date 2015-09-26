path = require 'path'
fs = require 'fs-plus'

module.exports =
class Utility

  @getNotePath: (title) -> path.join(Utility.getNoteDirectory(), Utility.trim(title) + Utility.getPrimaryNoteExtension())

  @getNoteDirectory: -> fs.normalize(atom.config.get('nvatom.directory'))

  @getPrimaryNoteExtension: -> if atom.config.get('nvatom.extensions').length then atom.config.get('nvatom.extensions')[0] else '.md'

  @isNote: (filePath) -> filePath.startsWith(Utility.getNoteDirectory()) and path.extname(filePath) in atom.config.get('nvatom.extensions')

  @trim: (str) -> str?.replace /^\s+|\s+$/g, ''
