#!/bin/sh

/usr/bin/printf "%-6s %-9s %s\n" "PID" "Total" "Command"
/usr/bin/printf "%-6s %-9s %s\n" "---" "-----" "-------"
PS_CMD=`which ps`
AWK_CMD=`which awk`
TAIL_CMD=`which tail`
PMAP_CMD=`which pmap`
PRINTF_CMD=`which printf`
SORT_CMD=`which sort`

for PID in `$PS_CMD -e | $AWK_CMD '$1 ~ /[0-9]+/ { print $1 }'`
do
   CMD=`$PS_CMD -o comm,args,time -p $PID | $TAIL_CMD -1`
   # Avoid "pmap: cannot examine 0: system process"-type errors
   # by redirecting STDERR to /dev/null
   TOTAL=`$PMAP_CMD $PID 2>/dev/null | $TAIL_CMD -1 | \
$AWK_CMD '{ print $2 }'`
   [ -n "$TOTAL" ] &&  $PRINTF_CMD "%-6s %-9s %s\n" "$PID" "$TOTAL" "$CMD"
done | $SORT_CMD -n -k2
