fs = require 'fs-plus'
{CompositeDisposable} = require 'atom'
Utility = require './utility'

module.exports =
class NoteLink
  constructor: ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace', 'nvatom:openInterlink': => @openInterlink()

  destroy: ->
    @subscriptions.dispose()

  openInterlink: ->
    editor = atom.workspace.getActiveTextEditor()
    return unless editor?
    return unless Utility.isNote(editor.getPath())

    noteTitle = @getInterlinkUnderCursor(editor)
    return unless noteTitle?
    return unless noteTitle.length

    notePath = Utility.getNotePath(noteTitle)

    unless fs.existsSync(notePath)
      fs.writeFileSync(notePath, '')
    atom.workspace.open(notePath)

  getInterlinkUnderCursor: (editor) ->
    cursorPosition = editor.getCursorBufferPosition()
    token = editor.tokenForBufferPosition(cursorPosition)
    return unless token
    return unless token.value
    return unless token.scopes.indexOf('markup.underline.link.interlink.gfm') > -1

    return token.value
