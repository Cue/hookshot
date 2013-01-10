#!/usr/bin/env python
# Copyright 2012 Greplin, Inc.  All Rights Reserved.

"""Analyzes a profile dump.  Usage: profile.py [pid]"""

import argparse
import glob
import os
import re
import sys

from parser import ProfileData


def dataFiles():
  """Generator of data file paths."""
  for root in glob.glob(os.path.expanduser('~/Desktop/*.xcappdata')):
    for directory, _, filenames in os.walk(os.path.join(root, 'AppData')):
      for filename in filenames:
        if filename.startswith('profile-'):
          yield (directory, filename)
  for directory, _, filenames in os.walk(os.path.expanduser('~/Library/Application Support/iPhone Simulator')):
    for filename in filenames:
      if filename.startswith('profile-'):
        yield (directory, filename)


def cleanDataFiles():
  """Clean data files."""
  files = list(dataFiles())
  for directory, filename in files:
    fullPath = os.path.join(directory, filename)
    print 'rm %s' % fullPath
    os.unlink(fullPath)


def listDataFiles():
  """List data files."""
  files = list(dataFiles())
  for directory, filename in files:
    fullPath = os.path.join(directory, filename)
    print '%s' % fullPath


def getDataPath(pid):
  """Get the data path of the requested (or latest) profile output."""
  best = None
  bestModificationTime = 0
  for directory, filename in dataFiles():
    fullPath = os.path.join(directory, filename)
    if pid:
      if filename == 'profile-%s' % pid:
        return fullPath
    else:
      modificationTime = os.stat(fullPath).st_mtime
      if modificationTime > bestModificationTime:
        bestModificationTime = modificationTime
        best = fullPath

  return best


def fit(s, l):
  """Fit the given string into the given number of characters."""
  return s + ' ' * (l - len(s))


def printNode(node, indent = 0):
  """Prints a tree node."""
  print ' ' * indent + node.fullName
  if node.children:
    for child in node.children:
      printNode(child, indent + 2)


def buildRule(args):
  """Builds a rule function."""
  rules = []
  if args.classRegex:
    classRegex = re.compile(args.classRegex)
    rules.append(lambda **kw: classRegex.match(kw['name'].partition('.')[0]))

  if args.messageRegex:
    messageRegex = re.compile(args.messageRegex)
    rules.append(lambda **kw: messageRegex.match(kw['name'].partition('.')[2]))

  if args.thread:
    rules.append(lambda **kw: kw['thread'] == args.thread)

  if args.minTime:
    minTime = long(args.minTime)
    rules.append(lambda **kw: kw['start'] >= minTime)

  if args.maxTime:
    maxTime = long(args.maxTime)
    rules.append(lambda **kw: kw['start'] <= maxTime)

  if rules:
    return lambda name, thread, start: \
        len([1 for rule in rules if rule(name = name, thread = thread, start = start)]) == len(rules)

  return None


def listMessages(data, message):
  """Mode for listing messages."""
  for name, thread in data.threads.iteritems():
    print 'Thread: %s' % name
    for event in thread.events:
      if event.fullName == message:
        print '%0.1fms - own %0.3fms' % (event.start / 1000.0, event.own / 1000.0)
    print


def getData(pid):
  """Gets data for the given pid."""
  path = getDataPath(pid)
  if path:
    print 'Using %s' % path
  else:
    print 'No path found'
    sys.exit(1)
  return ProfileData(path)


def main():
  """Perform the analysis."""
  parser = argparse.ArgumentParser(description='Process some integers.')
  parser.add_argument('pid', metavar='PID', type=int, nargs='?',
                      help='the pid of the run to analyze, or omit to use the latest')

  parser.add_argument('--ownTime', dest='sort', action='store_const', const='own', help='sort by own time')
  parser.add_argument('--calls', dest='sort', action='store_const', const='calls', help='sort by call count')
  parser.add_argument('--average', dest='sort', action='store_const', const='avg', help='sort by call count')
  parser.add_argument('--total', dest='sort', action='store_const', const='total', help='sort by total time')
  parser.add_argument('--max', dest='sort', action='store_const', const='max', help='sort by total time')

  parser.add_argument('--class', dest='classRegex', help='regex for classes to include')
  parser.add_argument('--message', dest='messageRegex', help='regex for messsages to include')

  parser.add_argument('--threads', dest='action', action='store_const', const='threads', help='print thread list')
  parser.add_argument('--thread', dest='thread', help='filter by thread')

  parser.add_argument('--minTime', dest='minTime', help='minimum time in micros to include')
  parser.add_argument('--maxTime', dest='maxTime', help='maximum time in micros to include')

  parser.add_argument('--tree', dest='tree', help='print a call tree')

  parser.add_argument('--list', dest='listMessage', help='print a list of the given message calls')

  parser.add_argument('--server', dest='action', action='store_const', const='server', help='run server')

  parser.add_argument('--files', dest='action', action='store_const', const='files', help='list profile files')
  parser.add_argument('--clean', dest='action', action='store_const', const='clean', help='delete profile files')

  args = parser.parse_args()

  if args.action == 'clean':
    cleanDataFiles()
    return

  if args.action == 'files':
    listDataFiles()
    return

  data = getData(args.pid)
  if args.action == 'threads':
    for threadName, thread in data.threads.iteritems():
      print '%s - %d events' % (threadName, len(thread.events))
    return

  if args.action == 'server':
    from server import run
    run(data)
    return

  if args.tree:
    for node in data.threads[args.tree].tree:
      printNode(node)
    return

  if args.listMessage:
    return listMessages(data, args.listMessage)

  rule = buildRule(args)

  longestName, ownTime, count, avg, totalTime, maxTime = data.compute(rule)

  sortBy = ownTime
  if args.sort == 'calls':
    sortBy = count
  elif args.sort == 'avg':
    sortBy = avg
  elif args.sort == 'total':
    sortBy = totalTime
  elif args.sort == 'max':
    sortBy = maxTime

  mostTime = sorted(sortBy.items(), key=lambda x: x[1], reverse=True)[:100]
  print '%s %s %s %s %s %s' % (
      fit('message', longestName + 3), fit('calls', 9), fit('ownTime', 13),
      fit('avgOwn', 11), fit('maxOwn', 14), fit('total', 15))
  for name, _ in mostTime:
    print '%s %s %s %s %s %s' % (
        fit(name, longestName + 3),
        fit('%d' % count[name], 9),
        fit('%0.3fms' % (ownTime.get(name, 0) / 1000.0), 13),
        fit('%0.4fms' % (avg.get(name, 0) / 1000.0), 11),
        fit('%0.4fms' % (maxTime[name] / 1000.0), 14),
        fit('%0.3fms' % (totalTime[name] / 1000.0), 15),
      )


if __name__ == '__main__':
  main()
