path = require 'path'
fs = require 'fs-plus'
_ = require 'underscore-plus'
{$, $$, SelectListView} = require 'atom-space-pen-views'
DocQuery = require 'docquery'

module.exports =
class NotationalVelocityView extends SelectListView
  initialize: (state) ->
    @initializedAt = new Date()
    super
    @addClass('nvatom from-top overlay')
    @rootDirectory = atom.config.get('nvatom.directory')
    unless fs.existsSync(@rootDirectory)
      throw new Error("The given directory #{@rootDirectory} does not exist. "
        + "Set the note directory to the existing one from Settings.")
    @skipPopulateList = false
    @prevCursorPosition = 0
    @documentsLoaded = false
    @docQuery = new DocQuery(@rootDirectory, {recursive: true, extensions: atom.config.get('nvatom.extensions')})
    @docQuery.on "ready", () =>
      @documentsLoaded = true
      @setLoading()
      @populateList()
    @docQuery.on "added", (fileDetails) =>
      @populateList() if @documentsLoaded
    @docQuery.on "updated", (fileDetails) =>
      @populateList() if @documentsLoaded
    @docQuery.on "removed", (fileDetails) =>
      @populateList() if @documentsLoaded
    unless atom.config.get('nvatom.enableLunrPipeline')
      @docQuery.searchIndex.pipeline.reset()

  isCursorProceeded: ->
    editor = @filterEditorView.model
    currCursorPosition = editor.getCursorBufferPosition().column
    isCursorProceeded = @prevCursorPosition < currCursorPosition
    @prevCursorPosition = currCursorPosition
    return isCursorProceeded

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
    filePath = null
    sanitizedQuery = @getFilterQuery().replace(/\s+$/, '')
    extension = if atom.config.get('nvatom.extensions').length then atom.config.get('nvatom.extensions')[0] else '.md'
    calculatedPath = path.join(@rootDirectory, sanitizedQuery + extension)
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
          atom.packages.deactivatePackage 'whitespace'
          editor.save()
          atom.packages.activatePackage 'whitespace'
        debouncedSave = _.debounce save, 1000
        editor.onDidStopChanging () ->
          debouncedSave() if editor.isModified()

    @cancel()

  destroy: ->
    @cancel()
    @panel?.destroy()

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

  filterByTitle: (filterQuery) ->
    if (filterQuery is "") or (filterQuery is undefined)
      return []
    filterQuery = filterQuery.toLowerCase()
    matchingNotes = []
    filteredNotes = []
    for note in @docQuery.documents
      title = note.title.toLowerCase()
      if title is filterQuery
        matchingNotes.push(note)
      else if filteredNotes.length < @maxItems and title.startsWith(filterQuery)
        filteredNotes.push(note)
    notes = matchingNotes.concat(filteredNotes)
    if notes.length > @maxItems
      notes = notes.slice(0, @maxItems)
    return notes

  filterByLunr: (filterQuery) ->
    notes = []
    if (filterQuery is "") or (filterQuery is undefined)
      notes = @docQuery.documents
    else
      notes = @docQuery.search(filterQuery)
    if notes.length > @maxItems
      notes = notes.slice(0, @maxItems)
    return notes

  populateList: ->
    filterQuery = @getFilterQuery()
    notesByTitle = @filterByTitle(filterQuery)
    notesByLunr = @filterByLunr(filterQuery)
    isCursorProceeded = @isCursorProceeded()

    @list.empty()
    if notesByTitle.length + notesByLunr.length == 0
      @setError(@getEmptyMessage(@docQuery.documents.length, 0))
      return

    @setError(null)
    for note in notesByTitle
      itemView = $(@viewForItem(note))
      itemView.data('select-list-item', note)
      @list.append(itemView)

    if notesByTitle.length
      # autoselect
      @selectItemView(@list.find("li:nth-child(1)"))

      #autocomplete
      note = notesByTitle[0]
      if note.title.toLowerCase() is filterQuery.toLowerCase() or isCursorProceeded
        @skipPopulateList = true
        editor = @filterEditorView.model
        editor.setText(filterQuery + note.title.slice(filterQuery.length))
        editor.selectLeft(note.title.length - filterQuery.length)

    if @list.length >= @maxItems
      return

    for note in notesByLunr
      if @list.length >= @maxItems
        break
      if filterQuery?.length and note.title.toLowerCase().startsWith(filterQuery.toLowerCase())
        continue
      itemView = $(@viewForItem(note))
      itemView.data('select-list-item', note)
      @list.append(itemView)

  schedulePopulateList: ->
    unless @skipPopulateList
      super
    @skipPopulateList = false
