/*
 * Copyright 2012 The hookshot Authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

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
}

+ (int)getCountForTesting:(Class)cls;
{
    @synchronized (_classCounts) {
        return [_classCounts countForObject:cls];
    }
}

@end
