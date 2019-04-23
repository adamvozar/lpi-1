#!/usr/bin/env /bin/bash

source "$(dirname "$0")/common.sh"

echo
msg  "Testujem ${clYellow}$TRAVIS_BRANCH${clNorm}"
echo

if [[ "$TRAVIS_PULL_REQUEST" = "false" ]]; then
	echo "No tests for non-pull requests!";
	exit 0;
fi

# path to linux minisat for SAT tasks
export PATH="$PATH:$PWD/tools/lin/"


case "$TRAVIS_BRANCH" in
	pu*|bonus*|sat*) cd "${TASKS_DIR}/${TRAVIS_BRANCH}" || die "Nemôžem nájsť ${TASKS_DIR}/${TRAVIS_BRANCH}. Pull request oproti nesprávnej vetve ${TRAVIS_BRANCH}?";;
	*) die "Pull request oproti nesprávnej vetve ${TRAVIS_BRANCH}!";;
esac

if [[ -r Makefile ]] ; then
	make test
elif [[ -r test.sh ]] ; then
	bash test.sh
elif [[ -r test.py ]] ; then
	./test.py
else
	# try each subdir if it is a supported language
	runTestsForChanged $(testLangsDefault)
fi

# vim: set sw=4 sts=4 ts=4 noet :
