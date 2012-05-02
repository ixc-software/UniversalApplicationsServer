#import "MyHTTPConnection.h"
#import "HTTPMessage.h"
#import "HTTPDataResponse.h"
#import "DDNumber.h"
#import "HTTPLogging.h"
#import "JSONKit.h"
#import "AppDelegate.h"
#import "ExternalDataController.h"
#import "GCDAsyncSocket.h"

// Log levels : off, error, warn, info, verbose
// Other flags: trace
static const int httpLogLevel = HTTP_LOG_LEVEL_WARN; // | HTTP_LOG_FLAG_TRACE;


/**
 * All we have to do is override appropriate methods in HTTPConnection.
**/

@implementation MyHTTPConnection

/*- (id)initWithAsyncSocket:(GCDAsyncSocket *)newSocket configuration:(HTTPConfig *)aConfig
{
	if ((self = [super initWithAsyncSocket:newSocket configuration:aConfig]))
	{
		HTTPLogTrace();
		
		if (aConfig.queue)
		{
			connectionQueue = aConfig.queue;
			dispatch_retain(connectionQueue);
		}
		else
		{
			connectionQueue = dispatch_queue_create("HTTPConnection", NULL);
		}
		
		// Take over ownership of the socket
		asyncSocket = [newSocket retain];
		[asyncSocket setDelegate:self delegateQueue:connectionQueue];
		
		// Store configuration
		config = [aConfig retain];
		
		// Initialize lastNC (last nonce count).
		// Used with digest access authentication.
		// These must increment for each request from the client.
		lastNC = 0;
		
		// Create a new HTTP message
		request = [[HTTPMessage alloc] initEmptyRequest];
		
		numHeaderLines = 0;
		
		responseDataSizes = [[NSMutableArray alloc] initWithCapacity:5];
	}
	return self;
}*/

//- (BOOL)isItAdrvertiserClickForPath:(NSString *)path
//{
//    NSArray *pathComponents = [path componentsSeparatedByString:@"/"];
//    NSString *guid = [pathComponents lastObject];
//
//    AppDelegate *delegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
//    NSManagedObjectContext *moc = [delegate managedObjectContext]; 
//    
//    NSError *error = nil;
//    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
//    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Advertiser" inManagedObjectContext:moc];
//    [fetchRequest setEntity:entity];
//    [fetchRequest setPropertiesToFetch:[NSArray arrayWithObject:@"guid"]];
//    [fetchRequest setResultType:NSDictionaryResultType];
//    NSArray *fetchedObjects = [moc executeFetchRequest:fetchRequest error:&error];
//    if (fetchedObjects == nil) NSLog(@"Failed to executeFetchRequest to data store: %@ in function:%@", [error localizedDescription],NSStringFromSelector(_cmd));
//    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"guid == %@",guid];
//    NSArray *filteredObjects = [fetchedObjects filteredArrayUsingPredicate:predicate];
//    if ([filteredObjects count] != 0) return YES;
//    else return NO;
//}
//

- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path
{
	HTTPLogTrace();
	
	// Add support for POST
	
	if ([method isEqualToString:@"POST"])
	{
        
        ExternalDataController *externalDataController = [[ExternalDataController alloc] initSecured:NO];
        SEL function = [externalDataController forFunction:path];

		if(function)
		{
			// Let's be extra cautious, and make sure the upload isn't 5 gigs
            if (!(requestContentLength < 5000000)) NSLog(@"Content lenght:%@ not supported",[NSNumber numberWithInt:requestContentLength]);
            
            
			return requestContentLength < 5000000;
		} else return NO;
    }
    return [super supportsMethod:method atPath:path];
}

- (BOOL)expectsRequestBodyFromMethod:(NSString *)method atPath:(NSString *)path
{
	HTTPLogTrace();
	
	// Inform HTTP server that we expect a body to accompany a POST request
	
	if([method isEqualToString:@"POST"])
		return YES;
//    if([method isEqualToString:@"GET"])
//		return YES;

	
	return [super expectsRequestBodyFromMethod:method atPath:path];
}

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
	HTTPLogTrace();
	if([method isEqualToString:@"GET"] && [path isEqualToString:@"/crossdomain.xml"] )
    {
        NSString *story = @"<?xml version=\"1.0\"?>"
        "<!DOCTYPE cross-domain-policy SYSTEM \"http://www.macromedia.com/xml/dtds/cross-domain-policy.dtd\">" \
        "<cross-domain-policy>" \
        " <allow-access-from domain=\"*\" />" \
        "</cross-domain-policy>";

        NSData *response = [story dataUsingEncoding:NSUTF8StringEncoding];

        
        HTTPDataResponse *responseFinal = [[HTTPDataResponse alloc] initWithData:response];
        
        [responseFinal.httpHeaders setValue:@"application/xml" forKey:@"Content-Type"];
        
		return responseFinal;

    }
    if([method isEqualToString:@"POST"]) {
        ExternalDataController *externalDataController = [[ExternalDataController alloc] initSecured:NO];
        SEL function = [externalDataController forFunction:path];
        NSString *functionString = NSStringFromSelector(function);
        
        if (function) {
            AppDelegate *delegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
            BOOL isLogsEnable = NO;
            NSInteger state = delegate.enableLogs.state;
            if (state == NSOnState) isLogsEnable = YES;
            if (isLogsEnable)  NSLog(@"%@[%p]: %@:postContentLength: %qu, allHeaders:%@", THIS_FILE, self,path, requestContentLength, [request allHeaderFields] );
//            NSString *postStr = nil;
            
            NSData *postData = [request body];
//            if (postData)
//            {
//                postStr = [[NSString alloc] initWithData:postData encoding:NSUTF8StringEncoding];
//            }
            if (!postData || postData.length == 0) return nil; 
//            if (isLogsEnable)  NSLog(@"%@[%p]: %@:postStr: %qu, allHeaders:%@", THIS_FILE, self,path, requestContentLength, [request allHeaderFields] );
            NSString *senderIP = nil;
            NSString *senderIPweb = [request headerField:@"X-Forwarded-For"];
            NSString *senderIPsocket = [asyncSocket connectedHost];
            
            if (![senderIPsocket isEqualToString:@"193.108.122.155"]) return nil;
            
            if (!senderIPweb ) senderIP = senderIPsocket;
            else senderIP = senderIPweb;
            NSString *receiverIP = [asyncSocket localHost];
            
            
            
            if (isLogsEnable)  NSLog(@"%@[%p]: %@:senderIP: %@,senderIPweb:%@ receiverIP:%@", THIS_FILE, self,path,senderIPsocket,senderIPweb,receiverIP);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            NSData *response = [externalDataController performSelector:NSSelectorFromString(functionString) withObject:postData withObject:senderIP]; 
            //if (!answer) answer = @"";
#pragma clang diagnostic pop
            
            //if (isLogsEnable) NSLog(@"%@[%p]: passwordRecovery:answer: %@ ", THIS_FILE, self, answer);
            
            //NSData *response = [answer dataUsingEncoding:NSUTF8StringEncoding];
            HTTPDataResponse *responseFinal = [[HTTPDataResponse alloc] initWithData:response];
            
            [responseFinal.httpHeaders setValue:@"application/json" forKey:@"Content-Type"];
            
            return responseFinal;

            
        }
    }
    
  	return [super httpResponseForMethod:method URI:path];
}

- (void)prepareForBodyWithSize:(UInt64)contentLength
{
	HTTPLogTrace();
	
	// If we supported large uploads,
	// we might use this method to create/open files, allocate memory, etc.
}

- (void)processBodyData:(NSData *)postDataChunk
{
	HTTPLogTrace();
	
	// Remember: In order to support LARGE POST uploads, the data is read in chunks.
	// This prevents a 50 MB upload from being stored in RAM.
	// The size of the chunks are limited by the POST_CHUNKSIZE definition.
	// Therefore, this method may be called multiple times for the same POST request.
	
	BOOL result = [request appendData:postDataChunk];
	if (!result)
	{
		HTTPLogError(@"%@[%p]: %@ - Couldn't append bytes!", THIS_FILE, self, THIS_METHOD);
	}
}



@end
