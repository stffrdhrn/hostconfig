" .VImrc
" Stafford Horne

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

"
set background=dark
set showmatch
set nowrap

"set cindent
"set cino=>5n-3f0^-2{2
set ts=8
set sw=3
set sts=8
set expandtab

set showmode
set showcmd
 
set laststatus=2

set hlsearch 
set statusline=%f\ %h%m%r\ %-20.(line=%l,col=%c,totlin=%L%)%=[0x%B][#%n][%Y]%p%%
