pass - shell password manager
=============================

This is a clean-room reimplementation of "the standard unix password
manager", [ZX2C4's pass](https://www.passwordstore.org) in fully
portable POSIX shell script. It aims to be a drop-in replacement.
It isn't there yet, but is functional enough for me to use.

What's already supported
------------------------
All supported commands also fully support all options.

  - show
  - edit
  - insert, add (does not honour .gpg-id file, uses default gpg id)
  - remove, rm, delete
  - list, ls

Usage
-----
For now, see the link in the first paragraph of this README.

Why?
----
Two reasons:

  - The other pass is 'portable'. It uses bash, and abstracts
    platform differences away in a file called `platform.sh` which
    is installed from a different repository file depending on the
    operating system make is called on. This does not work for my
    very contrived usecase. I copy most of my shellscripts around
    for the systems I use. Those systems include Alpine (no bash)
    and macOS (different `platform.sh`).
  
    Writing correct and portable POSIX shell scripts is not easy,
    but I've made it a bit of a hobby or puzzle. Rewriting the other
    pass to be POSIX compatible would probably not be accepted by
    upstream. This version only requires a POSIX environment and
    gpg.
  - This project is licensed under CC0. This means I can't look at
    the code from the other pass to figure out what the deal is
    with multiple gpg id's. :(

Bugs
----
All of them. Like missing a ton of essential features.

