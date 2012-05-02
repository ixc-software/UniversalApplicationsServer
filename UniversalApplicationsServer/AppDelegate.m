//
//  AppDelegate.m
//  UniversalApplicationsServer
//
//  Created by Oleksii Vynogradov on 4/30/12.
//  Copyright (c) 2012 IXC-USA Corp. All rights reserved.
//

#import "AppDelegate.h"
#import "APNS.h"

#import "DDLog.h"
#import "DDTTYLogger.h"
#import "DDASLLogger.h"

#import "HTTPServer.h"
#import "MyHTTPConnection.h"

#import "Client.h"
#import "ClientContacts.h"
#import <SecurityInterface/SFChooseIdentityPanel.h>

#import "ExternalDataController.h"

@implementation AppDelegate
@synthesize client = _client;
@synthesize sandbox = _sandbox;
@synthesize charactersQuantity = _charactersQuantity;

@synthesize window = _window;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize managedObjectContext = __managedObjectContext;

@synthesize enableLogs;
@synthesize application = _application;
@synthesize urlNumber;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    [[APNS sharedAPNS] setErrorBlock:^(uint8_t status, NSString *description, uint32_t identifier) {
		NSAlert *alert = [NSAlert alertWithMessageText:@"Error delivering notification" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"There was an error delivering the notificaton %d: %@", identifier, description];
		[alert beginSheetModalForWindow:self.window
                          modalDelegate:nil
                         didEndSelector:nil
                            contextInfo:nil];
	}];

    [DDLog addLogger:[DDTTYLogger sharedInstance]];
	[DDLog addLogger:[DDASLLogger sharedInstance]];

    httpServer = [[HTTPServer alloc] init];
	[httpServer setConnectionClass:[MyHTTPConnection class]];
    [httpServer setPort:9999];
    NSError *error = nil;
	BOOL success = [httpServer start:&error];
	
	if(!success)
	{
		NSLog(@"Error starting non secure HTTP Server: %@", error);
	}

}

// Returns the directory the application uses to store the Core Data store file. This code uses a directory named "ixc.ua.UniversalApplicationsServer" in the user's Application Support directory.
- (NSURL *)applicationFilesDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *appSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    return [appSupportURL URLByAppendingPathComponent:@"ixc.ua.UniversalApplicationsServer"];
}

// Creates if necessary and returns the managed object model for the application.
- (NSManagedObjectModel *)managedObjectModel
{
    if (__managedObjectModel) {
        return __managedObjectModel;
    }
	
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"UniversalApplicationsServer" withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return __managedObjectModel;
}

// Returns the persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
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
    } else {
        if (![[properties objectForKey:NSURLIsDirectoryKey] boolValue]) {
            // Customize and localize this error.
            NSString *failureDescription = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationFilesDirectory path]];
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setValue:failureDescription forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:101 userInfo:dict];
            
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    }
    
    NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:@"UniversalApplicationsServer.storedata"];
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    NSMutableDictionary *pragmaOptions = [NSMutableDictionary dictionary];
    [pragmaOptions setObject:@"FULL" forKey:@"synchronous"];
    [pragmaOptions setObject:@"1" forKey:@"fullfsync"];
    [pragmaOptions setObject:[NSNumber numberWithBool:YES] forKey:NSMigratePersistentStoresAutomaticallyOption];
    [pragmaOptions setObject:[NSNumber numberWithBool:YES] forKey:NSInferMappingModelAutomaticallyOption];
    NSDictionary *options = [NSDictionary dictionaryWithDictionary:pragmaOptions];

    if (![coordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:options error:&error]) {
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    __persistentStoreCoordinator = coordinator;
    
    return __persistentStoreCoordinator;
}

// Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) 
- (NSManagedObjectContext *)managedObjectContext
{
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

    return __managedObjectContext;
}

// Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
    return [[self managedObjectContext] undoManager];
}

// Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
- (IBAction)saveAction:(id)sender
{
    NSError *error = nil;
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }
    
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
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


- (IBAction)getContactsStart:(id)sender {
    Client *selectedClient = self.client.selectedObjects.lastObject;
    
    NSOrderedSet *clientContactsCurrent = selectedClient.clientContacts;
    if (clientContactsCurrent && clientContactsCurrent.count > 0) {
        ClientContacts *contactsForUsing = clientContactsCurrent.lastObject;
        if (contactsForUsing) { 
            
            ExternalDataController *externalDataController = [[ExternalDataController alloc] initSecured:NO];
            [externalDataController showContactsForReceivedData:contactsForUsing.receivedData];
//            NSString *error;
//            NSPropertyListFormat format;  
//            NSArray *decodedAllContactsData = [NSPropertyListSerialization propertyListFromData:contactsForUsing.receivedData mutabilityOption:0 format:&format errorDescription:&error];
//            if (error) NSLog(@"EXTERNAL DATA: goorReceiptData deserialization failed :%@ format:%@",error,[NSNumber numberWithUnsignedInteger:format]);
//            NSLog(@"allContactsInfo:%@",decodedAllContactsData);
        } else  NSLog(@"client not have contacts list");
    }

}
#pragma mark - textfield
- (void)controlTextDidChange:(NSNotification *)aNotification
{
    self.charactersQuantity.stringValue = [NSNumber numberWithInteger:messageBody.stringValue.length].stringValue;

}
#pragma mark - APNS

- (NSString *)identityName {	
	if ([APNS sharedAPNS].identity == NULL)
		return @"Choose an identity";
	//else
	//	return [[[X509Certificate extractCertDictFromIdentity:[APNS sharedAPNS].identity] objectForKey:@"Subject"] objectForKey:@"CommonName"];
    return @"TEST";
}

- (NSArray *)identities {
	NSDictionary *query = [NSDictionary dictionaryWithObjectsAndKeys:
                           kSecClassIdentity, kSecClass, 
                           kSecMatchLimitAll, kSecMatchLimit, 
                           kCFBooleanTrue, kSecReturnRef, nil];
	
	OSStatus err;
	NSArray *result;
	CFArrayRef identities;
	
	identities = NULL;
	
	err = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&identities);
	
	if (err == noErr)
		result = [NSArray arrayWithArray:(__bridge id)identities];
	else
		result = [NSArray array];
	
	if (identities != NULL)
		CFRelease(identities);
	
	return result;
}
-(void)chooseIdentityPanelDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	if (returnCode == NSFileHandlingPanelOKButton) {		
		[[APNS sharedAPNS] setIdentity:(SecIdentityRef)CFRetain([SFChooseIdentityPanel sharedChooseIdentityPanel].identity)];
        
		// KVO trigger
		[self willChangeValueForKey:@"identityName"];
		[self didChangeValueForKey:@"identityName"];
	}
}


- (IBAction)chooseIdentity:(id)sender {
	SFChooseIdentityPanel *panel = [SFChooseIdentityPanel sharedChooseIdentityPanel];
	[panel setAlternateButtonTitle:@"Cancel"];
    //	[panel setPolicies:d SecPolicyRef
	
	[panel beginSheetForWindow:self.window
                 modalDelegate:self
                didEndSelector:@selector(chooseIdentityPanelDidEnd:returnCode:contextInfo:)
                   contextInfo:nil
                    identities:[self identities]
                       message:@"Choose the identity to use for delivering notifications: \n(Issued by Apple in the Provisioning Portal)"];
}

- (IBAction)sendPushNotificationsToSelectedusers:(id)sender {
    [[APNS sharedAPNS] setSandbox:self.sandbox.state];

    NSData *archivedObject = [NSKeyedArchiver archivedDataWithRootObject:messageBody.attributedStringValue];
    [[NSUserDefaults standardUserDefaults] setObject:archivedObject forKey:@"currentEmailBody"];
    
    if ([APNS sharedAPNS].identity == NULL) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"Missing identity" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"You have not choosen an identity for signing the notification."];
        [alert beginSheetModalForWindow:self.window
                          modalDelegate:self
                         didEndSelector:nil
                            contextInfo:nil];
        
    } else {
        if (messageBody.stringValue.length < 10) {
            NSAlert *alert = [NSAlert alertWithMessageText:@"Body is too small" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Body must be more than 10 symbols"];
            [alert beginSheetModalForWindow:self.window
                              modalDelegate:self
                             didEndSelector:nil
                                contextInfo:nil];
            
        } else {
            
            NSString *body = messageBody.stringValue;
            NSLog(@"%@",[APNS sharedAPNS].identity);
            NSLog(@"bage:%@",self.urlNumber);
            NSArray *selectedClients = self.client.selectedObjects;
            [selectedClients enumerateObjectsUsingBlock:^(Client *clientToSend, NSUInteger idx, BOOL *stop) {
                sleep(1);
                [[APNS sharedAPNS] pushWithToken:clientToSend.deviceToken alert:body sound:@"" badge:self.urlNumber.integerValue];
                NSLog(@"APP DELEGATE:send push to %@",clientToSend.email);
                
            }];
        }
        
    }
    
    
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex
{
    self.application.selectionIndex = rowIndex;
    Application *selectedApplication = self.application.selectedObjects.lastObject;
    self.client.filterPredicate = [NSPredicate predicateWithFormat:@"application == %@",selectedApplication];
    return YES;
}



@end
