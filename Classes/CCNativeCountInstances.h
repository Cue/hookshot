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

#ifndef __CCNativeCountInstances_H_
#define __CCNativeCountInstances_H_

#ifdef HOOKSHOT_ENABLED

#ifdef __cplusplus
#include <string>
#include <map>
#include <pthread.h>
#include <Foundation/Foundation.h>

template <class T>
struct CCNativeCountClassNameTrait
{
    static const std::string& name;
};

template <class T>
class CCNativeCountInstances {

public:
    CCNativeCountInstances();
    virtual ~CCNativeCountInstances();
};

static std::map<std::string, volatile int *> _countMap;
static std::map<std::string, volatile int *> _deleteMap;
static pthread_mutex_t _mutex;

template <class T>
CCNativeCountInstances<T>::CCNativeCountInstances()
{
    const std::string& name = T::name;
    
    pthread_mutex_lock(&_mutex);
    volatile int *add = _countMap[name];
    volatile int *del = _deleteMap[name];
    if (!add) {
        add = new int();
        del = new int();
        _countMap[name] = add;
        _deleteMap[name] = del;
    }
    (*add)++;
    pthread_mutex_unlock(&_mutex);
    
    NSLog(@"[alloc] %s: %d (%d - %d)", name.c_str(), (*add) - (*del), (*add), (*del));
}


template <class T>
CCNativeCountInstances<T>::~CCNativeCountInstances()
{
    const std::string& name = T::name;
    
    pthread_mutex_lock(&_mutex);
    volatile int *add = _countMap[name];
    volatile int *del = _deleteMap[name];
    (*del)++;
    pthread_mutex_unlock(&_mutex);
    
    NSLog(@"[dealloc] %s: %d (%d - %d)", name.c_str(), (*add) - (*del), (*add), (*del));
}


#endif // __cplusplus

#endif // HOOKSHOT_ENABLED

#endif // __CCNativeCountInstances_H_
