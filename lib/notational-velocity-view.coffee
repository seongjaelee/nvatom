path = require 'path'
fs = require 'fs'
{$, $$, SelectListView} = require 'atom'

module.exports =
class NotationalVelocityView extends SelectListView
  initialize: ->
    console.log 'initialize'
    super

    @addClass('notational-velocity from-top overlay')
    @loadData()

  loadData: ->
    @data = []

    # directory = '/Users/seongjae/github/notational-velocity/testdata'
    directory = atom.config.get('notational-velocity.directory')

    for filename in fs.readdirSync(directory)
      filepath = path.join(directory, filename)
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
