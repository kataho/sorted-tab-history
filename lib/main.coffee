{CompositeDisposable} = require 'atom'
TabHistoryFacade = require './tab-history-facade'
TabHistoryManager = require './tab-history-manager'

module.exports =
  config:
    itemTopOnSelect:
      order: 1
      type: 'boolean'
      default: false
      title: 'Pop item on select'
      description: 'Make a tab top of the list when it is selected with this function.'
    itemTopOnActive:
      order: 2
      type: 'boolean'
      default: false
      title: 'Pop item on alternative select'
      description: 'Make a tab top of the list when it is selected with an alternative function. (ex. tabs, tree-view)'
    itemTopOnOpen:
      order: 3
      type: 'boolean'
      default: false
      title: 'Pop item on open'
      description: 'Make a tab top of the list when it is opened. (otherwise place on next of current active tab)'
    itemTopOnChange:
      order: 4
      type: 'boolean'
      default: false
      title: 'Pop item on change'
      description: 'Make a tab top of the list when its content is changed.'
    limitItems:
      order:10
      type: 'number'
      default: 0
      title: 'Forget old items'
      description: 'Auto close tabs from bottom of the list keeping this limit. (0 for no limit)'

  activate: (state) ->
    @disposable = new CompositeDisposable
    @managers = {}
    @facade = new TabHistoryFacade

    newManagerWithFacade = (pane) =>
      @facade.observeManager new TabHistoryManager(pane)

    @disposable.add atom.workspace.onDidAddPane ({pane}) => @managers[pane.id] = newManagerWithFacade(pane)
    @disposable.add atom.workspace.onWillDestroyPane ({pane}) => @managers[pane.id].dispose(); delete @managers[pane.id]
    @managers[pane.id] = newManagerWithFacade(pane) for pane in atom.workspace.getPanes()

    # you should set longer enough partialMatchTimeout to avoid this to get fire
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
      'tab-history:top': =>
        resetAbortTimer()
        @managers[pane.id]?.navigateTop() if pane = atom.workspace.getActivePane()
      'tab-history:select': =>
        @managers[pane.id]?.select() if pane = atom.workspace.getActivePane()

    # resort to close abandonned modal pane with mousedown
    atom.views.getView(atom.workspace).addEventListener 'mousedown', (event) =>
      @facade.reset()

  deactivate: ->
    @disposable.dispose()
    man.dispose() for man in @managers
    @facade.dispose()
