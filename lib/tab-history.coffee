{CompositeDisposable, Emitter} = require 'atom'
TabHistoryFacade = require './tab-history-facade'

class TabHistoryManager
  _removeItem: (array, item) ->
    array.splice(index, 1) if (index = array.indexOf(item)) >= 0
    index

  _moveItemTo: (array, item, toIndex) ->
    array.splice(toIndex + (fromIndex < toIndex ? -1 : 0), 0, array.splice(fromIndex, 1)[0]) if (fromIndex = array.indexOf(item)) >= 0

  _ringBufferIndex: (array, index) ->
    if index < 0 then array.length + index else if index >= array.length then index - array.length else index

  constructor: (pane) ->
    @pane = pane
    @navigating = false
    @history = pane.getItems().concat()
    @disposable = new CompositeDisposable
    @headIndex = @history.indexOf pane.getActiveItem()
    @emitter = new Emitter

    @pendingUntilChange = false

    @disposable.add pane.onDidAddItem ({item}) =>
      toIndex = Math.max(0, @history.indexOf(@pane.getActiveItem()))
      @history.splice(toIndex, 0, item)

    @disposable.add pane.onWillRemoveItem ({item}) =>
      index = @_removeItem @history, item
      @headIndex-- if index < @headIndex

    @disposable.add pane.observeActiveItem (item) =>
      @activeEditorCb?.dispose()
      if atom.config.get 'tab-history.itemTopOnChange'
        if atom.workspace.isTextEditor(item)
          @activeEditorCb = item.onDidStopChanging =>
            @makeItemTop item
            @activeEditorCb?.dispose();

      if @navigating
        @emitter.emit 'on-navigate', this
      else
        @makeItemTop item if atom.config.get 'tab-history.itemTopOnActive'

  makeItemTop: (item) ->
    @_moveItemTo @history, item, @headIndex

  navigate: (stride) ->
    @navigating = true
    @pane.activateItem @history[@_ringBufferIndex @history, @history.indexOf(@pane.getActiveItem()) + stride]

  select: ->
    if @navigating
      @emitter.emit 'on-end-navigation', this
      @navigating = false
      @makeItemTop @pane.getActiveItem() if atom.config.get 'tab-history.itemTopOnSelect'

  onNavigate: (func) ->
    @disposable.add @emitter.on 'on-navigate', func

  onEndNavigation: (func) ->
    @disposable.add @emitter.on 'on-end-navigation', func

  dispose: ->
    @disposable.dispose()
    @activeEditorCb?.dispose()

module.exports =
  config:
    itemTopOnSelect:
      order: 1
      type: 'boolean'
      default: false
      title: 'Make a tab top of the list when it is selected by this packge function'
    itemTopOnActive:
      order: 2
      type: 'boolean'
      default: false
      title: 'Make a tab top of the list when it is activated by other function to activate tab  (ex. tabs, tree-view)'
    itemTopOnChange:
      order: 3
      type: 'boolean'
      default: false
      title: 'Make a tab top of the list when its content changed'

  activate: (state) ->
    @disposable = new CompositeDisposable
    @managers = {}
    @facade = new TabHistoryFacade

    newManagerWithFacade = (pane) =>
      @facade.observeManager new TabHistoryManager(pane)

    @disposable.add atom.workspace.onDidAddPane ({pane}) => @managers[pane.id] = newManagerWithFacade(pane)
    @disposable.add atom.workspace.onWillDestroyPane ({pane}) => @managers[pane.id].dispose(); delete @managers[pane.id]
    @managers[pane.id] = newManagerWithFacade(pane) for pane in atom.workspace.getPanes()

    # set longer enough partialMatchTimeout to avoid this to fire
    resetAbortTimer = =>
      clearTimeout @keymapTimeout
      @keymapTimeout = setTimeout (=> @facade.reset()), atom.keymaps.getPartialMatchTimeout() + 100

    @disposable.add atom.commands.add 'atom-workspace',
      'tab-history:forward': =>
        resetAbortTimer()
        @managers[pane.id]?.navigate(-1) if pane = atom.workspace.getActivePane()
      'tab-history:back': =>
        resetAbortTimer()
        @managers[pane.id]?.navigate(1) if pane = atom.workspace.getActivePane()
      'tab-history:select': =>
        @managers[pane.id]?.select() if pane = atom.workspace.getActivePane()

    # resort to close abandonned modal pane with mousedown
    atom.views.getView(atom.workspace).addEventListener 'mousedown', (event) =>
      @facade.reset()

  deactivate: ->
    @disposable.dispose()
    man.dispose() for man in @managers
    @facade.dispose()
