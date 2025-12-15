"colorscheme ron
"set dictionary-=~/.vim/funclist.txt

"本配置和注释主要来源于<<Vim 实用技术，第 3 部分: 定制 Vim>>----http://www.ibm.com/developerworks/cn/linux/l-tip-vim3/
"整理:陈刚 ( http://www.chengang.com.cn )

"注释。其中包含一个模式行
" vim:shiftwidth=2:tabstop=8:expandtab

"判断系统是否具有“自动命令”（autocmd）的支持
if has('autocmd')
  "清除所有的自动命令，以方便调试
  au!
  "对于后缀为“.asm”的文件，认为其是微软的 Macro Assembler 格式
  au BufNewFile,BufReadPre *.asm let b:asmsyntax='masm'
endif

"当使用了图形界面时，确保所有的文件类型会在菜单“语法”（“Syntax”）下出现，而不是出现一个菜单项“Show filetypes in menu”。缺省行为可以让 Vim 启动得更快一点点。
if has('gui_running')
  let do_syntax_sel_menu=1
  colorscheme vividchalk
endif

"当使用了图形界面，并且环境变量 LANG 中不含“.”（即没有规定编码）时，把 Vim 的内部编码设为 UTF-8
if has('gui_running') && $LANG !~ '\.'
  set encoding=utf-8
endif

"不需要保持和 vi 非常兼容
set nocompatible
"执行 Vim 缺省提供的 .vimrc 文件的示例，包含了打开语法加亮显示等最常用的功能
source $VIMRUNTIME/vimrc_example.vim

"打开自动缩进
set autoindent
"显示行号（否：nonumber）
set number
"不自动换行(否：wrap)
"set nowrap
"缺省不产生备份文件
set nobackup
"在输入括号时光标会短暂地跳到与之相匹配的括号处，不影响输入
set showmatch
"正确地处理中文字符的折行和拼接
set formatoptions+=mM
"可自动识别的文件类型为带 BOM 字符的 Unicode 文件、UTF-8 编码的文件和 GBK 编码的文件
set fileencodings=ucs-bom,utf-8,gbk
"设置状态行，使其能额外显示文件的编码信息
set statusline=%<%f\ %h%m%r%=%k[%{(&fenc==\"\")?&enc:&fenc}%{(&bomb?\",BOM\":\"\")}]\ %-14.(%l,%c%V%)\ %P
"如果该 Vim 支持鼠标，则启用鼠标支持
if has('mouse')
  set mouse=a
endif
"判断 Vim 是否包含多字节语言支持，并且版本号大于 6.1
if has('multi_byte') && v:version > 601
  "如果 Vim 的语言（受环境变量 LANG 影响）是中文（zh）、日文（ja）或韩文（ko）的话，将模糊宽度的 Unicode 字符的宽度设为双宽度（double）
  if v:lang =~? '^\(zh\)\|\(ja\)\|\(ko\)'
    set ambiwidth=double
  endif
endif


"一些适用于文本模式运行的 Vim 的设定
if !has('gui_running')
   "将变量 Tlist_Inc_Winwidth 的值设为 0，防止 taglist 插件改变终端窗口的大小（有些情况下会引起系统不稳定）。使用“has('eval')”是让该语句仅在功能较为完整、至少支持表达式的 Vim 版本中运行。
  if has('eval')
    let Tlist_Inc_Winwidth=0
  endif

  "在系统支持 wildmenu 特性启用文本模式的菜单
  if has('wildmenu')
    set wildmenu  "打开 wildmenu 选项，启动具有菜单项提示的命令行自动完成。
    set cpoptions-=<    "确保字符序列“<C-Z>”被理解为 Ctrl-Z 而不是分开的五个字符
    set wildcharm=<C-Z>   "设置使用 Ctrl-Z 激活自动完成提示
    "把正常模式和插入模式下的 F10 映射成执行菜单项，再按Tab键会自动提示菜单内容。
    nmap <F10>        :emenu <C-Z>
    imap <F10>   <C-O>:emenu <C-Z>
  endif
endif

"使用自动命令（autocmd）特性的设置。定义了若干个下面的自动命令会用到的函数。每个“function”之后都用了一个“!”这也是为了方便调试，让“source ~/.vimrc”能正确运行而不会报告函数已定义的错误
if has('autocmd')
  function! SetFileEncodings(encodings)
    let b:my_fileencodings_bak=&fileencodings
    let &fileencodings=a:encodings
  endfunction

  function! RestoreFileEncodings()
    let &fileencodings=b:my_fileencodings_bak
    unlet b:my_fileencodings_bak
  endfunction

  function! CheckFileEncoding()
    if &modified && &fileencoding != ''
      exec 'e! ++enc=' . &fileencoding
    endif
  endfunction

  function! ConvertHtmlEncoding(encoding)
    if a:encoding ==? 'gb2312'
      return 'gbk'              " GB2312 imprecisely means GBK in HTML
    elseif a:encoding ==? 'iso-8859-1'
      return 'latin1'           " The canonical encoding name in Vim
    elseif a:encoding ==? 'utf8'
      return 'utf-8'            " Other encoding aliases should follow here
    else
      return a:encoding
    endif
  endfunction

  function! DetectHtmlEncoding()
    if &filetype != 'html'
      return
    endif
    normal m`
    normal gg
    if search('\c<meta http-equiv=\("\?\)Content-Type\1 content="text/html; charset=[-A-Za-z0-9_]\+">') != 0
      let reg_bak=@"
      normal y$
      let charset=matchstr(@", 'text/html; charset=\zs[-A-Za-z0-9_]\+')
      let charset=ConvertHtmlEncoding(charset)
      normal ``
      let @"=reg_bak
      if &fileencodings == ''
        let auto_encodings=',' . &encoding . ','
      else
        let auto_encodings=',' . &fileencodings . ','
      endif
      if charset !=? &fileencoding &&
         \(auto_encodings =~ ',' . &fileencoding . ',' || &fileencoding == '')
        silent! exec 'e ++enc=' . charset
      endif
    else
      normal ``
    endif
  endfunction

  function! GnuIndent()
    setlocal cinoptions=>8,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1
    setlocal shiftwidth=2
    setlocal tabstop=8
  endfunction

"只要没有将环境变量 VIM_HATE_SPACE_ERRORS 的值设为零，则把变量 c_space_errors 的值设为 1——效果是在 C/C++ 代码中“不正确”的空白字符（行尾的空白字符和紧接在制表符之前的空格字符）将会被高亮显示。
  function! RemoveTrailingSpace()
    if $VIM_HATE_SPACE_ERRORS != '0' &&
          \(&filetype == 'c' || &filetype == 'cpp' || &filetype == 'vim')
      normal m`
      silent! :%s/\s\+$//e
      normal ``
    endif
  endfunction

  if $VIM_HATE_SPACE_ERRORS != '0'
    let c_space_errors=1
  endif

  "使用的英文拼写变体为加拿大风格，即使用拼写“abridgement”（而不是“abridgment”）、“colour”（而不是 “color”）等，比较符合中国人一般的英语教科书中的拼写方式，也比较适合于写“国际”英语。
  let spchkdialect='can'

  "使用键盘映射“\a”来查看光标下字符的属性，主要用于调试 Vim 的语法文件。
  map <Leader>a :call SyntaxAttr()<CR>

  "在函数找不到时，自动在运行环境（Linux 下一般为 ~/.vim）的 autoload 目录下读入与函数名同名的 .vim 文件。
  "au FuncUndefined * exec 'runtime autoload/' . expand('<afile>') . '.vim'

  " File type related autosetting
  au FileType c,cpp setlocal cinoptions=:0,g0,(0,w1 shiftwidth=4 tabstop=4 "设置适用于 C/C++ 文件的选项
  au FileType diff  setlocal shiftwidth=4 tabstop=4   "把补丁文件的缩进和制表符宽度设定设成和 C/C++ 文件相同
  au FileType html  setlocal autoindent indentexpr=   "取消 Vim 对 HTML 标记自动产生的缩进，但打开自动缩进选项
  au FileType changelog setlocal textwidth=76  "对于变更日志类型的文件，设置行宽为 76 个字符

  "当文件后缀为“.gb”时，认为这是一个 GBK 编码的文件，在读入文件之前调用函数 SetFileEncodings 把原先的 fileencodings 选项的内容保存在本缓冲区的一个变量中，然后把 fileencodings 设成 gbk，即只尝试对文件内容作为 GBK 字符序列来解释。
  au BufReadPre  *.gb               call SetFileEncodings('gbk')
  au BufReadPre  *.big5             call SetFileEncodings('big5')
  au BufReadPre  *.nfo              call SetFileEncodings('cp437')
  au BufReadPost *.gb,*.big5,*.nfo  call RestoreFileEncodings()
  au BufWinEnter *.txt              call CheckFileEncoding()

  "在遇到 HTML 文件时，如果 Vim 判断出的编码类型和 HTML 代码中使用“<meta http-equiv="Content-Type" content="text/html; charset=编码">”规定的编码不一致，将使用网页中规定的编码重新读入该文件。函数 ConvertHtmlEncoding 会把一些网页中使用的编码名称转换成 Vim 能够正确处理的编码名称；函数 DetectHtmlEncoding 在判断文件类型确实是 HTML 之后，会记下当前的光标位置，并搜索上面这样的 HTML 代码行，找出字符集编码后，在编码不等于当前文件编码（fileencoding）时且当前文件编码为空或等于系统判断出的文件编码时，使用该编码强制重新读入文件，忽略任何错误（“silent!”）。该自动命令写成是可嵌套执行的（“:help autocmd-nested”），目的是保证语法高亮显示有效，且上次打开文件的光标位置能够正确保持。
  au BufReadPost *.htm* nested      call DetectHtmlEncoding()

  "确保把 /usr/include/c++ 和 /usr/include/g++-3 目录下的所有文件都当成 C++ 类型的文件。C++ 的很多标准头文件（如“algorithm”）没有文件后缀，缺省情况下不会被 Vim 当作 C++ 文件。
  au BufEnter /usr/include/c++/*    setf cpp
  au BufEnter /usr/include/g++-3/*  setf cpp

  "第 142 行把 C/C++ 文件的制表符宽度设成了 4（个人设置），但系统的源代码一般使用 GNU 编码规范，制表符宽度为 8。该行设置所有 /usr 目录下的文件都使用 GNU 编码规范。
  au BufEnter /usr/*                call GnuIndent()

   "在写文件之前，调用函数 RemoveTrailingSpace:只要没有将环境变量 VIM_HATE_SPACE_ERRORS 的值设为零，则对于文件类型为 C、C++、Vim 脚本类型的文件，自动悄悄清除所有的行尾空白字符；“normal m`”记忆当前的光标位置，“normal ``”恢复记忆下来的光标位置。
  au BufWritePre *                  call RemoveTrailingSpace()
endif

""""""""""""""""""""""""""""""
" Tag list (ctags)
""""""""""""""""""""""""""""""
"let Tlist_Show_One_File = 1      "不同时显示多个文件的tag，只显示当前文件的
"let Tlist_Exit_OnlyWindow = 1    "如果taglist窗口是最后一个窗口，则退出vim
"let Tlist_Use_Right_Window = 0   "在右侧窗口中显示taglist窗口

"let Tlist_Ctags_Cmd="/usr/bin/ctags"
"let Tlist_Inc_Winwidth=0
"colorscheme desert

set nocp
"filetype plugin indent on


"通常情况下这些键的作用范围是逻辑行，所以如果行很长的话光标的移动可能会不太方便；这些键盘映射把这些键的作用范围改成屏幕行。noremap作用于正常模式、可视模式和命令执行时；inoremap仅作用于插入模式，其中使用“Ctrl-O”临时执行一个普通模式的命令
noremap  j      gj
noremap  k      gk
noremap  <Down>    gj
noremap  <Up>      gk
inoremap <Down>    <C-O>gj
inoremap <Up>      <C-O>gk



"nmap用于正常模式，imap用于插入模式。

"在当前文件和上一个文件之间来回切换
nmap <F1>       :e#<CR>
imap <F1>  <C-O>:e#<CR>
"列出缓冲区文件列表(必须先安装bufexplorer.vim插件)
nmap <F2>       \be
imap <F2>  <C-O>:BufExplorer<CR>
"关闭文件，并将文件从缓冲区删除
nmap <F3>       :bd<CR>
imap <F3>  <C-O>:bd<CR>
"将缓冲区文件打开成标签页
nmap <F4>       :tab ball<CR>
imap <F4>  <C-O>:tab ball<CR>
"自动换行/不换行
nmap <F5>       :set wrap<CR>
imap <F5>  <C-O>:set wrap<CR>
nmap <F6>       :set nowrap<CR>
imap <F6>  <C-O>:set nowrap<CR>
"取消搜索/替换的加亮显示。
nmap <F8>       :nohlsearch<CR>
imap <F8>  <C-O>:nohlsearch<CR>
"打开/关闭--文件目录树。如果安装了Beryl，则需要将Beryl的F9快捷键去掉
nmap <F9>       :NERDTreeToggle<CR>
imap <F9>  <C-O>:NERDTreeToggle<CR>
"打开/关闭taglist窗口
nmap <F10>       :Tlist<CR>
imap <F10>  <C-O>:Tlist<CR>
"取出会话
nmap <F11>       :source /home/wangqi/temp.vim<CR>:nohlsearch<CR>
imap <F11>  <C-O>:source /home/wangqi/temp.vim<CR>:nohlsearch<CR>
"保存当前会话，并退出
nmap <F12>       :mksession! /home/wangqi/temp.vim<CR>:wq<CR>
imap <F12>  <C-O>:mksession! /home/wangqi/temp.vim<CR><C-O>:wq<CR>

"Ctrl+S定义为:w保存
nmap <C-s>       :w<CR>
imap <C-s>  <C-O>:w<CR>

vmap <C-c> y:call system("xclip -i -selection clipboard", getreg("\""))<CR>:call system("xclip -i", getreg("\""))<CR>

"set shiftwidth=2 tabstop=2 expandtab
set shiftwidth=4 tabstop=4 expandtab
set noundofile
set encoding=utf-8

execute pathogen#infect()
syntax on
filetype plugin indent on
