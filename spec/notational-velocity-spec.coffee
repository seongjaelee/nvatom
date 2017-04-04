path = require 'path'
temp = require 'temp'

temp.track()

describe "nvAtom", ->
  defaultDirectory = atom.config.get('nvatom.directory')
  activationPromise = null
  workspaceElement = null

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)

  afterEach ->
    atom.config.set('nvatom.directory', defaultDirectory)

  describe "when the nvatom:toggle event is triggered", ->
    it "attaches and then detaches the view", ->
      noteDirectory = path.join(temp.mkdirSync())
      atom.config.set('nvatom.directory', noteDirectory)
      
      waitsForPromise ->
        atom.packages.activatePackage('nvatom')

      runs ->
        expect(workspaceElement.querySelector('.nvatom')).not.toExist()

        atom.commands.dispatch workspaceElement, 'nvatom:toggle'
        expect(workspaceElement.querySelector('.nvatom')).toExist()
        expect(workspaceElement.querySelector('.nvatom').parentNode.style.display).not.toBe 'none'

        atom.commands.dispatch workspaceElement, 'nvatom:toggle'
        expect(workspaceElement.querySelector('.nvatom').parentNode.style.display).toBe 'none'

    it "checks if we banned the default directory under packages directory", ->
      noteDirectory = path.join(process.env.ATOM_HOME, 'packages', 'nvatom', 'notebook')
      atom.config.set('nvatom.directory', noteDirectory)

      waitsForPromise ->
        atom.packages.activatePackage('nvatom')

      runs ->
        waitsForPromise ->
          atom.packages.activatePackage('notifications')

        runs ->
          notificationContainer = workspaceElement.querySelector('atom-notifications')
          notification = notificationContainer.querySelector('atom-notification.fatal')
          expect(notification).toExist()
