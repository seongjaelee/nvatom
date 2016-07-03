fs = require 'fs'
path = require 'path'
temp = require 'temp'
NoteCache = require '../lib/note-cache'

temp.track()

String::repeat = (n) -> Array(n+1).join(this)

describe 'note cache', ->
  cache = null
  directoryPath = null

  beforeEach ->
    directoryPath = temp.mkdirSync()
    fs.writeFileSync(path.join(directoryPath, 'foo.md'), 'foo'.repeat(100))
    fs.utimesSync(path.join(directoryPath, 'foo.md'), 0, 1)
    fs.writeFileSync(path.join(directoryPath, 'bar.md'), 'bar'.repeat(100))
    fs.utimesSync(path.join(directoryPath, 'bar.md'), 0, 2)
    fs.mkdirSync(path.join(directoryPath, 'baz'))
    fs.writeFileSync(path.join(directoryPath, 'baz', 'baz.md'), 'baz'.repeat(100))
    fs.utimesSync(path.join(directoryPath, 'baz', 'baz.md'), 0, 3)
    
    cache = new NoteCache(directoryPath, 2, 100)
      .upsert('foo.md', fs.statSync(path.join(directoryPath, 'foo.md')).mtime)
      .upsert(path.join('baz', 'baz.md'), fs.statSync(path.join(directoryPath, 'baz/baz.md')).mtime)
      .upsert('bar.md', fs.statSync(path.join(directoryPath, 'bar.md')).mtime)
      .ready()
  
  it 'getNoteIds', ->
    noteIds = cache.getNoteIds()
    for noteId in ['foo.md', 'bar.md', 'baz/baz.md']
      expect(noteIds).toContain(noteId)
    expect(cache.length()).toBe(3)
  
  it 'getRecentNotes', ->
    notes = cache.getRecentNotes()
    expect(notes.length).toBe(2)
    expect(notes[0].title).toBe('baz')
    expect(notes[1].title).toBe('bar')
    
  it 'getNote', ->
    expect(cache.getNote('baz/baz.md').title).toBe('baz')
    expect(cache.getNote('bar.md').title).toBe('bar')
    expect(cache.getNote('foo.md').title).toBe('foo')
  
  it 'hasNoteId', ->
    expect(cache.hasNoteId('baz/baz.md')).toBe(true)
    expect(cache.hasNoteId('bar.md')).toBe(true)
    expect(cache.hasNoteId('foo.md')).toBe(true)
    expect(cache.hasNoteId('baz.md')).toBe(false)
  
  it 'getModifiedAt', ->    
    expect(cache.getModifiedAt('baz/baz.md')).toBe(3000)
    expect(cache.getModifiedAt('bar.md')).toBe(2000)
    expect(cache.getModifiedAt('foo.md')).toBe(1000)

  it 'adds a new note', ->
    fs.writeFileSync(path.join(directoryPath, 'moo.md'), 'moo'.repeat(100))
    fs.utimesSync(path.join(directoryPath, 'moo.md'), 0, 4)
    cache.upsert('moo.md', fs.statSync(path.join(directoryPath, 'moo.md')).mtime)
    
    expect(cache.length()).toBe(4)
    expect(cache.hasNoteId('moo.md')).toBe(true)
    expect(cache.getModifiedAt('moo.md')).toBe(4000)
    expect(cache.getRecentNotes().length).toBe(2)
    expect(cache.getRecentNotes()[0].title).toBe('moo')
    expect(cache.getNote('moo.md').title).toBe('moo')
    
  it 'updates a note not in the recent notes', ->
    fs.writeFileSync(path.join(directoryPath, 'foo.md'), 'foo'.repeat(2))
    fs.utimesSync(path.join(directoryPath, 'foo.md'), 0, 4)
    cache.upsert('foo.md', fs.statSync(path.join(directoryPath, 'foo.md')).mtime)
    
    expect(cache.length()).toBe(3)
    expect(cache.hasNoteId('foo.md')).toBe(true)
    expect(cache.getModifiedAt('foo.md')).toBe(4000)
    expect(cache.getRecentNotes().length).toBe(2)
    expect(cache.getRecentNotes()[0].title).toBe('foo')
    expect(cache.getNote('foo.md').title).toBe('foo')
    
  it 'updates a note in the recent notes', ->
    fs.writeFileSync(path.join(directoryPath, 'bar.md'), 'bar'.repeat(2))
    fs.utimesSync(path.join(directoryPath, 'bar.md'), 0, 4)
    cache.upsert('bar.md', fs.statSync(path.join(directoryPath, 'bar.md')).mtime)
    
    expect(cache.length()).toBe(3)
    expect(cache.hasNoteId('bar.md')).toBe(true)
    expect(cache.getModifiedAt('bar.md')).toBe(4000)
    expect(cache.getRecentNotes().length).toBe(2)
    expect(cache.getRecentNotes()[0].title).toBe('bar')
    expect(cache.getNote('bar.md').title).toBe('bar')
  
  it 'deletes a note not in the recent notes', ->
    fs.unlinkSync(path.join(directoryPath, 'foo.md'))
    cache.remove('foo.md')

    expect(cache.length()).toBe(2)
    expect(cache.hasNoteId('foo.md')).toBe(false)
    expect(cache.getRecentNotes().length).toBe(2)
    expect(cache.getRecentNotes()[0].title).toBe('baz')
    expect(cache.getRecentNotes()[1].title).toBe('bar')
  
  it 'deletes a note in the recent notes', ->
    cache.remove('bar.md')

    expect(cache.length()).toBe(2)
    expect(cache.hasNoteId('bar.md')).toBe(false)
    expect(cache.getRecentNotes().length).toBe(2)
    expect(cache.getRecentNotes()[0].title).toBe('baz')
    expect(cache.getRecentNotes()[1].title).toBe('foo')
  
  it 'deletes two notes', ->
    cache.remove('bar.md')
    cache.remove('foo.md')

    expect(cache.length()).toBe(1)
    expect(cache.hasNoteId('foo.md')).toBe(false)
    expect(cache.hasNoteId('bar.md')).toBe(false)
    expect(cache.getRecentNotes().length).toBe(1)
    expect(cache.getRecentNotes()[0].title).toBe('baz')

# describe 'note cache', ->
#   cache = null
#   directoryPath = null
#   
#   beforeEach ->
#     directoryPath = temp.mkdirSync()
# 
#   it 'handles cyclic symlink directories', ->
#     fs.symlinkSync(directoryPath, path.join(directoryPath, 'foo'))
#     fs.writeFileSync(path.join(directoryPath, 'foo.md'), 'foo'.repeat(100))
#     cache = new NoteCache(directoryPath, ['.md'], 2, 100)
#     expect(cache.length()).toBe(1)
#   
#   it 'handles symlink notes', ->
#     # TODO: this behavior should be same for chokidar.
#     anotherDirectoryPath = temp.mkdirSync()
#     fs.writeFileSync(path.join(anotherDirectoryPath, 'foo.md'), 'foo'.repeat(100))
#     fs.symlinkSync(path.join(anotherDirectoryPath, 'foo.md'), path.join(directoryPath, 'foo.md'))
#     fs.symlinkSync(path.join(anotherDirectoryPath, 'foo.md'), path.join(directoryPath, 'bar.md'))
#     fs.symlinkSync(anotherDirectoryPath, path.join(directoryPath, 'bar'))    
#     cache = new NoteCache(directoryPath, ['.md'], 2, 100)
#     # foo.md, bar.md, bar/foo.md
#     expect(cache.length()).toBe(3)

describe 'note cache', ->
  cache = null
  directoryPath = null

  beforeEach ->
    directoryPath = temp.mkdirSync()
    cache = new NoteCache(directoryPath, 2, 100)
      .ready()

    fs.writeFileSync(path.join(directoryPath, 'foo.md'), 'foo'.repeat(100))
    fs.utimesSync(path.join(directoryPath, 'foo.md'), 0, 1)
    fs.writeFileSync(path.join(directoryPath, 'bar.md'), 'bar'.repeat(100))
    fs.utimesSync(path.join(directoryPath, 'bar.md'), 0, 2)
    fs.mkdirSync(path.join(directoryPath, 'baz'))
    fs.writeFileSync(path.join(directoryPath, 'baz', 'baz.md'), 'baz'.repeat(100))
    fs.utimesSync(path.join(directoryPath, 'baz', 'baz.md'), 0, 3)
    cache
      .upsert('foo.md', fs.statSync(path.join(directoryPath, 'foo.md')).mtime)
      .upsert('bar.md', fs.statSync(path.join(directoryPath, 'bar.md')).mtime)
      .upsert(path.join('baz', 'baz.md'), fs.statSync(path.join(directoryPath, 'baz', 'baz.md')).mtime)
  
  it 'has all note ids', ->
    noteIds = cache.getNoteIds()
    for noteId in ['foo.md', 'bar.md', 'baz/baz.md']
      expect(noteIds).toContain(noteId)
    expect(cache.length()).toBe(3)
  
  it 'getRecentNotes', ->
    notes = cache.getRecentNotes()
    expect(notes.length).toBe(2)
    expect(notes[0].title).toBe('baz')
    expect(notes[1].title).toBe('bar')
    
  it 'getNote', ->
    expect(cache.getNote('baz/baz.md').title).toBe('baz')
    expect(cache.getNote('bar.md').title).toBe('bar')
    expect(cache.getNote('foo.md').title).toBe('foo')
  
  it 'getModifiedAt', ->    
    expect(cache.getModifiedAt('baz/baz.md')).toBe(3000)
    expect(cache.getModifiedAt('bar.md')).toBe(2000)
    expect(cache.getModifiedAt('foo.md')).toBe(1000)
