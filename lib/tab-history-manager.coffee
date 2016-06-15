{CompositeDisposable, Emitter} = require 'atom'

module.exports =
class TabHistoryManager
  newHistoryBuffer: (baseArray, headItem) ->
    A = baseArray.concat()
    A = A.concat(A.splice(0, baseArray.indexOf(headItem)))

    A.removeItem = (item) ->
      @splice(index, 1) if (index = @indexOf(item)) >= 0

    A.moveItemTo = (item, toIndex) ->
      if (fromIndex = @indexOf(item)) >= 0
        @splice(toIndex + (if fromIndex < toIndex then -1 else 0), 0, @splice(fromIndex, 1)[0])

    A.moveItemHead = (item) ->
      @moveItemTo item, 0

    A.itemAtModIndex = (index) ->
      @[(index + @length) % @length]
    A

  constructor: (pane) ->
    @pane = pane
    @navigating = false
    @history = @newHistoryBuffer pane.getItems(), pane.getActiveItem()
    @disposable = new CompositeDisposable
    @emitter = new Emitter
    @lastActiveItem = pane.getActiveItem()
    @ignoreOnChange = false

    @disposable.add pane.onDidAddItem ({item}) =>
      @history.push item
      @moveItemOnAltSelect item, 'tab-history-mrx.itemMoveOnOpen'
      @forgetOldItems limit, item if (limit = atom.config.get 'tab-history-mrx.limitItems') > 0
      # bypass follwoing events ( active and change )
      @ignoreOnChange = true
      setTimeout (=> @ignoreOnChange = false), 150

    @disposable.add pane.onWillRemoveItem ({item}) =>
      @history.removeItem item

    @disposable.add pane.observeActiveItem (item) =>
      @activeEditorCb?.dispose()
      if atom.config.get 'tab-history-mrx.itemTopOnChange'
        if atom.workspace.isTextEditor(item)
          @activeEditorCb = item.getBuffer().onDidStopChanging =>
            unless @ignoreOnChange
              @history.moveItemHead item
              @activeEditorCb?.dispose()

      if @navigating
        @emitter.emit 'on-navigate', this
      else
        unless @ignoreOnChange
          @moveItemOnAltSelect item, 'tab-history-mrx.itemMoveOnAltSelect'

      @lastActiveItem = item

  _destroyStep: (limit, keepItem) ->
    if @history.length > limit
      for i in [@history.length - 1..0]
        item = @history[i]
        break if item isnt keepItem and (not atom.workspace.isTextEditor(item) or not item.isModified())
        return if i is 0
      @pane.destroyItem item
      setTimeout (=> @_destroyStep limit, keepItem), 33

  forgetOldItems: (limit, keepItem) ->
    @_destroyStep limit, keepItem

  moveItemOnAltSelect: (item, configKey) ->
    switch atom.config.get configKey
      when 'top' then @history.moveItemHead item
      when 'front-active' then @history.moveItemTo item, Math.max(0, @history.indexOf(@lastActiveItem))
      when 'back-active' then @history.moveItemTo item, Math.max(0, @history.indexOf(@lastActiveItem)) + 1
      when 'bottom' then @history.moveItemTo item, @history.length - 1

  navigate: (stride) ->
    @navigating = true
    @pane.activateItem @history.itemAtModIndex @history.indexOf(@pane.getActiveItem()) + stride

  navigateTop: ->
    @navigating = true
    @pane.activateItem @history[0]

  select: ->
    if @navigating
      @emitter.emit 'on-end-navigation', this
      @navigating = false
      @history.moveItemHead @pane.getActiveItem() if atom.config.get 'tab-history-mrx.itemTopOnSelect'

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
    @activeEditorCb?.dispose()
