path = require 'path'
fs = require 'fs-plus'
{CompositeDisposable, Disposable} = require 'atom'

module.exports =
  config:
    directory:
      title: 'Note Directory'
      description: 'The directory to archive notes'
      type: 'string'
      default: path.join(process.env.ATOM_HOME, 'nvatom-notes')
    extensions:
      title: 'Extensions'
      description: 'The first extension will be used for newly created notes.'
      type: 'array'
      default: ['.md', '.txt']
      items:
        type: 'string'
    enableLunrPipeline:
      title: 'Enable Lunr Pipeline'
      description: 'Lunr pipeline preprocesses query to make search faster. However, it will skip searching some of stop words such as "an" or "be".'
      type: 'boolean'
      default: true

  notationalVelocityView: null

  activate: (state) ->
    @rootDirectory = @ensureNoteDirectory()

    # Events subscribed to in atom's system can be easily cleaned up with a
    # CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace',
      'nvatom:toggle': => @createView(state).toggle()

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

    @subscriptions.add atom.workspace.onWillDestroyPaneItem ({item}) => @autosave(item) unless @autodelete(item)

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
    return unless uri.indexOf(@rootDirectory) is 0
    return unless path.extname(uri) in atom.config.get('nvatom.extensions')
    paneItem?.save?()

  autodelete: (paneItem) ->
    return false unless paneItem?.getURI?()?
    uri = paneItem.getURI()
    return false unless uri.indexOf(@rootDirectory) is 0
    return false unless path.extname(uri) in atom.config.get('nvatom.extensions')
    return false unless paneItem?.isEmpty()
    fs.unlinkSync(uri)
    noteName = uri.substring(@rootDirectory.length + 1)
    atom.notifications.addInfo("Empty note #{noteName} is deleted.")
    return true

  autosaveAll: ->
    @autosave(paneItem) for paneItem in atom.workspace.getPaneItems()

  ensureNoteDirectory: ->
    noteDirectory = fs.normalize(atom.config.get('nvatom.directory'))
    packagesDirectory = path.join(process.env.ATOM_HOME, 'packages')
    defaultNoteDirectory = path.join(packagesDirectory, 'nvatom', 'notebook')

    if noteDirectory.startsWith(packagesDirectory)
      throw new Error("Note directory #{noteDirectory} cannot reside within atom packages directory. Please change its value from package settings.")

    # Initialize note directory.
    unless fs.existsSync(noteDirectory)
      @tryMigrateFromNotationalVelocity()
      noteDirectory = atom.config.get('nvatom.directory')
      unless fs.existsSync(noteDirectory)
        fs.makeTreeSync(noteDirectory)
        fs.copySync(defaultNoteDirectory, noteDirectory)

    return fs.realpathSync(noteDirectory)

  tryMigrateFromNotationalVelocity: ->
    prevNoteDirectory = atom.config.get('notational-velocity.directory')
    currNoteDirectory = atom.config.get('nvatom.directory')
    packagesDirectory = path.join(process.env.ATOM_HOME, 'packages')
    defaultNoteDirectory = path.join(packagesDirectory, 'nvatom', 'notebook')

    # notational-velocity does not exist.
    if prevNoteDirectory is undefined
      return

    atom.notifications.addInfo('Migrating from notational-velocity package...')

    unless fs.existsSync(prevNoteDirectory)
      atom.notifications.addError("notational-velocity.directory #{prevNoteDirectory} does not exists. Migration process is failed.")
      return

    if prevNoteDirectory.startsWith(packagesDirectory)
      fs.makeTreeSync(currNoteDirectory)
      fs.copySync(prevNoteDirectory, currNoteDirectory)
    else
      if path.join(process.env.ATOM_HOME, 'nvatom-notes') == currNoteDirectory
        atom.config.set('nvatom.directory', prevNoteDirectory)

    atom.notifications.addInfo('Finished migration.')
