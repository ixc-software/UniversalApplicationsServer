//
//  Application.h
//  UniversalApplicationsServer
//
//  Created by Oleksii Vynogradov on 4/30/12.
//  Copyright (c) 2012 IXC-USA Corp. All rights reserved.
///

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Client;

@interface Application : NSManagedObject

@property (nonatomic, retain) NSString * appleID;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSOrderedSet *client;
@end

@interface Application (CoreDataGeneratedAccessors)

- (void)insertObject:(Client *)value inClientAtIndex:(NSUInteger)idx;
- (void)removeObjectFromClientAtIndex:(NSUInteger)idx;
- (void)insertClient:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeClientAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInClientAtIndex:(NSUInteger)idx withObject:(Client *)value;
- (void)replaceClientAtIndexes:(NSIndexSet *)indexes withClient:(NSArray *)values;
- (void)addClientObject:(Client *)value;
- (void)removeClientObject:(Client *)value;
- (void)addClient:(NSOrderedSet *)values;
- (void)removeClient:(NSOrderedSet *)values;
@end
