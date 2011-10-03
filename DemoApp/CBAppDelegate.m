//
//  CBAppDelegate.m
//  DemoApp
//
//  Created by Michael Zornek on 10/3/11.
//  Copyright (c) 2011 Clickable Bliss. All rights reserved.
//

#import "CBAppDelegate.h"
#import "NSImage+CBAdditions.h"
#import "NSArray+CBAdditions.h"

@implementation CBAppDelegate

@synthesize window = _window;
@synthesize tableView=_tableView;
@synthesize editWindow=_editWindow;
@synthesize nameTextField=_nameTextField;

@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize managedObjectContext = __managedObjectContext;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    people = [[NSMutableArray alloc] init];
    
    [self.tableView setTarget:self];
    [self.tableView setDoubleAction:@selector(tableViewDidDoubleClickRow:)];
}

/**
    Returns the directory the application uses to store the Core Data store file. This code uses a directory named "DemoApp" in the user's Library directory.
 */
- (NSURL *)applicationFilesDirectory {

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *libraryURL = [[fileManager URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
    return [libraryURL URLByAppendingPathComponent:@"DemoApp"];
}

/**
    Creates if necessary and returns the managed object model for the application.
 */
- (NSManagedObjectModel *)managedObjectModel {
    if (__managedObjectModel) {
        return __managedObjectModel;
    }
	
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"DemoApp" withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];    
    return __managedObjectModel;
}

/**
    Returns the persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (__persistentStoreCoordinator) {
        return __persistentStoreCoordinator;
    }

    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) {
        NSLog(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
        return nil;
    }

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationFilesDirectory = [self applicationFilesDirectory];
    NSError *error = nil;
    
    NSDictionary *properties = [applicationFilesDirectory resourceValuesForKeys:[NSArray arrayWithObject:NSURLIsDirectoryKey] error:&error];
        
    if (!properties) {
        BOOL ok = NO;
        if ([error code] == NSFileReadNoSuchFileError) {
            ok = [fileManager createDirectoryAtPath:[applicationFilesDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
        }
        if (!ok) {
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    }
    else {
        if ([[properties objectForKey:NSURLIsDirectoryKey] boolValue] != YES) {
            // Customize and localize this error.
            NSString *failureDescription = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationFilesDirectory path]]; 
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setValue:failureDescription forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:101 userInfo:dict];
            
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    }
    
    NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:@"DemoApp.storedata"];
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    if (![coordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error]) {
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    __persistentStoreCoordinator = coordinator;

    return __persistentStoreCoordinator;
}

/**
    Returns the managed object context for the application (which is already
    bound to the persistent store coordinator for the application.) 
 */
- (NSManagedObjectContext *)managedObjectContext {
    if (__managedObjectContext) {
        return __managedObjectContext;
    }

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    __managedObjectContext = [[NSManagedObjectContext alloc] init];
    [__managedObjectContext setPersistentStoreCoordinator:coordinator];
    
    [self startObservingChangesForContext:__managedObjectContext];
    
    return __managedObjectContext;
}

/**
    Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
 */
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    return [[self managedObjectContext] undoManager];
}

/**
    Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
 */
- (IBAction)saveAction:(id)sender {
    NSError *error = nil;
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }

    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {

    // Save changes in the application's managed object context before the application terminates.

    if (!__managedObjectContext) {
        return NSTerminateNow;
    }

    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }

    if (![[self managedObjectContext] hasChanges]) {
        return NSTerminateNow;
    }

    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {

        // Customize this code block to include application-specific recovery steps.              
        BOOL result = [sender presentError:error];
        if (result) {
            return NSTerminateCancel;
        }

        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];

        NSInteger answer = [alert runModal];
        
        if (answer == NSAlertAlternateReturn) {
            return NSTerminateCancel;
        }
    }

    return NSTerminateNow;
}

#pragma mark -
#pragma mark Actions

- (IBAction)createPerson:(id)sender
{
    NSArray *names = [NSArray arrayWithObjects:@"Jacob",@"Emily",@"Michael",@"Isabella",@"Ethan",@"Emma",@"Joshua",@"Ava",@"Daniel",@"Madison",@"Christopher",@"Sophia",@"Anthony",@"Olivia",@"William",@"Abigail",@"Matthew",@"Hannah",@"Andrew",@"Elizabeth",@"Alexander",@"Addison",@"David",@"Samantha",@"Joseph",@"Ashley",@"Noah",@"Alyssa",@"James",@"Mia",@"Ryan",@"Chloe",@"Logan",@"Natalie",@"Jayden",@"Sarah",@"John",@"Alexis",@"Nicholas",@"Grace", nil];
    
    NSManagedObject *newPerson = [NSEntityDescription insertNewObjectForEntityForName:@"Person" inManagedObjectContext:self.managedObjectContext];
    [newPerson setValue:[names randomObject] forKey:@"name"];
    [newPerson setValue:[[NSImage cb_randomSystemImage] TIFFRepresentation] forKey:@"icon"];
}

- (IBAction)deleteSelection:(id)sender
{
    NSIndexSet *selectedRows = [self.tableView selectedRowIndexes];
    __block CBAppDelegate *blockSelf = self;
    [selectedRows enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        NSManagedObject *objectForRow = [people objectAtIndex:idx];
        [blockSelf.managedObjectContext deleteObject:objectForRow];
    }];
}

- (NSManagedObject *)personForCurrentRowSelection
{
    NSInteger rowIndex = [self.tableView selectedRow];
    if (rowIndex != NSNotFound) {
        if (rowIndex <= people.count) {
            return [people objectAtIndex:rowIndex];
        } else {
            NSLog(@"Not attempting to find person, rowIndex %ld is > people.count %lu", rowIndex, people.count);
            return nil;
        }
    } else {
        return nil;
    }
}

- (IBAction)tableViewDidDoubleClickRow:(id)sender
{
    NSManagedObject *person = [self personForCurrentRowSelection];
    if (person) {
        [self editPerson:person];
    } else {
        NSBeep();
    }
}

- (void)editPerson:(NSManagedObject *)person
{
    self.nameTextField.objectValue = [person valueForKey:@"name"];
    [NSApp beginSheet:self.editWindow
       modalForWindow:self.window
        modalDelegate:nil
       didEndSelector:NULL
          contextInfo:NULL];
}

- (IBAction)editSheetDone:(id)sender
{
    NSManagedObject *person = [self personForCurrentRowSelection];
    [person setValue:self.nameTextField.stringValue forKey:@"name"];
    [NSApp endSheet:self.editWindow];
    [self.editWindow orderOut:self];
}

#pragma mark -
#pragma mark Core Data Nofitication

- (void)startObservingChangesForContext:(NSManagedObjectContext *)context
{
    if (context) {
        NSLog(@"startObservingChangesForContext %@", context);
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleContextChangeNotification:) name:NSManagedObjectContextObjectsDidChangeNotification object:context];
    }
}

- (void)stopObservingChangesForContext:(NSManagedObjectContext *)context
{
    if (context) {
        NSLog(@"stopObservingChangesForContext %@", context);
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextObjectsDidChangeNotification object:context];
    }
}

- (void)handleContextChangeNotification:(NSNotification *)notification
{
    NSLog(@"handleContextChangeNotification:");
    NSArray* insertedObjects = [[notification userInfo] objectForKey:NSInsertedObjectsKey];
    NSArray* deletedObjects = [[notification userInfo] objectForKey:NSDeletedObjectsKey];
    NSArray* updatedObjects = [[notification userInfo] objectForKey:NSUpdatedObjectsKey];
    
    [self.tableView beginUpdates];
    
    for (id object in insertedObjects) {    
        [people addObject:object];
        NSUInteger index = [people indexOfObject:object];
        [self.tableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:index] withAnimation:NSTableViewAnimationEffectFade];
    }
    
    for (id object in deletedObjects) {
        NSUInteger index = [people indexOfObject:object];
        [people removeObject:object];
        [self.tableView removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:index] withAnimation:NSTableViewAnimationEffectFade];        
    }
    
    for (id object in updatedObjects) {
        // CODE I'D LIKE TO USE
        NSUInteger index = [people indexOfObject:object];
        [people indexOfObject:object];
        [self.tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:index] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
        
        // WORKAROUND
        //[self reloadDataForTableView:self.tableView maintainRowSelection:YES];
    }
    
    [self.tableView endUpdates];
}


#pragma mark -
#pragma mark NSTableView Delegate Methods

- (void)reloadDataForTableView:(NSTableView *)someTableView maintainRowSelection:(BOOL)maintainRowSelection
{
    NSIndexSet *selectionIndex = nil;
    if (maintainRowSelection) {
        selectionIndex = [someTableView selectedRowIndexes];
    }
    [someTableView reloadData];
    if (maintainRowSelection) {
        [someTableView selectRowIndexes:selectionIndex byExtendingSelection:NO];
    }
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [people count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row 
{    
    NSManagedObject *person = [people objectAtIndex:row];
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:@"PersonCell" owner:self];
    cellView.textField.stringValue = [person valueForKey:@"name"];
    cellView.imageView.image = [[NSImage alloc] initWithData:[person valueForKey:@"icon"]];
    return cellView;
}

@end
