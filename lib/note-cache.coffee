fs = require 'fs-plus'
path = require 'path'

# Keeps a track of notes and its modified time.
#
# It caches recent notes. Note that a note may partially contain its file content. A file system watcher should call
# `upsert` and `remove` accordingly once the note cache is created.
#
# TODO: Is it a good design? On creation, it deals with file system directly. Once it is created, it relies on outer
#       feedback, instead of monitoring the file system by itself.
#
module.exports =
class NoteCache
  constructor: (@_baseDirectory, @_maxItem, @_maxNoteLength) ->
    @_maxItem = @_maxItem ? 100
    @_maxNoteLength = @_maxNoteLength ? 100
    @_noteStats = {}
    @_state = 'init'
  
  load: (noteStats) ->
    @_noteStats = noteStats
    @_state = 'cache'
    this
  
  ready: ->
    @_buildNoteSortedList()
    @_buildNoteCache()
    @_assert()
    @_state = 'ready'
    this
      
  toJSON: ->
    @_assertReady()
    JSON.stringify(@_noteStats)

  upsert: (noteId, mtime) ->
    @_noteStats[noteId] = mtime.getTime()
    return this unless @_state == 'ready'
    
    if !(noteId in @_noteSortedList)
      @_noteSortedList.push(noteId)
    # TODO: Can this be improved?
    @_noteSortedList.sort(@_noteIdCompare)
    if @_noteSortedList.indexOf(noteId) < @_maxItem
      @_noteCache[noteId] = @_buildNote(noteId)
      if @_noteSortedList.length > @_maxItem and @_noteSortedList[@_maxItem] in Object.keys(@_noteCache)
        delete @_noteCache[@_noteSortedList[@_maxItem]]
    @_assert()
    this
  
  remove: (noteId) ->
    delete @_noteStats[noteId]
    return this unless @_state == 'ready'
    
    if noteId in Object.keys(@_noteCache)
      delete @_noteCache[noteId]
      if @_noteSortedList.length > @_maxItem and !(@_noteSortedList[@_maxItem] in Object.keys(@_noteCache))
        @_noteCache[@_noteSortedList[@_maxItem]] = @_buildNote(@_noteSortedList[@_maxItem])
    @_noteSortedList.splice(@_noteSortedList.indexOf(noteId), 1)
    @_assert()
    this

  getNote: (noteId) ->
    @_assertReady()
    if noteId in @_noteCache then @_noteCache[noteId] else @_buildNote(noteId)
  
  getRecentNotes: ->
    @_assertReady()
    @_noteSortedList
      .slice(0, @_maxItem)
      .map((noteId) => @_noteCache[noteId])
  
  hasNoteId: (noteId) ->
    @_noteStats.hasOwnProperty(noteId)
    
  getNoteIds: ->
    @_noteSortedList ? Object.keys(@_noteStats)
  
  getModifiedAt: (noteId) ->
    @_noteStats[noteId]

  length: -> 
    @_assertReady()
    @_noteSortedList.length
  
  _assertReady: ->
    throw new Error "state is not ready; #{@_state}" unless @_state == 'ready'
  
  _assert: ->
    throw new Error "cache length is wrong; #{Object.keys(@_noteCache).length} #{@_noteSortedList} #{@_maxItem}" unless Object.keys(@_noteCache).length == Math.min(@_maxItem, @_noteSortedList.length)
    throw new Error 'list length is wrong' unless @_noteSortedList.length == Object.keys(@_noteStats).length
  
  _buildNoteSortedList: ->
    @_noteSortedList = Object.keys(@_noteStats)
    @_noteSortedList.sort(@_noteIdCompare)
    
  _buildNoteCache: ->
    @_noteCache = {}
    for noteId in @_noteSortedList.slice(0, @_maxItem)
      @_noteCache[noteId] = @_buildNote(noteId)
    
  _buildNote: (noteId) ->
    filePath = path.join(@_baseDirectory, noteId)
    fileName = path.basename(filePath)
    # TODO: Verify it is right
    title = path.basename(fileName, path.extname(fileName))
    body = ''
    if fs.existsSync(filePath)
      # TODO: Read just the first n letters.
      body = fs.readFileSync(filePath, 'utf8').slice(0, @_maxNoteLength)
    return { title: title, body: body, filePath: filePath, modifiedAt: fs.statSync(filePath).mtime }

  _noteIdCompare: (a, b) =>
    if @_noteStats[a] > @_noteStats[b]
      return -1
    if @_noteStats[a] < @_noteStats[b]
      return 1
    return 0