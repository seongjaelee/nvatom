path = require 'path'
fs = require 'fs-plus'
{CompositeDisposable, Disposable} = require 'atom'

module.exports =
  config:
    directory:
      title: 'Note Directory'
      description: 'The directory to archive notes'
      type: 'string'
      default: path.join(process.env.ATOM_HOME, 'notational-velocity-notes')

  notationalVelocityView: null

  activate: (state) ->
    @rootDirectory = @ensureNoteDirectory()

    # Events subscribed to in atom's system can be easily cleaned up with a
    # CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace',
      'notational-velocity:toggle': => @createView(state).toggle()

    handleBeforeUnload = @autosaveAll.bind(this)
    window.addEventListener('beforeunload', handleBeforeUnload, true)
    @subscriptions.add new Disposable -> window.removeEventListener('beforeunload', handleBeforeUnload, true)

    handleBlur = (event) =>
      if event.target is window
        @autosaveAll()
      else if event.target.matches('atom-text-editor:not([mini])') and not event.target.contains(event.relatedTarget)
        @autosave(event.target.getModel())
    window.addEventListener('blur', handleBlur, true)
    @subscriptions.add new Disposable -> window.removeEventListener('blur', handleBlur, true)

    @subscriptions.add atom.workspace.onWillDestroyPaneItem ({item}) => @autosave(item)

  deactivate: ->
    @subscriptions.dispose()
    @notationalVelocityView.destroy()

  serialize: ->
    notationalVelocityViewState: @notationalVelocityView.serialize()

  createView: (state, docQuery) ->
    unless @notationalVelocityView?
      NotationalVelocityView = require './notational-velocity-view'
      @notationalVelocityView = new NotationalVelocityView(state.notationalVelocityViewState)
    @notationalVelocityView

  autosave: (paneItem) ->
    return unless paneItem?.getURI?()?
    return unless paneItem?.isModified?()
    uri = paneItem.getURI()
    return unless uri.indexOf(@rootDirectory) == 0
    return unless fs.isMarkdownExtension(path.extname(uri))
    paneItem?.save?()

  autosaveAll: ->
    @autosave(paneItem) for paneItem in atom.workspace.getPaneItems()

  ensureNoteDirectory: ->
    noteDirectory = atom.config.get('notational-velocity.directory')
    packagesDirectory = path.join(process.env.ATOM_HOME, 'packages')
    defaultNoteDirectory = path.join(packagesDirectory, 'notational-velocity', 'notebook')

    if noteDirectory.startsWith(packagesDirectory)
      storageDirectory = path.join(packagesDirectory, 'storage')
      throw new Error("""
          The note directory (#{noteDirectory}) should NOT nest under #{packagesDirectory}.
          It is likely that you updated the package to a newer version from v0.1.0.
          It is likely that the note directory is overwritten.
          Unfortunately, I couldn't find a way to recover overwritten notes.
          You might recover partial notes from #{storageDirectory}.
          I am extremely sorry.
          - Seongjae Lee""")

    if !fs.existsSync(noteDirectory)
      fs.makeTreeSync(noteDirectory)
      fs.copySync(defaultNoteDirectory, noteDirectory)

    return fs.realpathSync(noteDirectory)
