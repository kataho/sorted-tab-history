module.exports =
class HistoryBuffer
  constructor: (baseArray, headItem) ->
    @stampNames = ['select', 'cursor', 'change', 'save']
    @configPrefix = 'tab-history-mrx.sortRank_'
    @stamps = []
    @sortedItemListCache = null
    @pushItem item for item in baseArray
    @stamp headItem, 'select'

  pushItem: (item) ->
    obj = {item: item}
    obj[name] = 0 for name in @stampNames
    @stamps.push obj

  removeItem: (item) ->
    index = @stamps.findIndex (element) -> element.item is item
    @stamps.splice index, 1 if index >= 0

  stamp: (item, stampOn) ->
    index = @stamps.findIndex (element) -> element.item is item
    if index >= 0
      @stamps[index][stampOn] = Date.now()
      @sortedItemListCache = null

  stampOfItem: (item) ->
    ret = Object.assign {}, @stamps.find (element) -> element.item is item
    delete ret['item']
    ret

  sortedItemList: ->
    return @sortedItemListCache if @sortedItemListCache isnt null
    sortRanks = @stampNames
      .map (name) ->
        {name: name, rank: atom.config.get @configPrefix + name}
      .sort (a, b) ->
        a.rank - b.rank
    @sortedItemListCache = @stamps
      .sort (a, b) ->
        for {name} in sortRanks
          return d if (d = b[name] - a[name]) isnt 0
        0
      .map (element) ->
        element.item
