## vim-anzu

現在の検索位置を画面に表示するためのプラグインです。

![test](https://f.cloud.github.com/assets/214488/999607/67346324-0a34-11e3-8264-158c8865d669.gif)


#### Example

```vim
" mapping
nmap n <Plug>(anzu-n-with-echo)
nmap N <Plug>(anzu-N-with-echo)
nmap * <Plug>(anzu-star-with-echo)
nmap # <Plug>(anzu-sharp-with-echo)

" clear status
nmap <Esc><Esc> <Plug>(anzu-clear-search-status)


" statusline
set statusline=%{anzu#search_status()}
```



