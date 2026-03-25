#!/bin/sh

# Update CPU and memory items in one pass to avoid duplicate sampling.
cpu_usage=$(top -l 1 -n 0 | awk '/CPU usage/ {u=$3; s=$5; gsub("%","",u); gsub("%","",s); printf "%.1f", u+s}')

mem_usage=$(memory_pressure 2>/dev/null | awk '/System-wide memory free percentage:/ {gsub("%","",$5); printf "%.1f", 100-$5}')

# Fallback to vm_stat if memory_pressure is unavailable
if [ -z "$mem_usage" ]; then
  mem_usage=$(vm_stat | awk '
    /Pages active/ {gsub("\\.", "", $3); active=$3}
    /Pages inactive/ {gsub("\\.", "", $3); inactive=$3}
    /Pages speculative/ {gsub("\\.", "", $3); speculative=$3}
    /Pages wired down/ {gsub("\\.", "", $4); wired=$4}
    /Pages free/ {gsub("\\.", "", $3); free=$3}
    END {used=active+inactive+speculative+wired; total=used+free; if(total>0) printf "%.1f", used*100/total}
  ')
fi

[ -n "$cpu_usage" ] && sketchybar --set cpu icon="" label="${cpu_usage}%"
[ -n "$mem_usage" ] && sketchybar --set memory icon="" label="${mem_usage}%"
