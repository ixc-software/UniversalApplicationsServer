#import <Foundation/Foundation.h>
#import "HTTPResponse.h"


@interface HTTPDataResponse : NSObject <HTTPResponse>
{
	NSUInteger offset;
	NSData *data;
    NSMutableDictionary *httpHeaders; 

}
@property (nonatomic) NSMutableDictionary *httpHeaders; 

- (id)initWithData:(NSData *)data;

@end
