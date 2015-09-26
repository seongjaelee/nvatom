Utility = require '../lib/utility'

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
