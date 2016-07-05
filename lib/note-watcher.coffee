chokidar = require 'chokidar'
fs = require 'fs'
lunr = require 'lunr'
path = require 'path'
_ = require 'underscore-plus'
zlib = require 'zlib'
{EventEmitter} = require 'events'
NoteCache = require './note-cache'

module.exports =
class NoteWatcher extends EventEmitter
  @cacheVersion = 0
  
  constructor: (@_baseDirectory, @_extensions, @_maxItems, @_enableLunrPipeline) ->
    @_maxItems = @_maxItems ? 100
    @_extensions = @_extensions ? ['.txt', '.md']
    @_enableLunrPipeline = @_enableLunrPipeline ? false
    @_noteCache = new NoteCache(@_baseDirectory, @_maxItems)
    @_restoreSearchIndex() || @_initSearchIndex()
    @_startWatcher()

  save: ->
    return unless @_state == 'ready'
    cache = {
      baseDirectory: @_baseDirectory,
      extensions: @_extensions,
      enableLunrPipeline: @_enableLunrPipeline,
      version: @_cacheVersion,
      searchIndex: JSON.stringify(@_searchIndex),
      noteCache: @_noteCache.toJSON(),
    }
    fs.writeFileSync(
      path.join(@_baseDirectory, 'nvatom.cache'), 
      zlib.deflateSync(JSON.stringify(cache)))
  
  close: ->
    @_watcher?.close()
  
  search: (query) ->
    if query? and query.length > 0
      return @_searchIndex.search(query)
        .slice(0, @_maxItems)
        .map((x) => @_noteCache.getNote(x.ref))
    else
      return @_noteCache.getRecentNotes()
  
  length: -> 
    @_noteCache.length()
    
  _initSearchIndex: ->
    @_state = 'initializing'
    @_searchIndex = lunr(() ->
      @field('title', { boost: 10 })
      @field('body')
    )
    if !@_enableLunrPipeline
      @_searchIndex.pipeline.reset()
  
  _restoreSearchIndex: ->
    cacheFilePath = path.join(@_baseDirectory, 'nvatom.cache')
    return false unless fs.existsSync(cacheFilePath)
    cache = JSON.parse(zlib.inflateSync(fs.readFileSync(cacheFilePath)))
    return false if cache == null
    return false unless _.isEqual(cache.baseDirectory, @_baseDirectory)
    return false unless _.isEqual(cache.extensions, @_extensions)
    return false unless _.isEqual(cache.enableLunrPipeline, @_enableLunrPipeline)
    return false unless _.isEqual(cache.version, @_cacheVersion)
    @_searchIndex = lunr.Index.load(JSON.parse(cache.searchIndex))
    # TODO: Make this as an interface. Old note cache does not have to know upsert, remove, ready and so on.
    #       It only needs to know getNoteIds, hasNoteId, and getModifiedAt.
    @_oldNoteCache = new NoteCache(@_baseDirectory, @_maxItems).load(JSON.parse(cache.noteCache))
    @_state = 'recovering'
    return true

  _startWatcher: ->
    options = {
      ignored: (filePath, fileStat) =>
        if fileStat?.isFile() then @_extensions.indexOf(path.extname(filePath)) < 0 else false
    }
    
    @_watcher = chokidar
      .watch @_baseDirectory, options
      .on 'add', (args) => @_add(args)
      .on 'change', (args) => @_change(args)
      .on 'unlink', (args) => @_unlink(args)
      .on 'ready', () => @_ready()

  _add: (filePath) ->
    @_noteCache.upsert(@_toNoteId(filePath), fs.statSync(filePath).mtime)
    if @_state != 'recovering'
      @_searchIndex.add(@_toFileDetails(filePath))
    @emit 'update', filePath
  
  _change: (filePath) ->
    @_noteCache.upsert(@_toNoteId(filePath), fs.statSync(filePath).mtime)
    if @_state != 'recovering'
      @_searchIndex.update(@_toFileDetails(filePath))
    @emit 'update', filePath
  
  _unlink: (filePath) ->
    @_noteCache.remove(@_toNoteId(filePath))
    if @_state != 'recovering'
      @_searchIndex.remove(@_toFileDetails(filePath))
    @emit 'update', filePath
  
  _ready: () -> 
    @_noteCache.ready()
    if @_state == 'recovering'
      @_updateSearchIndex(@_oldNoteCache, @_noteCache)
      delete @_oldNoteCache
    @_state = 'ready'
    @emit 'ready'
  
  _updateSearchIndex: (oldNoteCache, newNoteCache) ->
    for noteId in oldNoteCache.getNoteIds()
      if !newNoteCache.hasNoteId(noteId)
        @_searchIndex.remove(@_toFileDetails(@_toFilePath(noteId)))
      else if oldNoteCache.getModifiedAt(noteId) <= newNoteCache.getModifiedAt(noteId)
        @_searchIndex.update(@_toFileDetails(@_toFilePath(noteId)))
    for noteId in newNoteCache.getNoteIds()
      if !oldNoteCache.hasNoteId(noteId)
        @_searchIndex.add(@_toFileDetails(@_toFilePath(noteId)))
  
  _toNoteId: (filePath) ->
    path.relative(@_baseDirectory, filePath)
  
  _toFilePath: (noteId) ->
    path.join(@_baseDirectory, noteId)
  
  _toFileDetails: (filePath) ->
    fileName = path.basename(filePath)
    return {
      id: @_toNoteId(filePath),
      title: path.basename(fileName, path.extname(fileName)),
      body: if fs.existsSync(filePath) then fs.readFileSync(filePath, { encoding: 'utf8' }) else ''
    }