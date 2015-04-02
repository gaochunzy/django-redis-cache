from hashlib import sha1
import bisect
from random import randint
from django.utils.encoding import smart_str


HEX_DIGITS = 7
MAX_NODES = 16 ** HEX_DIGITS


class Node(object):
    def __init__(self, value, _id):
        self.value = value
        self.id = _id

    def __repr__(self):
        return "<Node: value=%s>" % self.value

    def __cmp__(self, x):
        if isinstance(x, Node):
            return cmp(self.value, x.value)
        else:
            return cmp(self.value, x)

    def __eq__(self, other):
        if isinstance(other, Node):
            return self.id == other.id
        else:
            return self.id == other


class Interval(object):
    """
    Simple data structure to hold the start and end values of a keyspace
    interval.
    """
    #__slots__ = ['start', 'end']

    def __init__(self, start, end):
        self.start, self.end = start, end

    def __repr__(self):
        return "[%s, %s]" % (self.start, self.end)

    @property
    def length(self):
        return self.end - self.start

    def __len__(self):
        return self.length

    def __cmp__(self, other):
        return cmp(self.length, other.length)


class CacheSharder(object):

    def __init__(self, replicas=4):
        self.replicas = replicas
        self._intervals = []
        self._nodes = []

    def __len__(self):
        return len(self._nodes)

    def _add(self, id):
        if len(self._intervals) == 0:
            self._intervals.append(Interval(0, 1))
            value = 0.0
        else:
            interval = self._intervals.pop()
            value = interval.start + (interval.end - interval.start) / 2.0
            # Create two half-sized intervals and push back into the list
            self._intervals.extend([
                Interval(interval.start, value),
                Interval(value, interval.end),
            ])
            self._intervals.sort()
        #insert the node
        bisect.insort_left(self._nodes, Node(value, id))

    def add(self, _id, weight=1):
        """
        Adds client to the sorted client list.

        Uses the sorted interval list to find the largest one available.  Pop
        that interval and split it into two equal pieces and place back into
        the list and resort.  The client value will be the bisect of the popped
        interval.
        """
        for _ in xrange(self.replicas * weight):
            self._add(_id)

    def _remove(self, i):
        node = self._nodes[i]
        left, = filter(lambda x: x.end == node.value, self._intervals)
        right, = filter(lambda x: x.start == node.value, self._intervals)

        self._intervals.append(Interval(left.start, right.end))
        self._intervals.remove(left)
        self._intervals.remove(right)
        self._intervals.sort()
        self._nodes.remove(node)

    def remove(self, _id):
        """
        Removes a client using the id.

        Finds adjacent intervals and combines them before removing client from
        the
        """
        nodes = [node for node in self._nodes if node.id == _id]
        for node in nodes:
            i = self._nodes.index(node)
            self._remove(i)

    def get_position(self, key):
        return int(sha1(smart_str(key)).hexdigest()[:HEX_DIGITS], 16) / float(MAX_NODES)

    def get_node(self, key):
        position = self.get_position(key)
        index = bisect.bisect(self._nodes, position) - 1
        return self._nodes[index]
