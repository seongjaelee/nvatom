path = require 'path'
fs = require 'fs'
chokidar = require 'chokidar'

module.exports =
class Note
  constructor: (@filePath, @parent, @onChangeCallback) ->
    @updateMetadata()
    @updateText()
    @watcher = chokidar.watch(@filePath).on('all', (event) => @onChange(event))

  destroy: ->
    @watcher.close()

  updateMetadata: ->
    @modified = fs.statSync(@filePath).mtime
    relativePath = path.relative(atom.config.get('notational-velocity.directory'), @filePath)
    @title = path.join(
      path.dirname(relativePath),
      path.basename(relativePath, path.extname(relativePath))
    )

  updateText: ->
    @text = fs.readFileSync(@filePath, 'utf8')

  onChange: (event) ->
    # For the case of rename and change, it will be handled in its parent.
    if event == 'change' && fs.existsSync(@filePath)
      @updateMetadata()
      @updateText()
      if @onChangeCallback != null
        @onChangeCallback()

  getTitle: -> @title
  getText: -> @text
  getModified: -> @modified
  getFilePath: -> @filePath
