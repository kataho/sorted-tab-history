{CompositeDisposable} = require 'atom'

module.exports =
class TabHistoryFacade
  constructor: ->
    @disposable = new CompositeDisposable

    @modalItem = document.createElement('ol')
    @modalItem.classList.add('tab-history-mrx-facade')
    @modal = atom.workspace.addModalPanel {item: @modalItem, visible: false, className: 'tab-history-mrx-facade-panel'}
    @displayTime = 0

  renderHistory: (history, activeItem) ->
    list = history.sortedItemList()

    createListItem = ->
      li = document.createElement('li')
      e = document.createElement('div')
      e.classList.add('icon-file-text')
      li.appendChild(e)
      info = document.createElement('div')
      info.classList.add('info-container')
      li.appendChild(info)
      e = document.createElement('span')
      e.classList.add('stamp-delay')
      info.appendChild(e)
      e = document.createElement('span')
      e.classList.add('file-info')
      info.appendChild(e)
      li

    diff = list.length - @modalItem.children.length
    @modalItem.appendChild(createListItem()) for i in [0...diff] if diff > 0
    @modalItem.removeChild(@modalItem.firstChild) for i in [0...diff] if diff < 0

    clearTimeout @activateTimeout
    for i in [0...list.length]
      item = list[i]
      element = @modalItem.children[i]
      span = element.children[0]
      element.classList.remove('active')
      @activateTimeout = setTimeout ((e) -> -> e.classList.add('active'))(element) if item is activeItem
      span.setAttribute('data-name', item.getTitle())
      span.innerText = item.getTitle()

      info = history.restInfoOfItem item

      identElm = element.children[1].children[1]
      identElm.innerText = if 'ident' of info then info.ident else ''

      stampElm = element.children[1].children[0]
      stampElm.innerText = ''
      if 'sortbase' of info
        stampElm.setAttribute('name', info.sortbase)
        stampElm.innerText = @formatDelayTime(@displayTime - info[info.sortbase])

  formatDelayTime: (mills) ->
    hours = Math.floor(mills / (1000 * 60 * 60))
    return hours + 'h' if hours > 0
    mins = Math.floor(mills / (1000 * 60))
    return mins + 'm' if mins > 0
    return Math.floor(mills / 1000) + 's'

  observeManager: (manager) ->
    manager.onNavigate (manager) =>
      @displayTime = Date.now() if @displayTime == 0
      unless @modal.isVisible()
        @modal.show()
      else if @modalItem.children[0]?.classList.contains('hiding')
        clearTimeout @hideTimeout
        item.classList.remove('hiding') for item in @modalItem.children

      @renderHistory manager.history, manager.pane.getActiveItem()

    manager.onEndNavigation (manager) =>
      @displayTime = 0
      item.classList.add('hiding') for item in @modalItem.children
      @hideTimeout = setTimeout (=>
        @modal.hide()
        item.classList.remove('hiding') for item in @modalItem.children
      ), 500

    manager.onReset (manager) =>
      @modal.hide()

    @modal.hide()
    manager

  dispose: ->
    @disposable.dispose()
    @modal.destroy()
