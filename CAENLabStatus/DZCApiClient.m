#import "DZCApiClient.h"
#import "AFJSONRequestOperation.h"

@implementation DZCApiClient

- (id)init {
    NSURL * const baseUrl = [NSURL URLWithString:@"http://labwatch.engin.umich.edu/labs/js/"];
    
    self = [super initWithBaseURL:baseUrl];
    if (!self) {
        return nil;
    }
    
    [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
    
    // Accept HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
	[self setDefaultHeader:@"Accept" value:@"application/json"];
    
    return self;
}

@end
