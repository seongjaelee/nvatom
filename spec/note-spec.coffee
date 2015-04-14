path = require 'path'
fs = require 'fs-plus'
temp = require 'temp'
pathWatcher = require 'pathwatcher'
Note = require '../lib/note'

describe 'Note', ->
  defaultDirectory = atom.config.get('notational-velocity.directory')
  tempDirectory = temp.mkdirSync('node-pathwatcher-directory')
  tempFilePath = path.join(tempDirectory, 'Temp.md')

  beforeEach ->
    atom.config.set('notational-velocity.directory', tempDirectory)
    fs.writeFileSync(tempFilePath, 'old')

  afterEach ->
    fs.unlinkSync(tempFilePath)
    atom.config.set('notational-velocity.directory', defaultDirectory)

  it 'creates a note', ->
    note = new Note(tempFilePath, null, null)
    expect(note.getTitle()).toBe 'Temp'
    expect(note.getText()).toBe 'old'
    expect(note.getFilePath()).toBe tempFilePath
    note.destroy()

  it 'modifies a note', ->
    note = new Note(tempFilePath, null, null)
    expect(note.getText()).toBe 'old'

    fs.writeFileSync(tempFilePath, 'new')
    oldModified = note.getModified()
    waitsFor -> oldModified != note.getModified()
    runs ->
      expect(note.getText()).toBe 'new'
      note.destroy()
