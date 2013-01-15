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

#import "CCCountInstancesTest.h"
#import "CCCountInstances.h"

static BOOL dealloc1WasCalled = NO;
static BOOL dealloc2WasCalled = NO;

@interface CCClassWithNoDealloc : NSObject

@end

@implementation CCClassWithNoDealloc

@end



@interface CCClassWithDealloc1 : NSObject

@end

@implementation CCClassWithDealloc1

- (void)dealloc;
{
    dealloc1WasCalled = YES;
    [super dealloc];
}

@end



@interface CCClassWithDealloc2 : CCClassWithNoDealloc

@end

@implementation CCClassWithDealloc2

- (void)dealloc;
{
    dealloc2WasCalled = YES;
    [super dealloc];
}

@end



@implementation CCCountInstancesTest

+ (void)initialize;
{
    if (self != [CCCountInstancesTest class]) {
        return;
    }
    
    [CCCountInstances countInstances:[CCClassWithNoDealloc class]];
    [CCCountInstances countInstances:[CCClassWithDealloc1 class]];
    [CCCountInstances countInstances:[CCClassWithDealloc2 class]];
}

- (void)setUp;
{
    dealloc1WasCalled = NO;
    dealloc2WasCalled = NO;
}

- (void)testClassWithNoDealloc;
{
    id obj = [[CCClassWithNoDealloc alloc] init];
    STAssertEquals(1, [CCCountInstances getCountForTesting:[CCClassWithNoDealloc class]], @"should count instance");
    [obj release];
    STAssertEquals(0, [CCCountInstances getCountForTesting:[CCClassWithNoDealloc class]], @"should remove instance");
}

- (void)testClassWithDealloc;
{
    id obj = [[CCClassWithDealloc1 alloc] init];
    STAssertEquals(1, [CCCountInstances getCountForTesting:[CCClassWithDealloc1 class]], @"should count instance");
    [obj release];
    STAssertEquals(0, [CCCountInstances getCountForTesting:[CCClassWithDealloc1 class]], @"should remove instance");
    STAssertTrue(dealloc1WasCalled, @"should set the dealloc bit");
}

- (void)testMultipleClassesWithDealloc;
{
    id obj1 = [[CCClassWithDealloc1 alloc] init];
    STAssertEquals(1, [CCCountInstances getCountForTesting:[CCClassWithDealloc1 class]], @"should count instance");

    id obj2 = [[CCClassWithDealloc2 alloc] init];
    STAssertEquals(1, [CCCountInstances getCountForTesting:[CCClassWithDealloc2 class]], @"should count instance");

    [obj2 release];
    STAssertEquals(0, [CCCountInstances getCountForTesting:[CCClassWithDealloc2 class]], @"should remove instance");
    STAssertTrue(dealloc2WasCalled, @"should set the dealloc bit");

    [obj1 release];
    STAssertEquals(0, [CCCountInstances getCountForTesting:[CCClassWithDealloc1 class]], @"should remove instance");
    STAssertTrue(dealloc1WasCalled, @"should set the dealloc bit");
}


@end
