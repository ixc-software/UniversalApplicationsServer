//
//  Client.h
//  UniversalApplicationsServer
//
//  Created by Oleksii Vynogradov on 5/1/12.
//  Copyright (c) 2012 IXC-USA Corp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Application, ClientContacts;

@interface Client : NSManagedObject

@property (nonatomic, retain) NSString * country;
@property (nonatomic, retain) NSDate * creationDate;
@property (nonatomic, retain) NSData * deviceToken;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * guid;
@property (nonatomic, retain) NSString * macAddress;
@property (nonatomic, retain) NSDate * modificationDate;
@property (nonatomic, retain) NSString * phoneNumber;
@property (nonatomic, retain) NSString * receiverIP;
@property (nonatomic, retain) NSString * senderIP;
@property (nonatomic, retain) NSString * localeIdentifier;
@property (nonatomic, retain) Application *application;
@property (nonatomic, retain) NSOrderedSet *clientContacts;
@end

@interface Client (CoreDataGeneratedAccessors)

- (void)insertObject:(ClientContacts *)value inClientContactsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromClientContactsAtIndex:(NSUInteger)idx;
- (void)insertClientContacts:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeClientContactsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInClientContactsAtIndex:(NSUInteger)idx withObject:(ClientContacts *)value;
- (void)replaceClientContactsAtIndexes:(NSIndexSet *)indexes withClientContacts:(NSArray *)values;
- (void)addClientContactsObject:(ClientContacts *)value;
- (void)removeClientContactsObject:(ClientContacts *)value;
- (void)addClientContacts:(NSOrderedSet *)values;
- (void)removeClientContacts:(NSOrderedSet *)values;
@end
