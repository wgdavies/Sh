# HOWTO: Install Non-local Packages Locally
When you don't have local administrator access on your macos computer, or when you want to install programs that only you have direct access to, the local `~/Applications` and `~/Library` are right there waiting for you. This page shows how to take a downloaded, installable macos package that normally installs to a common filesystem location (e.g `/Applications` or `/usr/local`), extract the contents, and perform a local-only 'install'. 

The one drawback to this method is that it will not register the package in the global package database (which may require administrative access, anyway). This means that you may not be able to just drag an application to the trash to remove/uninstall it, since that may not remove all the components. _Caveat emptor_. 

## TL;DR:
```
mkdir tmp
cp pkgname.pkg tmp && cd tmp
ls
xar -xf ./pkgname.pkg
cat newpkgname.pkg/Payload | gzip -dc | cpio -i
ls
```

The above steps extract a PKG-formatted file into a useable file/directory structure. Installable files or directories will now be peered under the `tmp/` directory. The two `ls` steps will show which files or directories are new and included in the Payload archive (e.g a new `usr/local/` directory structure).


## Verify Files
Use the `otool -L` command to verify that all library dependencies are met in any resulting binaries. Here is a script to help automate the task:
```
file bin/* | tr -d ':' | while read -A line; do
    if [[ ${line[1]} == Mach-O ]]; then
        otool -L ${line[0]}
    fi
done | less
```

## [Re-]Install Files
Binaries, &c will typically be relocated to `~/bin` or `~/Applications`. Simply copy or move files into place, e.g:
```
mv usr/local/bin/* ~/bin
```

Check for `man/` or other directories (e.g `lib/`, `share/`, &c) that may also need to be copied or moved.


## Other Issues
Here are various other issues to watch out for.

### Symlinks
If you have symlinks that will point to the wrong location after files are moved, modify the following to suit your purposes:
```
cd ~/bin
ls -l | while read -A line; do
    if [[ ${line:0:1} == l ]] && [[ ${line[-1]} =~ ../../ ]]; then
        newln=${line[-1]}
        rm ${line[9]}
        ln -s ${newln/..\/..\//./} ${line[9]}
    fi
done
```

In particular, you'll want to correct the lines containing `../../` to match your errant symlinks.

> Nota Bene: all command-lines and scriptlets were executed on Korn Shell Version AJM 93u+ 2012-08-01, which ships default on macos. These examples should also work with BASH and derivatives, though has not been tested therewith. 
