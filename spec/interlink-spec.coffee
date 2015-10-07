fs = require 'fs-plus'
path = require 'path'
temp = require 'temp'
Interlink = require '../lib/interlink'

temp.track()

describe 'Interlink', ->
  defaultDirectory = atom.config.get('nvatom.directory')
  noteDirectory = null

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    noteDirectory = temp.mkdirSync()

    atom.config.set('nvatom.directory', noteDirectory)

    waitsForPromise ->
      atom.packages.activatePackage('nvatom')

  afterEach ->
    atom.config.set('nvatom.directory', defaultDirectory)

  describe 'when getInterlinkUnderCursor is called', ->
    editor = null

    describe 'under the note directory', ->
      beforeEach ->
        waitsForPromise ->
          atom.workspace.open(path.join(noteDirectory, 'Interlink.md')).then (o) -> editor = o

      it 'returns a trimmed interlink text', ->
        testdata = [
          { position: [0, 2], text: '[[Car]]', expected: 'Car' },
          { position: [0, 2], text: '[[Notational Velocity]]', expected: 'Notational Velocity' },
          { position: [0, 2], text: '[[한글 Alphabet Test]]', expected: '한글 Alphabet Test' },
          { position: [0, 2], text: '[[ Car ]]', expected: 'Car' },
          { position: [0, 2], text: '[[Car/Mini]]', expected: 'Car/Mini' },
        ]

        for testitem in testdata
          editor.setText testitem.text
          editor.setCursorBufferPosition testitem.position
          expect(Interlink.getInterlinkUnderCursor(editor)).toBe testitem.expected

      it 'returns undefined for invalid text', ->
        testdata = [
          { position: [0, 2], text: '[[]]' },
          { position: [0, 3], text: '[[]]' },
          { position: [0, 2], text: '[[   ]]' },
          { position: [0, 1], text: '[Car]' },
          { position: [0, 2], text: '[[[Car]]]' },
          { position: [0, 2], text: '[[Car]' },
          { position: [0, 2], text: '[[Car]]]' },
          { position: [0, 1], text: 'Car' },
        ]

        for testitem in testdata
          editor.setText testitem.text
          editor.setCursorBufferPosition testitem.position
          expect(Interlink.getInterlinkUnderCursor(editor)).toBe undefined

    describe 'under a random directory', ->
      beforeEach ->
        waitsForPromise ->
          atom.workspace.open(path.join(temp.mkdirSync(), 'Interlink.md')).then (o) -> editor = o

      it 'does not apply the grammar', ->
        editor.setText '[[Car]]'
        editor.setCursorBufferPosition [0, 2]
        expect(Interlink.getInterlinkUnderCursor(editor)).toBe undefined

  describe 'when openInterlink is called', ->
    describe 'when the editor path is under the note directory', ->
      editor = null

      beforeEach ->
        waitsForPromise ->
          atom.workspace.open(path.join(noteDirectory, 'Interlink.md')).then (o) -> editor = o

      it 'opens the referred notes', ->
        editor.setText '[[Car]]'
        editor.setCursorBufferPosition [0, 2]

        editorPromise = Interlink.openInterlink()
        expect(editorPromise).not.toBe undefined
        waitsForPromise ->
          editorPromise

        runs ->
          expect(atom.workspace.getActiveTextEditor().getPath().endsWith('Car.md')).toBe true

    describe 'when the editor path is not under the note directory', ->
      editor = null

      beforeEach ->
        waitsForPromise ->
          atom.workspace.open(path.join(temp.mkdirSync(), 'Interlink.md')).then (o) -> editor = o

      it 'does nothing', ->
        editor.setText '[[Car]]'
        editor.setCursorBufferPosition [0, 2]

        editorPromise = Interlink.openInterlink()
        expect(editorPromise).toBe undefined
