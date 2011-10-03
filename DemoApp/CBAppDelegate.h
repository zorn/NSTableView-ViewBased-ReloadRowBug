//
//  CBAppDelegate.h
//  DemoApp
//
//  Created by Michael Zornek on 10/3/11.
//  Copyright (c) 2011 Clickable Bliss. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CBAppDelegate : NSObject <NSApplicationDelegate>
{
    NSMutableArray *people;
}

@property (strong) IBOutlet NSWindow *window;
@property (strong) IBOutlet NSTableView *tableView;
@property (strong) IBOutlet NSWindow *editWindow;
@property (strong) IBOutlet NSTextField *nameTextField;

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

- (IBAction)saveAction:(id)sender;
- (IBAction)createPerson:(id)sender;
- (IBAction)deleteSelection:(id)sender;
- (NSManagedObject *)personForCurrentRowSelection;
- (IBAction)tableViewDidDoubleClickRow:(id)sender;
- (void)editPerson:(NSManagedObject *)person;
- (IBAction)editSheetDone:(id)sender;


- (void)startObservingChangesForContext:(NSManagedObjectContext *)context;
- (void)stopObservingChangesForContext:(NSManagedObjectContext *)context;

- (void)reloadDataForTableView:(NSTableView *)someTableView maintainRowSelection:(BOOL)maintainRowSelection;

@end
