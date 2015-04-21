path = require 'path'
fs = require 'fs-plus'
{$, $$, SelectListView} = require 'atom-space-pen-views'
NoteDirectory = require './note-directory'
Note = require './note'

module.exports =
class NotationalVelocityView extends SelectListView
  initialize: ->
    super
    @addClass('notational-velocity from-top overlay')
    @rootDirectory = atom.config.get('notational-velocity.directory')
    if !fs.existsSync(@rootDirectory)
      throw new Error("The given directory #{@rootDirectory} does not exist. "
        + "Set the note directory to the existing one from Settings.")
    @noteDirectory = new NoteDirectory(@rootDirectory, null, () => @updateNotes())
    @updateNotes()
    @prevFilterQuery = ''
    @prevCursorPosition = 0

  updateNotes: () ->
    @notes = @noteDirectory.getNotes()
    @setItems(@notes)

  selectItem: (filterQuery) ->
    if filterQuery.length == 0
      @prevCursorPosition = 0
      return null

    titlePatterns = [
      ///^#{filterQuery}$///i,
      ///^#{filterQuery}///i,
    ]

    titleItem = null
    for titlePattern in titlePatterns
      titleItems = @notes
        .filter (x) -> x.getTitle().match(titlePattern) != null
      titleItem = if titleItems.length > 0 then titleItems[0] else null
      if titleItem != null
        break

    # If title item is not null, auto-fill the search panel.
    # But we don't want to fill it when deleting.
    editor = @filterEditorView.model
    currCursorPosition = editor.getCursorBufferPosition().column
    if titleItem != null && @prevCursorPosition < currCursorPosition
      @prevFilterQuery = titleItem.getTitle()
      editor.setText(titleItem.getTitle())
      editor.selectLeft(titleItem.getTitle().length - filterQuery.length)
    @prevCursorPosition = currCursorPosition

    return titleItem

  filter: (filterQuery) ->
    if filterQuery.length == 0
      return @notes

    queries = filterQuery.split(' ')
      .filter (x) -> x.length > 0
      .map (x) -> new RegExp(x, 'gi')
    return @notes
      .filter (x) ->
        queries
          .map (q) -> q.test(x.getText()) || q.test(x.getTitle())
          .reduce (x, y) -> x && y

  getFilterKey: ->
    'filetext'

  toggle: ->
    if @panel?.isVisible()
      @hide()
    else
      @populateList()
      @show()

  viewForItem: (item) ->
    content = item.getText()[0...100]

    $$ ->
      @li class: 'two-lines', =>
        @div class: 'primary-line', =>
          @span "#{item.getTitle()}"
          @div class: 'metadata', "#{item.getModified().toLocaleDateString()}"
        @div class: 'secondary-line', "#{content}"

  confirmSelection: ->
    item = @getSelectedItem()
    if item?
      atom.workspace.open(item.getFilePath())
      @cancel()
    else
      sanitizedQuery = @getFilterQuery().replace(/\s+$/, '')
      if sanitizedQuery.length > 0
        filePath = path.join(@rootDirectory, sanitizedQuery + '.md')
        fs.writeFileSync(filePath, '')
        atom.workspace.open(filePath)
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

  populateList: ->
    return unless @notes?

    filterQuery = @getFilterQuery()
    filteredItems = @filter(filterQuery)
    selectedItem = @selectItem(filterQuery)

    @list.empty()
    if filteredItems.length
      @setError(null)

      for i in [0...Math.min(filteredItems.length, @maxItems)]
        item = filteredItems[i]
        itemView = $(@viewForItem(item))
        itemView.data('select-list-item', item)
        @list.append(itemView)

      if selectedItem
        n = filteredItems.indexOf(selectedItem) + 1
        @selectItemView(@list.find("li:nth-child(#{n})"))

    else
      @setError(@getEmptyMessage(@notes.length, filteredItems.length))

  schedulePopulateList: ->
    # We can skip it when we are just moving the position of the cursor.
    currFilterQuery = @getFilterQuery()
    if @prevFilterQuery != currFilterQuery
      super
    @prevFilterQuery = currFilterQuery
