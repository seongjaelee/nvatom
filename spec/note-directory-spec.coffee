path = require 'path'
fs = require 'fs-plus'
temp = require 'temp'
pathWatcher = require 'pathwatcher'
NoteDirectory = require '../lib/note-directory'
Note = require '../lib/note'

describe 'NoteDirectory.getNotes', ->
  defaultDirectory = atom.config.get('notational-velocity.directory')
  tempDirectory = temp.mkdirSync('node-pathwatcher-directory')
  noteDirectory = null
  isCallbackCalled = false

  # We don't want to let the mtimes of two consecutively create files are same.
  # This function ensures the mtime of the file created before calling this function to be always
  # smaller than to the mtime of the file created after calling this function.
  wait = ->
    timestampDirectory = temp.mkdirSync('node-pathwatcher-timestamp')
    filePath = path.join(timestampDirectory, 'temp')
    fs.writeFileSync(filePath, '.')
    mtimeOld = fs.statSync(filePath).mtime
    mtimeNew = mtimeOld
    while mtimeOld >= mtimeNew
      fs.writeFileSync(filePath, '.')
      mtimeNew = fs.statSync(filePath).mtime

  beforeEach ->
    isCallbackCalled = false
    callback = => isCallbackCalled = true

    atom.config.set('notational-velocity.directory', tempDirectory)

    fs.writeFileSync(path.join(tempDirectory, 'Readme.md'), 'read me')
    wait()

    fs.mkdirSync(path.join(tempDirectory, 'Car'))
    fs.writeFileSync(path.join(tempDirectory, 'Car', 'Mini.md'), 'mini')
    wait()

    noteDirectory = new NoteDirectory(tempDirectory, null, callback)

  afterEach ->
    noteDirectory.destroy()
    fs.unlinkSync(path.join(tempDirectory, 'Car', 'Mini.md'))
    fs.rmdirSync(path.join(tempDirectory, 'Car'))
    fs.unlinkSync(path.join(tempDirectory, 'Readme.md'))
    atom.config.set('notational-velocity.directory', defaultDirectory)

  it 'gives a list of notes in the order so that the newest one comes first', ->
    notes = noteDirectory.getNotes()
    expect(notes.length).toEqual(2)
    expect(notes[0].getText()).toBe 'mini'
    expect(notes[1].getText()).toBe 'read me'
    expect(notes[0].getModified().getTime()).toBeGreaterThan(notes[1].getModified().getTime())

  it 'changes its order when a note is changed', ->
    fs.writeFileSync(path.join(tempDirectory, 'Readme.md'), 'read me new')
    wait()

    waitsFor -> isCallbackCalled
    runs ->
      notes = noteDirectory.getNotes()
      expect(notes[0].getText()).toBe 'read me new'
      expect(notes[1].getText()).toBe 'mini'

  it 'changes its order when a note is created', ->
    fs.writeFileSync(path.join(tempDirectory, 'Car', 'Prius.md'), 'prius')
    wait()

    waitsFor -> isCallbackCalled
    runs ->
      notes = noteDirectory.getNotes()
      expect(notes.length).toEqual(3)
      expect(notes[0].getText()).toBe 'prius'
      expect(notes[1].getText()).toBe 'mini'
      expect(notes[2].getText()).toBe 'read me'
      fs.unlinkSync(path.join(tempDirectory, 'Car', 'Prius.md'))

  it 'changes its order when a note is deleted', ->
    fs.unlinkSync(path.join(tempDirectory, 'Car', 'Mini.md'))
    wait()

    waitsFor -> isCallbackCalled
    runs ->
      notes = noteDirectory.getNotes()
      expect(notes.length).toEqual(1)
      expect(notes[0].getText()).toBe 'read me'
      # So that it won't spit an error in the teardown stage.
      fs.writeFileSync(path.join(tempDirectory, 'Car', 'Mini.md'), 'mini')

  it 'changes its order when a note is renamed', ->
    oldPath = path.join(tempDirectory, 'Car', 'Mini.md')
    newPath = path.join(tempDirectory, 'Mini.md')
    fs.renameSync(oldPath, newPath)
    wait()

    waitsFor -> isCallbackCalled
    runs ->
      notes = noteDirectory.getNotes()
      expect(notes.length).toEqual(2)
      expect(notes[0].getTitle()).toBe 'Mini'
      expect(notes[1].getTitle()).toBe 'Readme'
      # So that it won't spit an error in the teardown stage.
      fs.renameSync(newPath, oldPath)

  it 'updates properly when a directory is created and a note is created inside it', ->
    fs.mkdirSync(path.join(tempDirectory, 'Food'))
    fs.writeFileSync(path.join(tempDirectory, 'Food', 'Milk.md'), 'milk')
    wait()
    waitsFor -> isCallbackCalled
    runs ->
      notes = noteDirectory.getNotes()
      expect(notes.length).toEqual(3)
      expect(notes[0].getText()).toBe 'milk'
      # So that it won't spit an error in the teardown stage.
      fs.unlinkSync(path.join(tempDirectory, 'Food', 'Milk.md'))
      fs.rmdirSync(path.join(tempDirectory, 'Food'))
