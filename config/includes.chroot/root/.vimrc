""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Solarized syntax highlighting

syntax enable
set background=dark
set t_Co=16

" The below is not needed if the terminal colors are set properly
" colorscheme solarized

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Settings for Vim inside IRB

if has("autocmd")
  " Enable filetype detection
  filetype plugin indent on
 
  " Restore cursor position
  autocmd BufReadPost *
    \ if line("'\"") > 1 && line("'\"") <= line("$") |
    \   exe "normal! g`\"" |
    \ endif
endif
if &t_Co > 2 || has("gui_running")
  " Enable syntax highlighting
  syntax on
endif

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Tab completion
function! Tab_Or_Complete()
   if col('.')>1 && strpart( getline('.'), col('.')-2, 3 ) =~ '^\w'
      return "\<C-X>\<C-O>"
   else
      return "\<Tab>"
   endif
endfunction

inoremap <Tab> <C-R>=Tab_Or_Complete()<CR>
set omnifunc=syntaxcomplete#Complete
set complete=".,w,b,u,t,i,k"
set completeopt=longest,menuone
set dictionary-=/usr/share/dict/words dictionary+=/usr/share/dict/words

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Enable filetype plugins
filetype plugin on
filetype indent on

" Keep the cursor vertically in the center of the screen
set scrolloff=80

" Always show the current position
set ruler

" Ignore case while searching
set ignorecase

" Highlight search results
set hlsearch

" Highlight search as it is typed
set incsearch

" Don't redraw while executing macros (Performance)
set lazyredraw

" Regular expressions
set magic

" Show matching brackets
set showmatch

" How many tenths of a second to blink when matching brackets
set mat=2

" No bells on error
set noerrorbells
set novisualbell
set t_vb=
set tm=500

" Set unix as the standard line ending
set fileformats=unix,dos

" Use spaces instead of tabs
set expandtab

" Use smart tabs
set smarttab

" 1 tab is 3 spaces
set shiftwidth=3
set tabstop=3
set shiftwidth=3

" Show line numbers
set number

" Use vim defaults
set nocompatible

" Show the cursor position at all times
set ruler

" Turn on autoindenting
set autoindent
set copyindent

" Shift-Tab
nmap <S-Tab> <<
imap <S-Tab> <Esc><<i

