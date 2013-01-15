//  CCNativeCountInstances.cpp
//  Cue
//
//  Created by Aaron Sarazan on 9/25/12.
//  Copyright (c) 2012 Cue, Inc. All rights reserved.

#include "CCNativeCountInstances.h"
#include <Foundation/Foundation.h>
#include <map>
#include <pthread.h>

static std::map<std::string, volatile int *> _countMap;
static std::map<std::string, volatile int *> _deleteMap;
static pthread_mutex_t _mutex;

__attribute__((constructor)) static void _CCNativeCountInstancesInit()
{
    pthread_mutex_init(&_mutex, NULL);
}

CCNativeCountInstances::CCNativeCountInstances(const char *className) : _className(className)
{
    pthread_mutex_lock(&_mutex);
    volatile int *add = _countMap[_className];
    volatile int *del = _deleteMap[_className];
    if (!add) {
        add = new int();
        del = new int();
        _countMap[_className] = add;
        _deleteMap[_className] = del;
    }
    (*add)++;
    pthread_mutex_unlock(&_mutex);

    NSLog(@"[alloc] %s: %d (%d - %d)", _className.c_str(), (*add) - (*del), (*add), (*del));
}

CCNativeCountInstances::~CCNativeCountInstances()
{
    pthread_mutex_lock(&_mutex);
    volatile int *add = _countMap[_className];
    volatile int *del = _deleteMap[_className];
    (*del)++;
    pthread_mutex_unlock(&_mutex);
    
    NSLog(@"[dealloc] %s: %d (%d - %d)", _className.c_str(), (*add) - (*del), (*add), (*del));
}
