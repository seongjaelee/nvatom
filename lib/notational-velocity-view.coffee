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

  filter: (filterQuery) ->
    queries = []

    for queryStr in filterQuery.split(' ')
      if queryStr.length
        queries.push(new RegExp(queryStr, 'gim'))

    perfs = []
    for item,i in @items
      perfs.push({score: 1, index: i})

    # The most recent one comes to the top.
    for query in queries
      for perf in perfs
        if @items[perf.index].filetext.match(query) != null || @items[perf.index].title.match(query) != null
          perf.score = @items[perf.index].modified
        else
          perf.score = 0

        # This snippet implements a manual relevance metric.
        # result = @items[perf.index].filetext.match(query)
        # if result == null
        #   perf.score = 0
        #   continue
        # perf.score *= result.length
        # result = @items[perf.index].title.match(query)
        # if result != null
        #   perf.score *= 10

      perfs = perfs.filter (x) -> x.score > 0

    perfs.sort (a, b) -> if a.score > b.score then -1 else 1

    return (@items[p.index] for p in perfs)

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
    if filterQuery.length
      filteredItems = @filter(filterQuery)
      #filteredItems = fuzzyFilter(@items, filterQuery, key: @getFilterKey())
    else
      filteredItems = @items

    @list.empty()
    if filteredItems.length
      @setError(null)

      for i in [0...Math.min(filteredItems.length, @maxItems)]
        item = filteredItems[i]
        itemView = $(@viewForItem(item))
        itemView.data('select-list-item', item)
        @list.append(itemView)

      @selectItemView(@list.find('li:first'))
    else
      @setError(@getEmptyMessage(@items.length, filteredItems.length))
