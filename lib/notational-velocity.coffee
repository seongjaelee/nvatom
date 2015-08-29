path = require 'path'
fs = require 'fs-plus'
{CompositeDisposable, Disposable} = require 'atom'

module.exports =
  config:
    directory:
      title: 'Note Directory'
      description: 'The directory to archive notes'
      type: 'string'
      default: process.env.ATOM_HOME + '/packages/notational-velocity/notebook'

  notationalVelocityView: null

  activate: (state) ->
    @rootDirectory = fs.realpathSync(atom.config.get('notational-velocity.directory'))

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
