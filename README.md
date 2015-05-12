## vim-anzu

現在の検索位置を画面に表示するためのプラグインです。

![test](https://f.cloud.github.com/assets/214488/999607/67346324-0a34-11e3-8264-158c8865d669.gif)
![anzu3](https://f.cloud.github.com/assets/214488/1506514/25dc147c-4930-11e3-9780-a81c8ae7e087.gif)


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


" if start anzu-mode key mapping
" anzu-mode is anzu(12/51) in screen
" nmap n <Plug>(anzu-mode-n)
" nmap N <Plug>(anzu-mode-N)
```



