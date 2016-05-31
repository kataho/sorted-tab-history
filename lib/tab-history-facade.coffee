{CompositeDisposable} = require 'atom'

module.exports =
class TabHistoryFacade
  constructor: ->
    @disposable = new CompositeDisposable

    @modalItem = document.createElement('ol')
    @modalItem.classList.add('tab-history-facade')
    @modal = atom.workspace.addModalPanel {item: @modalItem, visible: false, className: 'tab-history-facade-panel'}

  renderList: (list, headIndex, activeItem) ->
    diff = list.length - @modalItem.children.length
    @modalItem.appendChild(document.createElement('li')) for i in [0...diff] if diff > 0
    @modalItem.removeChild(@modalItem.firstChild) for i in [0...diff] if diff < 0

    childIndex = 0
    for i in [headIndex...list.length].concat [0...headIndex]
      item = list[i]
      element = @modalItem.children[childIndex++]
      element.classList.remove('active')
      if item is activeItem
        setTimeout ((e) -> -> e.classList.add('active'))(element)
      element.innerHTML =
        "<span class='icon-file-text' data-name='#{item.getTitle()}'></span>" +
        "<span>#{item.getTitle()}</span>"

  observeManager: (manager) ->
    manager.onNavigating (manager) =>
      @modal.show() unless @modal.isVisible()
      @renderList manager.history, manager.headIndex, manager.pane.getActiveItem()

    manager.onEndNavigation (manager) =>
      item.classList.add('hiding') for item in @modalItem.children
      setTimeout (=>
        @modal.hide()
        item.classList.remove('hiding') for item in @modalItem.children
      ), 500

    @modal.hide()
    manager

  dispose: ->
    @disposable.dispose()
    @modal.destroy()
