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
      if atom.config.get 'tab-history.itemTopOnOpen'
        @history.moveItemHead item
      else
        @history.moveItemTo item, Math.max(0, @history.indexOf(@pane.getActiveItem()))

      @destroyItemStep() if atom.config.get 'tab-history.limitItems' > 0

    @disposable.add pane.onWillRemoveItem ({item}) =>
      @history.removeItem item

    @disposable.add pane.observeActiveItem (item) =>
      @activeEditorCb?.dispose()
      if atom.config.get 'tab-history.itemTopOnChange'
        if atom.workspace.isTextEditor(item)
          @activeEditorCb = item.onDidStopChanging =>
            @history.moveItemHead item
            @activeEditorCb?.dispose();

      if @navigating
        @emitter.emit 'on-navigate', this
      else
        @history.moveItemHead item if atom.config.get 'tab-history.itemTopOnActive'

  destroyItemStep: ->
    if @history.length > atom.config.get 'tab-history.limitItems'
      @pane.destroyItem @history.itemAtOffsetHead(-1)
      setTimeout (=> @destroyItemStep()), 33

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
      @history.moveItemHead @pane.getActiveItem() if atom.config.get 'tab-history.itemTopOnSelect'

  onNavigate: (func) ->
    @disposable.add @emitter.on 'on-navigate', func

  onEndNavigation: (func) ->
    @disposable.add @emitter.on 'on-end-navigation', func

  dispose: ->
    @disposable.dispose()
    @activeEditorCb?.dispose()
