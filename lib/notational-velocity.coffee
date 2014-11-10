module.exports =
  configDefaults:
    directory: '/'

  notationalVelocityView: null

  activate: (state) ->
    atom.workspaceView.command 'notational-velocity:toggle', =>
      @createView(state).toggle()

  deactivate: ->
    @notationalVelocityView.destroy()

  serialize: ->
    notationalVelocityViewState: @notationalVelocityView.serialize()

  createView: (state) ->
    unless @notationalVelocityView?
      NotationalVelocityView = require './notational-velocity-view'
      @notationalVelocityView = new NotationalVelocityView(state.notationalVelocityViewState)
    @notationalVelocityView
