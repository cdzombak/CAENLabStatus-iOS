#import "UIColor+DZCColors.h"

@implementation UIColor (DZCColors)

+ (UIColor *)dzc_logoBlueColor
{
    return [UIColor colorWithRed:29.0/255.0
                           green:36.0/255.0
                            blue:79.0/255.0
                           alpha:1.0];
}

+ (UIColor *)dzc_tableViewHeaderColor
{
    return [UIColor colorWithRed:29.0 * 1.5 /255.0
                           green:36.0 * 1.5 /255.0
                            blue:79.0 * 1.5 /255.0
                           alpha:0.9];
}

+ (UIColor *)dzc_refreshViewColor
{
    return [UIColor colorWithRed:29.0 * 2.0 /255.0
                           green:36.0 * 2.0 /255.0
                            blue:79.0 * 2.0 /255.0
                           alpha:0.9];
}

+ (UIColor *)dzc_tableViewBackgroundColor
{
    return [UIColor colorWithRed:226.0/255.0 green:231.0/255.0 blue:238.0/255.0 alpha:1];
}

@end
