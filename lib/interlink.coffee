fs = require 'fs-plus'
path = require 'path'
{CompositeDisposable} = require 'atom'
Utility = require './utility'

module.exports =
class Interlink
  constructor: ->
    Interlink.loadGrammarSync()
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace', 'nvatom:openInterlink': => Interlink.openInterlink()
    @subscriptions.add atom.workspace.observeTextEditors (editor) ->
      if Utility.isNote(editor.getPath())
        editor.setGrammar(atom.grammars.grammarForScopeName('source.gfm.nvatom'))

  destroy: ->
    @subscriptions.dispose()

  @loadGrammarSync: ->
    unless atom.grammars.grammarForScopeName('source.gfm.nvatom')
      grammarPath = path.join(atom.packages.resolvePackagePath('nvatom'), 'grammars', 'nvatom.cson')
      atom.grammars.loadGrammarSync(grammarPath)

  @openInterlink: ->
    editor = atom.workspace.getActiveTextEditor()
    return unless editor?
    return unless Utility.isNote(editor.getPath())

    noteTitle = Interlink.getInterlinkUnderCursor(editor)
    return unless noteTitle?
    return unless noteTitle.length

    notePath = Utility.getNotePath(noteTitle)

    unless fs.existsSync(notePath)
      fs.writeFileSync(notePath, '')
    atom.workspace.open(notePath)

  @getInterlinkUnderCursor: (editor) ->
    cursorPosition = editor.getCursorBufferPosition()
    token = editor.tokenForBufferPosition(cursorPosition)
    return unless token
    return unless token.value
    return unless token.scopes.indexOf('markup.underline.link.interlink.gfm') > -1

    interlink = Utility.trim(token.value)
    return unless interlink.length
    return interlink
