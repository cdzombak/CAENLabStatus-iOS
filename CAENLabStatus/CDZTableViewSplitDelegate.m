#import "CDZTableViewSplitDelegate.h"
#import <objc/runtime.h> // shit just got real

@implementation CDZTableViewSplitDelegate

- (id)initWithScrollViewDelegate:(id<UIScrollViewDelegate>)scrollViewDelegate
               tableViewDelegate:(id<UITableViewDelegate>)tableViewDelegate
{
    self = [super init];
    if (self) {
        self.svDelegate = scrollViewDelegate;
        self.tvDelegate = tableViewDelegate;
    }
    return self;
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    if ([self selectorIsPartOfUIScrollViewDelegate:aSelector]) {
        return self.svDelegate;
    }

    if ([self selectorIsPartOfUITableViewDelegate:aSelector]) {
        return self.tvDelegate;
    }

    return [super forwardingTargetForSelector:aSelector];
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    id forwardingTarget = [self forwardingTargetForSelector:aSelector];

    if (forwardingTarget == self.tvDelegate || forwardingTarget == self.svDelegate) {
        return [forwardingTarget respondsToSelector:aSelector];
    }

    return [super respondsToSelector:aSelector];
}

- (BOOL)selectorIsPartOfUIScrollViewDelegate:(SEL)aSelector
{
    // assuming all UIScrollViewDelegate methods are instance methods
    return [self selector:aSelector isInstanceMethodForProtocol:@protocol(UIScrollViewDelegate)];
}

- (BOOL)selectorIsPartOfUITableViewDelegate:(SEL)aSelector
{
    // assuming all UITableViewDelegate methods are instance methods
    return [self selector:aSelector isInstanceMethodForProtocol:@protocol(UITableViewDelegate)];
}

- (BOOL)selector:(SEL)aSelector isInstanceMethodForProtocol:(Protocol *)p
{
    if ([self selector:aSelector isInstanceMethodForProtocol:p required:YES]) return YES;
    else return [self selector:aSelector isInstanceMethodForProtocol:p required:NO];
}

- (BOOL)selector:(SEL)aSelector isInstanceMethodForProtocol:(Protocol *)p required:(BOOL)isRequired
{
    NSParameterAssert(p != NULL);

    struct objc_method_description methodDesc = protocol_getMethodDescription(p, // protocol
                                                                              aSelector, // selector
                                                                              isRequired, // whether selector represents a required method
                                                                              YES  // whether selector represents an instance method
                                                                              );

    return (methodDesc.name) ? YES : NO;
}

@end