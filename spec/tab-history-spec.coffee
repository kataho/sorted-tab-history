describe 'SortedTabHistory', ->
  activeItem = -> atom.workspace.getActivePane().getActiveItem()
  activeItemTitle = -> atom.workspace.getActivePane().getActiveItem().getTitle()
  activateItemWithTitle = (title) ->
    atom.workspace.getActivePane().activateItem atom.workspace.getActivePane().getItems().find (item) ->
      item.getTitle() == title
  dispatchCommand = (cmd) -> atom.commands.dispatch(atom.views.getView(atom.workspace), cmd)
  internalListTitles = -> historyManager.history.sortedItemList().reduce ((p, c) -> (p && p + ',') + c.getTitle()), ''

  historyManager = null
  mainModule = null
  workspaceElement = null
  RANK_IGNORE = -1
  TMP_DIR = '/tmp/sorted-tab-history.spec/'

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = null

    runs ->
      activationPromise = atom.packages.activatePackage('sorted-tab-history')
      jasmine.attachToDOM(workspaceElement)

    waitsForPromise ->
      activationPromise.then ->
        mainModule = atom.packages.getActivePackage('sorted-tab-history').mainModule
        historyManager = mainModule.managers[atom.workspace.getActivePane().id]

    waitsForPromise ->
      atom.config.set('sorted-tab-history.sortRank_open', 6)
      atom.config.set('sorted-tab-history.sortRank_select_ext', 5)
      atom.config.set('sorted-tab-history.sortRank_select', 4)
      atom.config.set('sorted-tab-history.sortRank_change', 3)
      atom.config.set('sorted-tab-history.sortRank_cursor', 2)
      atom.config.set('sorted-tab-history.sortRank_save', 1)
      atom.config.set('sorted-tab-history.timeoutMinutes', 180)
      atom.config.set('sorted-tab-history.limitItems', 5)
      atom.config.set('sorted-tab-history.circularList', true)
      atom.workspace.open('E1').then ->
        atom.workspace.open('E2').then ->
          atom.workspace.open('E3').then ->
            atom.workspace.open('E4')

  afterEach ->
    atom.workspace.getActivePane().destroyItems()

  describe 'Package activation', ->
    it 'makes stuff looks ready to go', ->
      expect(atom.packages.isPackageActive('sorted-tab-history')).toBe true

  describe 'List navigation commands', ->
    it 'changes active item in pane to next list item', ->
      expect(activeItemTitle()).toBe 'E4'
      dispatchCommand('sorted-tab-history:forward')
      dispatchCommand('sorted-tab-history:forward')
      dispatchCommand('sorted-tab-history:forward')
      dispatchCommand('sorted-tab-history:select')
      expect(activeItemTitle()).toBe 'E3'

    it 'changes active item in pane to previous list item', ->
      expect(activeItemTitle()).toBe 'E4'
      dispatchCommand('sorted-tab-history:back')
      dispatchCommand('sorted-tab-history:back')
      dispatchCommand('sorted-tab-history:back')
      dispatchCommand('sorted-tab-history:select')
      expect(activeItemTitle()).toBe 'E1'

    it 'activates item while selection', ->
      expect(activeItemTitle()).toBe 'E4'
      dispatchCommand('sorted-tab-history:back')
      expect(activeItemTitle()).toBe 'E3'
      dispatchCommand('sorted-tab-history:back')
      expect(activeItemTitle()).toBe 'E2'
      dispatchCommand('sorted-tab-history:forward')
      expect(activeItemTitle()).toBe 'E3'

  describe 'Settings: sorting items', ->
    it 'sorts with various kind of event', ->
      # initial order
      expect(internalListTitles()).toBe 'E4,E3,E2,E1'

      # it sorts items by open event

      # it sorts items by other select feature
      activateItemWithTitle 'E2'
      expect(internalListTitles()).toBe 'E2,E4,E3,E1'
      activateItemWithTitle 'E3'
      expect(internalListTitles()).toBe 'E3,E2,E4,E1'
      activateItemWithTitle 'E4'
      expect(internalListTitles()).toBe 'E4,E3,E2,E1'

      # it sorts items by select event
      dispatchCommand('sorted-tab-history:back')
      dispatchCommand('sorted-tab-history:select')
      expect(internalListTitles()).toBe 'E3,E4,E2,E1'

      # it sorts items by change event
      activeItem().setText('abcdefg')
      dispatchCommand('sorted-tab-history:back')
      dispatchCommand('sorted-tab-history:back')
      dispatchCommand('sorted-tab-history:select')
      expect(internalListTitles()).toBe 'E3,E2,E4,E1'
      activeItem().setText('abcdefg')
      expect(internalListTitles()).toBe 'E2,E3,E4,E1'

      # it sorts items by cursor move event
      dispatchCommand('sorted-tab-history:back')
      dispatchCommand('sorted-tab-history:select')
      activeItem().moveLeft(1)
      expect(internalListTitles()).toBe 'E3,E2,E4,E1'

      # priority of events
      dispatchCommand('sorted-tab-history:back')
      dispatchCommand('sorted-tab-history:back')
      dispatchCommand('sorted-tab-history:back')
      dispatchCommand('sorted-tab-history:select')
      expect(internalListTitles()).toBe 'E3,E2,E1,E4'

      # it sorts items by save event
      dispatchCommand('sorted-tab-history:forward')
      dispatchCommand('sorted-tab-history:select')
      activeItem().saveAs(TMP_DIR + 'E2')
      expect(internalListTitles()).toBe 'E2,E3,E1,E4'

      dispatchCommand('sorted-tab-history:back')
      dispatchCommand('sorted-tab-history:back')
      dispatchCommand('sorted-tab-history:select')
      activeItem().setText('abcdefg')
      expect(internalListTitles()).toBe 'E2,E1,E3,E4'

  describe 'Settings: sorting items (multiple events share a rank)', ->
    it 'compares different timestamp value as one sorting parameter', ->
      atom.config.set('sorted-tab-history.sortRank_select', 5)
      atom.config.set('sorted-tab-history.sortRank_select_ext', 5)
      activateItemWithTitle 'E2'
      expect(internalListTitles()).toBe 'E2,E4,E3,E1'
      dispatchCommand('sorted-tab-history:back')
      dispatchCommand('sorted-tab-history:back')
      dispatchCommand('sorted-tab-history:select')
      expect(internalListTitles()).toBe 'E3,E2,E4,E1'
      activateItemWithTitle 'E1'
      expect(internalListTitles()).toBe 'E1,E3,E2,E4'

  describe 'Settings: timeoutMinutes', ->
    it 'ignores timestamp of action older than timeoutMinutes', ->
      jasmine.useRealClock()
      expect(internalListTitles()).toBe 'E4,E3,E2,E1'

      activeItem().setText('abcdefg')
      dispatchCommand('sorted-tab-history:back')
      dispatchCommand('sorted-tab-history:select')
      activeItem().setText('abcdefg')
      expect(internalListTitles()).toBe 'E3,E4,E2,E1'

      atom.config.set('sorted-tab-history.timeoutMinutes', (1.0 / 60.0) * 0.5)
      atom.config.set('sorted-tab-history.sortRank_select_ext', RANK_IGNORE)
      atom.config.set('sorted-tab-history.sortRank_open', RANK_IGNORE)

      waitsForPromise ->
        new Promise (resolve) ->
          setTimeout resolve, 1000
        .then ->
          dispatchCommand('sorted-tab-history:forward')
          dispatchCommand('sorted-tab-history:select')
          expect(internalListTitles()).toBe 'E1,E3,E4,E2'

    it 'totally ignores timestamps which rank is "ignore rank" (the worst number in rank list in settings)', ->
      expect(internalListTitles()).toBe 'E4,E3,E2,E1'
      atom.config.set('sorted-tab-history.sortRank_select', RANK_IGNORE)
      expect(internalListTitles()).toBe 'E4,E3,E2,E1'
      dispatchCommand('sorted-tab-history:back')
      dispatchCommand('sorted-tab-history:select')
      expect(internalListTitles()).toBe 'E4,E3,E2,E1'
      activeItem().setText('abcdefg')
      expect(internalListTitles()).toBe 'E3,E4,E2,E1'
      dispatchCommand('sorted-tab-history:forward')
      dispatchCommand('sorted-tab-history:select')
      expect(internalListTitles()).toBe 'E3,E4,E2,E1'

    it 'handles timestamps which rank is not "ignore rank" but minimum rank never timeout', ->
      jasmine.useRealClock()
      expect(internalListTitles()).toBe 'E4,E3,E2,E1'
      atom.config.set('sorted-tab-history.timeoutMinutes', 0.0001)
      atom.config.set('sorted-tab-history.sortRank_select_ext', RANK_IGNORE)
      atom.config.set('sorted-tab-history.sortRank_open', RANK_IGNORE)

      dispatchCommand('sorted-tab-history:back')
      dispatchCommand('sorted-tab-history:select')
      expect(internalListTitles()).toBe 'E3,E4,E2,E1'
      dispatchCommand('sorted-tab-history:forward')
      dispatchCommand('sorted-tab-history:select')
      expect(internalListTitles()).toBe 'E1,E3,E4,E2'

      waitsForPromise ->
        new Promise (resolve) ->
          setTimeout resolve, 1000
        .then ->
          dispatchCommand('sorted-tab-history:back')
          dispatchCommand('sorted-tab-history:select')
          expect(internalListTitles()).toBe 'E3,E1,E4,E2'

  describe 'Settings: limitItems', ->
    it 'closes and disposes items on tail to keep count of items in the list', ->
      waitsForPromise ->
        atom.workspace.open('E5').then ->
          atom.workspace.open('E6').then ->
            advanceClock(1000)
            expect(internalListTitles()).toBe 'E6,E5,E4,E3,E2'
            atom.workspace.open('E7').then ->
              advanceClock(1000)
              expect(internalListTitles()).toBe 'E7,E6,E5,E4,E3'

    it 'does not close items on tail but modified', ->
      atom.config.set('sorted-tab-history.sortRank_change', RANK_IGNORE)
      atom.config.set('sorted-tab-history.sortRank_cursor', RANK_IGNORE)
      waitsForPromise ->
        atom.workspace.open('E5').then ->
          list = historyManager.history.sortedItemList()
          expect(list[list.length - 1].getTitle()).toBe 'E1'
          list[list.length - 1].setText('abcde')
          atom.workspace.open('E6').then ->
            advanceClock(1000)
            expect(internalListTitles()).toBe 'E6,E5,E4,E3,E1'

    it 'does not close items on tail but currently opened', ->
      atom.config.set('sorted-tab-history.sortRank_select_ext', RANK_IGNORE)
      atom.config.set('sorted-tab-history.sortRank_open', RANK_IGNORE)
      waitsForPromise ->
        atom.workspace.open('E5').then ->
          advanceClock(1000)
          expect(internalListTitles()).toMatch '.*,E5$'
          atom.workspace.open('E6').then ->
            advanceClock(1000)
            expect(internalListTitles()).toMatch '.*,E6$'

  describe 'Settings: circularList', ->
    it 'prevents active item change on forwarding from head and backwarding from tail. [coverage false case]', ->
      atom.config.set('sorted-tab-history.circularList', false)
      atom.config.set('sorted-tab-history.sortRank_select_ext', 4)
      atom.config.set('sorted-tab-history.sortRank_select', RANK_IGNORE)
      expect(activeItemTitle()).toBe('E4')
      dispatchCommand('sorted-tab-history:forward')
      dispatchCommand('sorted-tab-history:select')
      expect(activeItemTitle()).toBe('E4')
      dispatchCommand('sorted-tab-history:back')
      dispatchCommand('sorted-tab-history:back')
      dispatchCommand('sorted-tab-history:back')
      dispatchCommand('sorted-tab-history:back')
      dispatchCommand('sorted-tab-history:back')
      dispatchCommand('sorted-tab-history:select')
      expect(activeItemTitle()).toBe('E1')

    it 'changes active item from head to tail with forwarding, from tail to head with backwarding.', ->
      atom.config.set('sorted-tab-history.sortRank_select_ext', 4)
      atom.config.set('sorted-tab-history.sortRank_select', RANK_IGNORE)
      expect(activeItemTitle()).toBe('E4')
      dispatchCommand('sorted-tab-history:forward')
      dispatchCommand('sorted-tab-history:select')
      expect(activeItemTitle()).toBe('E1')
      dispatchCommand('sorted-tab-history:back')
      dispatchCommand('sorted-tab-history:back')
      dispatchCommand('sorted-tab-history:select')
      expect(activeItemTitle()).toBe('E3')

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
