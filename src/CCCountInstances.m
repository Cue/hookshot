//
//  CCCountInstances
//  Greplin
//
//  Created by Robby Walker on 9/7/12.
//  Copyright 2012 Greplin, Inc. All rights reserved.
//

#import "CCCountInstances.h"
#import <objc/runtime.h>
#import "CCInstanceMessageInstrumentation.h"

static NSCountedSet *_classCounts = nil;

@implementation CCCountInstances

+ (void)initialize;
{
    _classCounts = [[NSCountedSet alloc] init];
}

+ (void)countInstances:(Class)class;
{
#ifdef GREPLIN_DEBUG
    [CCInstanceMessageInstrumentation instrumentInstanceMessages:class before:^(id obj, Class cls, SEL selector) {
        int count;
        if (selector == @selector(allocWithZone:)) {
            @synchronized (_classCounts) {
                [_classCounts addObject:cls];
                count = [_classCounts countForObject:cls];
            }
            NSLog(@"%s: %d (after alloc)", class_getName(cls), count);
        } else if (selector == @selector(dealloc)) {
            @synchronized (_classCounts) {
                [_classCounts removeObject:cls];
                count = [_classCounts countForObject:cls];
            }
            NSLog(@"%s: %d (after dealloc)", class_getName(cls), count);
        }
    } after:nil except:nil];
#endif
}

+ (int)getCountForTesting:(Class)cls;
{
    @synchronized (_classCounts) {
        return [_classCounts countForObject:cls];
    }
}

@end
