#import "UIColor+DZCColors.h"

@implementation UIColor (DZCColors)

+ (UIColor *)dzc_blueTintColor
{
    return [UIColor colorWithRed:29.0f*1.5f/255.0f
                           green:36.0f*1.5f/255.0f
                            blue:79.0f*1.5f/255.0f
                           alpha:1.0];
}

+ (UIColor *)dzc_refreshViewBackgroundColor
{
    return [UIColor colorWithRed:226.0f/255.0f
                           green:231.0f/255.0f
                            blue:238.0f/255.0f
                           alpha:1.0];
}

+ (UIColor *)dzc_groupTableViewBackgroundColor
{
    return [UIColor colorWithRed:208.0f/255.0f
                           green:213.0f/255.0f
                            blue:222.0f/255.0f
                           alpha:1.0];
}

@end
