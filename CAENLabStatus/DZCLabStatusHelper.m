#import "DZCLabStatusHelper.h"
#import "DZCLab.h"

@implementation DZCLabStatusHelper

/**
 * Make a best guess at whether a lab is currently open.
 * 
 * This is ugly, because the CAEN status API doesn't report a status
 * for every lab or building. Additionally, some labs appear twice in the
 * status list.
 * 
 * And this will fail on breaks & holidays unless we specifically
 * check for these cases.
 */
+ (NSNumber *)statusGuessForLab:(DZCLab *)lab
{
    DZCLabStatus status = DZCLabStatusOpen;
    
    NSDate *now = [NSDate date];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *dateComponents =[gregorian components:(NSHourCalendarUnit | NSWeekdayCalendarUnit) fromDate:now];
    NSInteger weekday = [dateComponents weekday];
    NSInteger hour = [dateComponents hour];
    
    if ([lab.building isEqualToString:@"DC"]) {
        // DC hours: http://www.dc.umich.edu/hoursmaps/hours.htm
        // 24 hours except for breaks & holidays
        status = DZCLabStatusOpen;
    }
    else if ([lab.building isEqualToString:@"SHAPIRO"]) {
        // Ugli hours: http://www.lib.umich.edu/unithours/36.unit/month/January/30/2012/mid_141
        // open 8am-5am weekdays; 10am-5am weekends
        // closed & special hours on breaks & holidays
        if (weekday == 1 || weekday == 7) {
            if (hour > 4 && hour < 10) {
                status = DZCLabStatusClosed;
            }
        } else {
            if (hour > 4 && hour < 8) {
                status = DZCLabStatusClosed;
            }
        }
    }
    else if ([lab.building isEqualToString:@"AH"]) {
        // couldn't find a course for AH hours
        // I think AH is 24-hour, possibly except breaks and holidays
        status = DZCLabStatusOpen;
    }
    else if ([lab.building isEqualToString:@"SEB"]) {
        // M-F 7am - 9pm ; closed weekends
        // http://www.soe.umich.edu/faqs/tag/building/
        // closed holidays
        
        if (weekday == 1 || weekday == 7) {
            status = DZCLabStatusClosed;
        } else {
            if (hour < 7 || hour > 20) {
                status = DZCLabStatusClosed;
            }
        }
    }
    else if ([lab.building isEqualToString:@"BAITS_COMAN"]
             || [lab.building isEqualToString:@"BURSLEY"]
             || [lab.building isEqualToString:@"MO-JO"]) {
        // these dorm labs are open 24/7 if you have access to the building
        status = DZCLabStatusOpen;
    }
    
    return [NSNumber numberWithInt:status];
}

@end
