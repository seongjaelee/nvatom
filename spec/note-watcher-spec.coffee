fs = require 'fs'
path = require 'path'
temp = require 'temp'
NoteWatcher = require '../lib/note-watcher'

temp.track()

describe 'note-watcher', ->
  watcher = null
  directoryPath = null
  
  beforeEach ->
    directoryPath = temp.mkdirSync()
    fs.writeFileSync(
      path.join(directoryPath, 'foo.md'), 
      'The use of foo in a programming context is generally credited to the Tech Model Railroad Club (TMRC) of MIT.')
    fs.writeFileSync(
      path.join(directoryPath, 'bar.md'),
      'When used in connection with bar it is generally traced to the World War II military slang FUBAR.')
    spy = jasmine.createSpy()
    watcher = new NoteWatcher(directoryPath)
    watcher.on 'ready', spy
    waitsFor -> spy.wasCalled
    
  afterEach ->
    watcher.close()
  
  # it 'handles a symbolic link note properly', ->
  #   spy = jasmine.createSpy()
  #   watcher.on 'update', spy
  #   
  #   anotherDirectoryPath = temp.mkdirSync()
  #   fs.writeFileSync(path.join(anotherDirectoryPath, 'baz.md'), 'A common name for the foobar, also foobaz.')
  #   fs.symlinkSync(path.join(anotherDirectoryPath, 'baz.md'), path.join(directoryPath, 'baz.md'))
  #   
  #   waitsFor -> spy.wasCalled
  #   
  #   runs -> 
  #     result = watcher.search('baz')
  #     expect(result.length).toBe(1)

  # it 'handles a symbolic link directory properly', ->
  #   spy = jasmine.createSpy()
  #   watcher.on 'update', spy
  # 
  #   anotherDirectoryPath = temp.mkdirSync()
  #   fs.writeFileSync(path.join(anotherDirectoryPath, 'baz.md'), 'A common name for the foobar, also foobaz.')
  #   fs.symlinkSync(anotherDirectoryPath, path.join(directoryPath, 'baz'))
  # 
  #   waitsFor -> spy.wasCalled
  #   
  #   runs -> 
  #     result = watcher.search('baz')
  #     expect(result.length).toBe(1)
  #     expect(result[0].filePath).toBe(path.join(directoryPath, 'baz', 'baz.md'))
  
  # it 'handles paired symbolic links properly without falling into an infinite loop', ->
  #   spy = jasmine.createSpy()
  #   watcher.on 'update', spy
  # 
  #   anotherDirectoryPath = temp.mkdirSync()
  #   fs.writeFileSync(path.join(anotherDirectoryPath, 'baz.md'), 'A common name for the foobar, also foobaz.')
  #   fs.symlinkSync(anotherDirectoryPath, path.join(directoryPath, 'bazDir'))
  #   fs.symlinkSync(directoryPath, path.join(anotherDirectoryPath, 'fooDir'))
  # 
  #   waitsFor -> spy.wasCalled
  #   
  #   runs -> 
  #     result = watcher.search('baz')
  #     expect(result.length).toBe(1)
  #     expect(result[0].filePath).toBe(path.join(directoryPath, 'bazDir', 'baz.md'))
  
  # it 'watches adding a file', ->
  #   spy = jasmine.createSpy()
  #   watcher.on 'update', spy
  #   fs.writeFileSync(path.join(directoryPath, 'note.md'), 'hello world')
  #   
  #   waitsFor -> spy.wasCalled
  # 
  # it 'watches changing a file', ->
  #   spy = jasmine.createSpy()
  #   watcher.on 'update', spy
  #   filePath = path.join(directoryPath, 'note.md')
  #   fs.writeFileSync(filePath, 'hello world')
  #   waitsFor -> spy.callCount == 1
  #   
  #   runs -> fs.writeFileSync(filePath, 'hello world 2')
  #   
  #   waitsFor -> spy.callCount == 2    
  # 
  # it 'watches removing a file', ->
  #   spy = jasmine.createSpy()
  #   watcher.on('update', spy)
  #   filePath = path.join(directoryPath, 'note.md')
  #   fs.writeFileSync(filePath, 'hello world')
  #   waitsFor -> spy.callCount == 1
  #   
  #   runs -> fs.unlinkSync(filePath)
  #   
  #   waitsFor -> spy.callCount == 2
  # 
  # it 'searches', ->
  #   result = watcher.search('programming')
  #   expect(result.length).toBe(1)
  #   expect(result[0].title).toBe('foo')
  # 
  # it 'saves and loads', ->
  #   watcher.save()
  #   watcher.close()
  #   watcher = new NoteWatcher(directoryPath)
  #   spy = jasmine.createSpy()
  #   watcher.on 'ready', spy
  # 
  #   waitsFor -> spy.wasCalled
  #   
  #   runs -> 
  #     result = watcher.search('programming')
  #     expect(result.length).toBe(1)
  #     expect(result[0].title).toBe('foo')
    
  it 'loads the modified contents correctly', ->
    watcher.save()
    watcher.close()
    
    # create, change, and delete
    fs.writeFileSync(path.join(directoryPath, 'baz.md'), 'A common name for the foobar, also foobaz.')
    fs.writeFileSync(path.join(directoryPath, 'foo.md'), 'The etymology of foo is obscure.')
    fs.unlinkSync(path.join(directoryPath, 'bar.md'))
    
    watcher = new NoteWatcher(directoryPath)
    spy = jasmine.createSpy()
    watcher.on('ready', spy)
    waitsFor -> spy.wasCalled
    
    runs ->
      # in deleted foo.md
      expect(watcher.search('programming').length).toBe(0)
      # in replaced foo.md
      expect(watcher.search('obscure').length).toBe(1)
      # in bar.md
      expect(watcher.search('connection').length).toBe(0)
      # in baz.md
      expect(watcher.search('baz').length).toBe(1)