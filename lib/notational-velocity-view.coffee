path = require 'path'
fs = require 'fs-plus'
_ = require 'underscore-plus'
{$, $$, SelectListView} = require 'atom-space-pen-views'
DocQuery = require 'docquery'
NoteWatcher = require './note-watcher'
Utility = require './utility'

module.exports =
class NotationalVelocityView extends SelectListView
  initialize: (state) ->
    super
    @addClass('nvatom')
    @maxItems = 100
    @rootDirectory = Utility.getNoteDirectory()
    unless fs.existsSync(@rootDirectory)
      throw new Error("The given directory #{@rootDirectory} does not exist. "
        + "Set the note directory to the existing one from Settings.")
    @skipPopulateList = false
    @prevCursorPosition = 0
    @documentsLoaded = false
    @noteWatcher = new NoteWatcher(@rootDirectory, atom.config.get('nvatom.extensions'), @maxItems)
    @noteWatcher.on "ready", () =>
      @documentsLoaded = true
      @setLoading()
      @populateList()
    @noteWatcher.on "update", () => 
      @populateList() if @documentsLoaded
    unless atom.config.get('nvatom.enableLunrPipeline')
      @noteWatcher.searchIndex.pipeline.reset()

  isCursorProceeded: ->
    editor = @filterEditorView.model
    currCursorPosition = editor.getCursorBufferPosition().column
    isCursorProceeded = @prevCursorPosition < currCursorPosition
    @prevCursorPosition = currCursorPosition
    return isCursorProceeded

  selectItem: (filteredItems, filterQuery) ->
    isCursorProceeded = @isCursorProceeded()

    for item in filteredItems
      if item.title.toLowerCase() is filterQuery.toLowerCase()
        # autoselect
        n = filteredItems.indexOf(item) + 1
        @selectItemView(@list.find("li:nth-child(#{n})"))
        return

    for item in filteredItems
      if item.title.toLowerCase().startsWith(filterQuery.toLowerCase()) and isCursorProceeded
        # autocomplete
        @skipPopulateList = true
        editor = @filterEditorView.model
        editor.setText(filterQuery + item.title.slice(filterQuery.length))
        editor.selectLeft(item.title.length - filterQuery.length)

        # autoselect
        n = filteredItems.indexOf(item) + 1
        @selectItemView(@list.find("li:nth-child(#{n})"))

  filter: (filterQuery) ->
    @noteWatcher.search(filterQuery)

  getFilterKey: ->
    'filetext'

  toggle: ->
    if @panel?.isVisible()
      @hide()
    else if @documentsLoaded
      @populateList()
      @show()
    else
      @setLoading("Loading documents")
      @show()

  viewForItem: (item) ->
    content = item.body[0...100]

    $$ ->
      @li class: 'two-lines', =>
        @div class: 'primary-line', =>
          @span "#{item.title}"
          @div class: 'metadata', "#{item.modifiedAt.toLocaleDateString()}"
        @div class: 'secondary-line', "#{content}"

  confirmSelection: ->
    item = @getSelectedItem()
    sanitizedQuery = Utility.trim(@getFilterQuery())
    calculatedPath = Utility.getNotePath(sanitizedQuery)
    filePath = null
    if item?
      filePath = item.filePath
    else if fs.existsSync(calculatedPath)
      filePath = calculatedPath
    else if sanitizedQuery.length > 0
      filePath = calculatedPath
      fs.writeFileSync(filePath, '')

    if filePath
      atom.workspace.open(filePath).then (editor) ->
        save = ->
          isWhiteSpaceActive = atom.packages.isPackageActive 'whitespace'
          if isWhiteSpaceActive
            atom.packages.deactivatePackage 'whitespace'
          editor.save()
          if isWhiteSpaceActive
            atom.packages.activatePackage 'whitespace'
        debouncedSave = _.debounce save, 1000
        editor.onDidStopChanging () ->
          debouncedSave() if editor.isModified()

    @cancel()

  destroy: ->
    @cancel()
    @panel?.destroy()
    @noteWatcher.save()
    @noteWatcher.close()

  show: ->
    @storeFocusedElement()
    @panel ?= atom.workspace.addModalPanel(item: this)
    @panel.show()
    @focusFilterEditor()

  cancelled: ->
    @hide()

  hide: ->
    @panel?.hide()

  getFilterQuery: ->
    editor = @filterEditorView.model
    fullText = editor.getText()
    selectedText = editor.getSelectedText()
    return fullText.substring(0, fullText.length - selectedText.length)

  populateList: ->
    filterQuery = @getFilterQuery()
    filteredItems = @filter(filterQuery)

    @list.empty()
    if filteredItems.length
      @setError(null)

      for i in [0...Math.min(filteredItems.length, @maxItems)]
        item = filteredItems[i]
        itemView = $(@viewForItem(item))
        itemView.data('select-list-item', item)
        @list.append(itemView)

      @selectItem(filteredItems, filterQuery)

    else
      @setError(@getEmptyMessage(@noteWatcher.length, filteredItems.length))

  schedulePopulateList: ->
    unless @skipPopulateList
      super
    @skipPopulateList = false
