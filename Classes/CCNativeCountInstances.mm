//  CCNativeCountInstances.cpp
//  Cue
//
//  Created by Aaron Sarazan on 9/25/12.
//  Copyright (c) 2012 Cue, Inc. All rights reserved.

#include "CCNativeCountInstances.h"

__attribute__((constructor)) static void _CCNativeCountInstancesInit()
{
    pthread_mutex_init(&_mutex, NULL);
}

template <class T>
const std::string& CCNativeCountClassNameTrait<T>::name("Unknown");
