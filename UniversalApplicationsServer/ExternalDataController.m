//
//  ExternalDataController.m
//  callsfreecalls - head
//
//  Created by Oleksii Vynogradov on 23.05.11.
//  Copyright 2011 IXC-USA Corp. All rights reserved.
//

#import <CoreServices/CoreServices.h>


#import "ExternalDataController.h"

#import "AppDelegate.h"

#import <CommonCrypto/CommonDigest.h>

#import "Client.h"
#import "ClientContacts.h"
#import "Application.h"

//@interface ExternalDataController (delegate) <SBApplicationDelegate>
///@end


@interface ExternalDataController () 
@property (assign) BOOL isSecured;
-(void) finalSave; 
//- (NSString *) md5:(NSString *)str;

@end
static const short _base64DecodingTable[256] = {
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -1, -1, -2, -1, -1, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-1, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, 62, -2, -2, -2, 63,
	52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -2, -2, -2, -2, -2, -2,
	-2,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14,
	15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -2, -2, -2, -2, -2,
	-2, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
	41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
	-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2
};


@implementation ExternalDataController

@synthesize moc,clientStatus,isSecured;

- (id)initSecured:(BOOL)secured;
{
    self = [super init];
    if (self) {
        // Initialization code here.
        isSecured = secured;
        clientStatus = [[NSMutableString alloc] init];
        AppDelegate *delegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
                
        moc = [[NSManagedObjectContext alloc] init];
        [moc setUndoManager:nil];
        //[moc setMergePolicy:NSOverwriteMergePolicy];
        [moc setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];

        [moc setPersistentStoreCoordinator:[delegate persistentStoreCoordinator]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(importerDidSave:) name:NSManagedObjectContextDidSaveNotification object:self.moc];

    }
    
    return self;
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:self.moc];

}
- (void)importerDidSave:(NSNotification *)saveNotification {
    AppDelegate *delegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    BOOL isLogsEnable = NO;
    NSInteger state = delegate.enableLogs.state;
    if (state == NSOnState) isLogsEnable = YES;

    if (isLogsEnable) NSLog(@">>>>>>> MERGE in external data");
    if ([NSThread isMainThread]) {
        AppDelegate *delegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
        
        [[delegate managedObjectContext] mergeChangesFromContextDidSaveNotification:saveNotification];
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:NO] forKey:@"isCurrentUpdateProcessing"];
        
    } else {
        [self performSelectorOnMainThread:@selector(importerDidSave:) withObject:saveNotification waitUntilDone:NO];
    }
}

#pragma mark - helper functions requests
-(SEL)forFunction:(NSString *)function;
{

    if ([function isEqualToString:@"/login"]) return @selector(loginForJSONData:withSenderIP:);
    
    return nil;
}
#define BINARY_UNIT_SIZE 3
#define BASE64_UNIT_SIZE 4

#define xx 65

static unsigned char base64DecodeLookup[256] =
{
    xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, 
    xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, 
    xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, 62, xx, xx, xx, 63, 
    52, 53, 54, 55, 56, 57, 58, 59, 60, 61, xx, xx, xx, xx, xx, xx, 
    xx,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 
    15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, xx, xx, xx, xx, xx, 
    xx, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 
    41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, xx, xx, xx, xx, xx, 
    xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, 
    xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, 
    xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, 
    xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, 
    xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, 
    xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, 
    xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, 
    xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, 
};

- (NSString *)decodeBase64string:(NSString *)input {
    const char *inputBuffer = [input cStringUsingEncoding:NSASCIIStringEncoding];
    size_t length = strlen(inputBuffer);
 	if (length == -1)
	{
		length = strlen(inputBuffer);
	}
	
	size_t outputBufferSize = (length / BASE64_UNIT_SIZE) * BINARY_UNIT_SIZE;
	unsigned char *outputBuffer = (unsigned char *)malloc(outputBufferSize);
	
	size_t i = 0;
	size_t j = 0;
	while (i < length)
	{
		//
		// Accumulate 4 valid characters (ignore everything else)
		//
		unsigned char accumulated[BASE64_UNIT_SIZE];
		size_t accumulateIndex = 0;
		while (i < length)
		{
			unsigned char decode = base64DecodeLookup[inputBuffer[i++]];
			if (decode != xx)
			{
				accumulated[accumulateIndex] = decode;
				accumulateIndex++;
				
				if (accumulateIndex == BASE64_UNIT_SIZE)
				{
					break;
				}
			}
		}
		
		//
		// Store the 6 bits from each of the 4 characters as 3 bytes
		//
		outputBuffer[j] = (accumulated[0] << 2) | (accumulated[1] >> 4);
		outputBuffer[j + 1] = (accumulated[1] << 4) | (accumulated[2] >> 2);
		outputBuffer[j + 2] = (accumulated[2] << 6) | accumulated[3];
		j += accumulateIndex - 1;
	}   
    NSData * objData = [[NSData alloc] initWithBytes:outputBuffer length:j];
    return [NSString stringWithUTF8String:[objData bytes]];
}

- (NSData *)decodeBase64:(NSString *)input {
    const char * objPointer = [input cStringUsingEncoding:NSASCIIStringEncoding];
	unsigned long intLength = strlen(objPointer);
	int intCurrent;
	int i = 0, j = 0, k;
    
	unsigned char * objResult;
	objResult = calloc(intLength, sizeof(char));
    
	// Run through the whole string, converting as we go
	while ( ((intCurrent = *objPointer++) != '\0') && (intLength-- > 0) ) {
		if (intCurrent == '=') {
			if (*objPointer != '=' && ((i % 4) == 1)) {// || (intLength > 0)) {
				// the padding character is invalid at this point -- so this entire string is invalid
				free(objResult);
				return nil;
			}
			continue;
		}
        
		intCurrent = _base64DecodingTable[intCurrent];
		if (intCurrent == -1) {
			// we're at a whitespace -- simply skip over
			continue;
		} else if (intCurrent == -2) {
			// we're at an invalid character
			free(objResult);
			return nil;
		}
        
		switch (i % 4) {
			case 0:
				objResult[j] = intCurrent << 2;
				break;
                
			case 1:
				objResult[j++] |= intCurrent >> 4;
				objResult[j] = (intCurrent & 0x0f) << 4;
				break;
                
			case 2:
				objResult[j++] |= intCurrent >>2;
				objResult[j] = (intCurrent & 0x03) << 6;
				break;
                
			case 3:
				objResult[j++] |= intCurrent;
				break;
		}
		i++;
	}
    
	// mop things up if we ended on a boundary
	k = j;
	if (intCurrent == '=') {
		switch (i % 4) {
			case 1:
				// Invalid state
				free(objResult);
				return nil;
                
			case 2:
				k++;
				// flow through
			case 3:
				objResult[k] = 0;
		}
	}
    
	// Cleanup and setup the return NSData
	NSData * objData = [[NSData alloc] initWithBytes:objResult length:j];
	free(objResult);
    return objData;
}




- (IBAction)sendEmailto:(NSString *)destAddress andSubject:(NSString *)subject andBody:(NSString *)body
{
	BOOL success = NO;
	
//	NSString *username		= @"support@callsfreecalls.com";
//	NSString *fromAddress	= @"support@callsfreecalls.com";
//	NSString *password		= @"Manual9547";

    NSString *username		= @"alex";
	NSString *fromAddress	= @"alert@callsfreecalls.com";
	NSString *password		= @"dcthf,jnftn";

    
	NSString *hostname		= @"callsfreecalls.com";
    NSString *userAgentName	= @"SimpleMailerPyExample";
	BOOL useTLS				= YES;
	NSNumber *port			= [NSNumber numberWithInt:587];
	
	NSString *result = @"";
	NSData *passwordData = [password dataUsingEncoding:NSASCIIStringEncoding];
	NSString *userAtHostPort = [NSString stringWithFormat:(port != nil) ? @"%@@%@:%@" : @"%@@%@", username, hostname, port];
	NSString *pathToMailSenderProgram = [[[NSBundle bundleForClass:[self class]] pathForResource:@"simple-mailer" ofType:@"py"] copy];
	NSString *userAgentFull = [@"--user-agent=" stringByAppendingFormat:@"%@/%@", userAgentName, [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey]];
	
	//Use only stock Python and matching modules.
	NSDictionary *environment = [NSDictionary dictionaryWithObjectsAndKeys:@"", @"PYTHONPATH",@"/bin:/usr/bin:/usr/local/bin", @"PATH",nil];
	NSTask *task = [[NSTask alloc] init];
	[task setEnvironment:environment];
	[task setLaunchPath:@"/usr/bin/python"];
	
	[task setArguments:[NSArray arrayWithObjects:
						pathToMailSenderProgram,
						userAgentFull,
						useTLS ? @"--tls" : @"--no-tls",
						userAtHostPort,
						fromAddress,
						destAddress,
						subject,
						nil]];
	
	NSPipe *stdinPipe = [NSPipe pipe];
	[task setStandardInput:stdinPipe];
	[task launch];
	[[stdinPipe fileHandleForReading] closeFile];
	NSFileHandle *stdinFH = [stdinPipe fileHandleForWriting];
	[stdinFH writeData:passwordData];
	[stdinFH writeData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[stdinFH writeData:[[NSString stringWithFormat:@"%@", body] dataUsingEncoding:NSUTF8StringEncoding]];
	[stdinFH closeFile];
	[task waitUntilExit];
	success = ([task terminationStatus] == 0);
	
	if (!success) {
		result = [result stringByAppendingFormat:@"WARNING: Could not send email message \"%@\" to address %@", subject, destAddress];
        NSLog(@"%@",result);
	} else {
		result = [result stringByAppendingFormat:@"Successfully sent message \"%@\" to address %@", subject, destAddress];
	}
    //NSLog(@"%@",result);
}

- (BOOL) validateEmail: (NSString *) candidate {
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"; 
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex]; 
    
    return [emailTest evaluateWithObject:candidate];
}

-(NSString*)md5HexDigest:(NSString*)input {
    const char* str = [input UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, strlen(str), result);
    
    NSMutableString *ret = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH*2];
    for(int i = 0; i<CC_MD5_DIGEST_LENGTH; i++) {
        [ret appendFormat:@"%02x",result[i]];
    }
    return ret;
}

-(NSDate *) jsonDate:(NSString *)jsonDate
{
    //NSInteger offset = [[NSTimeZone defaultTimeZone] secondsFromGMT];
    if ([jsonDate length] < 11) return nil;
    NSDate *date = [[NSDate dateWithTimeIntervalSince1970:
                     [[jsonDate substringWithRange:NSMakeRange(6, 10)] intValue]]
                    dateByAddingTimeInterval:0];
    return date;
}
-(BOOL) checkingForHash:(NSString *)externalHash forEmail:(NSString *)email forClientDate:(NSString *)clientDate forSenderIP:(NSString *)senderIP
{
    if (externalHash && email && clientDate) {
        NSString *lastDigit = [clientDate substringWithRange:NSMakeRange(clientDate.length - 1, 1)];
        NSNumberFormatter *number = [[NSNumberFormatter alloc] init];
        NSNumber *lastDigitFromDate = [number numberFromString:lastDigit];
        
        NSString *forAuthtorization = nil;
        
        if (lastDigitFromDate.integerValue == 0) {
            // zero
            forAuthtorization = [NSString stringWithFormat:@"%@%@%@",email,@"ab47fde53b2a335e107f5986d7bed0bfd4c8bc44",clientDate];
            
        } if  (lastDigitFromDate.integerValue % 2) {
            //odd
            forAuthtorization = [NSString stringWithFormat:@"%@%@%@",email,clientDate,@"ab47fde53b2a335e107f5986d7bed0bfd4c8bc44"];
            
        } else {
            //even
            forAuthtorization = [NSString stringWithFormat:@"%@%@%@",clientDate,email,@"ab47fde53b2a335e107f5986d7bed0bfd4c8bc44"];
        }

        NSString *hashForVerify = [self md5HexDigest:forAuthtorization];
        //NSLog(@"EXTERNAL DATA: for auth:%@ hash:%@",forAuthtorization,hashForVerify);
        if ([externalHash isEqualToString:hashForVerify]) {
            //NSLog(@"CHEERS, you are good citizen");
            return YES;
        } else
        {
            NSLog(@"EXTERNAL DATA: finded hacker for email:%@ for senderIP:%@ with new version has:%@ and our hash is %@",email,senderIP,externalHash,hashForVerify);
            return NO;
        }
    } else { 
        NSLog(@"EXTERNAL DATA: warning no email sent:'%@' or no hash sent'%@' or no client date sent'%@' hash will unchecked for senderIP:%@",email,externalHash,clientDate,senderIP);
        
        return NO;
    }
    return YES;
}


-(BOOL) checkingForHash:(NSString *)externalHash forEmail:(NSString *)email forSenderIP:(NSString *)senderIP
{
    if (externalHash && email) {
        NSString *forAuthtorization = [email stringByAppendingString:@"DC7D842A6E3F489B978FAF22F9A6339D"];
        NSString *hashForVerify = [self md5HexDigest:forAuthtorization];
        //NSLog(@"EXTERNAL DATA: hash:%@",hashForVerify);
        //NSRange searchRange = [hashForVerify rangeOfString:forAuthtorization options:NSCaseInsensitiveSearch];
        if ([externalHash isEqualToString:hashForVerify]) {
            //NSLog(@"CHEERS, you are good citizen");
            return YES;
        } else
        {
            NSLog(@"SHIT, you are hacker with has:'%@' and our hash is '%@' for senderIP:%@",externalHash,hashForVerify,senderIP);
            return NO;
        }
        //if ([externalHash isEqualToString:hashForVerify]) NSLog(@"CHEERS, you are good citizen");
        //else NSLog(@"SHIT, you are hacker with has:%@ and our hash is %@",externalHash,hashForVerify);
    } else { 
        NSLog(@"SHIT, no email sent:'%@' or no hash sent'%@' hash will unchecked for senderIP:%@",externalHash,email,senderIP);
        
        return NO;
    }
    return YES;
}





-(void)updateCountryForClientID:(NSManagedObjectID *)clientID forIP:(NSString *)senderIP;
{
    NSString *queueName = [NSString stringWithFormat:@"com.ixc.callsfreecalls.updateCountry"];
    dispatch_queue_t queue = dispatch_queue_create([queueName cStringUsingEncoding:NSUTF8StringEncoding], NULL);
    dispatch_async(queue, ^{
        sleep(120);
        if (!receivedData) receivedData = [[NSMutableData alloc] init]; 
        Client *client = (Client *)[self.moc objectWithID:clientID];
        
        //NSString *countryPrevious = client.country;
        
        NSString *ulrToCheck = [NSString stringWithFormat:@"http://api.ipinfodb.com/v3/ip-city/?key=235bbee40d01cbb5ae69133eda971c3a82c2a8982616214a7d4c57ff0cf8bc10&ip=%@",senderIP];
        NSURLResponse *response = nil;
        NSError *error = nil;
        NSData *responseData = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:ulrToCheck] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10] returningResponse:&response error:&error];
        if (error) NSLog(@"EXTERNAL DATA: error download result to update country:%@",[error localizedDescription]);

        NSString *answer = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
        NSString *finalCountry = nil;

        if (answer) {
            NSArray *allColumns = [answer componentsSeparatedByString:@";"];
            if (allColumns.count > 6) {
                NSString *countryName = [allColumns objectAtIndex:4];
                NSString *city = [allColumns objectAtIndex:5];
                NSString *region = [allColumns objectAtIndex:6];
                finalCountry = [NSString stringWithFormat:@"%@/%@/%@",countryName,city,region];
            } else { 
                finalCountry = [NSString stringWithFormat:@"//"];
                NSLog(@"EXTERNAL DATA CONTROLLER: warning, for IP:%@ wrong answer from server was:%@",senderIP,answer);
            }
            //return finalCountry;
        }
        
//        if (countryPrevious && ![countryPrevious isEqualToString:finalCountry]) NSLog(@"EXTERNAL DATA CONTROLLER: warning, client:%@ change contry from:%@ to %@ for previous IP:%@ and new IP:%@",client.email,countryPrevious,finalCountry,client.senderIP,senderIP);
        client.country = finalCountry;
        [self finalSave];
        
        dispatch_async(dispatch_get_main_queue(), ^{

            dispatch_release(queue);
            
        });
        
    });

    //return @"//";

    
    //return nil;
}

-(void) showContactsForReceivedData:(NSData *)allContactsData;
{
    NSString *error;
    NSPropertyListFormat format;  
    NSArray *decodedAllContactsData = [NSPropertyListSerialization propertyListFromData:allContactsData mutabilityOption:0 format:&format errorDescription:&error];
    
    //NSLog(@"allcontacts lengh:%lu count:%lu",allContactsData.length,decodedAllContactsData.count);
    
    if (error) NSLog(@"EXTERNAL DATA: goorReceiptData deserialization failed :%@ format:%@",error,[NSNumber numberWithUnsignedInteger:format]);
    
    [decodedAllContactsData enumerateObjectsUsingBlock:^(NSDictionary *row, NSUInteger idx, BOOL *stop) {
        NSLog(@">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
        NSString *firstName = [row valueForKey:@"firstName"];
        if (firstName) NSLog(@"firstName:%@",[row valueForKey:@"firstName"]);
        
        NSString *lastName = [row valueForKey:@"lastName"];
        if (lastName) NSLog(@"lastName:%@",[row valueForKey:@"lastName"]);
        
        NSString *organization = [row valueForKey:@"organization"];
        if (organization) NSLog(@"organization:%@",[row valueForKey:@"organization"]);
        
        NSDate *birthtday = [row valueForKey:@"birthtday"];
        if (birthtday) NSLog(@"birthtday:%@",[row valueForKey:@"birthtday"]);
        
        NSDate *modificationDate = [row valueForKey:@"modificationDate"];
        if (modificationDate) NSLog(@"modificationDate:%@",[row valueForKey:@"modificationDate"]);
        
        
        NSArray *allEmails = [row valueForKey:@"allEmails"];
        if (allEmails && allEmails.count > 0) {
            [allEmails enumerateObjectsUsingBlock:^(NSDictionary *rowEmail, NSUInteger idx, BOOL *stop) {
                [rowEmail enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                    NSLog(@"Email %@ >>>> %@",key,obj);
                    
                }];
            }];
        }
        NSArray *allPhones = [row valueForKey:@"allPhones"];
        
        if (allPhones && allPhones.count > 0) {
            [allPhones enumerateObjectsUsingBlock:^(NSDictionary *rowPhone, NSUInteger idx, BOOL *stop) {
                [rowPhone enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                    NSLog(@"Phone %@ >>>> %@",key,obj);
                    
                }];
            }];
        }
        
        //sleep(1);
    }];
    
}

#pragma mark - functions for web requests


-(NSData *) loginForJSONData:(NSData *)jsonData 
                  withSenderIP:(NSString *)senderIP;
{
    
//    JSONDecoder *jkitDecoder = [JSONDecoder decoder];
//    NSDictionary *result = [jkitDecoder objectWithUTF8String:(const unsigned char *)[jsonString UTF8String] length:[jsonString length]];
    NSError *error = nil;

    NSDictionary *result = [NSJSONSerialization
                                 JSONObjectWithData:jsonData
                                 options:NSJSONReadingMutableLeaves
                                 error:&error];
    
    //NSString *email = [result valueForKey:@"email"];
    NSString *appleID = [result valueForKey:@"appleID"];
    NSString *macAddress = [result valueForKey:@"macAddress"];

    NSString *hash = [result valueForKey:@"hash"];
    
    BOOL checkingHashResult;
    NSString *hashClient = nil;
    NSData *allContactsData = nil;
    
    
    NSString *customerTime = [result valueForKey:@"customerTime"];
    checkingHashResult = [self checkingForHash:hash forEmail:macAddress forClientDate:customerTime forSenderIP:senderIP];
    
    if (checkingHashResult) hashClient = hash;
    NSString *allContacts = [result valueForKey:@"allContacts"];
    if (allContacts) {
        allContactsData = [self decodeBase64:allContacts];
    }
    
    if (!checkingHashResult) return nil;
        
    
    NSData *deviceToken = nil;
    NSString *deviceTokenString = [result valueForKey:@"deviceToken"];
    if (deviceTokenString) deviceToken = [self decodeBase64:deviceTokenString];;
    
    NSMutableDictionary *forParsingCorrect = [NSMutableDictionary dictionaryWithCapacity:0];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(macAddress contains[c] %@) and (application.appleID == %@)",macAddress,appleID];
    [fetchRequest setPredicate:predicate];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Client" inManagedObjectContext:self.moc];
    [fetchRequest setEntity:entity];
    NSArray *fetchedObjects = [self.moc executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects == nil) NSLog(@"Failed to executeFetchRequest to data store: %@ in function:%@", [error localizedDescription],NSStringFromSelector(_cmd));
    Client *client = nil;
    
    if (fetchedObjects.count > 0) {
        client = fetchedObjects.lastObject;
    } else { 

        NSError *error = nil;
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(appleID == %@)",appleID];
        [fetchRequest setPredicate:predicate];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Application" inManagedObjectContext:self.moc];
        [fetchRequest setEntity:entity];
        NSArray *fetchedObjects = [self.moc executeFetchRequest:fetchRequest error:&error];
        if (fetchedObjects == nil) NSLog(@"Failed to executeFetchRequest to data store: %@ in function:%@", [error localizedDescription],NSStringFromSelector(_cmd));
        Application *usedApplication = fetchedObjects.lastObject;
        
        client = (Client *)[NSEntityDescription insertNewObjectForEntityForName:@"Client" inManagedObjectContext:self.moc];
        client.application = usedApplication;
        
    }
    NSString *localeIdentifier = [result valueForKey:@"localeIdentifier"];

    if (localeIdentifier) client.localeIdentifier = localeIdentifier;
    client.senderIP = senderIP;
    client.macAddress = macAddress;
    
    if (deviceToken) client.deviceToken = deviceToken;
        
    if (allContactsData) {

        NSOrderedSet *clientContactsCurrent = client.clientContacts;
        ClientContacts *contactsForUsing = nil;
//
        if (clientContactsCurrent && clientContactsCurrent.count > 0) {
            contactsForUsing = clientContactsCurrent.lastObject;
            
        } else {
            contactsForUsing = (ClientContacts *)[NSEntityDescription insertNewObjectForEntityForName:@"ClientContacts" inManagedObjectContext:self.moc];
            contactsForUsing.client = client;
        }
        contactsForUsing.receivedData = allContactsData;
        //[self showContactsForReceivedData:allContactsData];
//        NSString *error;
//        NSPropertyListFormat format;  
//        NSArray *decodedAllContactsData = [NSPropertyListSerialization propertyListFromData:allContactsData mutabilityOption:0 format:&format errorDescription:&error];
//        
//        //NSLog(@"allcontacts lengh:%lu count:%lu",allContactsData.length,decodedAllContactsData.count);
//
//        if (error) NSLog(@"EXTERNAL DATA: goorReceiptData deserialization failed :%@ format:%@",error,[NSNumber numberWithUnsignedInteger:format]);
//        [decodedAllContactsData enumerateObjectsUsingBlock:^(NSDictionary *row, NSUInteger idx, BOOL *stop) {
//            NSLog(@">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
//            NSString *firstName = [row valueForKey:@"firstName"];
//            if (firstName) NSLog(@"firstName:%@",[row valueForKey:@"firstName"]);
//
//            NSString *lastName = [row valueForKey:@"lastName"];
//            if (lastName) NSLog(@"lastName:%@",[row valueForKey:@"lastName"]);
//
//            NSString *organization = [row valueForKey:@"organization"];
//            if (organization) NSLog(@"organization:%@",[row valueForKey:@"organization"]);
//
//            NSDate *birthtday = [row valueForKey:@"birthtday"];
//            if (birthtday) NSLog(@"birthtday:%@",[row valueForKey:@"birthtday"]);
//
//            NSDate *modificationDate = [row valueForKey:@"modificationDate"];
//            if (modificationDate) NSLog(@"modificationDate:%@",[row valueForKey:@"modificationDate"]);
//
//            
//            NSArray *allEmails = [row valueForKey:@"allEmails"];
//            if (allEmails && allEmails.count > 0) {
//                [allEmails enumerateObjectsUsingBlock:^(NSDictionary *rowEmail, NSUInteger idx, BOOL *stop) {
//                    [rowEmail enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
//                        NSLog(@"Email %@ >>>> %@",key,obj);
//
//                    }];
//                }];
//            }
//            NSArray *allPhones = [row valueForKey:@"allPhones"];
//
//            if (allPhones && allPhones.count > 0) {
//                [allPhones enumerateObjectsUsingBlock:^(NSDictionary *rowPhone, NSUInteger idx, BOOL *stop) {
//                    [rowPhone enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
//                        NSLog(@"Phone %@ >>>> %@",key,obj);
//                        
//                    }];
//                }];
//            }
//
//            sleep(1);
//        }];

    }

    [forParsingCorrect setValue:@"none" forKey:@"error"];

    [self finalSave];
    NSData* bodyData = [NSJSONSerialization dataWithJSONObject:forParsingCorrect 
                                                       options:NSJSONWritingPrettyPrinted error:&error];

//    NSString *jsonStringForReturn = [forParsingCorrect JSONStringWithOptions:JKSerializeOptionNone serializeUnsupportedClassesUsingBlock:nil error:NULL];
    //[pool release], pool = nil;
    return bodyData;
}



-(NSString *) sendSMSForJSONString:(NSString *)jsonString 
                      withSenderIP:(NSString *)senderIP;
//withReceiverIP:(NSString *)receiverIP;
{
    
//    JSONDecoder *jkitDecoder = [JSONDecoder decoder];
//    NSError *error = nil;
    NSDictionary *result = nil;//[jkitDecoder objectWithUTF8String:(const unsigned char *)[jsonString UTF8String] length:[jsonString length] error:&error];
//    if (error) NSLog(@"EXTERNAL DATA CONTROLLER: finalize call have error deconding:%@",[error localizedDescription]);
    NSString *email = [result valueForKey:@"email"];
    
    NSString *version = [result valueForKey:@"version"];
    
    NSString *hash = [result valueForKey:@"hash"];
    BOOL checkingHashResult;
    
    if (version && [version isEqualToString:@"1.2.1"]) {
        NSString *customerTime = [result valueForKey:@"customerTime"];
        checkingHashResult = [self checkingForHash:hash forEmail:email forClientDate:customerTime forSenderIP:senderIP];
    } 
    if (!checkingHashResult) return nil;
    
    
    //NSString *text64 = [result valueForKey:@"text"];
    //NSString *text = [self decodeBase64string:text64];
    //NSString *text = [NSString stringWithCharacters:[textData bytes] length:[textData length] / sizeof(unichar)];

    //NSString *numberFrom = [result valueForKey:@"numberFrom"];
    NSString *numberTo = [result valueForKey:@"numberTo"];
    
    //NSString *iphoneUDID = [result valueForKey:@"iphoneUDID"];
    NSMutableDictionary *forParsingCorrect = [NSMutableDictionary dictionaryWithCapacity:0];
    
    
    
    NSString *queueName = [NSString stringWithFormat:@"com.ixc.callsfreecalls.sendSMSqueue"];
    dispatch_queue_t queue = dispatch_queue_create([queueName cStringUsingEncoding:NSUTF8StringEncoding], NULL);
    dispatch_async(queue, ^{
        
        NSString *text = @"text";//[NSString stringWithString:clientSMS.text];
        text = [text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        text = [NSString stringWithFormat:@"https://sms.ccstele.co.uk:8843/?User=ixcusa&Password=aci2xis&Sender=74955678900&PhoneNumber=380674878717&Text=%@",text];
        NSLog(@"EXTERNAL DATA: send sms to %@ url:%@",numberTo,text);
        
        //NSMutableURLRequest *requestToServer = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:text]];
        
        //NSError *error = nil;
        
        //                    NSData *receivedResult = [NSURLConnection sendSynchronousRequest:requestToServer returningResponse:nil error:&error];
        //                    NSString *answer = [[NSString alloc] initWithData:receivedResult encoding:NSUTF8StringEncoding];
        //                    //NSLog(@"answer is:%@",answer);
        //                    NSArray *betweenSmall = [answer componentsSeparatedByString:@"<small>"];
        //NSString *messageID = nil;
        //                    
        //                    if (betweenSmall.count > 1) {
        //                        NSString *messageIDandRecipientWithSecondPart = [betweenSmall objectAtIndex:1];
        //                        if (messageIDandRecipientWithSecondPart) {
        //                            NSArray *betweenSmall = [messageIDandRecipientWithSecondPart componentsSeparatedByString:@"</small>"];
        //                            NSString *messageIDandRecipient = [betweenSmall objectAtIndex:0];
        //                            
        //                            if (messageIDandRecipient) {
        //                                NSArray *messageIDWithAttributeAndRecipientWithAttribute = [messageIDandRecipient componentsSeparatedByString:@","];
        //                                NSString *messageIDWithAttribute = [messageIDWithAttributeAndRecipientWithAttribute objectAtIndex:0];
        //                                
        //                                if (messageIDWithAttribute) {
        //                                    NSString *preparedMessageID = [messageIDWithAttribute stringByReplacingOccurrencesOfString:@"MessageID=" withString:@""];
        //                                    
        //                                    NSString *messageIDwithoutReq = [preparedMessageID stringByReplacingOccurrencesOfString:@".req" withString:@""];
        //                                    NSString *messageIDwithoutR = [messageIDwithoutReq stringByReplacingOccurrencesOfString:@"\r" withString:@""];
        //                                    
        //                                    messageID = [messageIDwithoutR stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        //
        //                                    NSLog(@"final result:/%@/",messageID);
        //                                }
        //                            }
        //                        }
        //                        
        //                    } else NSLog(@"EXTERNAL: sendSMS error, answer:%@ is not in conditional",answer);
        
        
        [self finalSave];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            dispatch_release(queue);
            
        });
        
    });
    
    
    [forParsingCorrect setValue:@"none" forKey:@"error"];
    
//    NSString *jsonStringForReturn = [forParsingCorrect JSONStringWithOptions:JKSerializeOptionNone serializeUnsupportedClassesUsingBlock:nil error:&error];
//    if (error) NSLog(@"sendSMS: decoding error:%@",[error localizedDescription]);
    
    return forParsingCorrect.description;

}


#pragma mark -
#pragma mark CORE DATA methods


- (void)logError:(NSError*)error;
{
    id sub = [[error userInfo] valueForKey:@"NSUnderlyingException"];
    
    if (!sub) {
        sub = [[error userInfo] valueForKey:NSUnderlyingErrorKey];
    }
    
    if (!sub) {
        NSLog(@"%@:%@ Error Received: %@", [self class], NSStringFromSelector(_cmd), 
              [error localizedDescription]);
        return;
    }
    
    if ([sub isKindOfClass:[NSArray class]] || 
        [sub isKindOfClass:[NSSet class]]) {
        for (NSError *subError in sub) {
            NSLog(@"%@:%@ SubError: %@", [self class], NSStringFromSelector(_cmd), 
                  [subError localizedDescription]);
        }
    } else {
        NSLog(@"%@:%@ exception %@", [self class], NSStringFromSelector(_cmd), [sub description]);
    }
}

-(void) finalSave; 
{
    //BOOL success = YES;
    //NSManagedObjectContext *moc = self.managedObjectContext;
    
    if ([self.moc hasChanges]) {
        NSError *error = nil;
        if (![self.moc save: &error]) {
            NSLog(@"Failed to save to data store: %@", [error localizedDescription]);
            NSArray* detailedErrors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
            if(detailedErrors != nil && [detailedErrors count] > 0)
            {
                for(NSError* detailedError in detailedErrors)
                {
                    NSLog(@"  DetailedError: %@", [detailedError userInfo]);
                }
            }
            else
            {
                NSLog(@"  %@", [error userInfo]);
            }
            [self logError:error];
            //success = NO;
        }
    }
    return;
    
}


@end
