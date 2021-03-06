.model small
.stack 200h

.data
    SCREEN_W dw 0140h
    SCREEN_H dw 0C8h

    loading db "LOADING...$"
    text    db "nexthop$"

    off dw 0AAh

    key_buffer db 128 dup(0)
    isr1_address0 dw 0
    isr1_address1 dw 0

    player_pos_x dw 0A0h
    player_pos_y dw 064h
    player_prev_pos_x dw 0A0h
    player_prev_pos_y dw 064h

    player_draw_x dw 0A0h
    player_draw_y dw 064h

    player_move_x dw 0
    player_move_y dw 0

    player_w dw 05h
    player_h dw 0Bh
    player_w_2 dw 02h
    player_h_2 dw 05h

    player_velocity dw 1
    player_color db 0Fh

    player_shadow_y dw ?
    player_shadow_w dw 09h
    player_shadow_h dw 05h
    player_shadow_w_2 dw 04h
    player_shadow_h_2 dw 02h

    ground_color db 0Ch
    rec_color db ?
.code

key_press macro
    push ax
    mov ah, 08h
    int 21h
    pop ax
endm

sleep macro amount
    mov     cx, 00h
    mov     dx, amount
    mov     ah, 86h
    int     15h 
endm

exit proc
    call resotre_isr

    mov ah, 4ch
    mov al,00h
    int 21h
    ret
exit endp

interupt_request_1_routine:
    push    ax
    push    bx
    push    cx

    ; read keyboard scan code
    in      al, 60h

    ; update keyboard state
    xor     bh, bh
    mov     bl, al
    and     bl, 7Fh             ; bx = scan code
    mov     cl, 7
    shr     al, cl              ; al = 0/1 not_pressed / pressed
    xor     al, 1               ; al = 0/1 pressed    /  not pressed
    mov     ds:[bx+key_buffer], al

    ; send EOI to XT keyboard
    in      al, 61h
    mov     ah, al
    or      al, 80h
    out     61h, al
    mov     al, ah
    out     61h, al

    ; send EOI to master PIC
    mov     al, 20h
    out     20h, al

    pop     cx
    pop     bx
    pop     ax
    iret

change_isr proc
    push    ax

    xor     ax, ax
    mov     es, ax

    cli                         ; update ISR address w/ ints disabled
    mov     ax, es:[9*4+2]      ; preserve ISR address
    mov     isr1_address1, ax

    mov     ax, es:[9*4]
    mov     isr1_address0, ax

    lea     si, interupt_request_1_routine

    mov     es:[9*4], si
    mov     es:[9*4+2], cs
    sti

    pop ax
    ret
change_isr endp

resotre_isr proc
    cli 
    mov     ax, isr1_address0
    mov     es:[9*4], ax 

    mov     ax, isr1_address1
    mov     es:[9*4+2], ax
    sti
    ret
resotre_isr endp

draw_pixel macro pix_x, pix_y, pix_color, video_page
    push    ax
    push    bx
    push    cx
    push    dx

    mov     cx, pix_x
    mov     dx, pix_y
    mov     al, pix_color
    mov     ah, 0Ch
    mov     bx, video_page
    mov     bh, bl
    int     010h

    pop     dx
    pop     cx
    pop     bx
    pop     ax
endm

resotre_background macro
    mov     bh, 2       ; read from page 2
    mov     ah, 0Dh
    int     10h   

    mov     bh, 0       ; write to page 0
    mov     ah, 0Ch
    int     10h
endm

;--------------------------------------------------------------------
draw_rect proc
;
;   TODO: dont use loop, use cx for x and dx for y
;  
;   usage:
;       push vide_page  [+12]
;       push color      [+10]
;       push x1         [+8]
;       push y1         [+6]
;       push x2         [+4]
;       push y2         [+2]
;       call draw_rect
;--------------------------------------------------------------------
    push    ax
    push    bx
    push    cx
    push    dx
    push    di
    push    bp

    mov     bp, sp
    mov     di, 0Ch

    mov     bx, [bp+di +2]
    sub     bx, [bp+di +6]
    mov     cx, bx                      ; rect height

    cmp     cx, 0
    jle     end_draw_rect

    mov     bx, [bp+di +4]
    sub     bx, [bp+di +8]              ; rect width
    mov     [bp+di +2], bx

    cmp     bx, 0
    jle     end_draw_rect

    mov     ax, [bp+di +6]
    mov     dx, [bp+di +10]
    mov     rec_color, dl
    mov     si, [bp+di +12]             ; video page

    inc     cx                          ; doesnt go through whole height/width, whole proc loop needs a change
    draw_y:
        push    cx
        mov     cx, [bp+di +2]          ; loop through width
        inc cx
        mov     bx, [bp+di +8]          ; x1

        draw_x:
            push    cx
            push    bx
            push    ax

            mov     cx, bx
            mov     dx, ax
            mov     al, rec_color
            mov     bx, si
            mov     bh, bl
            mov     ah, 0Ch
            int 10h
            
            pop     ax
            pop     bx
            pop     cx

            inc     bx
            loop    draw_x
        
        inc     ax
        pop     cx
        loop    draw_y

    end_draw_rect:
    pop     bp
    pop     di
    pop     dx
    pop     cx
    pop     bx
    pop     ax
    ret     0Ch
draw_rect endp

draw_level_on_page proc
    push    bp

    mov     bp, sp

    ; drawing water
    mov     cx, SCREEN_H
    mov     dx, 0
    water_y:
        push    cx
        mov     cx, SCREEN_W

        water_x:
            mov     si, ax
            and     si, 1

            mov     di, dx
            and     di, 1

            cmp     di, si
            je      dark_water
            mov     bx, 0Bh
            jmp     water_color_chosen
            dark_water:
            mov     bx, 03h
            jmp     water_color_chosen
            water_color_chosen:

            draw_pixel ax dx bl [bp+2+2]
            inc ax
        loop    water_x
        mov     ax, 0
        inc     dx

    pop     cx
    loop    water_y

    ; darker rect aroung main one 
    mov     bx, [bp+2 +2]   ; page number
    ; push    bx

    ; mov     al, ground_color
    ; sub     al, 8
    ; xor     ah, ah
    ; push    ax

    ; mov     ax, 04Fh
    ; push    ax
    ; mov     ax, 013h
    ; push    ax
    ; mov     ax, 0F1h
    ; push    ax
    ; mov     ax, 0B5h
    ; push    ax
    ; call    draw_rect

    ; drawing big red rect
    push    bx

    mov     al, ground_color
    xor     ah, ah
    push    ax

    mov     ax, 050h
    push    ax
    mov     ax, 014h
    push    ax
    mov     ax, 0F0h
    push    ax
    mov     ax, 0B4h
    push    ax
    call    draw_rect


    pop     bp
    ret     2
draw_level_on_page endp
;--------------------------------------------------------------------
draw_level proc
; 
;   draws a 160x160 square
;   starts at (80, 40)   
;
;   draws on page 0 and page 2
;--------------------------------------------------------------------
    mov     ax, 0
    push    ax
    call draw_level_on_page

    mov     ax, 2
    push    ax
    call draw_level_on_page

    ret
draw_level endp

;--------------------------------------------------------------------
draw_player macro draw_player_color
;
;   drawing a rect in a way that a player actual position
;   is at the middle of the base of a rectanle, so the
;   top-left and bottom-right coordinates for drawing a rect are:
;       (pdx = player_draw_x, pw = player_w)
;       x1 = pdx - pw/2
;       y1 = dpy - ph
;       x2 = pdx + pw/2
;       y2 = pdy
;--------------------------------------------------------------------
    push    ax

    xor     ax, ax
    push    ax

    mov     ax, draw_player_color   ; color parameter for draw rect proc
    push    ax

    left_corner_x player_draw_x player_w_2
    push    ax
    top_corner_y player_draw_y player_h
    push    ax
    right_corner_x player_draw_x player_w_2
    push    ax
    bottom_corner_y player_draw_y
    push    ax

    call    draw_rect

    pop     ax
endm

;------------------------------------------------------------------------
draw_shadow_pixel macro sha_x, sha_y
;   0Dh has 16 colors, first 8 are darker variants of last 8
;   Shadow pixel will be the darker variant of whatever is in the background
;   If its already dark, its just gonna be black
;------------------------------------------------------------------------
    push    ax
    push    bx
    push    cx
    push    dx

    mov     cx, sha_x
    mov     dx, sha_y
    mov     ah, 0Dh
    mov     bh, 02h
    int     10h

    cmp     al, 08h             
    jle     already_dark
    sub     al, 08h
    jmp     draw_pix
    
    already_dark:
    cmp     al, 03h
    jne     not_dark_cyan
    ; dark cyan will be dark blue in shadow instead of black
    mov     al, 01h
    jmp     draw_pix

    not_dark_cyan:
    mov     al, 00h

    draw_pix:
    mov     ah, 0Ch
    mov     bh, 00h
    int     10h

    pop     dx
    pop     cx
    pop     bx
    pop     ax
endm

erase_shadow proc
    mov     ax, player_pos_x
    sub     ax, player_w_2
    sub     ax, 02h

    mov     dx, player_pos_y
    sub     dx, 02h

    mov     cx, player_shadow_h
    erase_shadow_y:
        push    cx
        mov     cx, player_shadow_w
        erase_shadow_x:
            push    cx
            push    ax
            push    bx

            mov     cx, ax
            resotre_background
            
            pop     bx
            pop     ax
            pop     cx

            inc     ax
            loop    erase_shadow_x
        
        pop     cx
        inc     dx

        mov     ax, player_pos_x
        sub     ax, player_w_2
        sub     ax, 02h

        loop    erase_shadow_y

    ret
erase_shadow endp

draw_shadow proc
    push bx

    mov     si, player_draw_x
    sub     si, player_w_2

    mov     di, player_draw_x
    add     di, player_w_2

    mov     ax, player_pos_x
    sub     ax, player_w_2
    sub     ax, 02h

    mov     dx, player_pos_y
    sub     dx, 02h

    mov     cx, player_shadow_h
    shadow_y:
        push    cx
        mov     cx, player_shadow_w
        shadow_x:

            cmp     dx, player_draw_y
            jg      shadow_is_not_behind

            cmp     ax, si 
            jl      shadow_is_not_behind
            cmp     ax, di  
            jg      shadow_is_not_behind

            jmp     shadow_is_behind

            shadow_is_not_behind:
            draw_shadow_pixel ax dx

            shadow_is_behind:
            inc     ax
            loop    shadow_x
        
        pop     cx
        inc     dx

        mov     ax, player_pos_x
        sub     ax, player_w_2
        sub     ax, 02h

        loop    shadow_y

    pop     bx
    ret
draw_shadow endp


; player corners, used for drawing and erasing player rect
bottom_corner_y macro bc_y
    mov     ax, bc_y
endm

top_corner_y macro tc_y, tc_h
    mov     ax, tc_y
    sub     ax, tc_h
endm

left_corner_x macro lc_x, lc_w2
    mov     ax, lc_x
    sub     ax, lc_w2
endm

right_corner_x macro rc_x, rc_w2
    mov     ax, rc_x
    add     ax, rc_w2
endm


; TODO: maybe try to make one macro that does all 4
erase_rect_right macro er_x, er_y, er_h, er_w2
    local   erase
    push    ax

    ; starting corner coordinates
    top_corner_y er_y er_h
    mov     dx, ax
    right_corner_x er_x er_w2
    mov     cx, ax

    ; end pixel y
    bottom_corner_y er_y
    mov     si, ax

    erase:       
        resotre_background       
        inc     dx
        cmp     dx, si 
        jle     erase

    pop     ax
endm

erase_rect_left macro el_x, el_y, el_h, el_w2
    local   erase
    push    ax

    ; starting corner coordinates
    top_corner_y el_y el_h
    mov     dx, ax
    left_corner_x el_x el_w2
    mov     cx, ax

    ; end pixel y
    bottom_corner_y el_y
    mov     si, ax

    erase:       
        resotre_background       
        inc     dx
        cmp     dx, si 
        jle     erase

    pop     ax
endm

erase_rect_up macro eu_x, eu_y, eu_h, eu_w2
    local   erase
    push    ax

    ; starting corner coordinates
    top_corner_y eu_y eu_h
    mov     dx, ax
    left_corner_x eu_x eu_w2
    mov     cx, ax

    ; end pixel y
    right_corner_x eu_x eu_w2
    mov     si, ax

    erase:       
        resotre_background       
        inc     cx
        cmp     cx, si 
        jle     erase

    pop     ax
endm

erase_rect_down macro ed_x, ed_y, ed_h, ed_w2  
    local   erase
    push    ax

    ; starting corner coordinates
    bottom_corner_y ed_y
    mov     dx, ax
    left_corner_x ed_x ed_w2
    mov     cx, ax

    ; end pixel y
    right_corner_x ed_x ed_w2
    mov     si, ax

    erase:       
        resotre_background       
        inc     cx
        cmp     cx, si 
        jle     erase

    pop     ax
endm

handle_input macro
    local   dont_exit
    
    mov     ax, player_velocity

    cmp     [key_buffer + 01h], 1
    jne     ESC_checked
    call    exit
    ESC_checked:

    ; for testing, N changes to page 2
    cmp     [key_buffer + 031h], 1
    jne     N_checked

    mov     [key_buffer + 031h], 0
    call resotre_isr

    mov     ax, 00502h
    int     10h
    
    mov ah, 8
    int 21h

    mov     ax, 00500h
    int     10h

    call change_isr
    N_checked:

    ; for testing, P changes to loading screen (page 1)
    cmp     [key_buffer + 019h], 1
    jne     P_checked

    mov     ax, 00501h
    int     10h
    
    mov ah, 8
    int 21h

    mov     ax, 00500h
    int     10h

    call change_isr
    P_checked:

    ; erase and draw player at new pos
    xor     bx, bx                  ; if player moves, bx = 1

    cmp     [key_buffer + 011h], 1  ; check W
    jne     W_checked

    cmp     player_pos_y, 014h
    jle     W_checked               ; level border

    erase_rect_down player_draw_x player_draw_y player_h player_w_2
    erase_rect_down player_pos_x player_shadow_y player_shadow_h player_shadow_w_2
    mov     bx, 1

    dec     player_pos_y            ; decrement positions
    dec     player_draw_y
    W_checked:

    cmp     [key_buffer + 01Eh], 1  ; check A
    jne     A_checked

    cmp     player_pos_x, 050h      ; level border
    jle     A_checked

    erase_rect_right player_draw_x player_draw_y player_h player_w_2
    erase_rect_right player_pos_x player_shadow_y player_shadow_h player_shadow_w_2
    mov     bx, 1

    dec     player_pos_x
    dec     player_draw_x
    A_checked:

    cmp     [key_buffer + 01Fh], 1  ; check S
    jne     S_checked

    cmp     player_pos_y, 0B4h
    jge     S_checked

    erase_rect_up player_draw_x player_draw_y player_h player_w_2
    erase_rect_up player_pos_x player_shadow_y player_shadow_h player_shadow_w_2
    mov     bx, 1

    inc     player_pos_y
    inc     player_draw_y
    S_checked:

    cmp     [key_buffer + 020h], 1  ; check D
    jne     D_checked

    cmp     player_pos_x, 0F0h
    jge     D_checked

    erase_rect_left player_draw_x player_draw_y player_h player_w_2
    erase_rect_left player_pos_x player_shadow_y player_shadow_h player_shadow_w_2
    mov     bx, 1

    inc     player_pos_x
    inc     player_draw_x
    D_checked:

endm

draw_rect_m macro p, c, x1, y1, x2, y2
    mov     ax, p
    push    ax
    mov     ax, c
    push    ax
    mov     ax, x1
    push    ax
    mov     ax, y1
    push    ax
    mov     ax, x2
    push    ax
    mov     ax, y2
    push    ax
    call draw_rect
endm

start:
    mov     ax, @data
    mov     ds, ax          ; init data segment

    call    change_isr

    mov     ax, 0Dh         ; graphics mode, 320x200 16 color graphics (EGA,VGA), 0-7 video pages
    int     010h

    mov     ax, 00501h      ; move to page 1 while stuff is drawing on the screen 
    int     10h

    mov     ah, 02h         ; set cursor coords
    mov     bh, 01h         ; page
    mov     dh, 010h        ; y
    mov     dl, 0Dh         ; x
    int     10h

    lea     dx, loading     ; write loading... while waiting for drawing to finish
    mov     ah, 09h
    int     21h

    call    draw_level

    ; for testing
    draw_rect_m 0 0Dh 0A0h 0Ah 0AAh 014h
    draw_rect_m 2 0Dh 0A0h 0Ah 0AAh 014h

    ; write nexthop to page 2 
    mov     ax, 00502h
    int     10h

    mov     bh, 02h
    mov     dh, 01h
    mov     dl, 0Ah
    mov     ah, 02h
    int     10h

    lea     dx, text
    mov     ah, 09h
    int     21h

    mov     ax, 00500h          ; finished drawing, move back from loading to page 0
    int     10h

    ; draw nexthop to page 0
    mov     bh, 00h
    mov     dh, 01h
    mov     dl, 0Ah
    mov     ah, 02h
    int     10h

    lea     dx, text
    mov     ah, 09h
    int     21h

    ; calclulate shadow y position

    call    draw_shadow
    draw_player 0Eh

    game_loop:
        mov     ax, player_pos_y
        add     ax, player_shadow_h_2
        mov     player_shadow_y, ax
        sleep   0211Bh 


        handle_input                ; changes ax, bx, cx
        
        cmp bx, 1
        jne player_didnt_move_dont_draw

        call draw_shadow
        draw_player 0Eh         ; draw player in color white at new position

        player_didnt_move_dont_draw:

    jmp     game_loop

    call    exit

end start
