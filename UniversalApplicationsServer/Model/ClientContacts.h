//
//  ClientContacts.h
//  UniversalApplicationsServer
//
//  Created by Oleksii Vynogradov on 4/30/12.
//  Copyright (c) 2012 IXC-USA Corp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Client;

@interface ClientContacts : NSManagedObject

@property (nonatomic, retain) NSData * receivedData;
@property (nonatomic, retain) Client *client;

@end
