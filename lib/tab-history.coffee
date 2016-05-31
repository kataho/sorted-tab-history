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
    @pendingActivation = false
    @history = pane.getItems().concat()
    @disposable = new CompositeDisposable
    @headIndex = @history.indexOf pane.getActiveItem()
    @emitter = new Emitter

    @orderWhenChange = false

    @disposable.add pane.onDidAddItem ({item}) =>
      @history.push item

    @disposable.add pane.onWillRemoveItem ({item}) =>
      index = @_removeItem @history, item
      @headIndex-- if index < @headIndex

    @disposable.add pane.observeActiveItem (item) =>
      if @pendingActivation
        @emitter.emit 'on-navigating', this
      else
        @moveItemToTop item

  moveItemToTop: (item) ->
    if @orderWhenChange
      @activeEditorCb?.dispose()
      if atom.workspace.isTextEditor(item)
        @activeEditorCb = item.onDidStopChanging =>
          @_moveItemTo @history, item, @headIndex
          @activeEditorCb?.dispose();
    else
      @_moveItemTo @history, item, @headIndex

  back: ->
    @pendingActivation = true
    @pane.activateItem @history[@_ringBufferIndex @history, @history.indexOf(@pane.getActiveItem()) + 1]

  forward: ->
    @pendingActivation = true
    @pane.activateItem @history[@_ringBufferIndex @history, @history.indexOf(@pane.getActiveItem()) - 1]

  select: ->
    @emitter.emit 'on-end-navigation', this
    @pendingActivation = false
    @moveItemToTop @pane.getActiveItem()

  onNavigating: (func) ->
    @disposable.add @emitter.on 'on-navigating', func

  onEndNavigation: (func) ->
    @disposable.add @emitter.on 'on-end-navigation', func

  dispose: ->
    @disposable.dispose()
    @activeEditorCb?.dispose()

  serialize: ->


module.exports =
  config: {}

  activate: (state) ->
    @disposable = new CompositeDisposable
    @managers = {}
    @facade = new TabHistoryFacade

    newManagerWithFacade = (pane) =>
      @facade.observeManager new TabHistoryManager(pane)

    @disposable.add atom.workspace.onDidAddPane ({pane}) => @managers[pane.id] = newManagerWithFacade(pane)
    @disposable.add atom.workspace.onWillDestroyPane ({pane}) => @managers[pane.id].dispose(); delete @managers[pane.id]
    @managers[pane.id] = newManagerWithFacade(pane) for pane in atom.workspace.getPanes()

    @disposable.add atom.commands.add 'atom-workspace',
      'tab-history:forward': =>
        @managers[pane.id]?.forward() if pane = atom.workspace.getActivePane()
      'tab-history:back': =>
        @managers[pane.id]?.back() if pane = atom.workspace.getActivePane()
      'tab-history:select': =>
        @managers[pane.id]?.select() if pane = atom.workspace.getActivePane()

  deactivate: ->
    @disposable.dispose()
    man.dispose() for man in @managers
    @facade.dispose()
