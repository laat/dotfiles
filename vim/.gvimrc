autocmd GUIEnter * set visualbell t_vb=
if has("gui_running")
      set guioptions-=m
      set guioptions-=T

      " no scrollbars
      set guioptions+=LlRrb
      set guioptions-=LlRrb

      highlight SpellBad term=underline gui=undercurl guisp=Orange 

      let s:uname = system("uname")
      if s:uname == "Darwin\n"
          set guifont=DejaVu\ Sans\ Mono\ for\ Powerline:h14
          set clipboard=unnamed " OSX clipboard
      endif

      if s:uname == "Linux\n"
          set guifont=DejaVu\ Sans\ Mono\ for\ Powerline\ 10
          set clipboard=unnamedplus " X11 clipboard
      endif

endif
