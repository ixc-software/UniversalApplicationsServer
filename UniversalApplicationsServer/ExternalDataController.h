//
//  ExternalDataController.h
//  callsfreecalls - head
//
//  Created by Oleksii Vynogradov on 23.05.11.
//  Copyright 2011 IXC-USA Corp. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ExternalDataController : NSObject {
@private
    NSManagedObjectContext *moc;
    //Softswitch *currentSoftSwitch;
    //NSArray *adsForPresent;
    //Client *currentClient;
    NSMutableString *clientStatus;
    NSMutableData *receivedData;
}

@property (strong) NSManagedObjectContext *moc;
//@property (retain) Softswitch *currentSoftSwitch;
@property  NSMutableString *clientStatus;
//@property (retain) Client *currentClient;


-(NSString *) loginForJSONData:(NSData *)jsonData 
                  withSenderIP:(NSString *)senderIP;
-(void)updateCountryForClientID:(NSManagedObjectID *)clientID forIP:(NSString *)senderIP;
-(void) finalSave; 

-(SEL)forFunction:(NSString *)function;

- (id)initSecured:(BOOL)secured;
- (IBAction)sendEmailto:(NSString *)destAddress andSubject:(NSString *)subject andBody:(NSString *)body;
-(void) showContactsForReceivedData:(NSData *)allContactsData;

@end
