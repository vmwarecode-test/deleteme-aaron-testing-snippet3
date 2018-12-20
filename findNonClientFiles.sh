#!/bin/sh

###############################################################################
# this script searches for all files under the workbench vide directory and prints the names of
# any that are not in the perforce client view to stdout.  Note that the directory searching and
# such in the loops are an attempt to avoid searching the contents of GENERATED directories and files
# that are a part of the build, e.g. eclipse bin directories, ant build directories and the *.class
# files that they contain
###############################################################################

# utility function that searches a given directory for all subdirectories that are
# valid ones to search for new files (which means directories that are not bin or build)
# arg1=path to check
CheckProjectForFilesNotInClient()
{
    ROOTDIR=${1}

    echo "checking ${ROOTDIR}"

    #find all subdirectories that are not named bin or build.  we do not want to search these
    #TODO append .p4ignore content to this?
    DIRECTORIES=`find ${ROOTDIR} -maxdepth 1 -type d ! \( -iname bin -or -iname build \)`

    for d in ${DIRECTORIES}
    do
        if [ "$d" == "${ROOTDIR}" ]; then
            #don't do a recursive check on . for files since that would pick up the contents of bin
            #echo "    non-recursive $d"
            find $d -maxdepth 1 -type f \( ! -iname bin -and ! -iname *.class \) | p4 -x- have > /dev/null
        else
            #echo "    recursive     $d"
            # find all files and then direct the results into p4 to check if we have them in the client
            find $d -type f \( ! -iname bin -and ! -iname *.class \) | p4 -x- have > /dev/null
        fi

        rc=$?
        if [[ $rc != 0 ]] ; then
            echo "ERROR: find in $d exited with ${rc}"
            exit 1
        fi
    done
}

###############################################################################

#first off, check to see if there is a path on the command line.  If there is, then we only search it
if [ ! -z "${1}" ]; then

    GLOB=`echo "${1}"`

	for PROJECT_DIR in ${GLOB}; do
        CheckProjectForFilesNotInClient "${PROJECT_DIR}"
    done
    echo "DONE!"
    exit 0
fi

# there is no path, assume we are checking the entire tree

if [ -z "${SRC_ROOT}" ]; then

    # SRC_ROOT is not defined.

    SCRIPT_DIR="$( cd "$( dirname "$0" )" && pwd )"

    # Try to see if the script is in the SRC_ROOT
    if [ -d "${SCRIPT_DIR}/vide" ]; then
        SRC_ROOT=${SCRIPT_DIR}
    else
 		#see if we are actually in the SRC_ROOT
	    SRC_ROOT=`pwd`
    fi
fi

if [ ! -d "${SRC_ROOT}" ]; then
    echo "SRC_ROOT is not set and you are not running this script from the Workbench root.  You must either change into the SRC_ROOT, set the SRC_ROOT variable, put the script in the SRC_ROOT"
    exit 1;
fi

VIDEDIR=${SRC_ROOT}/vide

# search for the plugin and feature directories
PROJECTDIRS=`find ${VIDEDIR} -maxdepth 2 -type d`

for projdir in ${PROJECTDIRS}
do
    if [ "$projdir" != "${VIDEDIR}" ]; then
        CheckProjectForFilesNotInClient "${projdir}"
    fi
done

echo "DONE!"
