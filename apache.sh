#!/bin/bash
#Using Apache log example create a script to answer the following questions:

 exec 1> ~/Desktop/TaskBash/task2/apachelog.txt
echo `date`
echo  "1. Most requests were from this IP:"
  awk '{ print $1}' ~/Desktop/TaskBash/task2/example_log.log | sort | uniq -c | sort -nr | head -n 1
echo
echo  "2. The most requested page: "
echo
  awk '{ print $7 }' ~/Desktop/TaskBash/task2/example_log.log | sort | uniq -c | sort -rn | head -n 1
echo
echo "3. The number of requests from each IP:"
echo
   awk '{ print $1}'  ~/Desktop/TaskBash/task2/example_log.log | sort | uniq -c | sort -nr
echo
echo "4. Nonexistent pages were referenced by customers: "
echo
      grep " 404 " ~/Desktop/TaskBash/task2/example_log.log | cut -d ' ' -f 7 | sort | uniq -c | sort -nr | head 
echo
echo "5.The time at which the site received the greatest number of requests: "
echo
    awk '{ print $4 $5 }' ~/Desktop/TaskBash/task2/example_log.log | sort | uniq -c|sort -rn| head -n 1
echo
echo "6. The search bots that accessed the site : "
echo
   awk -F\"  '/bot/{print $1 $6 }' ~/Desktop/TaskBash/task2/example_log.log | sort | uniq | sort -nr



