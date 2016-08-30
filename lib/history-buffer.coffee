module.exports =
class HistoryBuffer
  constructor: (baseArray, headItem) ->
    @stampNames = ['select', 'select_ext', 'open', 'cursor', 'change', 'save']
    @configPrefix = 'sorted-tab-history.sortRank_'
    @stamps = []
    @sortedItemListCache = null
    @pushItem item for item in baseArray
    @stamp headItem, 'select_ext'

  pushItem: (item) ->
    obj = {item: item, subTitle: ''}
    obj[name] = 0 for name in @stampNames
    @stamps.push obj
    @setSubTitle(obj)
    @sortedItemListCache = null

  removeItem: (item) ->
    index = @stamps.findIndex (element) -> element.item is item
    @stamps.splice index, 1 if index >= 0
    @sortedItemListCache = null

  stamp: (item, stampOn) ->
    index = @stamps.findIndex (element) -> element.item is item
    if index >= 0
      @stamps[index][stampOn] = Date.now()
      @sortedItemListCache = null

  extraInfoOfItem: (item) ->
    found = Object.assign {}, @stamps.find (element) -> element.item is item
    delete found.item if found
    found

  sortedItemList: ->
    return @sortedItemListCache if @sortedItemListCache isnt null
    timeoutTimeEnable = Date.now() - atom.config.get('sorted-tab-history.timeoutMinutes') * 60 * 1000
    configPrefix = @configPrefix
    sortRanks = @stampNames
      .map (name) ->
        {name: name, rank: atom.config.get(configPrefix + name)}
      .sort (a, b) ->
        a.rank - b.rank
      .reduce ((merged, elm, index) ->
        if index > 0 && merged[merged.length - 1].rank == elm.rank
          merged[merged.length - 1].names.push elm.name
        else
          merged.push {names: [elm.name], rank: elm.rank}
        merged
      ), []

    sortRanks.shift() while sortRanks.length > 0 and sortRanks[0].rank < 0 # negative rank no. is totally ignored
    minRank = sortRanks[sortRanks.length - 1].rank # worst ranked event is never timed out
    sortRanks.forEach (element) -> element.timeoutTime = if element.rank == minRank then 0 else timeoutTimeEnable
    @stamps.forEach (element) -> delete element.sortFactor
    @sortedItemListCache = @stamps
      .sort (a, b) ->
        for {names, rank, timeoutTime} in sortRanks
          aname = names.reduce (maxname, name) -> if a[maxname] < a[name] then name else maxname
          bname = names.reduce (maxname, name) -> if b[maxname] < b[name] then name else maxname
          aval = Math.max(0, a[aname] - timeoutTime)
          bval = Math.max(0, b[bname] - timeoutTime)
          if aval != bval
            a.sortFactor = aname if aval > 0
            b.sortFactor = bname if bval > 0
            return bval - aval
        0
      .map (element) ->
        element.item

  setSubTitle: (newItem) ->
    for i in [0...@stamps.length]
      if (matched = if 'getLongTitle' of @stamps[i].item then @stamps[i].item.getLongTitle().match(/\u2014 (.*)$/))
        @stamps[i].subTitle = matched[1]
    return

    # custom implementation which currently abandoned
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
            subTitles = ['', '']
            for pathIndex in [1..Math.min(pathElms[0].length, pathElms[1].length)]
              subTitles = pathElms.map (e) -> e[e.length - pathIndex]
              break if subTitles[0] != subTitles[1]
            @stamps[i].subTitle = subTitles[0]
            newItem.subTitle = subTitles[1]
