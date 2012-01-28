#import "DZCTableViewCellOpenLab.h"

@implementation DZCTableViewCellOpenLab

@synthesize labNameLabel, labOpenCountLabel, labTotalCountLabel, slashLabel;

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    if (selected) {
        labNameLabel.textColor = [UIColor whiteColor];
        labOpenCountLabel.textColor = [UIColor whiteColor];
        labTotalCountLabel.textColor = [UIColor whiteColor];
        slashLabel.textColor = [UIColor whiteColor];
    } else {
        labNameLabel.textColor = [UIColor blackColor];
        labOpenCountLabel.textColor = [UIColor blackColor];
        labTotalCountLabel.textColor = [UIColor blackColor];
        slashLabel.textColor = [UIColor blackColor];
    }
}

@end
