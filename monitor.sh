#!/bin/bash

#rpsene/dummy_04
USER=$1
PROJECT=$2
GHE_TOKEN=$3
PROJECT_NAME=$USER/$PROJECT

#Configure access to Travis using GHE
travis endpoint --set-default -X -e "https://travis.com/api"
travis login -X -e "https://travis.com/api" -g $GHE_TOKEN

#Commit a new file
rm -rf ./$PROJECT_NAME
git clone https://$USER:$GHE_TOKEN@github.com/$PROJECT_NAME.git
git clone git@github.com:$PROJECT
cd ./$PROJECT_NAME
git pull --rebase
RANDOM_STRING=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
echo $RANDOM_STRING >> ./strings
git add ./strings
git commit -s -m "Add new entry called $RANDOM_STRING"
git push

LATEST_COMMIT=$(git rev-parse HEAD | rev | cut -d/ -f1 | rev | cut -c1-12)

#collect the information about the project
raw=$(travis show -r $PROJECT)
#convert it to an array
hash=($raw)
#Get the commit has that started the job
COMMIT_HASH=$(echo ${hash[14]} | rev | cut -d/ -f1 | rev | cut -c16-27)

while [ "$LATEST_COMMIT" != "$COMMIT_HASH" ]
do
echo "Waiting the correct build to start!"
sleep 5s
raw=$(travis show -r $PROJECT)
#convert it to an array
hash=($raw)
#Get the commit has that started the job
COMMIT_HASH=$(echo ${hash[14]} | rev | cut -d/ -f1 | rev | cut -c16-27)
done

#Get the build status
TRAVIS_BUILD_STATUS=$(echo ${hash[7]})

while true
do
echo "Waiting the build to complete!"
sleep 5s
raw=$(travis show -r $PROJECT)
#convert it to an array
hash=($raw)
#Get the build status
TRAVIS_BUILD_STATUS=$(echo ${hash[7]})
echo "$TRAVIS_BUILD_STATUS"
if [ "$TRAVIS_BUILD_STATUS" = "passed" ] || [ "$TRAVIS_BUILD_STATUS" = "errored" ] ; then
	#Get the latest build number
	TRAVIS_BUILD_NUMBER=$(echo ${hash[1]} | tr -d \: | tr -d \#)

	echo
	echo "**************************************************************************************************"
	echo $LATEST_COMMIT, $COMMIT_HASH, $TRAVIS_BUILD_NUMBER, $TRAVIS_BUILD_STATUS, ${hash[22]}, ${hash[23]}

	if [ "$LATEST_COMMIT" = "$COMMIT_HASH" ]; then
	    echo "Latest commit was built by Travis :)"
	else
		echo "There is something wrong, Travis didn't build the lastet commit."
	    exit 1
	fi
    echo "**************************************************************************************************"
    echo
	break #Abandon the loop.
fi
done
