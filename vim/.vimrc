"                Security:
"----------------------------------

set modelines=0                               " no modelines [http://www.guninski.com/vim1.html]
let g:secure_modelines_verbose=0              " securemodelines vimscript
let g:secure_modelines_modelines = 15         " 15 available modelines

"                Bundle:
"----------------------------------

" NeoBundle auto-installation and setup {{{

" Auto installing NeoBundle
let iCanHazNeoBundle=1
let neobundle_readme=expand($HOME.'/.vim/bundle/neobundle.vim/README.md')
if !filereadable(neobundle_readme)
    echo "Installing NeoBundle.."
    echo ""
    silent !mkdir -p $HOME/.vim/bundle
    silent !git clone https://github.com/Shougo/neobundle.vim $HOME/.vim/bundle/neobundle.vim
    let iCanHazNeoBundle=0
endif


" Call NeoBundle
if has('vim_starting')
    set rtp+=$HOME/.vim/bundle/neobundle.vim/
endif
call neobundle#begin(expand('~/.vim/bundle/'))

" is better if NeoBundle rules NeoBundle (needed!)
NeoBundleFetch 'Shougo/neobundle.vim'
" }}}

"essential
NeoBundle 'tomasr/molokai'
"Bundle 'Lokaltog/powerline', {'rtp': 'powerline/bindings/vim/'}
NeoBundle 'vim-airline/vim-airline'
NeoBundle 'vim-airline/vim-airline-themes'
NeoBundle 'scrooloose/nerdtree'
NeoBundle 'ervandew/supertab'
NeoBundle 'scrooloose/syntastic'
NeoBundle 'editorconfig/editorconfig-vim'

"git
NeoBundle 'mattn/gist-vim'
NeoBundle 'tpope/vim-fugitive'
NeoBundle 'airblade/vim-gitgutter'

"python
NeoBundle 'ehamberg/vim-cute-python'
NeoBundle 'jmcantrell/vim-virtualenv'

"html5 (css, js, html)
NeoBundle 'ap/vim-css-color'
NeoBundle 'othree/html5.vim'
NeoBundle 'cakebaker/scss-syntax.vim'
NeoBundle 'vim-scripts/JSON.vim'
NeoBundle 'mattn/emmet-vim'
NeoBundle 'groenewege/vim-less'

NeoBundle 'ekalinin/Dockerfile.vim'

call neobundle#end()

syntax on
filetype on
filetype plugin indent on                    " load file type plugins + indentation

NeoBundleCheck
"                Sanity:
"----------------------------------

set nocompatible
set encoding=utf-8
set fileencodings=utf-8
set backspace=indent,eol,start               " backspace over all kinds of things
set noautowrite                              " don't automagically write on :next
set autoindent smartindent copyindent        " auto/smart indent
set smarttab                                 " tab and backspace are smart
set undolevels=1000                          " 1000 undos
set undofile                                 " undo after exit, <filename>.un~


set scrolloff=3                              " keep at least 3 lines above/below
set sidescrolloff=5                          " keep at least 5 lines left/right

"               Keybindings:
"----------------------------------
let mapleader = ","

" norwegian oe is :
nnoremap <Char-248> :
vnoremap <Char-248> :

set pastetoggle=<F2>                         " paste with F2

" forgetting to leave insertmode
imap jj <Esc>
imap kkk <Esc>

" It's 2012.
noremap j gj
noremap k gk
noremap gj j
noremap gk k

" window movement
no <C-L> <C-W>l
no <C-H> <C-W>h
no <C-J> <C-W>j
no <C-K> <C-W>k

"i accidentally  F1  too much
inoremap <F1> <ESC>
nnoremap <F1> <ESC>
vnoremap <F1> <ESC>

"tab movement
map <S-h> gT
map <S-l> gt

" Y and D behaves
nnoremap D d$
nnoremap Y y$

" sudo write
cmap w!! w !sudo tee % >/dev/null

iabbrev ldis ಠ_ಠ
iabbrev levi 😈

"                Search:
"----------------------------------

set incsearch                                " incremental search
set ignorecase                               " search ignoring case
set smartcase                                " Ignore case when searching lowercase
set hlsearch                                 " highlight the search
set showmatch                                " show matching bracket
set diffopt=filler,iwhite                    " ignore all whitespace and sync

" regex search, the default is sort of broken
nnoremap / /\v
vnoremap / /\v

noremap <silent> <leader><space> :noh<cr>:call clearmatches()<cr>

"                Style:
"----------------------------------

colorscheme molokai
set ruler                                    " show the line number on the bar
set nonu                                     " no linenumbers
set visualbell t_vb=                         " Disable ALL bells
set noerrorbells                             " no error bells please
set t_Co=256                                 " 256 colors
set cursorline                               " mark current line with a line
set laststatus=2
set noshowmode                               " Hide the default mode text

" space as vertical character
set fcs+=vert:\ 

" colorcolumn
set colorcolumn=+1                           " A line at 85 characters
hi ColorColumn ctermbg=black guibg=#232728

" Show special characters (tab and eol)
" set list
set listchars=tab:▸\ ,eol:¬
highlight NonText guifg=#4a4a59
highlight SpecialKey guifg=#4a4a59
augroup trailing " do not show tailing whitespace in insertmode
    au!
    au InsertEnter * :set listchars-=trail:⌴
    au InsertLeave * :set listchars+=trail:⌴
augroup END

"                Plugins:
"----------------------------------

" Nerdtree
autocmd vimenter * if !argc() | NERDTree | endif " auto open if no file
let NERDTreeIgnore=['\~$', '\.pyc$', '\.swp']
let NERDTreeWinPos="left"
let NERDTreeWinSize=28
nmap <leader>n :NERDTreeToggle<cr>

let g:airline_powerline_fonts=0
let g:airline_theme='molokai'
let g:airline#extensions#tabline#enabled = 1

let g:syntastic_error_symbol = '✗'
let g:syntastic_warning_symbol = '!'

"                Other:
"----------------------------------

" Always jump to last known cursor pos
if has("autocmd")
  autocmd BufReadPost *
    \ if line("'\"") > 0 && line("'\"") <= line("$") |
    \   exe "normal g`\"" |
    \ endif
endif " has("autocmd")


"         Tempfiles:
"----------------------------------

" Save your backups to a less annoying place than the current directory.
" If you have .vim-backup in the current directory, it'll use that.
" Otherwise it saves it to ~/.vim/backup or . if all else fails.
if isdirectory($HOME . '/.vim/backup') == 0
  silent !mkdir -p ~/.vim/backup >/dev/null 2>&1
endif
set backupdir-=.
set backupdir+=.
set backupdir-=~/
set backupdir^=~/.vim/backup/
set backupdir^=./.vim-backup/
set backup
" Prevent backups from overwriting each other. The naming is weird,
" since I'm using the 'backupext' variable to append the path.
" So the file '/home/docwhat/.vimrc' becomes '.vimrc%home%docwhat~'
if has("autocmd")
  autocmd BufWritePre * nested let &backupext = substitute(expand('%:p:h'), '/', '%', 'g') . '~'
endif


if has("macunix")
  set backupskip+=/private/tmp/*
endif

" Save your swp files to a less annoying place than the current directory.
" If you have .vim-swap in the current directory, it'll use that.
" Otherwise it saves it to ~/.vim/swap, ~/tmp or .
if isdirectory($HOME . '/.vim/swap') == 0
  silent !mkdir -p ~/.vim/swap >/dev/null 2>&1
endif
set directory=./.vim-swap//
set directory+=~/.vim/swap//
set directory+=~/tmp//
set directory+=.

" viminfo stores the the state of your previous editing session
set viminfo+=n~/.vim/viminfo
set viminfo^=!

if exists("+undofile")
  " undofile - This allows you to use undos after exiting and restarting
  " This, like swap and backups, uses .vim-undo first, then ~/.vim/undo
  " :help undo-persistence
  " This is only present in 7.3+
  if isdirectory($HOME . '/.vim/undo') == 0
    silent !mkdir -p ~/.vim/undo > /dev/null 2>&1
  endif
  set undodir=./.vim-undo//
  set undodir+=~/.vim/undo//
  set undofile
  set undolevels=1000         " maximum number of changes that can be undone
  set undoreload=10000        " maximum number lines to save for undo on a buffer reload
endif
