{CompositeDisposable} = require 'atom'
TabHistoryFacade = require './tab-history-facade'
TabHistoryManager = require './tab-history-manager'

module.exports =
  config:
    sortRank_select:
      order: 1
      type: 'integer'
      default: 4
      title: 'Sort Rank : Select'
      description: 'Sorting priority rank of activation (focusing) of a tab item'
      enum: [1, 2, 3, 4, 5]
    sortRank_cursor:
      order: 2
      type: 'integer'
      default: 3
      title: 'Sort Rank : Cursor Move'
      description: 'Sorting priority rank of cursor move on an editor'
      enum: [1, 2, 3, 4, 5]
    sortRank_change:
      order: 3
      type: 'integer'
      default: 2
      title: 'Sort Rank : Change'
      description: 'Sorting priority rank of content change of an editor'
      enum: [1, 2, 3, 4, 5]
    sortRank_save:
      order: 4
      type: 'integer'
      default: 1
      title: 'Sort Rank : Save'
      description: 'Sorting priority rank of save of content of a tab item'
      enum: [1, 2, 3, 4, 5]
    timeoutMinutes:
      order: 10
      type: 'number'
      default: 180
      title: 'Expiration of events (minutes)'
      description: 'An event past longer than this is ignored and the item is sorted by lesser rank events. '
    limitItems:
      order: 20
      type: 'integer'
      default: 0
      title: 'Maximum tabs in a pane'
      description: 'Keep number of tabs by closing last tabs of the sort result.
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
