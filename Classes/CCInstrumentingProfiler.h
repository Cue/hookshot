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

#import <Foundation/Foundation.h>

#ifdef HOOKSHOT_ENABLED

#ifdef __cplusplus

class CCStackProfiler {
    const char *_name;
public:
    CCStackProfiler(const char *className, const char *name);

    ~CCStackProfiler();
};
#endif


/**
 * Static methods for configuring the instrumenting profiler.
 */
@interface CCInstrumentingProfiler : NSObject

+ (void)profileClass:(Class)cls;

+ (void)profileClass:(Class)cls except:(NSArray *)exceptions;

+ (void)addCheckpoint:(NSString *)description;

+ (void)setTag:(NSString *)tag forObject:(id)o;

@end

#endif
