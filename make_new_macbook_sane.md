# How to make a new Macbook sane:

1. install Xcode:
	
	`xcode-select --install`

2. install Karabiner:

	[https://pqrs.org/osx/karabiner/](https://pqrs.org/osx/karabiner/)

3. re-map keys:

	- left_control -> fn
	- fn -> left_control
	- right option -> right control

4. install homebrew:

    `/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"`

5. install latest bash and gnutils:

	`brew install bash gnu-which gnu-tar gnu-which gnu-sed awk coreutils gzip grep rsync`

6. install bash-git-prompt:

	`git clone https://github.com/magicmonty/bash-git-prompt.git ~/.bash-git-prompt --depth=1`

7. install iterm:

	[https://www.iterm2.com/](https://www.iterm2.com/)

8. configure default shell to latest bash:

	`echo '/usr/local/bin/bash' >> /etc/shells && chsh -s /usr/local/bin/bash`

8. install custom dotfiles and bash helpers (links brew-installed utils to their correct names via scripts/homebrew_setup.sh):

	`cd ~ && mkdir git && cd git && git clone https://github.com/mattHawthorn/matty_dotfiles.git && cd matty_dotfiles && source scripts/homebrew_setup.sh && ./install.sh`
