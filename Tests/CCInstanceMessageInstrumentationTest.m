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

#import "CCInstanceMessageInstrumentation.h"
#import "CCInstanceMessageInstrumentationTest.h"

static int beforeCount = 0;

static int afterCount = 0;

static int getAndResetBeforeCount() {
    int result = beforeCount;
    beforeCount = 0;
    return result;
}

static int getAndResetAfterCount() {
    int result = afterCount;
    afterCount = 0;
    return result;
}


@interface CCTestClass : NSObject {
    int _lastValue;
}

- (int)setValue:(int)param;

@end



@implementation CCTestClass

+ (void)initialize;
{
    if (self == [CCTestClass class]) {
        [CCInstanceMessageInstrumentation
                instrumentInstanceMessages:[CCTestClass class]
                                    before:^(id _, Class __, SEL ___) {
                                        beforeCount += 1;
                                    }
                                     after:^(id _, Class __, SEL ___) {
                                         afterCount += 1;
                                     }
                                    except:nil];
    }
}

- (id)init;
{
    return [super init];
}

- (int)setValue:(int)param;
{
    _lastValue = param;
    return param;
}

- (BOOL)isEqualToTestClass:(CCTestClass *)other;
{
    return _lastValue == other->_lastValue;
}

- (BOOL)isEqual:(id)other;
{
    if (other == self) {
        return YES;
    }
    if (!other || ![other isKindOfClass:[self class]]) {
        return NO;
    }
    return [self isEqualToTestClass:other];
}

@end



@interface CCTestSubclass : CCTestClass

- (int)setValue:(int)param;

@end


@implementation CCTestSubclass

+ (void)initialize;
{
    if (self == [CCTestSubclass class]) {
        [CCInstanceMessageInstrumentation
                instrumentInstanceMessages:[CCTestSubclass class]
                                    before:^(id _, Class __, SEL ___) {
                                        beforeCount += 1;
                                    }
                                     after:^(id _, Class __, SEL ___) {
                                         afterCount += 1;
                                     }
                                    except:nil];
    }
}

- (id)init;
{
    return [super init];
}

- (int)setValue:(int)param;
{
    return [super setValue:param];
}

@end



@interface CCUninstrumentedSubclass : CCTestSubclass

@end


@implementation CCUninstrumentedSubclass

@end



@implementation CCInstanceMessageInstrumentationTest

- (void)setUp;
{
    [super setUp];
    beforeCount = 0;
    afterCount = 0;
}

- (CCTestClass *)createInstance;
{
    CCTestClass *obj = [[[CCTestClass alloc] init] autorelease];
    STAssertEquals(2, getAndResetBeforeCount(), @"Should count call to init and alloc");
    STAssertEquals(2, getAndResetAfterCount(), @"Should count call to init and alloc");
    return obj;
}

- (CCTestClass *)createSubclassInstance;
{
    CCTestClass *obj = [[[CCTestSubclass alloc] init] autorelease];
    STAssertEquals(2, getAndResetBeforeCount(), @"Should count call to alloc and init but not to super init");
    STAssertEquals(2, getAndResetAfterCount(), @"Should count call to alloc and init but not to super init");
    return obj;
}


- (void)testIsKindOfClass;
{
    CCTestClass *obj = [self createInstance];
    STAssertTrue([obj isKindOfClass:[CCTestClass class]], @"Should think it's the original class.");
    STAssertEquals(1, getAndResetBeforeCount(), @"Should count call to isKindOfClass");
    STAssertEquals(1, getAndResetAfterCount(), @"Should count call to isKindOfClass");

    STAssertEquals([CCTestClass class], [obj class], @"Should have correct class");
}

- (void)testMessageCount;
{
    CCTestClass *obj = [self createInstance];
    int result = [obj setValue:50];
    STAssertEquals(50, result, @"Should not munge the return value");
    STAssertEquals(1, getAndResetBeforeCount(), @"Should count call to setValue");
    STAssertEquals(1, getAndResetAfterCount(), @"Should count call to setValue");
}

- (void)testIsEqual;
{
    CCTestClass *a = [self createInstance];
    CCTestClass *b = [self createInstance];
    [a setValue:100];
    [b setValue:100];

    STAssertEqualObjects(a, b, @"should be equal");

    [b setValue:200];
    STAssertFalse([a isEqual:b], @"should not be equal");
}

- (void)testSuper;
{
    CCTestClass *a = [self createSubclassInstance];
    [a setValue:100];
    STAssertEquals(1, getAndResetBeforeCount(), @"Should count call to setValue but not one to parent class");
    STAssertEquals(1, getAndResetAfterCount(), @"Should count call to setValue but not one to parent class");

    STAssertEquals([CCTestSubclass class], [a class], @"Should have correct class");
    STAssertEquals([CCTestClass class], [a superclass], @"Should have correct superclass");
}

- (void)testUninstrumentedSubclass;
{
    // This used to crash.
    CCTestClass *a = [[[CCUninstrumentedSubclass alloc] init] autorelease];
    [a setValue:100];
    STAssertEquals(0, getAndResetBeforeCount(), @"Should count no calls");
    STAssertEquals(0, getAndResetAfterCount(), @"Should count no calls");
}

@end
