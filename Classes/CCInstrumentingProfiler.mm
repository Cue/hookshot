//
//  CCInstrumentingProfiler
//  Greplin
//
//  Created by Robby Walker on 9/10/12.
//  Copyright 2012 Greplin, Inc. All rights reserved.
//

#import "CCInstrumentingProfiler.h"
#import "CCInstanceMessageInstrumentation.h"

#import <objc/runtime.h>
#import <sys/time.h>
#import <pthread.h>

#import <map>
#import <vector>
#import <libkern/OSAtomic.h>

static volatile int32_t ACTIVE = 0;

static long currentTimeMicros()
{
    struct timeval time;
    gettimeofday(&time, NULL);
    return time.tv_sec * 1000000 + time.tv_usec;
}

#pragma mark Simple, append only lock free list

struct ListNode {
    char *buffer;
    int length;
    ListNode *next;
};

static volatile ListNode *MESSAGES = NULL;

void addMessageNode(ListNode *node)
{
    do {
        node->next = (ListNode*) MESSAGES;
    } while (!OSAtomicCompareAndSwapPtrBarrier(node->next, node, (void *volatile *)&MESSAGES));
}

void addMessage(const char * format, ...) {

    va_list args;
    va_start (args, format);
    int len = vsnprintf(NULL, 0, format, args);
    va_end (args);

    char *buffer = new char[len + 2];

    va_start (args, format);
    vsnprintf(buffer, len + 1, format, args);
    va_end (args);

    buffer[len] = '\n';
    buffer[len + 1] = 0;

    ListNode *node = new ListNode;
    node->buffer = buffer;
    node->length = len + 1;
    addMessageNode(node);
}

ListNode *stealList()
{
    ListNode *orig;
    do {
        orig = (ListNode *) MESSAGES;
    } while (!OSAtomicCompareAndSwapPtrBarrier(orig, NULL, (void *volatile *)&MESSAGES));
    return orig;
}

#pragma mark Thread frames and utilities

static BOOL isDispatchThread() {
    NSArray *arr = [NSThread callStackSymbols];
    return [(NSString *)[arr objectAtIndex:[arr count] - 3] rangeOfString:@"libdispatch"].location != NSNotFound;
}

static char * getCurrentThreadName() {
    NSThread *currentThread = [NSThread currentThread];
    NSString *name = currentThread == [NSThread mainThread] ? @"MAIN" : [currentThread name];
    if (![name length]) {
        if (isDispatchThread()) {
            dispatch_queue_t current = dispatch_get_current_queue();
            name = [NSString stringWithFormat:@"%s-%x", dispatch_queue_get_label(current), (int) currentThread];
        } else {
            name = [NSString stringWithFormat:@"0x%x", (int) currentThread];
        }
    }
    return strdup([name UTF8String]);
}


struct ThreadFrame {
    long startTime;
    long totalChildTime;
    const char* className;

    ThreadFrame(const char *_className) : className(_className), startTime(currentTimeMicros()), totalChildTime(0)
    {
    }
};

class ThreadProfileData {
    std::vector<ThreadFrame> stack;
    const char *threadName;

public:
    ThreadProfileData() : stack(), threadName(getCurrentThreadName())
    {
    }

    void startCall(id instance, const char *className, const char *selectorName)
    {
        stack.push_back(ThreadFrame(className));
        addMessage("> %s %x %s %s %ld",
                threadName, (int) instance, stack.back().className, selectorName, stack.back().startTime);
    }

    void finishCall(id instance, const char *selectorName)
    {
        ThreadFrame frame = stack.back();
        stack.pop_back();

        long finishTime = currentTimeMicros();
        long fnTime = finishTime - frame.startTime;
        long ownTime = fnTime - frame.totalChildTime;
        if (!stack.empty()) {
            stack.back().totalChildTime += fnTime;
        }
        addMessage("< %s %x %s %s %ld %ld",
                threadName, (int) instance, frame.className, selectorName, finishTime, ownTime);
    }
};

typedef std::map<pthread_t, ThreadProfileData*> ThreadMap;
static ThreadMap* THREADS = new ThreadMap();


static inline ThreadProfileData* threadData()
{
    ThreadMap *threads = THREADS;
    ThreadMap::iterator it = threads->find(pthread_self());
    if (it == threads->end()) {
        // We are not yet in the map.
        @synchronized (@"cc_profiler_thread_map") {
            ThreadMap* newThreadMap = new ThreadMap(*THREADS);
            ThreadProfileData* thisThread = new ThreadProfileData();
            (*newThreadMap)[pthread_self()] = thisThread;

            // NOTE: We let the old one leak, in case it's still in use by another thread.  It's not much memory.
            THREADS = newThreadMap;
            return thisThread;
        }
    }
    return it->second;
}

#pragma mark Logging functions

static inline void logStart(id instance, Class cls, SEL selector)
{
    threadData()->startCall(instance, class_getName(cls), sel_getName(selector));
}


static inline void logAfter(id instance, Class cls, SEL selector)
{
    threadData()->finishCall(instance, sel_getName(selector));
}


#pragma mark C++ Manual Profiling

CCStackProfiler::CCStackProfiler(const char *className, const char *name) : _name(name)
{
    threadData()->startCall(nil, className, name);
}


CCStackProfiler::~CCStackProfiler()
{
    threadData()->finishCall(nil, _name);
}


#pragma mark Profiler interface

@implementation CCInstrumentingProfiler

+ (void) messageThreadMain;
{
    int pid = [[NSProcessInfo processInfo] processIdentifier];
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * docPath = [[paths objectAtIndex:0] stringByAppendingFormat:@"/profile-%d", pid];
    NSLog(@"Writing profiler data to %@", docPath);
    FILE *output = fopen([docPath UTF8String], "w");

    [NSThread currentThread].threadPriority = 0.2;
    do {
        ListNode *current = stealList();
        ListNode *previous = NULL;

        // Reverse the list.
        while (current) {
            ListNode *next = current->next;
            current->next = previous;
            previous = current;
            current = next;
        }

        // Print it out.
        current = previous;
        while (current) {
            fwrite(current->buffer, sizeof(char), current->length, output);
            free(current->buffer);
            current = current->next;
        }
    } while (!sleep(1));
}

+ (void)profileClass:(Class)cls;
{
    [self profileClass:cls except:nil];
}

+ (void)profileClass:(Class)cls except:(NSArray *)exceptions;
{
    if (OSAtomicCompareAndSwap32(0, 1, &ACTIVE)) {
        [NSThread detachNewThreadSelector:@selector(messageThreadMain)
                                 toTarget:[CCInstrumentingProfiler class]
                               withObject:nil];
    }
    [CCInstanceMessageInstrumentation
            instrumentInstanceMessages:cls
            before:^(id instance, Class instanceCls, SEL selector) {
                logStart(instance, instanceCls, selector);
            } after:^(id instance, Class instanceCls, SEL selector) {
                logAfter(instance, instanceCls, selector);
            } except:exceptions];
}

+ (void)addCheckpoint:(NSString *)description;
{
    if (ACTIVE) {
        addMessage("# checkpoint:%ld:%s", currentTimeMicros(), [description UTF8String]);
    }
}

+ (void)setTag:(NSString *)tag forObject:(id)object;
{
    if (ACTIVE) {
        addMessage("# tag:%ld:%x:%s", currentTimeMicros(), (int)object, [tag UTF8String]);
    }
}

@end
