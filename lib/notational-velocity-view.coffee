path = require 'path'
fs = require 'fs'
fsPlus = require 'fs-plus'
{$, $$, SelectListView} = require 'atom-space-pen-views'

module.exports =
class NotationalVelocityView extends SelectListView
  initialize: ->
    super
    @addClass('notational-velocity from-top overlay')
    @loadData()
    @prevFilterQuery = ''
    @prevCursorPosition = 0

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
      titleItems = @items
        .filter (x) -> x.title.match(titlePattern) != null
        .sort (x, y) -> if x.modified.getTime() <= y.modified.getTime() then 1 else -1
      titleItem = if titleItems.length > 0 then titleItems[0] else null
      if titleItem != null
        break

    # If title item is not null, auto-fill the search panel.
    # But we don't want to fill it when deleting.
    editor = @filterEditorView.model
    currCursorPosition = editor.getCursorBufferPosition().column
    if titleItem != null && @prevCursorPosition < currCursorPosition
      @prevFilterQuery = titleItem.title
      editor.setText(titleItem.title)
      editor.selectLeft(titleItem.title.length - filterQuery.length)
    @prevCursorPosition = currCursorPosition

    return titleItem

  filter: (filterQuery) ->
    if filterQuery.length == 0
      return @items

    queries = filterQuery.split(' ')
      .filter (x) -> x.length > 0
      .map (x) -> new RegExp(x, 'gi')
    contentItems = @items
      .filter (x) ->
        queries
          .map (q) -> q.test(x.filetext) || q.test(x.title)
          .reduce (x, y) -> x && y
    return contentItems

  getSubPath: (baseDir, dir)->
    ret = []
    fullDir = path.join(baseDir, dir)
    try
      filenameList = fs.readdirSync(fullDir)
    catch e
      return ret

    for filename in filenameList
      filePath = path.join(dir, filename)
      fullPath = path.join(baseDir, filePath)
      try
        fileStat = fs.statSync(fullPath)
      catch e
        continue
      if fileStat.isDirectory()
        ret = ret.concat(@getSubPath(baseDir, filePath))
      else
        if !fsPlus.isMarkdownExtension(path.extname(filename))
          continue
        ret.push(filePath)
    return ret

  loadData: ->
    @data = []

    basedir = atom.config.get('notational-velocity.directory')

    for filepath in @getSubPath(basedir, '')
      fullpath = path.join(basedir, filepath)
      filename = path.basename(filepath, path.extname(filepath))
      filetext = fs.readFileSync(fullpath, 'utf8')
      title = path.join(path.dirname(filepath), filename)
      modified = fs.statSync(fullpath).mtime

      item = {
        'title': title,
        'modified': modified,
        'filetext': filetext,
        'filename': filename,
        'filepath': fullpath
      }
      @data.push(item)

    @data = @data.sort (x, y) -> if x.modified.getTime() <= y.modified.getTime() then 1 else -1

    @setItems(@data)

  getFilterKey: ->
    'filetext'

  toggle: ->
    if @panel?.isVisible()
      @hide()
    else
      @populateList()
      @show()

  viewForItem: (item) ->
    index = item.filetext.search /\n/
    content = item.filetext.slice(index, item.filetext.length)

    $$ ->
      @li class: 'two-lines', =>
        @div class: 'primary-line', =>
          @span "#{item.title}"
          @div class: 'metadata', "#{item.modified.toLocaleDateString()}"
        @div class: 'secondary-line', "#{content}"

  confirmSelection: ->
    item = @getSelectedItem()
    if item?
      @confirmed(item)
    else
      query = @getFilterQuery()
      @cancel()

  confirmed: (item) ->
    atom.workspace.open(item.filepath)
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
    return unless @items?

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
      @setError(@getEmptyMessage(@items.length, filteredItems.length))

  schedulePopulateList: ->
    # We can skip it when we are just moving the position of the cursor.
    currFilterQuery = @getFilterQuery()
    if @prevFilterQuery != currFilterQuery
      super
    @prevFilterQuery = currFilterQuery
