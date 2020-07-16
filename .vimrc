" be iMproved, required
set nocompatible
" required
filetype off
" No error bells
set noerrorbells


" --- PLUGINS start ---
" Specify a directory for plugins
" - For Neovim: stdpath('data') . '/plugged'
" - Avoid using standard Vim directory names like 'plugin'
call plug#begin('~/.vim/plugged')

" Make sure you use single quotes
" Colorscheme
Plug 'morhetz/gruvbox'
" Asynchronous Lint Engine
Plug 'dense-analysis/ale'
" COC autocompletion
Plug 'neoclide/coc.nvim', {'branch': 'release'}
" NERD commenting
Plug 'preservim/nerdcommenter'
" CSV syntax
Plug 'mechatroner/rainbow_csv'
" Colorize hex values
Plug 'chrisbra/Colorizer'
" NERDTree file browser
Plug 'preservim/nerdtree'
" NERDTree git integration
Plug 'Xuyuanp/nerdtree-git-plugin'
" Show git in gutter
Plug 'airblade/vim-gitgutter'
" Status bar plugin styling
Plug 'vim-airline/vim-airline'
" Plugin 'vim-airline/vim-airline-themes'
" Auto pair tagging
Plug 'jiangmiao/auto-pairs'
" Surround with quotes or whatnot
Plug 'tpope/vim-surround'
" Undo tree
Plug 'mbbill/undotree'
" Live html, css, and js
Plug 'turbio/bracey.vim'
" Auto close (x)html
Plug 'alvan/vim-closetag'
" Initialize plugin system
call plug#end()
" --- PLUGIN end ---


" filetype plugin indent on
" show existing tab with 4 spaces width
set tabstop=4
" when indenting with '>', use 4 spaces width
set shiftwidth=4
" On pressing tab, insert 4 spaces
set expandtab

au BufNewFile,BufRead *.js, *.html, *.css
    \ set tabstop=2 |
    \ set softtabstop=2 |
    \ set shiftwidth=2


" --- PYTHON start ---
au BufNewFile,BufRead *.py
    \ set tabstop=4 |
    \ set softtabstop=4 |
    \ set shiftwidth=4 |
    "\ set textwidth=79 |
    \ set expandtab |
    \ set autoindent |
    \ set fileformat=unix

"utf-8 encoding
set encoding=utf-8


"pretty python code
let python_highlight_all=1

"python with virtualenv support
py3 << EOF
import os
import sys
if 'VIRTUAL_ENV' in os.environ:
  project_base_dir = os.environ['VIRTUAL_ENV']
  activate_this = os.path.join(project_base_dir, 'bin/activate_this.py')
  exec(open(activate_this).read(), dict(__file__=activate_this))
EOF

" Run python with F9
autocmd FileType python map <buffer> <F9> :w<CR>:exec '!python3' shellescape(@%, 1)<CR>
autocmd FileType python imap <buffer> <F9> <esc>:w<CR>:exec '!python3' shellescape(@%, 1)<CR>
" --- PYTHON end ---


" --- VISUAL start ---
" Set color scheme
" colorscheme molokai
let g:gruvbox_contrast_dark='hard'
set background=dark
colorscheme gruvbox
" Show hybrid absolute/realtive line numbers
set number relativenumber
" Relative off when in insert mode
augroup numbertoggle
  autocmd!
  autocmd BufEnter,FocusGained,InsertLeave * set relativenumber
  autocmd BufLeave,FocusLost,InsertEnter   * set norelativenumber
augroup END
" Enable syntax highlighting
syntax enable
" Show leader when activated
set showcmd
" " Use terminal colors
set termguicolors
" Incremental search
set incsearch

let g:airline_powerline_fonts = 1
" Pmenu colors
hi Pmenu ctermfg=NONE ctermbg=236 cterm=NONE guifg=NONE guibg=#64666d gui=NONE
hi PmenuSel ctermfg=NONE ctermbg=24 cterm=NONE guifg=NONE guibg=#204a87 gui=NONE
" --- VISUAL end ---


" --- PLUGIN alterations start ---
" NERDTree specific settings
map <C-n> :NERDTreeToggle<CR>
" Close if only window open
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
" Show dot files automatically
let NERDTreeShowHidden=1

" NERDcommenter
" Add spaces after comment delimiters by default
let g:NERDSpaceDelims = 1

" Gitgutter settings
let g:gitgutter_async=0
let g:gitgutter_enabled = 1
let g:gitgutter_map_keys = 0
highlight clear SignColumn
highlight GitGutterAdd ctermfg=2
highlight GitGutterChange ctermfg=3
highlight GitGutterDelete ctermfg=1
highlight GitGutterChangeDelete ctermfg=4
" Change line number coloring to grey
highlight LineNr ctermfg=grey

" COC
" use <tab> for trigger completion and navigate to the next complete item
function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~ '\s'
endfunction

inoremap <silent><expr> <Tab>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<Tab>" :
      \ coc#refresh()
" Use <Tab> and <S-Tab> to navigate the completion list
inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
" Use <cr> to confirm completion
inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
" To make <cr> select the first completion item and confirm the completion when no item has been selected
inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm() : "\<C-g>u\<CR>"
" To make coc.nvim format your code on <cr>, use keymap
inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm() : "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"
" Close the preview window when completion is done
autocmd! CompleteDone * if pumvisible() == 0 | pclose | endif

" ALE
" Check Python files with flake8 and pylint
let b:ale_linters = {'python': ['flake8', 'pylint']}
" Fix Python files with black and iSort
let b:ale_fixers = {
\    '*': ['remove_trailing_lines', 'trim_whitespace'],
\    'python': ['black', 'isort'],
\}
let g:ale_python_flake8_options = "--ignore=E501"
let g:ale_python_pylint_options = "--disable=C0301,C0103,const-name-hint"
let g:ale_fix_on_save = 1

" Colorizer
" Turn on for specific filetypes
let g:colorizer_auto_filetype='css,sass,html'
" Skip coloring comments
let g:colorizer_skip_comments = 1

" Undotree
" remap to F5
nnoremap <F5> :UndotreeToggle<cr>
" --- PLUGIN alterations end ---


" --- REMAPS start ---
" Change leader to space
nnoremap <SPACE> <Nop>
let mapleader=" "
" Split navigation
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>
" Split creation
nnoremap <leader>h :split<Space>
nnoremap <leader>v :vsplit<Space>
" enable mouse use
set mouse=a
" indent/unindent with tab/shift-tab
nmap <Tab> >>
imap <S-Tab> <Esc><<i
nmap <S-tab> <<
" --- REMAPS end ---


" use system clipboard
set clipboard=unnamed
set smartindent
set autoindent
