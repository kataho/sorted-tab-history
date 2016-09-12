# Sorted Tab History

![travis-ci](https://travis-ci.org/kataho/tab-history-mrx.svg?branch=master)

Yet another tab item manager which sorts tabs with elapsed time from various things done recently.

This Atom package provides a list of tabs in each pane which is ordered by elapsed time from various user actions
(save, modification, cursor move and tab activation for now).
Of course also provides commands for keymap to navigate among the list.

Many editors have back/forward navigation feature, meanwhile, there is a small difference between
way of ordering items. It represents no ideal one in this world.
To help you to find the best of your own is the main point of this package.

< picture here >

## Keymap Commands

**Back**  - Activate previous (older) item of current active item in the history

**Forward** - Activate next (newer) item of current active item in the history

**Top** - Activate the most recent item in the history

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

#### Tab Auto Closing

Number of tabs we attempt to keep in a pane. a bottom item in the history list is used as a candidate to be closed in exchange for an item being added.

## Setting Examples

#### Most Recently Activated

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

Plus, preventing changed items never be closed. I am using this.

    SortRank:InternalSelect = 1
    SortRank:ExternalSelect = 1
    SortRank:Open = -1
    SortRank:Cursor = -1
    SortRank:Change = 2
    SortRank:Save = -1
    ExpirationOfEvents = 5

### Cursor Move History

Cursor move rather than item selection.

    SortRank:InternalSelect = -1
    SortRank:ExternalSelect = -1
    SortRank:Open = -1
    SortRank:Cursor = 1
    SortRank:Change = 2
    SortRank:Save = -1
    ExpirationOfEvents = 5

### Pure Save History

Can control the order all by yourself by turning auto saving off.

    SortRank:InternalSelect = -1
    SortRank:ExternalSelect = -1
    SortRank:Open = -1
    SortRank:Cursor = -1
    SortRank:Change = -1
    SortRank:Save = 1
    ExpirationOfEvents = 9999

#### Saved and Opened History

Items saved in last an hour are on upper list and recently opened items follow.

    SortRank:InternalSelect = -1
    SortRank:ExternalSelect = -1
    SortRank:Open = 2
    SortRank:Cursor = -1
    SortRank:Change = -1
    SortRank:Save = 1
    ExpirationOfEvents = 60
