{CompositeDisposable} = require 'atom'

module.exports =
  config:
    directory:
      type: 'string'
      default: 'testdata'

  notationalVelocityView: null

  activate: (state) ->
    # Events subscribed to in atom's system can be easily cleaned up with a
    # CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace',
      'notational-velocity:toggle': => @createView(state).toggle()

  deactivate: ->
    @subscriptions.dispose()
    @notationalVelocityView.destroy()

  serialize: ->
    notationalVelocityViewState: @notationalVelocityView.serialize()

  createView: (state) ->
    unless @notationalVelocityView?
      NotationalVelocityView = require './notational-velocity-view'
      @notationalVelocityView = new NotationalVelocityView(state.notationalVelocityViewState)
    @notationalVelocityView
