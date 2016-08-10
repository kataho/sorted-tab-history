{CompositeDisposable, Emitter} = require 'atom'
HistoryBuffer = require './history-buffer.coffee'

module.exports =
class TabHistoryManager
  constructor: (pane) ->
    @pane = pane
    @navigating = false
    @history = new HistoryBuffer pane.getItems(), pane.getActiveItem()
    @disposable = new CompositeDisposable
    @emitter = new Emitter

    @disposable.add pane.onDidAddItem ({item}) =>
      @history.pushItem item
      @forgetOldItems limit, item if (limit = atom.config.get 'sorted-tab-history.limitItems') > 0

    @disposable.add pane.onWillRemoveItem ({item}) =>
      @history.removeItem item

    @disposable.add pane.observeActiveItem (item) =>
      @activeEditorChangeCb?.dispose()
      @activeEditorCursorCb?.dispose()
      @activeEditorSaveCb?.dispose()
      if atom.workspace.isTextEditor(item)
        @activeEditorChangeCb = item.getBuffer().onDidStopChanging =>
          @history.stamp item, 'change' if item.isModified()
        @activeEditorCursorCb = item.onDidChangeCursorPosition =>
          @history.stamp item, 'cursor'
        @activeEditorSaveCb = item.getBuffer().onWillSave =>
          @history.stamp item, 'save'

      if @navigating
        @emitter.emit 'on-navigate', this
      else
        @history.stamp item, 'select_ext'

  _destroyStep: (limit, keepItem) ->
    list = @history.sortedItemList()
    if list.length > limit
      for i in [list.length - 1..0]
        item = list[i]
        break if item isnt keepItem and (not atom.workspace.isTextEditor(item) or not item.isModified())
        return if i == 0
      @pane.destroyItem item
      setTimeout (=> @_destroyStep limit, keepItem), 33

  forgetOldItems: (limit, keepItem) ->
    @_destroyStep limit, keepItem

  navigate: (stride) ->
    @navigating = true
    list = @history.sortedItemList()
    index = list.indexOf(@pane.getActiveItem())
    if atom.config.get 'sorted-tab-history.circularList'
      index = (index + stride + list.length) % list.length
    else
      index = Math.max(0, Math.min(list.length - 1, index + stride))
    @pane.activateItem list[index]

  navigateTop: ->
    @navigating = true
    @pane.activateItem @history.sortedItemList()[0]

  select: ->
    if @navigating
      @emitter.emit 'on-end-navigation', this
      @navigating = false
      @history.stamp @pane.getActiveItem(), 'select'

  resetSilently: ->
    @navigating = false

  reset: ->
    @emitter.emit 'on-reset', this
    @navigating = false

  onNavigate: (func) ->
    @disposable.add @emitter.on 'on-navigate', func

  onEndNavigation: (func) ->
    @disposable.add @emitter.on 'on-end-navigation', func

  onReset: (func) ->
    @disposable.add @emitter.on 'on-reset', func

  dispose: ->
    @disposable.dispose()
    @activeEditorChangeCb?.dispose()
    @activeEditorCursorCb?.dispose()
    @activeEditorSaveCb?.dispose()
