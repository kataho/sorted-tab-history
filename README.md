# Tab History Ordered by X

![travis-ci](https://travis-ci.org/kataho/tab-history-mrx.svg?branch=master)

Yet another tab manager which orders tabs in elapsed time from various thing done most recently.

This Atom package provides a list of tabs in each pane which is ordered by elapsed time from various user actions
(save, modification, cursor move and tab activation for now).
Of course also provides commands for keymap to navigate among the list.

Many editors have back/forward navigation shortcut, besides with a small difference between
way of ordering items. It seems no ideal one in this world.
Finding the best of your own is the main point of this project.

< picture here >

## Keymap Commands

**Back**  - Activate previous (older) item of current active item in the history

**Forward** - Activate next (newer) item of current active item in the history

**Top** - Activate the most recent item in the history

## Options

#### Ranks of Sort Priority

The history is sorted by multiple factors. First, tab items are sorted with time from last action of the best rank,
and on a subset of items with too old to compare, another sort is applied with time from last action of second best rank, and so forth.

\* An action labelled as the worst rank in pulldown list is handled as disabled. Time from the action is totally ignored.

**Sort Rank : Select** - Sorting priority rank of activation (focusing) of a tab item

**Sort Rank : Cursor Move** - Sorting priority rank of cursor move on an editor

**Sort Rank : Change** - Sorting priority rank of content change of an editor

**Sort Rank : Save** - Sorting priority rank of save of content of a tab item

#### Expiration of Event History

Integer of minutes of an action expires. An expired action is handled as never occurred.
It leads a lower rank action to be picked to calculate the order of the tab in the history.

\* Among enabled ranks, The action labelled as the worst never expires.

#### Tab Auto Closing

Number of tabs we attempt to keep in a pane. a bottom item in the history list is used as a candidate to be closed in exchange for an opening tab.

## Sample Configuration

#### Standard - Most Recently Activated

    SortRank:Select = 1
    SortRank:Cursor = 5
