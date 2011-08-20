### Bashmarks is a shell script that allows you to save and jump to commonly used directories. Now supports tab completion.

This version has the `o command` to open the bookmark in Finder.
It also allows placing commands after the the letter e.g `g webfolder ls` would go the webfolder bookmark then perform `ls`.  It will also print the directory when use `g` 

## Install

1. git clone git://github.com/Bilalh/bashmarks.git
2. make install
3. source **~/.local/bin/bashmarks.sh** from within your **~.bash\_profile** or **~/.bashrc** file

## Shell Commands

    s <bookmark_name> - Saves the current directory as "bookmark_name"
    g <bookmark_name> - Goes (cd) to the directory associated with "bookmark_name"
    o <bookmark_name> - Open the directory associated with "bookmark_name" in Finder
    p <bookmark_name> - Prints the directory associated with "bookmark_name"
    d <bookmark_name> - Deletes the bookmark
    l                 - Lists all available bookmarks
    
## Example Usage

    $ cd /var/www/
    $ s webfolder
    $ cd /usr/local/lib/
    $ s locallib
    $ l
        webfolder    /var/www/
        locallib     /usr/local/lib/
    $ g web<tab>
    $ g webfolder
	$ o webfolder 

## Where Bashmarks are stored
    
All of your directory bookmarks are saved in a file called ".sdirs" in your HOME directory.
