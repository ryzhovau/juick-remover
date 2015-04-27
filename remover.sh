#!/bin/bash

function usage {
    cat << EOF
This script removes all posts, recommends or comments from juick.com

Usage:	./remover.sh comments	- deletes all username comments,
	./remover.sh posts	- deletes all username posts,
	./remover.sh recommends	- deletes all username recomendations,
	./remover.sh all	- deletes everything.
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

function del_recommends {
    echo "Deleting recommends..."
    while true
    do
	curl -s -b .juick_cookies http://juick.com/ryzhov-al/?show=recomm > resp.txt
	if [ -z "$(cat resp.txt | grep 'article data-mid')" ] ; then
	    echo "Done."
	    rm -f resp.txt
	    break
	fi
	for post in $(cat resp.txt | grep "article data-mid" | cut -d "\"" -f 2)
	do
	    echo "Deleting recommend for #$post..."
	    curl -s -b .juick_cookies -F body="! #$post" http://juick.com/post2
	done
    done
}

function del_comments {
    echo "Deleting comments..."
    before=0
    while true
    do
	if [ "$before" == "0" ] ; then
	    curl -s -b .juick_cookies http://juick.com/?show=discuss > resp.txt
	else
	    curl -s -b .juick_cookies http://juick.com/?before=${before}\&show=discuss > resp.txt
	fi
	if [ -z "$(cat resp.txt | grep 'article data-mid')" ] ; then
	    echo "Done."
	    exit
	    rm -f resp.txt
	    break
	fi
	for post in $(cat resp.txt | grep "article data-mid" | cut -d "\"" -f 2)
	do
	    author_nick="$(cat ./resp.txt | grep $post | grep 'time datetime' | cut -d '/' -f 2)"
	    echo -n "at $author_nick/${post}: deleting "
	    for comment in $(curl -s -b .juick_cookies http://juick.com/$author_nick/$post  | grep $nick | grep 'class="msg"' | cut -d '"' -f 2)
	    do
		echo -n "${comment}, "
		curl -s -b .juick_cookies -F body="D #$post/$comment" http://juick.com/post2
	    done
	    echo "done."
	    rm -f post.txt
	done
	next_page=$(cat ./resp.txt | grep before= | grep 'class="page"' | cut -d '=' -f 4 | cut -d '&' -f 1)
	if [ -z "$next_page" ] || [ "x$next_page" == "x$before" ] ;
	then
	    echo "Done. No more pages to process."
	    rm -f resp.txt
	    break
	else
	    echo "Processing another HTML page..."
	    before=$next_page
	fi
    done
}

function del_posts {
    echo "Deleting posts..."
    while true
    do
	curl -s -b .juick_cookies http://juick.com/$nick/ > resp.txt
	if [ -z "$(cat resp.txt | grep 'article data-mid')" ] ; then
	    echo "Done."
	    rm -f resp.txt
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
    all)
	del_posts
	del_recommends
	del_comments
    ;;
    *)
    usage
    ;;
esac
