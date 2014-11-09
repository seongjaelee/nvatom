path = require 'path'
{$, $$, SelectListView} = require 'atom'

module.exports =
class NotationalVelocityView extends SelectListView
  initialize: ->
    console.log 'initialize'
    super

    @addClass('from-top overlay')
    @data = [
      {
        'title': 'car',
        'content': 'Car: A car is a wheeled, self-powered motor vehicle used for transportation. Most definitions of the term specify that cars are designed to run primarily on roads, to have seating for one to eight people, to typically have four wheels, and to be constructed principally for the transport of people rather than goods.'
      },
      {
        'title': 'bar',
        'content': 'Bar: Bars provide stools or chairs that are placed at tables or counters for their patrons. Some bars have entertainment on a stage, such as a live band, comedians, go-go dancers, or strippers. Bars which offer entertainment or live music are often referred to as music bars or nightclubs.'
      }
    ]
    @setItems(@data)

  getFilterKey: ->
    'content'

  toggle: ->
    console.log 'toggle'
    if @hasParent()
      @cancel()
    else
      @attach()

  viewForItem: (item) ->
    console.log 'viewForItem #{item}'

    element = document.createElement('li')
    element.textContent = item.content
    element

  confirmed: (item) ->
    console.log 'confirmed #{item}'

  destroy: ->
    console.log 'destroy'
    @cancel()
    @remove()

  attach: ->
    console.log 'attach'
    @storeFocusedElement()
    atom.workspaceView.append(this)
    @focusFilterEditor()

  cancel: ->
    console.log 'cancel'
    super

  cancelled: ->
    console.log 'cancelled'
    super

  setItems: (items=[]) ->
    console.log 'setItems'
    super(items)

  populateList: ->
    console.log 'populateList'
    super
