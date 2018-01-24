#!/usr/bin/env python
import sys
from datetime import datetime
import os

def tail(filename, count=1, offset=1024):
    """
    A more efficent way of getting the last few lines of a file.
    Depending on the length of your lines, you will want to modify offset
    to get better performance.
    """
    f_size = os.stat(filename).st_size
    if f_size == 0:
        return []
    with open(filename, 'r') as f:
        if f_size <= offset:
            offset = int(f_size / 2)
        while True:
            seek_to = min(f_size - offset, 0)
            f.seek(seek_to)
            lines = f.readlines()
            # Empty file
            if seek_to <= 0 and len(lines) == 0:
                return []
            # count is larger than lines in file
            if seek_to == 0 and len(lines) < count:
                return lines
            # Standard case
            if len(lines) >= (count + 1):
                return lines[count * -1:]

def head(filename, count=1):
    """
    This one is fairly trivial to implement but it is here for completeness.
    """
    with open(filename, 'r') as f:
        lines = [f.readline() for line in xrange(1, count+1)]
        return filter(len, lines)

fileName = sys.argv[1]
if len(sys.argv) < 3:
    lineNum = 1
else:
    lineNum = int(sys.argv[2])
print "Reading run time for " + fileName
sTimestamp = head(fileName, lineNum)
eTimestamp = tail(fileName, lineNum)

nb = len(sTimestamp[-1])
ns = len(eTimestamp[0])
begin_time = datetime.strptime(sTimestamp[-1][0:nb-1],'%a %b %d %H:%M:%S %Z %Y')
end_time = datetime.strptime(eTimestamp[0][0:ns-1],'%a %b %d %H:%M:%S %Z %Y')
print "Start time " + str(begin_time)
print "End time " + str(end_time)
timeElapsed = (end_time - begin_time)
print "Elapsed time " + str(timeElapsed)
