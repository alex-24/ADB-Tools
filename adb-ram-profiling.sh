#!/bin/bash

# $adb shell top
# ==============================================================================
#  PID   : Process ID.             - This is a unique identifier for each process running on the device.
#  USER  : User name.              - User who started the process.
#  PR    : Scheduling Priority.    - Processes with higher priority will be scheduled to run before the others.
#  NI    : Nice value.             - Used to change the priority. The lower the value the higher the priority.
#  VIRT  : Virtual memory size.    - Total amount of virtual memory (used + only allocated) used by the process. (can be bigger than the actual RAM size - extended by the swap)
#  RES   : Resident memory size.   - Amount of physical memory currently used by the process.
#  SHR   : Shared memory size.     - Amount of shared memory used by the process.
#  S     : Process status.         - Current status of the process (e.g., running, sleeping, stopped).
#  %CPU  : CPU usage.              - Percentage of CPU time used by the process since the last update.
#  %MEM  : Memory usage.           - Percentage of physical memory used by the process.
#  TIME+ : CPU time.               - Total amount of CPU time used by the process since it started.
#  NAME  : Command name.           - Name of the command that started the process. (ie. package name in most cases)

# check that a terminal is open
if [[ -t 0 || -p /dev/stdin ]]; then
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    BLUE=$(tput setaf 4)
    YELLOW=$(tput setaf 3)
    NO_COLOR=$(tput sgr0)
    BOLD=$(tput bold)
else
    RED=""
    GREEN=""
    BLUE=""
    YELLOW=""
    NO_COLOR=""
    BOLD=""
fi


simple_usage() {
    SCRIPT_NAME=$(basename $0)
    echo "${BOLD}Monitors the RAM usage of an Android package and writes the data to a CSV file.${NO_COLOR}"
    #echo "============================================================="
    echo "Usage: ${RED}\$${SCRIPT_NAME}${NO_COLOR} ${YELLOW}-s${NO_COLOR} [serial] ${YELLOW}-o${NO_COLOR} [output_file] ${YELLOW}-p${NO_COLOR} [package_name]"
    echo "  ${YELLOW}-s${NO_COLOR} serial            Serial number of the device (optional)"
    echo "  ${YELLOW}-o${NO_COLOR} output_file       Name of the output file"
    echo "  ${YELLOW}-p${NO_COLOR} package_name      Name of the package to monitor"
    echo "  ${YELLOW}-h${NO_COLOR} help              Display this help message and exit"
}


if [ $# -eq 0 ]; then
    simple_usage
    exit 1
fi

while getopts hs:o:p: flag
do
    case "${flag}" in
        h) simple_usage
            exit 0;;
        s) SERIAL="-s ${OPTARG}";;
        o) FILE=${OPTARG};;
        p) PACKAGE=${OPTARG};;
    esac
done

if [ -z "$FILE" ] || [ -z "$PACKAGE" ]; then
    echo "Error: missing required options"
    simple_usage
    exit 1
fi


ID=0
sep=";"

echo "#ID${sep}DATE${sep}VIRTUAL${sep}RESIDENT${sep}SHARED${sep}S${sep}CPU %${sep}RAM %" > $FILE
echo "single_numeric${sep}categorical${sep}single_numeric${sep}single_numeric${sep}single_numeric${sep}categorical${sep}single_numeric${sep}single_numeric" >> $FILE
echo "int${sep}None${sep}int${sep}int${sep}int${sep}None${sep}int${sep}int" >> $FILE
echo "None${sep}None${sep}GB${sep}MB${sep}MB${sep}None${sep}percentage${sep}percentage" >> $FILE
format="%-20s %-8s %-10s %-7s %-7s %-7s %-7s\r"
printf "$format\n" "DATE" "VIRTUAL" "RESIDENT" "SHARED" "S" "CPU %" "RAM %"


while true; do
    #DATE=$(date '+%Y-%m-%d %H:%M:%S.%3N')
    DATE=$(date '+%Y-%m-%d %H:%M:%S')
    #LINE=$(adb $SERIAL shell top -n 1 -b | grep "$PACKAGE")
    LINE=$(adb $SERIAL shell top -n 1 -b | grep "$PACKAGE")
    VIRT=$(echo $LINE | awk '{print $5}')
    RES=$(echo $LINE | awk '{print $6}')
    SHR=$(echo $LINE | awk '{print $7}')
    S=$(echo $LINE | awk '{print $8}')
    CPU=$(echo $LINE | awk '{print $9}')
    MEM=$(echo $LINE | awk '{print $10}')
    ID=$(($ID+1))

    echo $LINE

    shopt -s extglob # more powerful pattern matching
    if [[ -n "${VIRT##+([[:space:]])}" && -n "${RES##+([[:space:]])}" && -n "${SHR##+([[:space:]])}" && -n "${S##+([[:space:]])}"  && -n "${CPU##+([[:space:]])}"  && -n "${MEM##+([[:space:]])}" ]]; then
        echo "$ID$sep$DATE$sep$VIRT$sep$RES$sep$SHR$sep$S$sep$CPU$sep$MEM" >> $FILE
        #lines=$(echo "$output" | wc -l)
        #tput cuu $lines
        #tput el
        #printf "$format" "$DATE" "$VIRT" "$RES" "$SHR" "$S" "$CPU" "$MEM"
    fi
    sleep 1
done