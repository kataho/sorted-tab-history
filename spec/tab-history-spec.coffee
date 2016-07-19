describe 'TabHistoryMRX', ->
  activeItem = -> atom.workspace.getActivePane().getActiveItem()
  activeItemTitle = -> atom.workspace.getActivePane().getActiveItem().getTitle()
  dispatchCommand = (cmd) -> atom.commands.dispatch(atom.views.getView(atom.workspace), cmd)
  internalListTitles = -> historyManager.history.sortedItemList().reduce ((p, c) -> (p && p + ',') + c.getTitle()), ''

  historyManager = null
  mainModule = null
  workspaceElement = null
  RANK_IGNORE = 5
  TMP_DIR = '/tmp/tab-history-mrx.spec/'

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = null

    runs ->
      activationPromise = atom.packages.activatePackage('tab-history-mrx')
      jasmine.attachToDOM(workspaceElement)

    waitsForPromise ->
      activationPromise.then ->
        mainModule = atom.packages.getActivePackage('tab-history-mrx').mainModule
        historyManager = mainModule.managers[atom.workspace.getActivePane().id]

    waitsForPromise ->
      atom.config.set('tab-history-mrx.sortRank_select', 4)
      atom.config.set('tab-history-mrx.sortRank_change', 3)
      atom.config.set('tab-history-mrx.sortRank_cursor', 2)
      atom.config.set('tab-history-mrx.sortRank_save', 1)
      atom.config.set('tab-history-mrx.timeoutMinutes', 180)
      atom.config.set('tab-history-mrx.limitItems', 5)
      atom.workspace.open('E1').then ->
        atom.workspace.open('E2').then ->
          atom.workspace.open('E3').then ->
            atom.workspace.open('E4')

  afterEach ->
    atom.workspace.getActivePane().destroyItems()

  describe 'Package activation', ->
    it 'makes stuff looks ready to go', ->
      expect(atom.packages.isPackageActive('tab-history-mrx')).toBe true

  describe 'List navigation commands', ->
    it 'changes active item in pane to next list item', ->
      expect(activeItemTitle()).toBe 'E4'
      dispatchCommand('tab-history-mrx:forward')
      dispatchCommand('tab-history-mrx:forward')
      dispatchCommand('tab-history-mrx:forward')
      dispatchCommand('tab-history-mrx:select')
      expect(activeItemTitle()).toBe 'E3'

    it 'changes active item in pane to previous list item', ->
      expect(activeItemTitle()).toBe 'E4'
      dispatchCommand('tab-history-mrx:back')
      dispatchCommand('tab-history-mrx:back')
      dispatchCommand('tab-history-mrx:back')
      dispatchCommand('tab-history-mrx:select')
      expect(activeItemTitle()).toBe 'E1'

    it 'activates item while selection', ->
      expect(activeItemTitle()).toBe 'E4'
      dispatchCommand('tab-history-mrx:back')
      expect(activeItemTitle()).toBe 'E3'
      dispatchCommand('tab-history-mrx:back')
      expect(activeItemTitle()).toBe 'E2'
      dispatchCommand('tab-history-mrx:forward')
      expect(activeItemTitle()).toBe 'E3'

  describe 'Settings: sorting items', ->
    it 'sorts with various kind of event', ->
      # initial order
      expect(internalListTitles()).toBe 'E4,E3,E2,E1'

      # it sorts items by select event
      dispatchCommand('tab-history-mrx:back')
      dispatchCommand('tab-history-mrx:select')
      expect(internalListTitles()).toBe 'E3,E4,E2,E1'

      # it sorts items by change event
      activeItem().setText('abcdefg')
      dispatchCommand('tab-history-mrx:back')
      dispatchCommand('tab-history-mrx:back')
      dispatchCommand('tab-history-mrx:select')
      expect(internalListTitles()).toBe 'E3,E2,E4,E1'
      activeItem().setText('abcdefg')
      expect(internalListTitles()).toBe 'E2,E3,E4,E1'

      # it sorts items by cursor move event
      dispatchCommand('tab-history-mrx:back')
      dispatchCommand('tab-history-mrx:select')
      activeItem().moveLeft(1)
      expect(internalListTitles()).toBe 'E3,E2,E4,E1'

      # priority of events
      dispatchCommand('tab-history-mrx:back')
      dispatchCommand('tab-history-mrx:back')
      dispatchCommand('tab-history-mrx:back')
      dispatchCommand('tab-history-mrx:select')
      expect(internalListTitles()).toBe 'E3,E2,E1,E4'

      # it sorts items by save event
      dispatchCommand('tab-history-mrx:forward')
      dispatchCommand('tab-history-mrx:select')
      activeItem().saveAs(TMP_DIR + 'E2')
      expect(internalListTitles()).toBe 'E2,E3,E1,E4'

      dispatchCommand('tab-history-mrx:back')
      dispatchCommand('tab-history-mrx:back')
      dispatchCommand('tab-history-mrx:select')
      activeItem().setText('abcdefg')
      expect(internalListTitles()).toBe 'E2,E1,E3,E4'

  describe 'Settings: timeoutMinutes', ->
    it 'ignores timestamp of action older then timeoutMinutes', ->
      jasmine.useRealClock()
      expect(internalListTitles()).toBe 'E4,E3,E2,E1'

      activeItem().setText('abcdefg')
      dispatchCommand('tab-history-mrx:back')
      dispatchCommand('tab-history-mrx:select')
      activeItem().setText('abcdefg')
      expect(internalListTitles()).toBe 'E3,E4,E2,E1'

      atom.config.set('tab-history-mrx.timeoutMinutes', (1.0 / 60.0) * 0.5)

      waitsForPromise ->
        new Promise (resolve) ->
          setTimeout resolve, 1000
        .then ->
          dispatchCommand('tab-history-mrx:forward')
          dispatchCommand('tab-history-mrx:select')
          expect(internalListTitles()).toBe 'E1,E3,E4,E2'

    it 'totally ignores timestamps which rank is "ignore rank" (the worst number in rank list in settings)', ->
      expect(internalListTitles()).toBe 'E4,E3,E2,E1'
      atom.config.set('tab-history-mrx.sortRank_select', RANK_IGNORE)
      expect(internalListTitles()).toBe 'E4,E3,E2,E1'
      dispatchCommand('tab-history-mrx:back')
      dispatchCommand('tab-history-mrx:select')
      expect(internalListTitles()).toBe 'E4,E3,E2,E1'
      activeItem().setText('abcdefg')
      expect(internalListTitles()).toBe 'E3,E4,E2,E1'
      dispatchCommand('tab-history-mrx:forward')
      dispatchCommand('tab-history-mrx:select')
      expect(internalListTitles()).toBe 'E3,E4,E2,E1'

    it 'handles timestamps which rank is not "ignore rank" but minimum rank never timeout', ->
      jasmine.useRealClock()
      expect(internalListTitles()).toBe 'E4,E3,E2,E1'
      atom.config.set('tab-history-mrx.timeoutMinutes', 0.0001)

      dispatchCommand('tab-history-mrx:back')
      dispatchCommand('tab-history-mrx:select')
      expect(internalListTitles()).toBe 'E3,E4,E2,E1'
      dispatchCommand('tab-history-mrx:forward')
      dispatchCommand('tab-history-mrx:select')
      expect(internalListTitles()).toBe 'E1,E3,E4,E2'

      waitsForPromise ->
        new Promise (resolve) ->
          setTimeout resolve, 1000
        .then ->
          dispatchCommand('tab-history-mrx:back')
          dispatchCommand('tab-history-mrx:select')
          expect(internalListTitles()).toBe 'E3,E1,E4,E2'

  describe 'Settings: limitItems', ->
    it 'automatically close and dispose items for avoiding to exceed limit of items in the list', ->
      waitsForPromise ->
        atom.workspace.open('E5').then ->
          atom.workspace.open('E6').then ->
            advanceClock(1000)
            expect(internalListTitles()).toBe 'E6,E5,E4,E3,E2'
            atom.workspace.open('E7').then ->
              advanceClock(1000)
              expect(internalListTitles()).toBe 'E7,E6,E5,E4,E3'

    it 'does not close items on bottom and modified', ->
      atom.config.set('tab-history-mrx.sortRank_change', RANK_IGNORE)
      atom.config.set('tab-history-mrx.sortRank_cursor', RANK_IGNORE)
      waitsForPromise ->
        atom.workspace.open('E5').then ->
          list = historyManager.history.sortedItemList()
          expect(list[list.length - 1].getTitle()).toBe 'E1'
          list[list.length - 1].setText('abcde')
          atom.workspace.open('E6').then ->
            advanceClock(1000)
            expect(internalListTitles()).toBe 'E6,E5,E4,E3,E1'

    it 'does not close items on bottom and currently opened', ->
      atom.config.set('tab-history-mrx.sortRank_select', RANK_IGNORE)
      waitsForPromise ->
        atom.workspace.open('E5').then ->
          advanceClock(1000)
          expect(internalListTitles()).toMatch '.*,E5$'
          atom.workspace.open('E6').then ->
            advanceClock(1000)
            expect(internalListTitles()).toMatch '.*,E6$'

  describe 'Facade: sub-title', ->
    it 'generates sub-title by last difference of path fragments', ->
      waitsForPromise ->
        atom.workspace.open('file://' + TMP_DIR + 'ddd/ccc/bbbb/EX').then ->
          advanceClock(1000)
          atom.workspace.open('file://' + TMP_DIR + 'ddd/ccc/qqqq/bbbb/EX').then ->
            advanceClock(1000)
            expect(historyManager.history.stamps[0].subTitle).not.toBe ''
            expect(historyManager.history.stamps[1].subTitle).not.toBe ''
            expect(historyManager.history.stamps[2].subTitle).toBe ''

    it 'gives up making sub-title of item which can not getPath', ->
      waitsForPromise ->
        atom.workspace.open('EX').then ->
          advanceClock(1000)
          atom.workspace.open('EX').then ->
            advanceClock(1000)
            expect(historyManager.history.stamps[0].subTitle).toBe ''
            expect(historyManager.history.stamps[1].subTitle).toBe ''
            expect(historyManager.history.stamps[2].subTitle).toBe ''

  describe 'Facade: formating time elapsed', ->
    it 'formats millisecs to various short string', ->
      expect(mainModule.facade.formatDelayTime(1000)).toBe '1s'
      expect(mainModule.facade.formatDelayTime(1000 * 60)).toBe '1m'
      expect(mainModule.facade.formatDelayTime(1000 * 60 + 1)).toBe '1m'
      expect(mainModule.facade.formatDelayTime(1000 * 60 - 1)).toBe '59s'
      expect(mainModule.facade.formatDelayTime(1000 * 60 * 60)).toBe '1h'
      expect(mainModule.facade.formatDelayTime(1000 * 60 * 60 - 1)).toBe '59m'
