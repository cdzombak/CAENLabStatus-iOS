#import <Foundation/Foundation.h>
#import "DZCDataController.h"

@class DZCLab;

@interface DZCLabStatusHelper : NSObject

+ (NSNumber *)statusGuessForLab:(DZCLab *)lab;

@end
