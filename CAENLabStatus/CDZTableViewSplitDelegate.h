#import <Foundation/Foundation.h>

@interface CDZTableViewSplitDelegate : NSObject <UIScrollViewDelegate, UITableViewDelegate>

@property (nonatomic, weak) id<UITableViewDelegate> tvDelegate;
@property (nonatomic, weak) id<UIScrollViewDelegate> svDelegate;

- (id)initWithScrollViewDelegate:(id<UIScrollViewDelegate>)scrollViewDelegate tableViewDelegate:(id<UITableViewDelegate>)tableViewDelegate;

@end
