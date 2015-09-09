# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "NotationalVelocity", ->
  defaultDirectory = atom.config.get('notational-velocity.directory')
  activationPromise = null
  workspaceElement = null

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = atom.packages.activatePackage('notational-velocity')
    atom.config.set('notational-velocity.directory', 'testdata')

  afterEach ->
    atom.config.set('notational-velocity.directory', defaultDirectory)

  describe "when the notational-velocity:toggle event is triggered", ->
    it "attaches and then detaches the view", ->
      expect(workspaceElement.querySelector('.notational-velocity')).not.toExist()

      # This is an activation event, triggering it will cause the package to be
      # activated.
      atom.commands.dispatch workspaceElement, 'notational-velocity:toggle'

      waitsForPromise ->
        activationPromise

      runs ->
        expect(workspaceElement.querySelector('.notational-velocity')).toExist()
        atom.commands.dispatch workspaceElement, 'notational-velocity:toggle'
