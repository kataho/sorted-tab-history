{Disposable, CompositeDisposable} = require 'atom'
TabHistoryFacade = require './tab-history-facade'
TabHistoryManager = require './tab-history-manager'

module.exports =
  config:
    sortRank_select:
      order: 1
      type: 'integer'
      default: 1
      title: 'Sort Rank : Internal Select'
      description: 'Sorting priority rank of activation (focusing) of a tab item with the package\'s popup list.'
      enum: [1, 2, 3, 4, 5, 6, -1]
    sortRank_select_ext:
      order: 2
      type: 'integer'
      default: 1
      title: 'Sort Rank : External Select'
      description: 'Sorting priority rank of activation (focusing) of a tab item
                    with an other tab item selecting feature. (ex. by clicking tabs, tree-view items)'
      enum: [1, 2, 3, 4, 5, 6, -1]
    sortRank_open:
      order: 3
      type: 'integer'
      default: -1
      title: 'Sort Rank : Open'
      description: 'Sorting priority rank of opening of a new tab item'
      enum: [1, 2, 3, 4, 5, 6, -1]
    sortRank_cursor:
      order: 4
      type: 'integer'
      default: -1
      title: 'Sort Rank : Cursor Move'
      description: 'Sorting priority rank of cursor move on an editor.'
      enum: [1, 2, 3, 4, 5, 6, -1]
    sortRank_change:
      order: 5
      type: 'integer'
      default: 2
      title: 'Sort Rank : Change'
      description: 'Sorting priority rank of content change of an editor.'
      enum: [1, 2, 3, 4, 5, 6, -1]
    sortRank_save:
      order: 6
      type: 'integer'
      default: -1
      title: 'Sort Rank : Save'
      description: 'Sorting priority rank of save of content of a tab item.'
      enum: [1, 2, 3, 4, 5, 6, -1]
    timeoutMinutes:
      order: 10
      type: 'number'
      default: 5
      title: 'Expiration of Events (in minutes)'
      description: 'An event past longer than this is ignored. It leads the item being sorted by lesser ranked event. '
    limitItems:
      order: 20
      type: 'integer'
      default: 10
      title: 'Maximum Tabs in a Pane'
      description: 'Keeps number of tabs in a pane by closing last tabs of the sorted list. (0 for no limit)'
    circularList:
      order: 30
      type: 'boolean'
      default: false
      title: 'Circular List'
      description: 'Connects head and tail of the list.'

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
      'sorted-tab-history:forward': =>
        resetAbortTimer()
        @managers[getActivePaneId()]?.navigate(-1)
      'sorted-tab-history:back': =>
        resetAbortTimer()
        @managers[getActivePaneId()]?.navigate(1)
      'sorted-tab-history:top': =>
        resetAbortTimer()
        @managers[getActivePaneId()]?.navigateTop()
      'sorted-tab-history:select': =>
        clearTimeout @keymapTimeout
        @managers[getActivePaneId()]?.select()

    # resort to close abandoned modal pane with mousedown
    atom.views.getView(atom.workspace).addEventListener 'mousedown', (event) =>
      @managers[getActivePaneId()]?.reset()

  deactivate: ->
    @disposable.dispose()
    man.dispose() for man in @managers
    @facade.dispose()

  consumeElementIcons: (func) ->
    @facade.addIconToElement = func
    new Disposable =>
      @facade.addIconToElement = null
