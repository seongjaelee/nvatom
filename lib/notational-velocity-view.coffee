path = require 'path'
fs = require 'fs'
fsPlus = require 'fs-plus'
{$, $$, SelectListView} = require 'atom'

module.exports =
class NotationalVelocityView extends SelectListView
  initialize: ->
    console.log 'initialize'
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

    for query in queries
      for perf in perfs
        result = @items[perf.index].filetext.match(query)
        if result == null
          perf.score = 0
          continue
        perf.score *= result.length
        result = @items[perf.index].title.match(query)
        if result != null
          perf.score *= 10
      perfs = perfs.filter (x) -> x.score > 0

    perfs.sort (a, b) -> if a.score > b.score then -1 else 1

    return (@items[p.index] for p in perfs)

  loadData: ->
    @data = []

    # directory = '/Users/seongjae/github/notational-velocity/testdata'
    directory = atom.config.get('notational-velocity.directory')

    for filename in fs.readdirSync(directory)
      filepath = path.join(directory, filename)
      if !fsPlus.isMarkdownExtension(path.extname(filename))
        continue

      filetext = fs.readFileSync(filepath, 'utf8')

      title = ''
      result = filetext.match(/^#\s.+/)
      if result != null
        title = result[0].slice(2, result[0].length)

      item = {
        'title': title,
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
    if @hasParent()
      @cancel()
    else
      @attach()

  viewForItem: (item) ->
    console.log 'viewForItem #{item}'

    index = item.filetext.search /\n/
    content = item.filetext.slice(index, item.filetext.length)

    $$ ->
      @li class: 'two-lines', =>
        @div "#{item.title}", class: 'primary-line'
        @div "#{content}", class: 'secondary-line'

  confirmed: (item) ->
    # console.log 'confirmed #{item}'
    atom.workspaceView.open(item.filepath)

  destroy: ->
    # console.log 'destroy'
    @cancel()
    @remove()

  attach: ->
    # console.log 'attach'
    @storeFocusedElement()
    atom.workspaceView.append(this)
    @focusFilterEditor()

  # cancel: ->
  #   console.log 'cancel'
  #   super

  # cancelled: ->
  #   console.log 'cancelled'
  #   super

  # setItems: (items=[]) ->
  #   console.log 'setItems'
  #   super(items)

  # populateList: ->
  #   console.log 'populateList'
  #   super

  # selectItemView: (view) ->
  #   console.log 'selectItemView'
  #   super(view)
  #   return unless view.length
  #   console.log @list.indexOf(@list.find('.selected'))

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
