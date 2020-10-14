" be iMproved, required
    set nocompatible
" required
    filetype off
" for VimWiki
    " filetype plugin on
    filetype plugin indent on
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
    " Tab highlighting
        Plug 'nathanaelkane/vim-indent-guides'
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
    " Undo tree
        Plug 'mbbill/undotree'
    " Status bar plugin styling
        Plug 'vim-airline/vim-airline'
        " Plug 'vim-airline/vim-airline-themes'
    " Auto pair tagging
        Plug 'jiangmiao/auto-pairs'
    " Surround with quotes or whatnot
        " Plug 'tpope/vim-surround'
        Plug 'machakann/vim-sandwich'
    " Live html, css, and js
        Plug 'turbio/bracey.vim'
    " Auto close (x)html
        Plug 'alvan/vim-closetag'
    " Jinja syntax hylighting
        Plug 'lepture/vim-jinja'
    " Vim Markdown
        " Plug 'godlygeek/tabular'
        Plug 'plasticboy/vim-markdown'
    " Vim table mode for tale creation/editing
        Plug 'dhruvasagar/vim-table-mode'
    " Markdown preview
        Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install() }, 'for': ['markdown', 'vim-plug']}
    " VimWiki for notes and what notes
        " Plug 'vimwiki/vimwiki'
    " post install (yarn install | npm install) then load plugin only for editing supported files
        Plug 'prettier/vim-prettier', {
          \ 'do': 'yarn install',
          \ 'for': ['javascript', 'typescript', 'css', 'less', 'scss', 'json', 'graphql', 'markdown', 'vue', 'yaml', 'html'] }
    " For REPL
        Plug 'jpalardy/vim-slime'
    " Quickscope f/t highlighting
        Plug 'unblevable/quick-scope'
    " Initialize plugin system
    call plug#end()
" --- PLUGIN end ---


" show existing tab with 4 spaces width
    set tabstop=4
" when indenting with '>', use 4 spaces width
    set shiftwidth=4
" On pressing tab, insert 4 spaces
    set expandtab
" make backspace work like most other programs
    set backspace=2

    " au BufNewFile,BufRead *.js, *.html, *.css
    "     \ set tabstop=2 |
    "     \ set softtabstop=2 |
    "     \ set shiftwidth=2


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
    autocmd FileType python map <buffer> <F9> :w<CR>:exec '!clear; python3' shellescape(@%, 1)<CR>
    autocmd FileType python imap <buffer> <F9> <esc>:w<CR>:exec '!clear; python3' shellescape(@%, 1)<CR>
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
    " Use terminal colors
        set termguicolors
    " Incremental search
        set incsearch

        let g:airline_powerline_fonts = 1
    " Pmenu colors
        hi Pmenu ctermfg=NONE ctermbg=236 cterm=NONE guifg=NONE guibg=#64666d gui=NONE
        hi PmenuSel ctermfg=NONE ctermbg=24 cterm=NONE guifg=NONE guibg=#204a87 gui=NONE
" --- VISUAL end ---


" --- PLUGIN alterations start ---
    " Vim-Prettier running before save async
        let g:prettier#autoformat = 0
        autocmd BufWritePre *.js,*.jsx,*.mjs,*.ts,*.tsx,*.css,*.less,*.scss,*.json,*.graphql,*.md,*.vue,*.yaml PrettierAsync
        " autocmd BufWritePre *.jsx,*.mjs,*.ts,*.tsx,*.css,*.less,*.scss,*.json,*.graphql,*.md,*.vue,*.yaml PrettierAsync

    " Tab highlighting
        let g:indent_guides_enable_on_vim_startup = 1

    " NERDTree specific settings
        map <C-n> :NERDTreeToggle<CR>
    " Close if only window open
        autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
    " Show dot files automatically
        let NERDTreeShowHidden=1
    " Add spaces after comment delimiters by default
        let g:NERDSpaceDelims = 1
    " Align line-wise comment delimiters flush left instead of following code indentation
        let g:NERDDefaultAlign = 'left'

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
    " Map jinja to html
        let g:coc_filetype_map = {
        \ 'jinja.html': 'html',
        \}

    " ALE
    " Check Python files with flake8 and pylint
        let g:ale_linters = {'python': ['flake8', 'pylint']}
    " Fix Python files with black and iSort
        let g:ale_fixers = {
        \   '*': ['remove_trailing_lines', 'trim_whitespace'],
        \   'python': ['black', 'isort'],
        \   'html': ['html-beautify'],
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

    " Vim-Slime
        let g:slime_target = "tmux"
        let g:slime_paste_file = "$HOME/.slime_paste"
        let g:slime_default_config = {"socket_name": "default", "target_pane": "{right-of}"}

    " Quickscope
    " Trigger a highlight in the appropriate direction when pressing these keys:
        let g:qs_highlight_on_keys = ['f', 'F', 't', 'T']

    " vim-markdown
        " Spellcheck on for markdown
            autocmd BufRead,BufNewFile *.md setlocal spell
            set spelllang=en
        " disable vim-markdown fold method for vimwiki file type
            " au Filetype vimwiki let g:vim_markdown_folding_disabled = 1
        " set conceal for markdown to hide link and italics
            au Filetype markdown set conceallevel=2
            " au BufNewFile ~/Documents/VimWiki/Work/*/Meeting_Notes/* execute 'file' fnameescape(strftime("%Y-%m-%d.md"))
            au BufNewFile ~/Documents/VimWiki/Work/*/Meeting_Notes/*.md :silent 0r !~/.vim/bin/generate-vimwiki-meeting_notes-template.py '%'
" --- PLUGIN alterations end ---


" --- CUSTOM commands start ---
    " Save a file with time stamp
        function! SaveWithTS(filename) range
            let l:extension = '.' . fnamemodify( a:filename, ':e' )
            if len(l:extension) == 1
                let l:extension = '.md'
            endif
            let l:filename = escape( fnamemodify(a:filename, ':r') . strftime("_%Y-%m-%d") . l:extension, ' ' )
            execute "write " . l:filename
        endfunction
        command! -nargs=1 SWT call SaveWithTS( <q-args> ) " Use :SWT filename.extension
" --- CUSTOM commands end ---


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
    " Save with leader S
        noremap <Leader>s :update<CR>
    " Edit vimr configuration file
        nnoremap <Leader>ve :e $MYVIMRC<CR>
    " Reload vimr configuration file
        nnoremap <Leader>vr :source $MYVIMRC<CR>
    " Open notes index file
        nnoremap <Leader>ww :e ~/Documents/VimWiki/index.md<CR>
    " enable mouse use
        set mouse=a
    " indent/unindent with tab/shift-tab
        " nmap <Tab> >>
        " imap <S-Tab> <Esc><<i
        " nmap <S-tab> <<
" --- REMAPS end ---


" use system clipboard
    set clipboard=unnamed
    set smartindent
    set autoindent
" automatically set working directory to current file location
    set autochdir
" Set foldmethod for all files
    set foldenable
    set foldmethod=indent
    set foldlevel=1
" Searches with no capitals are case insensitive, searches will caps are
    set smartcase
    set ignorecase
