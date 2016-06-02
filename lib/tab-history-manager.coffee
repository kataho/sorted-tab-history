{CompositeDisposable, Emitter} = require 'atom'

module.exports =
class TabHistoryManager
  newHistoryBuffer: (baseArray, headItem) ->
    A = baseArray.concat()
    A.headIndex = baseArray.indexOf(headItem)

    A.removeItem = (item) ->
      @splice(index, 1) if (index = @indexOf(item)) >= 0
      @headIndex-- if index < @headIndex

    A.moveItemTo = (item, toIndex) ->
      @splice(toIndex + (fromIndex < toIndex ? -1 : 0), 0, @splice(fromIndex, 1)[0]) if (fromIndex = @indexOf(item)) >= 0

    A.moveItemHead = (item) ->
      @moveItemTo item, @headIndex

    A.itemAtModIndex = (index) ->
      @[(index + @length) % @length]

    A.itemAtOffsetHead = (index) ->
      @itemAtModIndex @headIndex + index
    A

  constructor: (pane) ->
    @pane = pane
    @navigating = false
    @history = @newHistoryBuffer pane.getItems(), pane.getActiveItem()
    @disposable = new CompositeDisposable
    @emitter = new Emitter

    @pendingUntilChange = false

    @disposable.add pane.onDidAddItem ({item}) =>
      @history.push item
      @moveItemOnAltSelect item
      limit = atom.config.get 'tab-history-mrx.limitItems'
      @destroyItemStep(limit) if limit > 0

    @disposable.add pane.onWillRemoveItem ({item}) =>
      @history.removeItem item

    @disposable.add pane.observeActiveItem (item) =>
      @activeEditorCb?.dispose()
      if atom.config.get 'tab-history-mrx.itemTopOnChange'
        if atom.workspace.isTextEditor(item)
          @activeEditorCb = item.onDidStopChanging =>
            @history.moveItemHead item
            @activeEditorCb?.dispose();

      if @navigating
        @emitter.emit 'on-navigate', this
      else
        @moveItemOnAltSelect item

  destroyItemStep: (limit) ->
    if @history.length > limit
      @pane.destroyItem @history.itemAtOffsetHead(-1)
      setTimeout (=> @destroyItemStep(limit)), 33

  moveItemOnAltSelect: (item) ->
    switch atom.config.get 'tab-history-mrx.itemMoveOnAltSelect'
      when 'top' then @history.moveItemHead item
      when 'forward-active' then @history.moveItemTo item, Math.max(0, @history.indexOf(@pane.getActiveItem()))
      when 'back-active' then @history.moveItemTo item, Math.max(0, @history.indexOf(@pane.getActiveItem())) + 1

  navigate: (stride) ->
    @navigating = true
    @pane.activateItem @history.itemAtModIndex @history.indexOf(@pane.getActiveItem()) + stride

  navigateTop: ->
    @navigating = true
    @pane.activateItem @history.itemAtOffsetHead 0

  select: ->
    if @navigating
      @emitter.emit 'on-end-navigation', this
      @navigating = false
      @history.moveItemHead @pane.getActiveItem() if atom.config.get 'tab-history-mrx.itemTopOnSelect'

  onNavigate: (func) ->
    @disposable.add @emitter.on 'on-navigate', func

  onEndNavigation: (func) ->
    @disposable.add @emitter.on 'on-end-navigation', func

  dispose: ->
    @disposable.dispose()
    @activeEditorCb?.dispose()
