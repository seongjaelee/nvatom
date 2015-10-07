path = require 'path'
fs = require 'fs-plus'

module.exports =
class Utility

  @getNotePath: (title) -> path.join(Utility.getNoteDirectory(), Utility.trim(title) + Utility.getPrimaryNoteExtension())

  @getNoteDirectory: -> fs.normalize(atom.config.get('nvatom.directory'))

  @getPrimaryNoteExtension: -> if atom.config.get('nvatom.extensions').length then atom.config.get('nvatom.extensions')[0] else '.md'

  @isNote: (filePath) ->
    return false unless path.extname(filePath) in atom.config.get('nvatom.extensions')

    filePath = fs.normalize(filePath)
    return true if filePath.startsWith(Utility.getNoteDirectory())
    return true if filePath.startsWith(fs.realpathSync(Utility.getNoteDirectory()))
    return false unless fs.existsSync(filePath)

    filePath = fs.realpathSync(filePath)
    return true if filePath.startsWith(Utility.getNoteDirectory())
    return true if filePath.startsWith(fs.realpathSync(Utility.getNoteDirectory()))
    return false

  @trim: (str) -> str?.replace /^\s+|\s+$/g, ''
