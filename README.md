The following app demonstrates a recent bug I've run into regarding reloading specific rows in a view based tables.

Radar: 10225466

StackOverflow: http://stackoverflow.com/questions/7616256/

FIXED: I think I fixed this bug. Turns out you have to be careful about closing with [self.tableView endUpdates] before attempting any kind of reloadDataForRowIndexes:columnIndexes: on the tableview.

## Replication Instructions

This app requires Xcode 4.2b6 or newer. It uses ARC and runs exclusively for Lion.

* Run the app
* Add three people
* Edit the second person.
* Delete the second person.

* !!! The table view is now drawing incorrectly -- you'll see a repeat of the second person in the third row. You can't click on that third row. If you select the second person and try to use the down arrow to change selection to the third row it won't let you. The third row is a drawing error.

## Background

This little app is setup as a simple Core Data app and for reasons specific to my real app we are not using an NSArrayController to bind the table but doing things more manually.

So we allow arbitrary parts of the system to add and delete objects to/from the context and the view controller needs to listen for changes from the context and update our internal person array as well as update the table view. We do this by listening to the NSManagedObjectContextObjectsDidChangeNotification.

If objects were inserted we:

`[self.tableView insertRowsAtIndexes: ... ];`

deleted:

`[self.tableView removeRowsAtIndexes: ... ];`

changed:

`[self.tableView reloadDataForRowIndexes: ... columnIndexes: ...];`

For additions and deletions things work fine but when an object is updated and we call NSTableView's reloadDataForRowIndexes:columnIndexes: we have a problem. It would seem that doing so causes the table view to drop its cell view but mistakenly hold on to the row view which causes problems when you delete an object after you edit it. [The docs](http://developer.apple.com/library/mac/#documentation/Cocoa/Reference/ApplicationKit/Classes/NSTableView_Class/Reference/Reference.html) even admit as much:

> For view-based table views, reloadDataForRowIndexes:columnIndexes: will drop the view-cells in the table row, but not the NSTableRowView instances.

I'm not sure how I'm suppose to drop the NSTableRowView instance or if this means that view based tables should avoid using this method entirely. reloadData: works but obviously is much heavier than the method I'd like to use. There is a workaround you can comment in if you want to see the app working as intended. 