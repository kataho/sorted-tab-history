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
    configPrefix = @configPrefix
    timeoutTime = Date.now() - atom.config.get('tab-history-mrx.timeoutMinutes') * 60 * 1000
    sortRanks = @stampNames
      .map (name) ->
        {name: name, rank: atom.config.get(configPrefix + name)}
      .sort (a, b) ->
        a.rank - b.rank
    @sortedItemListCache = @stamps
      .sort (a, b) ->
        for {name} in sortRanks
          aval = a[name] - timeoutTime
          aval = 0 if aval < 0
          bval = b[name] - timeoutTime
          bval = 0 if bval < 0
          return d if (d = bval - aval) != 0
        0
      .map (element) ->
        element.item
