fs = require 'fs'

module.exports =
class NotationalVelocityView
  constructor: (serializeState) ->
    # Create root element
    @element = document.createElement('div')
    @element.classList.add('notational-velocity',  'overlay', 'from-top')

    # Create message element
    message = document.createElement('div')
    message.textContent = "The NotationalVelocity package is Alive! It's ALIVE!"
    message.classList.add('message')
    @element.appendChild(message)

    # Register command that toggles this view
    atom.commands.add 'atom-workspace', 'notational-velocity:toggle': => @toggle()

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @element.remove()

  # Toggle the visibility of this view
  toggle: ->
    console.log 'NotationalVelocityView was toggled!'

    @readdir()

    if @element.parentElement?
      @element.remove()
    else
      atom.workspaceView.append(@element)

  # read filenames in a specific directory
  readdir: ->
    fs.readdir '.', (error, filenames) =>
      if error
        throw error
      for filename in filenames
        console.log filename
