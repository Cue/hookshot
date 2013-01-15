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

#import <objc/runtime.h>

#ifdef __cplusplus
extern "C" {
#endif

Method GetSuperMethod(Class cls, SEL selector);

BOOL HasOwnMethod(Class cls, SEL sel);

BOOL HasOwnClassMethod(Class cls, SEL sel);

void MethodSwizzle(Class cls, SEL a, SEL b);

void ClassMethodSwizzle(Class cls, SEL a, SEL b);

void MethodCopy(Class cls, SEL definition, SEL destination);

void ClassMethodCopy(Class cls, SEL definition, SEL destination);

#ifdef __cplusplus
}
#endif
