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

#ifdef HOOKSHOT_ENABLED

#import "CCInstrumentingProfiler.h"
#import "CCNativeCountInstances.h"
#import "CCInstanceMessageInstrumentation.h"
#import "CCCountInstances.h"

// Definitions for when hookshot is enabled.

#define HOOKSHOT_PROFILE_CLASS(c) [CCInstrumentingProfiler profileClass:(c)];

#define HOOKSHOT_PROFILE_CLASS_EXCEPT(c, ...) [CCInstrumentingProfiler profileClass:(c) except: @[ __VA_ARGS__ ]]

#define HOOKSHOT_PREVENT_INSTRUMENTATION(c, s) \
    [CCInstanceMessageInstrumentation preventInstrumentation:(c) selector:(s)]

#define HOOKSHOT_CHECKPOINT(s) [CCInstrumentingProfiler addCheckpoint:(s)]

#define HOOKSHOT_TAG(o, s) [CCInstrumentingProfiler setTag:(s) forObject:(o)]

#define HOOKSHOT_PROFILE_CPP_FUNCTION(className, name) CCStackProfiler __cc_stack_instrumenter__((className), (name))

#define HOOKSHOT_COUNT_INSTANCES(c) [CCCountInstances countInstances:(c)]

#define HOOKSHOT_COUNTED_CPP_CLASS(className) \
class className; \
template <> \
struct CCNativeCountClassNameTrait<className> \
{ \
    static const std::string& name; \
}; \
class className : public CCNativeCountInstances<CCNativeCountClassNameTrait<className>>

#define HOOKSHOT_COUNTED_CPP_CLASS_IMPLEMENTATION_PREAMBLE(className) \
const std::string& CCNativeCountClassNameTrait<className>::name = #className; \


#else

// No-op definitions for when hookshot is not enabled.

#define HOOKSHOT_PROFILE_CLASS(c)

#define HOOKSHOT_PROFILE_CLASS_EXCEPT(c, e, ...)

#define HOOKSHOT_PREVENT_INSTRUMENTATION(c, s)

#define HOOKSHOT_CHECKPOINT(s)

#define HOOKSHOT_TAG(o, s)

#define HOOKSHOT_PROFILE_CPP_FUNCTION(className, name)

#define HOOKSHOT_COUNT_INSTANCES(c)

#define HOOKSHOT_COUNTED_CPP_CLASS(className) \
class className

#define HOOKSHOT_COUNTED_CPP_CLASS_IMPLEMENTATION_PREAMBLE(className)

#endif
