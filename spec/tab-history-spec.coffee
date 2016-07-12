describe 'TabHistoryMRX', ->
  activeItemTitle = -> atom.workspace.getActivePane().getActiveItem().getTitle()
  dispatchCommand = (cmd) -> atom.commands.dispatch(atom.views.getView(atom.workspace), cmd)
  internalListTitles = ->
    historyManager.history.sortedItemList().reduce ((prev, cur) ->
      (if prev.length > 0 then prev + ',' else '') + cur.getTitle()), ''

  historyManager = null
  workspaceElement = null

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = null

    runs ->
      activationPromise = atom.packages.activatePackage('tab-history-mrx')
      jasmine.attachToDOM(workspaceElement)

    waitsForPromise ->
      activationPromise.then ->
        historyManager = atom.packages.getActivePackage('tab-history-mrx')
          .mainModule.managers[atom.workspace.getActivePane().id]

    waitsForPromise ->
      atom.config.set('tab-history-mrx.sortRank_select', 4)
      atom.config.set('tab-history-mrx.sortRank_cursor', 3)
      atom.config.set('tab-history-mrx.sortRank_change', 2)
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

  describe 'Options', ->
    describe 'sort by multiple order', ->
      it 'sorts items on test setting 0', ->
        expect(internalListTitles()).toBe 'E4,E3,E2,E1'

      it 'sorts items on test setting 1', ->


      it 'sorts items on test setting 2', ->

      it 'sorts items on test setting 3', ->

    describe 'timeoutMinutes', ->
      it 'ignores timestamp of action older then timeoutMinutes', ->

    describe 'limitItems', ->
      it 'automatically close and dispose item not to exceed limit of items in the list', ->

      it 'does not close item on bottom but modified', ->

      it 'does not close item on bottom but active currently', ->

  describe 'Facade testable', ->
    describe 'sub-title', ->
      it 'generates sub-title by last difference of path fragments', ->

      it 'gives up making sub-title of item which can not getPath', ->

    describe 'formating time elapsed', ->
      it 'shows secs if elapsed time is less than a min', ->

      it 'shows mins if elapsed time is less than an hour', ->

      it 'shows hours if elapsed time is much than an hour', ->

###
  describe 'Reorder list', ->
    it 'moves item to a head of the internal list when activated', ->
      expect(activeItemTitle()).toBe 'E4'
      atom.workspace.getActivePane().activateItemAtIndex(0)
      expect(internalListTitles()).toBe 'E1 E4 E3 E2'

  describe 'Facade', ->
    modalPanel = null

    beforeEach ->
      atom.config.set('tab-history-mrx.fadeInDelay', 0.1)
      modalPanel = atom.workspace.getModalPanels().filter((item) -> item.className is 'tab-history-mrx')[0]

    it 'makes popup ready', ->
      nodeList = workspaceElement.querySelectorAll('atom-panel.modal.tab-history-mrx')
      expect(nodeList).toBeInstanceOf(NodeList)
      expect(nodeList.item(0)).not.toBeNull()

    it 'pops modal panel up/down (next, select)', ->
      expect(modalPanel.isVisible()).toBe false
      dispatchCommand('tab-history-mrx:forward')
      advanceClock(150)
      expect(modalPanel.isVisible()).toBe true
      dispatchCommand('tab-history-mrx:select')
      expect(modalPanel.isVisible()).toBe false
      dispatchCommand('tab-history-mrx:next')
      dispatchCommand('tab-history-mrx:next')
      advanceClock(150)
      expect(modalPanel.isVisible()).toBe true
      dispatchCommand('tab-history-mrx:select')
      expect(modalPanel.isVisible()).toBe false

    it 'pops modal panel up/down (prev, cancel)', ->
      expect(modalPanel.isVisible()).toBe false
      dispatchCommand('tab-history-mrx:back')
      advanceClock(150)
      expect(modalPanel.isVisible()).toBe true
      dispatchCommand('tab-history-mrx:cancel')
      expect(modalPanel.isVisible()).toBe false
      dispatchCommand('tab-history-mrx:back')
      dispatchCommand('tab-history-mrx:back')
      advanceClock(150)
      expect(modalPanel.isVisible()).toBe true
      dispatchCommand('tab-history-mrx:cancel')
      expect(modalPanel.isVisible()).toBe false
  describe 'tab order synchronization', ->
    it "does reflect the internal list to atom tabs", ->
      atom.config.set('tab-history-mrx.reorderTabs', true)

      atom.workspace.getActivePane().activateItemAtIndex(n) for n in [0..3]

      expect(internalListTitles()).toBe 'E4 E3 E2 E1'
      expect(atomTabTitles()).toBe 'E4 E3 E2 E1'
      atom.workspace.getActivePane().activateItemAtIndex(3)
      expect(internalListTitles()).toBe 'E1 E4 E3 E2'
      expect(atomTabTitles()).toBe 'E1 E4 E3 E2'

    it "does NOT reflect the internal list to atom tabs", ->
      atom.config.set('tab-history-mrx.reorderTabs', false)
      oldAtomTabTitles = atomTabTitles()
      atom.workspace.getActivePane().activateItemAtIndex(0)
      expect(internalListTitles()).toBe 'E1 E4 E3 E2'
      expect(atomTabTitles()).toBe oldAtomTabTitles
###
