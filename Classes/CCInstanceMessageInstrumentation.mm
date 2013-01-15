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
#import "CCReflection.h"
#import <map>
#import <set>
#import <vector>

typedef void(^InstrumentBlock)(id, Class, SEL);
typedef std::pair<InstrumentBlock, std::set<SEL>> BlockWithExceptions;
typedef std::vector<BlockWithExceptions> Callbacks;

std::map<void*, Callbacks> beforeBlocks;
std::map<void*, Callbacks> afterBlocks;
std::map<void*, Class> classes;
std::map<void*, void *>liveObjectClass;


@interface NSInvocation (PrivateHack)
- (void)invokeUsingIMP:(IMP)imp; // This is a private method and must not make its way to production code!!
@end


static inline NSInvocation *call(id target, SEL selector, ...) {

    Class targetClass = [target class];
    NSMethodSignature *signature = [targetClass instanceMethodSignatureForSelector:selector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    invocation.target = target;
    invocation.selector = selector;

    va_list args;
    va_start(args, selector);
    for (int i = 2, len = signature.numberOfArguments; i < len; i++) {
        void *arg = va_arg(args, void*);
        [invocation setArgument:arg atIndex:i];
    }
    va_end(args);

    [target forwardInvocation:invocation];
    return invocation;
}

static inline void runCallbacks(
        std::map<void*, Callbacks>& callbacks, id instance, Class targetClass, SEL selector) {
    Callbacks& cbs = callbacks[targetClass];
    for (Callbacks::iterator it = cbs.begin(); it != cbs.end(); it++) {
        std::set<SEL> &exceptions = it->second;
        if (!exceptions.size() || !exceptions.count(selector)) {
            if (it->first) {
                it->first(instance, targetClass, selector);
            }
        }
    }
}


@interface CCInstrumentedProxy : NSProxy

@end



@implementation CCInstrumentedProxy


- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel;
{
    Class targetClass = [self class];
    return [targetClass instanceMethodSignatureForSelector:sel];
}

- (void)forwardInvocation:(NSInvocation *)inv;
{
    Class targetClass = [self class];
    SEL selector = inv.selector;

    runCallbacks(beforeBlocks, self, targetClass, selector);
    @try {
        Class proxyClass = nil;
        if (selector == @selector(setValue:forKeyPath:) ||
            selector == @selector(addObserver:forKeyPath:options:context:) ||
            selector == @selector(valueForKey:)) {
            // Workaround for instrumented KVO class crash.
            proxyClass = object_getClass(self);
            object_setClass(self, targetClass);
        }
        IMP imp = method_getImplementation(class_getInstanceMethod(targetClass, selector));
        [inv invokeUsingIMP:imp]; // This is a private method and must not make it's way to production code!!
        if (proxyClass) {
            object_setClass(self, proxyClass);
        }
    } @finally {
        runCallbacks(afterBlocks, self, targetClass, selector);
        if (selector == @selector(dealloc)) {
            liveObjectClass.erase(self);
        }
    }
}

- (BOOL)respondsToSelector:(SEL)sel;
{
    return [[self class] instancesRespondToSelector:sel];
}

- (BOOL)conformsToProtocol:(Protocol *)protocol;
{
    return [[self class] conformsToProtocol:protocol];
}

- (Class)class;
{
    return (Class) liveObjectClass[self];
}

- (void)dealloc;
{
    // NSProxy implements this, so we have to override.
    call(self, @selector(dealloc));
    // NOTE: lack of call to [super dealloc] is intentional since we never init as an NSProxy!
    // Suppress Compiler Warning
    if (0) { [super dealloc]; }
}

// "NSProxy implements these for some incomprehensibly stupid reason" - Mike Ash

- (NSUInteger)hash;
{
    NSUInteger out;
    [call(self, @selector(hash)) getReturnValue:&out];
    return out;
}

- (BOOL)isEqual:(id)obj
{
    BOOL out;
    [call(self, @selector(isEqual:), &obj) getReturnValue:&out];
    return out;
}

@end



@interface NSObject (LogInstanceMessages)

@end


@implementation NSObject (LogInstanceMessages)

+ (id)instrumentInstanceMessagesSwizzledAllocWithZone:(NSZone *)zone;
{
    BOOL instrument = !!classes.count(self);
    if (instrument) {
        runCallbacks(beforeBlocks, nil, self, @selector(allocWithZone:));
    }
    id result = [self instrumentInstanceMessagesSwizzledAllocWithZone:zone];
    if (instrument) {
        runCallbacks(afterBlocks, result, self, @selector(allocWithZone:));
        liveObjectClass[result] = self;
        object_setClass(result, classes[self]);
    }

    return result;
}

+ (id)instrumentInstanceMessagesAddedAllocWithZone:(NSZone *)zone;
{
    BOOL instrument = !!classes.count(self);
    Method method = GetSuperMethod(self, @selector(allocWithZone:));
    IMP imp = method_getImplementation(method);

    if (instrument) {
        runCallbacks(beforeBlocks, nil, self, @selector(allocWithZone:));
    }
    id result = imp(self, @selector(allocWithZone:), zone);
    if (instrument) {
        runCallbacks(afterBlocks, result, self, @selector(allocWithZone:));
        liveObjectClass[result] = self;
        object_setClass(result, classes[self]);
    }

    return result;
}

@end


@implementation CCInstanceMessageInstrumentation

+ (void)preventInstrumentation:(Class)cls selector:(SEL)selector;
{
    Method method = class_getInstanceMethod(cls, selector);
    class_addMethod(classes[cls], method_getName(method), method_getImplementation(method),
            method_getTypeEncoding(method));
}

+ (void)instrumentInstanceMessages:(Class)cls
                            before:(InstrumentBlock)before
                             after:(InstrumentBlock)after
                            except:(NSArray *)exceptions;
{
    BlockWithExceptions beforePair([before copy], std::set<SEL>());
    BlockWithExceptions afterPair([after copy], std::set<SEL>());
    for (NSValue *v in exceptions) {
        beforePair.second.insert((SEL) v.pointerValue);
        afterPair.second.insert((SEL) v.pointerValue);
    }

    if (!beforeBlocks.count(cls)) {
        // First instrumentation of this class.
        if (HasOwnClassMethod(cls, @selector(allocWithZone:))) {
            ClassMethodSwizzle(cls, @selector(instrumentInstanceMessagesSwizzledAllocWithZone:), @selector(allocWithZone:));
        } else {
            ClassMethodCopy(cls, @selector(instrumentInstanceMessagesAddedAllocWithZone:), @selector(allocWithZone:));
        }

        NSString *newName = [NSString stringWithFormat:@"CCInstrumentedProxy_%s", class_getName(cls)];
        Class subClass = objc_allocateClassPair([CCInstrumentedProxy class], [newName UTF8String], 0);
        classes[cls] = subClass;

        // TODO(robbyw): Would be nicer to actually instrument these methods.
        unsigned int methodCount;
        Class currentClass = cls;
        while (currentClass) {
            Method * methods = class_copyMethodList(currentClass, &methodCount);
            for (unsigned int i = 0; i < methodCount; i++) {
                char *returnType = method_copyReturnType(methods[i]);
                if (strchr(returnType, '<') != NULL) {
                    NSLog(@"Cannot instrument %s.%s : bad return type %s",
                          class_getName(cls), sel_getName(method_getName(methods[i])), returnType);
                    [self preventInstrumentation:cls selector:method_getName(methods[i])];
                }
                free(returnType);
            }
            free(methods);

            currentClass = class_getSuperclass(currentClass);
        }

        objc_registerClassPair(subClass);
    }

    beforeBlocks[cls].push_back(beforePair);
    afterBlocks[cls].push_back(afterPair);
}

@end
