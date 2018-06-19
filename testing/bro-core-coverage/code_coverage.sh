#!/bin/bash
#
# DEPENDS ON GCOV
#
# AUTOMATES CODE COVERAGE TESTING
#	1. Run test suite
# 	2. Check for .gcda files existing. 
#	3. Run gcov (-p to preserve path)
#	4a. Analyze .gcov files generated and create summary file
#	4b. Send .gcov files to appropriate path 
#

#CFLAG="--coverage -O0"
#CXXFLAG="--coverage -O0"
#./configure --enable-debug
#make

CURR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"	# Location of script
BASE=`realpath "${CURR}/../../"`
TMP="${CURR}/tmp"
mkdir $TMP

# OPERATE ON PROGRAM ROOT DIRECTORY
cd $BASE

# DEFINE CLEANUP PROCESS
function finish {
	find "$BASE" -name "*.gcda" -exec rm {} \; > /dev/null 2>&1
	sudo rm -rf $TMP
}
trap finish EXIT

# DEFINE CRUCIAL FUNCTIONS FOR COVERAGE CHECKING
function check_file_coverage {
	GCOV="$1"

	for i in $(ls $GCOV/* | grep -v $DATA); do 
		# Effective # of lines: starts with a number (# of runs in line) or ##### (line never run)
		TOTAL=$(cut -d: -f 1 "$i" | sed 's/ //g' | grep -v "^[[:alpha:]]" | grep -v "-" | wc -l)

		# Count number of lines never run
		UNRUN=$( grep "#####" "$i" | wc -l)

		# Lines in code are either run or unrun
		RUN=$(( $TOTAL - $UNRUN ))

		PERCENTAGE=$(bc <<< "scale=3; 100*$RUN/$TOTAL")

		# Find correlation between % of lines run vs. "Runs"
		echo -e "$PERCENTAGE\t$RUN\t$TOTAL\t$(grep "0:Runs" "$i" | sed 's/.*://')\t$i" 
	done
}
function check_group_coverage {
	DATA="$1"	# WHERE ACTUAL COVERAGE DATA IS CONTAINED
	SRC_FOLDER="$2" # WHERE BRO WAS COMPILED
	OUTPUT="$3"

	# Prints all the relevant directories
	DIRS=$(for i in $(cut -f 5 "$DATA"); do basename "$i" | sed 's/#[^#]*$//'; done \
		| sort | uniq | sed 's/^.*'"${SRC_FOLDER}"'//' | grep "^#s\+" )
	# "Generalize" folders unless it's from analyzers
	DIRS=$(for i in $DIRS; do
		if !(echo "$i" | grep "src#analyzer"); then
			echo "$i" | cut -d "#" -f 1,2,3
		fi
	done | sort | uniq )

	for i in $DIRS; do
		# For elements in #src, we only care about the files direclty in the directory.
		if [[ "$i" = "#src" ]]; then
			RUN=$(echo $(grep "$i#[^#]\+$" $DATA | grep "$SRC_FOLDER$i\|build$i" | cut -f 2) | tr " " "+" | bc)
			TOTAL=$(echo $(grep "$i#[^#]\+$" $DATA | grep "$SRC_FOLDER$i\|build$i" | cut -f 3) | tr " " "+" | bc)
		else
			RUN=$(echo $(grep "$i" $DATA | cut -f 2) | tr " " "+" | bc)
			TOTAL=$(echo $(grep "$i" $DATA | cut -f 3) | tr " " "+" | bc)
		fi

		PERCENTAGE=$( echo "scale=3;100*$RUN/$TOTAL" | bc | tr "\n" " " )
		printf "%-50s\t%12s\t%6s %%\n" "$i" "$RUN/$TOTAL" $PERCENTAGE >> $OUTPUT
	done
}

# 1. Run test suite
# SHOULD HAVE ALREADY BEEN RUN BEFORE THIS SCRIPT (BASED ON MAKEFILE TARGETS)

# 2. Check for .gcno and .gcda files existing
echo -n "Checking for coverage files... "
if ! $(find "$BASE" -name "*.gcda" > /dev/null 2>&1 ) || ! $(find "$BASE" -name "*.gcno" > /dev/null 2>&1 ); then
	exit
fi
echo "ok"

# 3. Run gcov (-p to preserve path) and move into tmp directory
echo -n "Creating coverage files... "
find . -name "*.o" -exec gcov -p {} > /dev/null 2>&1 \;
mv *.gcov "$TMP"
echo "ok"
 
# 4a. Analyze .gcov files generated and create summary file
echo -n "Creating summary file... "
DATA="${TMP}/data"
SUMMARY="$CURR/coverage.log"
check_file_coverage "$TMP" > "$DATA"
check_group_coverage "$DATA" ${BASE##*/} $SUMMARY
echo "ok"
 
# 4b. Send .gcov files to appropriate path
echo -n "Sending coverage files to respective directories... "
for i in $(ls ${TMP}/*); do
	# Only the gcov files with "#" (the ones that contain path information)
	# Also, _only_ the gcov files include # in their name
	if [ $(expr $(basename "$i") : "#") -eq 1 ] && [[ "$i" != *"c++"* ]]; then
		mv $i $( dirname $(echo $(basename $i) | sed 's/#/\//g' ) )
	fi
done
echo "ok"
