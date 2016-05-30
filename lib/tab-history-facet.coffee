{CompositeDisposable} = require 'atom'

module.exports =
class TabHistoryFacet
  constructor: ->
    @disposable = new CompositeDisposable

    @modalItem = document.createElement('ol')
    @modalItem.classList.add('tab-history-facet')
    

    @modal = atom.workspace.addModalPanel {item: @modalItem, visible: false}

  setTarget: (pane, manager) ->
    @pane = pane
    @manager = managers

    @modal.hide()


  dispose: ->
    @disposable.dispose()
    @modal.destroy()
