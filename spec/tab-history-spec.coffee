describe 'TabHistoryMRX', ->
  activeItemTitle = -> atom.workspace.getActivePane().getActiveItem().getTitle()
  dispatchCommand = (cmd) -> atom.commands.dispatch(atom.views.getView(atom.workspace), cmd)
  internalListTitles = -> (historyManager.history[n].item.getTitle() for n in [0..3]).join(' ')
  atomTabTitles = -> (atom.workspace.getActivePane().itemAtIndex(n).getTitle() for n in [0..3]).join(' ')

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
        historyManager = atom.packages.getActivePackage('tab-history-mrx').mainModule.managers[0]

    waitsForPromise ->
      atom.config.set('tab-history-mrx.itemTopOnSelect', false)
      atom.config.set('tab-history-mrx.itemTopOnChange', false)
      atom.config.set('tab-history-mrx.itemMoveOnAltSelect', 'front-active')
      atom.config.set('tab-history-mrx.itemMoveOnOpen', 'front-active')
      atom.config.set('tab-history-mrx.limitItems', 10)
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
    it '(itemTopOnSelect) moves active item top on select', ->

    it '(itemTopOnChnage) moves active item top on content change', ->

    describe 'itemMoveOnAltSelect', ->
      it '(top) moves selected item top on select by other method to select', ->

      it '(front-active) moves selected item front of last active item on select by other method to select', ->

      it '(back-active) moves selected item back of last active item on select by other method to select', ->

    describe 'itemMoveOnOpen', ->
      it '(top) moves opened item top', ->

      it '(bottom) moves opened item bottom', ->

      it '(front-active) moves opened item front of last active item', ->

      it '(back-active) moves opened item back of last active item', ->

      it '"alter select" option overrides this option', ->

      it 'properly ignores options bound on events which come just after open', ->

    describe 'limitItems', ->
      it 'automatically close and dispose item not to exceed limit of items in the list', ->

      it 'does not close item on bottom but modified', ->

      it 'does not close item on bottom but active currently', ->


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
