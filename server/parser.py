# Copyright 2012 Greplin, Inc.  All Rights Reserved.

"""Analyzes a profile dump."""

import collections


def computeAverages(numerators, denominators):
  """Compute average own times."""
  avg = {}
  for k, v in numerators.items():
    avg[k] = v * 1.0 / denominators[k]
  return avg



class TreeNode(object):
  """Node in the profile tree."""

  __slots__ = ('fullName', 'start', 'finish', 'own', 'children', 'tag')


  def __init__(self, fullName, start):
    self.fullName = fullName
    self.start = start
    self.finish = None
    self.own = None
    self.children = []
    self.tag = None



class ThreadData(object):
  """Data for an individual thread."""

  def __init__(self):
    self.events = []
    self.tree = []



class ProfileData(object):
  """Parsed profile data."""

  def _parseCheckpoint(self, line):
    """Parses a checkpoint."""
    micros, _, text = line[13:].strip().partition(':')
    self.checkpoints.append({'time': long(micros) - self.first, 'text': text})


  def _parseTag(self, line):
    """Parses an object tag."""
    _, address, tag = line[6:].strip().split(':', 2)
    self.tags[address] = tag


  def __init__(self, path):
    self.threads = collections.defaultdict(ThreadData)
    self.checkpoints = []
    self.tags = {}
    self.first = 0

    stacks = collections.defaultdict(list)

    with open(path) as f:
      for lineNo, line in enumerate(f):
        try:
          if line.startswith('> '):
            # Start: threadName, object address, class, message, start
            threadName, _, cls, message, start = line[2:].strip().split()
            start = long(start)
            self.first = self.first or start
            node = TreeNode('%s.%s' % (cls, message), start - self.first)

            stack = stacks[threadName]
            if stack:
              stack[-1].children.append(node)
            else:
              self.threads[threadName].tree.append(node)
            stack.append(node)

          elif line.startswith('< '):
            # Finish: threadName, object address, class, message, finish, own
            threadName, address, cls, message, finish, own = line[2:].strip().split()
            finish = long(finish)
            own = long(own)

            node = stacks[threadName].pop()
            fullName = '%s.%s' % (cls, message)
            assert node.fullName == fullName, \
                'Line %d - thread %s - expected %s but got %s' % (lineNo + 1, threadName, node.fullName, fullName)
            node.finish = finish - self.first
            node.own = own

            if address in self.tags:
              node.tag = self.tags[address]
              if message == 'dealloc':
                del self.tags[address]

            self.threads[threadName].events.append(node)

          elif line.startswith('# checkpoint:'):
            self._parseCheckpoint(line)

          elif line.startswith('# tag:'):
            self._parseTag(line)

        except ValueError:
          # Skip incomplete rows.
          pass


  def compute(self, eventInclusionRule = None):
    """Compute data for display."""
    ownTime = collections.Counter()
    count = collections.Counter()
    total = collections.Counter()
    maxTime = collections.defaultdict(list)
    longestName = 0

    for threadName, thread in self.threads.iteritems():
      stack = collections.Counter()
      queue = collections.deque(thread.tree)
      while queue:
        node = queue.popleft()
        if isinstance(node, basestring):
          stack[node] -= 1
        else:
          if not eventInclusionRule or eventInclusionRule(node.fullName, threadName, node.start):
            if node.own:
              ownTime[node.fullName] += node.own
              maxTime[node.fullName] = max(maxTime.get(node.fullName, 0), node.own)
            count[node.fullName] += 1
            longestName = max(longestName, len(node.fullName))
            if node.finish and not stack[node.fullName]:
              total[node.fullName] += node.finish - node.start
          if node.children:
            stack[node.fullName] += 1
            queue.appendleft(node.fullName)
            queue.extendleft(reversed(node.children))

    return longestName, ownTime, count, computeAverages(ownTime, count), total, maxTime
