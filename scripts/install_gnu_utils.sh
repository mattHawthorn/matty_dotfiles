#!/usr/bin/env bash

/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# # /usr/local/bin/brew
# # /usr/local/share/doc/homebrew
# # /usr/local/share/man/man1/brew.1
# # /usr/local/share/zsh/site-functions/_brew
# # /usr/local/etc/bash_completion.d/brew
# # /usr/local/Homebrew
# ==> The following existing directories will be made group writable:
# /usr/local/bin
# ==> The following existing directories will have their owner set to matthew_hawthorn:
# /usr/local/bin
# ==> The following existing directories will have their group set to admin:
# /usr/local/bin
# ==> The following new directories will be created:
# /usr/local/Cellar
# /usr/local/Homebrew
# /usr/local/Frameworks
# /usr/local/etc
# /usr/local/include
# /usr/local/lib
# /usr/local/opt
# /usr/local/sbin
# /usr/local/share
# /usr/local/share/zsh
# /usr/local/share/zsh/site-functions
# /usr/local/var

brew install wget

# # ==> Installing dependencies for wget: openssl@1.1


# ****************************
# ******* ==> Caveats ********
# ****************************

# A CA file has been bootstrapped using certificates from the system
# keychain. To add additional certificates, place .pem files in
#   /usr/local/etc/openssl@1.1/certs
#
# and run
#   /usr/local/opt/openssl@1.1/bin/c_rehash
#
# This formula is keg-only, which means it was not symlinked into /usr/local,
# because this is an alternate version of another formula.
#
# If you need to have this software first in your PATH run:
#   echo 'export PATH="/usr/local/opt/openssl@1.1/bin:$PATH"' >> ~/.bash_profile
#
# For compilers to find this software you may need to set:
#     LDFLAGS:  -L/usr/local/opt/openssl@1.1/lib
#     CPPFLAGS: -I/usr/local/opt/openssl@1.1/include

# ==> Summary
# 🍺  /usr/local/Cellar/openssl@1.1/1.1.0f: 6,421 files, 15.5MB

# ==> Installing wget

# 🍺  /usr/local/Cellar/wget/1.19.1_1: 11 files, 1.6MB


brew doctor
# Your system is ready to brew.

brew tap homebrew/dupes

# Warning: homebrew/dupes was deprecated. This tap is now empty as all its formulae were migrated.
# ==> Tapping homebrew/dupes
# Cloning into '/usr/local/Homebrew/Library/Taps/homebrew/homebrew-dupes'...

brew install findutils --with-default-names

# 🍺  /usr/local/Cellar/findutils/4.6.0: 25 files, 1.6MB, built in 3 minutes 43 seconds

brew install gnu-sed --with-default-names

# 🍺  /usr/local/Cellar/gnu-sed/4.4: 10 files, 486.8KB, built in 1 minute 55 seconds

brew install gnu-tar --with-default-names


# ****************************
# ******* ==> Caveats ********
# ****************************

# gnu-tar has been installed as "gtar".
#
# If you really need to use it as "tar", you can add a "gnubin" directory
# to your PATH from your bashrc like:
#
#     PATH="/usr/local/opt/gnu-tar/libexec/gnubin:$PATH"
#
# Additionally, you can access their man pages with normal names if you add
# the "gnuman" directory to your MANPATH from your bashrc as well:
#
#     MANPATH="/usr/local/opt/gnu-tar/libexec/gnuman:$MANPATH"

# ==> Summary
# 🍺  /usr/local/Cellar/gnu-tar/1.29_1: 15 files, 1.7MB

brew install gnu-which --with-default-names

# brew install gnutls --with-default-names

# ==> Installing dependencies for gnutls: libtasn1, gmp, nettle, libunistring, libffi, p11-kit

# ==> Installing gnutls dependency: libtasn1
# 🍺  /usr/local/Cellar/libtasn1/4.12: 59 files, 431.3KB

# ==> Installing gnutls dependency: gmp
# 🍺  /usr/local/Cellar/gmp/6.1.2: 18 files, 3.1MB

# ==> Installing gnutls dependency: nettle
# 🍺  /usr/local/Cellar/nettle/3.3: 81 files, 2.0MB

# ==> Installing gnutls dependency: libunistring
# 🍺  /usr/local/Cellar/libunistring/0.9.7: 53 files, 4.2MB

# ==> Installing gnutls dependency: libffi


# ****************************
# ******* ==> Caveats ********
# ****************************

# This formula is keg-only, which means it was not symlinked into /usr/local,
# because some formulae require a newer version of libffi.
#
# For compilers to find this software you may need to set:
#     LDFLAGS:  -L/usr/local/opt/libffi/lib

# ==> Summary
# 🍺  /usr/local/Cellar/libffi/3.2.1: 16 files, 297.0KB

# ==> Installing gnutls dependency: p11-kit
# 🍺  /usr/local/Cellar/p11-kit/0.23.8: 62 files, 2.5MB

# ==> Installing gnutls
# 🍺  /usr/local/Cellar/gnutls/3.5.15: 1,105 files, 7.6MB

brew install grep --with-default-names

# ==> Installing dependencies for grep: pkg-config, pcre

# ==> Installing grep dependency: pkg-config
# 🍺  /usr/local/Cellar/pkg-config/0.29.2: 11 files, 627.1KB

# ==> Installing grep dependency: pcre
# 🍺  /usr/local/Cellar/pcre/8.41: 204 files, 5.3MB

# ==> Installing grep --with-default-names
# 🍺  /usr/local/Cellar/grep/3.1: 15 files, 860KB, built in 2 minutes 12 seconds

brew install coreutils


# ****************************
# ******* ==> Caveats ********
# ****************************

# All commands have been installed with the prefix 'g'.
#
# If you really need to use these commands with their normal names, you
# can add a "gnubin" directory to your PATH from your bashrc like:
#
#     PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
#
# Additionally, you can access their man pages with normal names if you add
# the "gnuman" directory to your MANPATH from your bashrc as well:
#
#     MANPATH="/usr/local/opt/coreutils/libexec/gnuman:$MANPATH"

# ==> Summary
# 🍺  /usr/local/Cellar/coreutils/8.28: 430 files, 9.0MB

brew install binutils

# 🍺  /usr/local/Cellar/binutils/2.29.1: 113 files, 142.9MB

brew install diffutils

# 🍺  /usr/local/Cellar/diffutils/3.6: 17 files, 671.6KB

brew install gzip

# 🍺  /usr/local/Cellar/gzip/1.8: 34 files, 326.5KB

brew install watch

# ==> Installing dependencies for watch: gettext

# ==> Installing watch dependency: gettext


# ****************************
# ******* ==> Caveats ********
# ****************************

# This formula is keg-only, which means it was not symlinked into /usr/local,
# because macOS provides the BSD gettext library & some software gets confused if both are in the library path.
#
# If you need to have this software first in your PATH run:
#   echo 'export PATH="/usr/local/opt/gettext/bin:$PATH"' >> ~/.bash_profile
#
# For compilers to find this software you may need to set:
#     LDFLAGS:  -L/usr/local/opt/gettext/lib
#     CPPFLAGS: -I/usr/local/opt/gettext/include

# ==> Summary
# 🍺  /usr/local/Cellar/gettext/0.19.8.1: 1,934 files, 16.9MB


# ==> Installing watch

# 🍺  /usr/local/Cellar/watch/3.3.12: 8 files, 76.4KB

brew install tmux

# ==> Installing dependencies for tmux: openssl, libevent

# ==> Installing tmux dependency: openssl


# ****************************
# ******* ==> Caveats ********
# ****************************

# A CA file has been bootstrapped using certificates from the SystemRoots
# keychain. To add additional certificates (e.g. the certificates added in
# the System keychain), place .pem files in
#   /usr/local/etc/openssl/certs
#
# and run
#   /usr/local/opt/openssl/bin/c_rehash
#
# This formula is keg-only, which means it was not symlinked into /usr/local,
# because Apple has deprecated use of OpenSSL in favor of its own TLS and crypto libraries.
#
# If you need to have this software first in your PATH run:
#   echo 'export PATH="/usr/local/opt/openssl/bin:$PATH"' >> ~/.bash_profile
#
# For compilers to find this software you may need to set:
#     LDFLAGS:  -L/usr/local/opt/openssl/lib
#     CPPFLAGS: -I/usr/local/opt/openssl/include
# For pkg-config to find this software you may need to set:
#     PKG_CONFIG_PATH: /usr/local/opt/openssl/lib/pkgconfig

# ==> Summary
# 🍺  /usr/local/Cellar/openssl/1.0.2l: 1,709 files, 12.2MB


# ==> Installing tmux dependency: libevent
# 🍺  /usr/local/Cellar/libevent/2.1.8: 847 files, 2.2MB


# ==> Installing tmux


# ****************************
# ******* ==> Caveats ********
# ****************************

# Example configuration has been installed to:
#   /usr/local/opt/tmux/share/tmux
#
# Bash completion has been installed to:
#   /usr/local/etc/bash_completion.d

# ==> Summary
# 🍺  /usr/local/Cellar/tmux/2.5: 10 files, 660.4KB


# brew install gnupg

# ==> Installing dependencies for gnupg: npth, libgpg-error, libgcrypt, libksba, libassuan, pinentry, adns, libusb

# ==> Installing gnupg dependency: npth
# 🍺  /usr/local/Cellar/npth/1.5: 11 files, 70.6KB

# ==> Installing gnupg dependency: libgpg-error
# 🍺  /usr/local/Cellar/libgpg-error/1.27: 22 files, 559.6KB

# ==> Installing gnupg dependency: libgcrypt
# 🍺  /usr/local/Cellar/libgcrypt/1.8.1: 19 files, 2.6MB

# ==> Installing gnupg dependency: libksba
# 🍺  /usr/local/Cellar/libksba/1.3.5: 13 files, 359.5KB

# ==> Installing gnupg dependency: libassuan
# 🍺  /usr/local/Cellar/libassuan/2.4.3_1: 14 files, 427.2KB

# ==> Installing gnupg dependency: pinentry
# 🍺  /usr/local/Cellar/pinentry/1.0.0: 11 files, 182.9KB

# ==> Installing gnupg dependency: adns
# 🍺  /usr/local/Cellar/adns/1.5.1: 14 files, 602.7KB

# ==> Installing gnupg dependency: libusb
# 🍺  /usr/local/Cellar/libusb/1.0.21: 29 files, 510.5KB


# ==> Installing gnupg

# ****************************
# ******* ==> Caveats ********
# ****************************

# Once you run this version of gpg you may find it difficult to return to using
# a prior 1.4.x or 2.0.x. Most notably the prior versions will not automatically
# know about new secret keys created or imported by this version. We recommend
# creating a backup of your `~/.gnupg` prior to first use.
#
# For full details on each change and how it could impact you please see
#   https://www.gnupg.org/faq/whats-new-in-2.1.html

# ==> Summary
# 🍺  /usr/local/Cellar/gnupg/2.2.1: 132 files, 10.3MB


brew install vim --with-override-system-vi

# 🍺  /usr/local/Cellar/vim/8.0.1100_2: 1,418 files, 22.6MB, built in 1 minute 28 seconds

brew install make


# ****************************
# ******* ==> Caveats ********
# ****************************

# All commands have been installed with the prefix 'g'.
# If you do not want the prefix, install using the "with-default-names" option.
#
# If you need to use these commands with their normal names, you
# can add a "gnubin" directory to your PATH from your bashrc like:
#
#     PATH="/usr/local/opt/make/libexec/gnubin:$PATH"
#
# Additionally, you can access their man pages with normal names if you add
# the "gnuman" directory to your MANPATH from your bashrc as well:
#
#     MANPATH="/usr/local/opt/make/libexec/gnuman:$MANPATH"

# ==> Summary
# 🍺  /usr/local/Cellar/make/4.2.1_1: 15 files, 956KB


brew install nano

# ==> Installing dependencies for nano: ncurses

# ==> Installing nano dependency: ncurses

# ****************************
# ******* ==> Caveats ********
# ****************************

# This formula is keg-only, which means it was not symlinked into /usr/local,
# because macOS already provides this software and installing another version in
# parallel can cause all kinds of trouble.
#
# If you need to have this software first in your PATH run:
#   echo 'export PATH="/usr/local/opt/ncurses/bin:$PATH"' >> ~/.bash_profile
#
# For compilers to find this software you may need to set:
#     LDFLAGS:  -L/usr/local/opt/ncurses/lib
#     CPPFLAGS: -I/usr/local/opt/ncurses/include
# For pkg-config to find this software you may need to set:
#     PKG_CONFIG_PATH: /usr/local/opt/ncurses/lib/pkgconfig

# ==> Summary
# 🍺  /usr/local/Cellar/ncurses/6.0_3: 2,820 files, 8.9MB

# ==> Installing nano
# 🍺  /usr/local/Cellar/nano/2.8.7: 97 files, 2.3MB


brew install git


# ****************************
# ******* ==> Caveats ********
# ****************************

# Bash completion has been installed to:
#   /usr/local/etc/bash_completion.d
#
# zsh completions and functions have been installed to:
#   /usr/local/share/zsh/site-functions
#
# Emacs Lisp files have been installed to:
#   /usr/local/share/emacs/site-lisp/git

# ==> Summary
# 🍺  /usr/local/Cellar/git/2.14.2: 1,486 files, 33.5MB

brew install unzip


# ****************************
# ******* ==> Caveats ********
# ****************************

# This formula is keg-only, which means it was not symlinked into /usr/local,
# because macOS already provides this software and installing another version in
# parallel can cause all kinds of trouble.
#
# If you need to have this software first in your PATH run:
#   echo 'export PATH="/usr/local/opt/unzip/bin:$PATH"' >> ~/.bash_profile

# ==> Summary
# 🍺  /usr/local/Cellar/unzip/6.0_3: 15 files, 356.4KB

brew install make
# Warning: make 4.2.1_1 is already installed

brew install less

# 🍺  /usr/local/Cellar/less/487: 12 files, 332.2KB

brew install openssh

# 🍺  /usr/local/Cellar/openssh/7.5p1_1: 44 files, 4.5MB

brew install awk

# 🍺  /usr/local/Cellar/awk/20121220: 5 files, 159.8KB

brew install jq

# ==> Installing dependencies for jq: oniguruma

# ==> Installing jq dependency: oniguruma
# 🍺  /usr/local/Cellar/oniguruma/6.6.1: 17 files, 1.3MB

# ==> Installing jq
# 🍺  /usr/local/Cellar/jq/1.5_2: 18 files, 958KB

brew install rsync

# ==> Pouring rsync-3.1.2.sierra.bottle.tar.gz
# 🍺  /usr/local/Cellar/rsync/3.1.2: 9 files, 746.9KB

brew install bash

# ==> Installing dependencies for bash: readline

# ==> Installing bash dependency: readline


# ****************************
# ******* ==> Caveats ********
# ****************************

# This formula is keg-only, which means it was not symlinked into /usr/local,
# because macOS provides the BSD libedit library, which shadows libreadline.
# In order to prevent conflicts when programs look for libreadline we are
# defaulting this GNU Readline installation to keg-only..
#
# For compilers to find this software you may need to set:
#     LDFLAGS:  -L/usr/local/opt/readline/lib
#     CPPFLAGS: -I/usr/local/opt/readline/include

# ==> Summary
# 🍺  /usr/local/Cellar/readline/7.0.3_1: 46 files, 1.5MB


# ==> Installing bash

# ****************************
# ******* ==> Caveats ********
# ****************************

# In order to use this build of bash as your login shell,
# it must be added to /etc/shells.

# ==> Summary
# 🍺  /usr/local/Cellar/bash/4.4.12: 146 files, 8.8MB

# bash --version
# GNU bash, version 3.2.57(1)-release (x86_64-apple-darwin16)

# you can put /usr/local/bin/bash here:
sudo nano /etc/shells


# conda usually takes care of this
# brew install sqlite --with-functions --with-session --with-fts --with-dbstat

# ==> ./configure --prefix=/usr/local/Cellar/sqlite/3.20.1 --enable-dynamic-extensions --enable-readline --disable-editline
# SHA256 MISMATCH when --with-docs included

# git clone is preferred here
# brew install bash-git-prompt

# ==> Caveats
# You should add the following to your .bashrc (or equivalent):
#   if [ -f "/usr/local/opt/bash-git-prompt/share/gitprompt.sh" ]; then
#     __GIT_PROMPT_DIR="/usr/local/opt/bash-git-prompt/share"
#     source "/usr/local/opt/bash-git-prompt/share/gitprompt.sh"
#   fi

# ==> Summary
# 🍺  /usr/local/Cellar/bash-git-prompt/2.6.3: 42 files, 99.8KB, built in 2 seconds
