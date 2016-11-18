# Sorted Tab History

![travis-ci](https://travis-ci.org/kataho/sorted-tab-history.svg?branch=master)

Yet another tab item manager which sorts tabs with elapsed time from various actions.

This Atom package provides a list of tabs in each pane which is ordered by elapsed time from various actions
(save, modification, cursor move, tab activation and tab addition for now).
And also provides shortcut key commands to navigate among the list.

Many editors have back/forward navigation feature, meanwhile, there are small differences between them
on way of ordering items. It represents no ideal one for all people.
To help you to find the best of your own is the main point of this package.

![captured](http://kataho.github.io/sorted-tab-history/images/capture.gif)

## Keymap Commands

**Back**  - Activate previous (older) item of current active item in the history (default: cmd-left )

**Forward** - Activate next (newer) item of current active item in the history (default: cmd-right )

**Top** - Activate the most recent item in the history (default: shift-cmd-right )

## Options

#### Ranks of Sort Priority

The history is sorted by multiple factors. First, tab items are sorted with time from last action of the best rank,
and on a subset of items with too old to compare, another sort is applied with time from last action of second best rank, and so forth.

\* The rank -1 means disabled. The action is ignored.

**Sort Rank : Internal Select** - Sorting priority rank of activation of a tab item (by this package feature)

**Sort Rank : External Select** - Sorting priority rank of activation of a tab item (by other tab item selecting feature)

**Sort Rank : Open** - Sorting priority rank of addition of new tab item

**Sort Rank : Cursor Move** - Sorting priority rank of cursor move on an editor

**Sort Rank : Change** - Sorting priority rank of content change of an editor

**Sort Rank : Save** - Sorting priority rank of save of content of a tab item

#### Expiration of Event History

Integer of minutes of an action expires. An expired action is handled as never occurred.
It causes a next lower rank action to be picked to decide an order of the tab item.

\* An action labelled as the lowest rank among enabled ranks never expires.

#### Maximum Tabs in a Pane

Number of tabs we attempt to keep opened in a pane. Lower entry in the history list is used as candidate to be closed in exchange for an item being added.

## Recommended init.coffee Settings

Setting long enough partial match timeout is recommended to avoid the popup to be closed while selecting items.

    atom.keymaps.partialMatchTimeout = 90000

Insert above line in your init.coffee

## Setting Examples

#### :: Most Recently Activated

The list of recently used items. Commonly been seen around.

    SortRank:InternalSelect = -1
    SortRank:ExternalSelect = 1
    SortRank:Open = -1
    SortRank:Cursor = -1
    SortRank:Change = -1
    SortRank:Save = -1

Plus, selecting from this list also changes the order.

    SortRank:InternalSelect = 1
    SortRank:ExternalSelect = 1
    SortRank:Open = -1
    SortRank:Cursor = -1
    SortRank:Change = -1
    SortRank:Save = -1

Plus, prevent modified items to be auto closed. I am using this.

    SortRank:InternalSelect = 1
    SortRank:ExternalSelect = 1
    SortRank:Open = -1
    SortRank:Cursor = -1
    SortRank:Change = 2
    SortRank:Save = -1
    ExpirationOfEvents = 5

#### :: Cursor Move History

Cursor move rather than item selection.

    SortRank:InternalSelect = -1
    SortRank:ExternalSelect = -1
    SortRank:Open = -1
    SortRank:Cursor = 1
    SortRank:Change = 2
    SortRank:Save = -1
    ExpirationOfEvents = 5

#### :: Pure Save History

Can control the order all by yourself by turning auto saving off.

    SortRank:InternalSelect = -1
    SortRank:ExternalSelect = -1
    SortRank:Open = -1
    SortRank:Cursor = -1
    SortRank:Change = -1
    SortRank:Save = 1
    ExpirationOfEvents = 9999

#### :: Saved and Opened History

Items saved in last an hour are on upper list and recently opened items follow.

    SortRank:InternalSelect = -1
    SortRank:ExternalSelect = -1
    SortRank:Open = 2
    SortRank:Cursor = -1
    SortRank:Change = -1
    SortRank:Save = 1
    ExpirationOfEvents = 60
