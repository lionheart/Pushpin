Pushpin
=======

This project uses a few git hooks and merge drivers to prevent merge conflicts and to keep the project file clean. To set them up, just run:

```
$ git_config/configure.sh
```

The above command will also ensure that any Git commands stay in sync if they're updated.

There are also a few git submodules you're going to need. To set them up, just run:

```
$ git submodule init
$ git submodule update
$ git submodule -q foreach git pull -q origin master
```

Updating Screenshots
====================

```
gem install deliver
deliver init
# wait a few minutes
deliver
```

