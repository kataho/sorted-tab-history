{CompositeDisposable} = require 'atom'

module.exports =
class TabHistoryFacade
  constructor: ->
    @disposable = new CompositeDisposable

    @modalItem = document.createElement('ol')
    @modalItem.classList.add('tab-history-mrx-facade')
    @modal = atom.workspace.addModalPanel {item: @modalItem, visible: false, className: 'tab-history-mrx-facade-panel'}

  renderHistory: (history, activeItem) ->
    diff = history.length - @modalItem.children.length
    @modalItem.appendChild(document.createElement('li')) for i in [0...diff] if diff > 0
    @modalItem.removeChild(@modalItem.firstChild) for i in [0...diff] if diff < 0

    clearTimeout @activateTimeout
    for i in [0...history.length]
      item = history.itemAtModIndex(i)
      element = @modalItem.children[i]
      element.classList.remove('active')
      @activateTimeout = setTimeout ((e) -> -> e.classList.add('active'))(element) if item is activeItem
      element.innerHTML = "<span class='icon-file-text' data-name='#{item.getTitle()}'>#{item.getTitle()}</span>"

  observeManager: (manager) ->
    manager.onNavigate (manager) =>
      unless @modal.isVisible()
        @modal.show()
      else if @modalItem.children[0]?.classList.contains('hiding')
        clearTimeout @hideTimeout
        item.classList.remove('hiding') for item in @modalItem.children

      @renderHistory manager.history, manager.pane.getActiveItem()

    manager.onEndNavigation (manager) =>
      item.classList.add('hiding') for item in @modalItem.children
      @hideTimeout = setTimeout (=>
        @modal.hide()
        item.classList.remove('hiding') for item in @modalItem.children
      ), 500

    @modal.hide()
    manager

  reset: ->
    @modal.hide()

  dispose: ->
    @disposable.dispose()
    @modal.destroy()
