#import "DZCLabStatusApiClient.h"
#import "AFJSONRequestOperation.h"

@implementation DZCLabStatusApiClient

- (id)init {
    NSURL * const baseUrl = [NSURL URLWithString:@"http://labwatch.engin.umich.edu/labs/js/"];
    
    self = [super initWithBaseURL:baseUrl];
    if (!self) {
        return nil;
    }
    
    [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
    
    // Accept HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
	[self setDefaultHeader:@"Accept" value:@"application/json"];

    // I'm an asshole:
    [self setDefaultHeader:@"User-Agent" value:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_3) AppleWebKit/535.19 (KHTML, like Gecko) Chrome/18.0.1025.33 Safari/535.19"];
    
    return self;
}

@end
