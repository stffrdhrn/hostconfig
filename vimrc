" .VImrc
" Stafford Horne

" Make vim more like vim and not vi
set nocompatible

" Switch syntax highlighting on, when the terminal has colors
" Also switch on highlighting the last used search pattern.
if &t_Co > 2 || has("gui_running")
  syntax on
  set hlsearch
endif

filetype plugin on

if &term=="xterm"
     set t_Co=8
     set t_Sb=[4%dm
     set t_Sf=[3%dm
endif

" GNU guidelines
set textwidth=75
set colorcolumn=75

" Allow recusrive search of filenames
set path+=**

" Set path for searching tags, i.e. use ^] to find them
" GTAGS not compatible use ctags...
" set tags+=./GTAGS

set background=dark
set showmatch
set nowrap

set tabstop=8      " (ts) width that tab is displayed as
set shiftwidth=4   " (sw) width in spaces used in autoindent and >> <<
"set softtabstop=8 " (sts) makes spaces feel like tabs
"set expandtab      " (et) expand tabs to spaces

set showmode
set showcmd
set laststatus=2

set statusline=%f\ %h%m%r\ %-20.(line=%l,col=%c,totlin=%L%)%=[0x%B][#%n][%Y]%p%%

" Some useful mappings
map \s oSigned-off-by: Stafford Horne <shorne@gmail.com><CR><ESC>
