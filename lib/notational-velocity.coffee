NotationalVelocityView = require './notational-velocity-view'

module.exports =
  notationalVelocityView: null

  activate: (state) ->
    @notationalVelocityView = new NotationalVelocityView(state.notationalVelocityViewState)

  deactivate: ->
    @notationalVelocityView.destroy()

  serialize: ->
    notationalVelocityViewState: @notationalVelocityView.serialize()
