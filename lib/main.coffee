{CompositeDisposable} = require 'atom'
TabHistoryFacade = require './tab-history-facade'
TabHistoryManager = require './tab-history-manager'

module.exports =
  config:
    itemTopOnSelect:
      order: 1
      type: 'boolean'
      default: false
      title: 'Pop an item on select'
      description: 'Make a tab top of the list when it is selected with this function.'
    itemTopOnChange:
      order: 2
      type: 'boolean'
      default: false
      title: 'Pop an item on change'
      description: 'Make a tab top of the list when its content is changed.'
    itemMoveOnAltSelect:
      order: 3
      type: 'string'
      default: 'front-active'
      title: 'Where to move an item on alternative select'
      description: 'Move a tab when it is selected with an alternative function. (ex. tabs, tree-view)'
      enum: ['-', 'top', 'front-active', 'back-active']
    itemMoveOnOpen:
      order: 4
      type: 'string'
      default: 'front-active'
      title: 'Where to place an item on open'
      description: 'Place an opened tab. So far, an opened tab is always also selected,
                    this is overriden by \'alternative select\' setting unless \'-\' is chosen above.'
      enum: ['top', 'bottom', 'front-active', 'back-active']
    limitItems:
      order: 10
      type: 'integer'
      default: 0
      title: 'Forget old items'
      description: 'Auto close tabs from bottom of the list and attempt not to be higher than this limit.
                    (0 for no limit)'

  activate: (state) ->
    @disposable = new CompositeDisposable
    @managers = {}
    @facade = new TabHistoryFacade
    @activePaneId = -1

    newManagerWithFacade = (pane) =>
      @facade.observeManager new TabHistoryManager(pane)

    @disposable.add atom.workspace.onDidAddPane ({pane}) => @managers[pane.id] = newManagerWithFacade(pane)
    @disposable.add atom.workspace.onWillDestroyPane ({pane}) => @managers[pane.id].dispose(); delete @managers[pane.id]
    @managers[pane.id] = newManagerWithFacade(pane) for pane in atom.workspace.getPanes()

    getActivePaneId = =>
      currentActivePaneId = atom.workspace.getActivePane()?.id
      @managers[@activePaneId]?.resetSilently() if @activePaneId isnt currentActivePaneId
      @activePaneId = currentActivePaneId

    # you should set longer enough partialMatchTimeout to avoid this to get fire
    resetAbortTimer = =>
      clearTimeout @keymapTimeout
      @keymapTimeout = setTimeout (=> @managers[getActivePaneId()]?.reset()), atom.keymaps.getPartialMatchTimeout()

    @disposable.add atom.commands.add 'atom-workspace',
      'tab-history-mrx:forward': =>
        resetAbortTimer()
        @managers[getActivePaneId()]?.navigate(-1)
      'tab-history-mrx:back': =>
        resetAbortTimer()
        @managers[getActivePaneId()]?.navigate(1)
      'tab-history-mrx:top': =>
        resetAbortTimer()
        @managers[getActivePaneId()]?.navigateTop()
      'tab-history-mrx:select': =>
        clearTimeout @keymapTimeout
        @managers[getActivePaneId()]?.select()

    # resort to close abandoned modal pane with mousedown
    atom.views.getView(atom.workspace).addEventListener 'mousedown', (event) =>
      @managers[getActivePaneId()]?.reset()

  deactivate: ->
    @disposable.dispose()
    man.dispose() for man in @managers
    @facade.dispose()
