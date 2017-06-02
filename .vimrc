set nocompatible              " required
filetype off                  " required

set splitbelow
set splitright

"split navigations
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

" Enable folding
set foldmethod=indent
set foldlevel=99

" line numbers on left side
set nu

" Enable folding with the spacebar
nnoremap <space> za

" Python style spacing
au BufNewFile,BufRead *.py
    \ set tabstop=4
    \ set softtabstop=4
    \ set shiftwidth=4
    \ set textwidth=79
    \ set expandtab
    \ set autoindent
    \ set fileformat=unix

" web programming spacing conventions
au BufNewFile,BufRead *.js, *.html, *.css
    \ set tabstop=2
    \ set softtabstop=2
    \ set shiftwidth=2

" remove extraneous whitspace
au BufRead,BufNewFile *.py,*.pyw,*.c,*.h match BadWhitespace /\s\+$/

" for Python 3
set encoding=utf-8


" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

"python with virtualenv support
py << EOF
import os
import sys
if 'VIRTUAL_ENV' in os.environ:
  project_base_dir = os.environ['VIRTUAL_ENV']
  activate_this = os.path.join(project_base_dir, 'bin/activate_this.py')
  execfile(activate_this, dict(__file__=activate_this))
EOF


" Python autocomplete
Bundle 'Valloric/YouCompleteMe'

" YouCompleteMe config: make autocomplete go away when you're done with it
let g:ycm_autoclose_preview_window_after_completion=1
map <leader>g  :YcmCompleter GoToDefinitionElseDeclaration<CR>

" let Vundle manage Vundle, required
Plugin 'gmarik/Vundle.vim'
" rational folding
Plugin 'tmhedberg/SimpylFold'
" syntax checking
Plugin 'scrooloose/syntastic'
" powerline: status bar that tells you your virtualenv, git branch, files
" being edited, etc.
Plugin 'Lokaltog/powerline', {'rtp': 'powerline/bindings/vim/'}
" PEP8 checking
Plugin 'nvie/vim-flake8'

" Pretty Python code
let python_highlight_all=1
syntax on

" Nice colors
Plugin 'jnurmine/Zenburn'
Plugin 'altercation/vim-colors-solarized'

set t_Co=256

" set the default color scheme
" zenburn is fancy, but I've found slate to be more color-blind friendly
" (bolder without being harsh)
if has('gui_running')
  set background=dark
  colorscheme solarized
else
  colorscheme slate
endif

" fast color scheme toggling
" call togglebg#map("<F5>")


" Add all your plugins here (note older versions of Vundle used Bundle instead of Plugin)


" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required

