path = require 'path'

describe "nvAtom", ->
  defaultDirectory = atom.config.get('nvatom.directory')
  activationPromise = null
  workspaceElement = null

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = atom.packages.activatePackage('nvatom')
    atom.config.set('nvatom.directory', 'testdata')

  afterEach ->
    atom.config.set('nvatom.directory', defaultDirectory)

  describe "when the nvatom:toggle event is triggered", ->
    it "attaches and then detaches the view", ->
      expect(workspaceElement.querySelector('.nvatom')).not.toExist()

      # This is an activation event, triggering it will cause the package to be activated.
      atom.commands.dispatch workspaceElement, 'nvatom:toggle'

      waitsForPromise ->
        activationPromise

      runs ->
        expect(workspaceElement.querySelector('.nvatom')).toExist()
        atom.commands.dispatch workspaceElement, 'nvatom:toggle'

    it "checks if we banned the default directory under packages directory", ->
      atom.notifications.clear()

      waitsForPromise ->
        atom.packages.activatePackage('notifications')

      runs ->
        noteDirectoryUnderPackageDirectory = path.join(process.env.ATOM_HOME, 'packages', 'nvatom', 'notebook')
        atom.config.set('nvatom.directory', noteDirectoryUnderPackageDirectory)

        # This is an activation event, triggering it will cause the package to be activated.
        atom.commands.dispatch workspaceElement, 'nvatom:toggle'

        waitsForPromise ->
          activationPromise

        runs ->
          notificationContainer = workspaceElement.querySelector('atom-notifications')
          notification = notificationContainer.querySelector('atom-notification.fatal')
          expect(notification).toExist()
