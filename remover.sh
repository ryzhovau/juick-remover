#!/bin/bash

function usage {
    cat << EOF
This script removes all posts, recommends or comments from juick.com

Usage:	./remover.sh comments	- deletes all username comments,
	./remover.sh posts	- deletes all username posts,
	./remover.sh recommends	- deletes all username recomendations.
EOF
    exit 1
}

if [ -z "$1" ] ; then
    usage
fi

if [ -z "$(which curl)" ] ; then
    echo "curl required, aborting..."
    exit 1
fi

if [ ! -f .juick_cookies ] ; then
    echo "Authorization required. Please type LOGIN and paste login URL"
    read -p "[http://juick.com/login?xxxxxxxxxxxxxxxx]: " login_url
    curl -s -c .juick_cookies $login_url> /dev/null
fi

nick=$(curl -s -b .juick_cookies http://juick.com | grep "nav id=\"actions\"" | cut -d "@" -f 2 | cut -d "<" -f 1)
echo "Current nick is $nick"

delete_url=http://juick.com/post?body=D+%23
#http://juick.com/post?body=D+%232779087

function del_recommends {
    echo "deleting recommends..."
    curl -s -b .juick_cookies http://juick.com/ryzhov-al/?show=recomm > resp.txt
}

function del_comments {
    echo "deleting comments..."
    curl -s -b .juick_cookies http://juick.com/?show=discuss > resp.txt
}

function del_posts {
    echo "deleting posts..."
    while true
    do
	curl -s -b .juick_cookies http://juick.com/$nick/ > resp.txt
	if [ -z "$(cat resp.txt | grep 'article data-mid')" ] ; then
	    echo "Done."
	    break
	fi
	for post in $(cat resp.txt | grep "article data-mid" | cut -d "\"" -f 2)
	do
	    echo "Deleting #$post..."
	    curl -s -b .juick_cookies -F body="D #$post" http://juick.com/post2
	done
    done
}

case $1 in
    comments)
    del_comments
    ;;
    recommends)
    del_recommends
    ;;
    posts)
    del_posts
    ;;
    *)
    usage
    ;;
esac
