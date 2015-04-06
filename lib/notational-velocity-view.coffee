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

  selectItem: (filterQuery) ->
    if filterQuery.length == 0
      return null

    titleQuery = filterQuery.toLowerCase()
    titleItems = @items
      .filter (x) -> x.title.toLowerCase()[...titleQuery.length] is titleQuery
      .sort (x, y) -> x.modified > y.modified
    titleItem = if titleItems.length > 0 then titleItems[0] else null
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
          .map (q) -> q.test(x.filetext) || q.test(x.test)
          .reduce (x, y) -> x && y
    return contentItems

  loadData: ->
    @data = []

    directory = atom.config.get('notational-velocity.directory')

    for filename in fs.readdirSync(directory)
      if !fsPlus.isMarkdownExtension(path.extname(filename))
        continue

      filepath = path.join(directory, filename)
      filetext = fs.readFileSync(filepath, 'utf8')
      modified = fs.statSync(filepath).mtime

      title = ''
      result = filetext.match(/^#\s.+/)
      if result != null
        title = result[0].slice(2, result[0].length)

      item = {
        'title': title,
        'modified': modified,
        'filetext': filetext,
        'filename': filename,
        'filepath': filepath
      }
      @data.push(item)

    @setItems(@data)

  getFilterKey: ->
    'filetext'

  toggle: ->
    console.log 'toggle'
    if @panel?.isVisible()
      @hide()
    else
      @populateList()
      @show()

  viewForItem: (item) ->
    console.log 'viewForItem #{item}'

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
      if query?
        # TODO(seongjae): It should create a new document.
        console.log(query)
      @cancel()

  confirmed: (item) ->
    console.log 'confirmed #{item}'
    atom.workspace.open(item.filepath)
    @cancel()

  destroy: ->
    console.log 'destroy'
    @cancel()
    @panel?.destroy()

  show: ->
    console.log 'show'
    @storeFocusedElement()
    @panel ?= atom.workspace.addModalPanel(item: this)
    @panel.show()
    @focusFilterEditor()

  cancelled: ->
    @hide()

  hide: ->
    @panel?.hide()

  populateList: ->
    console.log 'populateList'
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
