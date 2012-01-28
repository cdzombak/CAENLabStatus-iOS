#import "DZCTableViewCellClosedLab.h"

@implementation DZCTableViewCellClosedLab

@synthesize labNameLabel, labCountLabel;

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    if (selected) {
        labNameLabel.textColor = [UIColor whiteColor];
        labCountLabel.textColor = [UIColor whiteColor];
    } else {
        labNameLabel.textColor = [UIColor blackColor];
        labCountLabel.textColor = [UIColor blackColor];
    }
}

@end
