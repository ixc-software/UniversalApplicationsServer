//
//  Client.m
//  UniversalApplicationsServer
//
//  Created by Oleksii Vynogradov on 5/1/12.
//  Copyright (c) 2012 IXC-USA Corp. All rights reserved.
//

#import "Client.h"
#import "Application.h"
#import "ClientContacts.h"


@implementation Client

@dynamic country;
@dynamic creationDate;
@dynamic deviceToken;
@dynamic email;
@dynamic guid;
@dynamic macAddress;
@dynamic modificationDate;
@dynamic phoneNumber;
@dynamic receiverIP;
@dynamic senderIP;
@dynamic localeIdentifier;
@dynamic application;
@dynamic clientContacts;

- (void)awakeFromInsert {
    NSDate *now = [NSDate date];
    
    [self willChangeValueForKey:@"guid"];
    [self setPrimitiveValue:[[NSProcessInfo processInfo] globallyUniqueString] forKey:@"guid"];
    [self didChangeValueForKey:@"guid"];
    
    [self willChangeValueForKey:@"creationDate"];
    [self setPrimitiveValue:now forKey:@"creationDate"];
    [self didChangeValueForKey:@"creationDate"];
    
    [self willChangeValueForKey:@"modificationDate"];
    [self setPrimitiveValue:now forKey:@"modificationDate"];
    [self didChangeValueForKey:@"modificationDate"];
}

-(void)willSave {
    NSDate *now = [NSDate date];
    if (self.modificationDate == nil || [now timeIntervalSinceDate:self.modificationDate] > 1.0) {
        [self willChangeValueForKey:@"modificationDate"];
        [self setPrimitiveValue:now forKey:@"modificationDate"];
        [self didChangeValueForKey:@"modificationDate"];
    }
}



@end
