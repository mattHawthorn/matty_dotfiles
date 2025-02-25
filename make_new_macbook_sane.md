# How to make a new Macbook sane:

1. install Xcode:
	
	`xcode-select --install`

2. re-map keys:
    
    1. Internal
        - left_control -> fn
        - fn -> left_control
        - right option -> right control
    2. External
        - option/alt -> command
        - command -> option/alt

3. install homebrew:

    `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`

4. install latest bash and gnutils:

	```bash
	brew install bash gnu-which gnu-tar gnu-sed awk less grep wget \
         coreutils findutils binutils diffutils \
         watch tree tmux rsync gzip unzip git make nano jq
    ```

5. install bash-git-prompt:

	`git clone https://github.com/magicmonty/bash-git-prompt.git ~/.bash-git-prompt --depth=1`

6. install iterm:

	[https://www.iterm2.com/](https://www.iterm2.com/)

7. configure default shell to latest bash:

	`echo '/usr/local/bin/bash' >> /etc/shells && chsh -s /usr/local/bin/bash`

8. install custom dotfiles and bash helpers (links brew-installed utils to their correct names via scripts/homebrew_setup.sh):

	`cd ~ && mkdir git && cd git && git clone https://github.com/mattHawthorn/matty_dotfiles.git && cd matty_dotfiles && source scripts/homebrew_setup.sh && ./install.sh`

9. install PyCharm, Anaconda
