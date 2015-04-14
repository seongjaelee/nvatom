path = require 'path'
fs = require 'fs-plus'
pathWatcher = require 'pathwatcher'
Note = require './note'

module.exports =
class NoteDirectory
  constructor: (@filePath, @parent, @onChangeCallback) ->
    @directories = []
    @notes = []
    @updateMetadata()
    @watcher = pathWatcher.watch(@filePath, (event) => @onChange(event))

  destroy: ->
    @notes.map (x) -> x.destroy()
    @directories.map (x) -> x.destroy()
    @watcher.close()

  updateMetadata: ->
    @notes.map (x) -> x.destroy()
    @directories.map (x) -> x.destroy()

    @directories = []
    @notes = []

    try
      filenames = fs.readdirSync(@filePath)
    catch e
      return
    for filename in filenames
      @addChild(path.join(@filePath, filename))

  addChild: (filePath) ->
    try
      fileStat = fs.statSync(filePath)
    catch e
      return
    if fileStat.isDirectory()
      @directories.push(new NoteDirectory(filePath, this, @onChangeCallback))
    else
      if fs.isMarkdownExtension(path.extname(filePath))
        @notes.push(new Note(filePath, this, @onChangeCallback))

  getNotes: ->
    ret = []
    ret = ret.concat(@notes)
    for directory in @directories
      ret = ret.concat(directory.getNotes())
    if @parent is null
      ret.sort (x, y) -> if x.getModified().getTime() <= y.getModified().getTime() then 1 else -1
    return ret

  onChange: (event) ->
    # For the case of rename and change, it will be handled in its parent.
    if event == 'change'
      @updateMetadata()
      if @onChangeCallback != null
        @onChangeCallback()
