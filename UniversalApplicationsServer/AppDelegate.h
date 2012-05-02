//
//  AppDelegate.h
//  UniversalApplicationsServer
//
//  Created by Oleksii Vynogradov on 4/30/12.
//  Copyright (c) 2012 IXC-USA Corp. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class   HTTPServer;


@interface AppDelegate : NSObject <NSApplicationDelegate>
{
    NSButton *__weak enableLogs;
    HTTPServer *httpServer;
    IBOutlet NSTextField *messageBody;
    
}

@property (assign) IBOutlet NSWindow *window;

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (weak) IBOutlet NSButton *enableLogs;

@property (weak) IBOutlet NSArrayController *application;
- (IBAction)saveAction:(id)sender;
@property (weak) IBOutlet NSArrayController *client;
@property (weak) IBOutlet NSButton *sandbox;
@property (weak) IBOutlet NSTextField *charactersQuantity;

@property (retain) NSNumber *urlNumber;

@end
