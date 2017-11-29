"                Security:
"----------------------------------

set modelines=0                               " no modelines [http://www.guninski.com/vim1.html]
let g:secure_modelines_verbose=0              " securemodelines vimscript
let g:secure_modelines_modelines = 15         " 15 available modelines


"                Sanity:
"----------------------------------

syntax on
filetype on
filetype plugin indent on                    " load file type plugins + indentation

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

"                Plugins:
"----------------------------------

call plug#begin('~/.vim/plugged')

Plug 'tomasr/molokai'

Plug 'scrooloose/syntastic'
let g:syntastic_error_symbol = '✗'
let g:syntastic_warning_symbol = '!'

Plug 'ctrlpvim/ctrlp.vim'

Plug 'scrooloose/nerdtree'
Plug 'Xuyuanp/nerdtree-git-plugin'
autocmd vimenter * if !argc() | NERDTree | endif " auto open if no file
let NERDTreeIgnore=['\~$', '\.pyc$', '\.swp']
let NERDTreeWinPos="left"
let NERDTreeWinSize=28
nmap <leader>n :NERDTreeToggle<cr>

Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
let g:airline_powerline_fonts=0
let g:airline_theme='molokai'
let g:airline#extensions#tabline#enabled = 1

Plug 'airblade/vim-gitgutter'

" Utilities
Plug 'tpope/vim-eunuch'                      " Gives :SudoWrite
Plug 'tpope/vim-surround'
Plug 'tpope/vim-repeat'
Plug 'editorconfig/editorconfig-vim'
Plug 'ntpeters/vim-better-whitespace'


" filetypes
Plug 'sheerun/vim-polyglot'
Plug 'ekalinin/Dockerfile.vim'
Plug 'alunny/pegjs-vim'

call plug#end()

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
if exists('+colorcolumn')                                                                      
  set colorcolumn=81                           " A line at 81 characters                       
  hi ColorColumn ctermbg=black guibg=#232728                                                   
endif  

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
" nvim and vim has icompatible format?
if !has('nvim')
  set viminfo+=n~/.vim/viminfo
else
  set viminfo+=n~/.vim/nviminfo
endif

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

