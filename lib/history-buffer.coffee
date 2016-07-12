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
    obj = {item: item, ident: ''}
    obj[name] = 0 for name in @stampNames
    @stamps.push obj
    @setIdent(obj)

  removeItem: (item) ->
    index = @stamps.findIndex (element) -> element.item is item
    @stamps.splice index, 1 if index >= 0

  stamp: (item, stampOn) ->
    index = @stamps.findIndex (element) -> element.item is item
    if index >= 0
      @stamps[index][stampOn] = Date.now()
      @sortedItemListCache = null

  restInfoOfItem: (item) ->
    found = Object.assign {}, @stamps.find (element) -> element.item is item
    delete found['item'] if found
    found

  sortedItemList: ->
    return @sortedItemListCache if @sortedItemListCache isnt null
    timeoutTime = Date.now() - atom.config.get('tab-history-mrx.timeoutMinutes') * 60 * 1000
    configPrefix = @configPrefix
    sortRanks = @stampNames
      .map (name) ->
        {name: name, rank: atom.config.get(configPrefix + name)}
      .sort (a, b) ->
        a.rank - b.rank
    @sortedItemListCache = @stamps
      .sort (a, b) ->
        for {name} in sortRanks
          aval = Math.max(0, a[name] - timeoutTime)
          bval = Math.max(0, b[name] - timeoutTime)
          d = bval - aval
          if d != 0
            a['sortbase'] = name if d < 0
            b['sortbase'] = name if d > 0
            return d
        0
      .map (element) ->
        element.item

  setIdent: (newItem) ->
    return if typeof newItem.item.getPath is 'undefined'
    # additional string for items of same titles
    for i in [0...@stamps.length]
      item = [@stamps[i], newItem]
      continue if typeof item[0].item.getPath is 'undefined'
      if item[0].item.getTitle() == item[1].item.getTitle()
        path = item.map (e) -> e.item.getPath()
        if path[0] != path[1]
          pathElms = path.map (e) -> e.split('/')
          if pathElms[0].length >= 2 and pathElms[1].length >= 2
            ident = ['', '']
            for pathIndex in [1..Math.min(pathElms[0].length, pathElms[1].length)]
              ident = pathElms.map (e) -> e[e.length - pathIndex]
              break if ident[0] != ident[1]
            @stamps[i]['ident'] = ident[0]
            newItem['ident'] = ident[1]
