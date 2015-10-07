fs = require 'fs-plus'
path = require 'path'
temp = require 'temp'
Utility = require '../lib/utility'

temp.track()

describe "utility", ->
  defaultNoteDirectory = atom.config.get('nvatom.directory')
  defaultNoteExtensions = atom.config.get('nvatom.extensions')

  afterEach ->
    atom.config.set('nvatom.directory', defaultDirectory)
    atom.config.set('nvatom.extensions', defaultNoteExtensions)

  describe 'trim', ->
    expect(Utility.trim(null)).toBe(undefined)
    expect(Utility.trim(undefined)).toBe(undefined)
    expect(Utility.trim('')).toBe('')
    expect(Utility.trim('  ')).toBe('')
    expect(Utility.trim('  hello world  ')).toBe('hello world')
    expect(Utility.trim('  hello world\t\n\r  ')).toBe('hello world')

  describe 'getPrimaryNoteExtension', ->
    atom.config.set('nvatom.extensions', ['.md', '.markdown'])
    expect(Utility.getPrimaryNoteExtension()).toBe('.md')
    atom.config.set('nvatom.extensions', ['.markdown'])
    expect(Utility.getPrimaryNoteExtension()).toBe('.markdown')
    atom.config.set('nvatom.extensions', [])
    expect(Utility.getPrimaryNoteExtension()).toBe('.md')

  describe 'isNote handles symlinks correctly', ->
    atom.config.set('nvatom.extensions', ['.md', '.markdown'])

    tempDirectoryPath = path.join(temp.mkdirSync())
    noteDirectoryPath = path.join(temp.mkdirSync())
    noteDirectoryPathSymlink = path.join(tempDirectoryPath, 'note book')
    notePath = path.join(noteDirectoryPath, 'note.md')
    notePathSymlink = path.join(noteDirectoryPathSymlink, 'note symlink.md')

    fs.writeFileSync(notePath, 'dummy')
    fs.symlinkSync(noteDirectoryPath, noteDirectoryPathSymlink)
    fs.symlinkSync(notePath, notePathSymlink)

    expect(fs.existsSync(notePath)).toBe(true)
    expect(fs.existsSync(fs.normalize(notePath))).toBe(true)

    atom.config.set('nvatom.directory', noteDirectoryPath)
    expect(Utility.isNote(notePath)).toBe(true)
    expect(Utility.isNote(notePathSymlink)).toBe(true)

    atom.config.set('nvatom.directory', noteDirectoryPathSymlink)
    expect(Utility.isNote(notePath)).toBe(true)
    expect(Utility.isNote(notePathSymlink)).toBe(true)
