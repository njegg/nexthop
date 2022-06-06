.model small
.stack 200h

.data
    SCREEN_W dw 0140h
    SCREEN_H dw 0C8h

    loading db "LOADING...$"

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
    player_h dw 0Ah

    player_velocity dw 1

    player_color db 0Fh

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

;--------------------------------------------------------------------
draw_rect proc
;  
;   usage:
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

    mov     bx, [bp+di +4]
    sub     bx, [bp+di +8]              ; rect width
    mov     [bp+di +2], bx

    mov     ax, [bp+di +6]
    mov     dx, [bp+di +10]
    mov     rec_color, dl
    draw_y:
        push    cx
        mov     cx, [bp+di +2]          ; loop through width
        mov     bx, [bp+di +8]          ; x1

        draw_x:
            mov     dx, 0Ch            ; color
            draw_pixel bx ax rec_color 0
            inc     bx
            loop    draw_x
        
        inc     ax
        pop     cx
        loop    draw_y

    pop     bp
    pop     di
    pop     dx
    pop     cx
    pop     bx
    pop     ax
    ret     0Ah
draw_rect endp

;--------------------------------------------------------------------
draw_level proc
; 
;   draws a 160x160 square
;   starts at (80, 40)   
;--------------------------------------------------------------------
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

    ret
draw_level endp

;--------------------------------------------------------------------
draw_player macro draw_player_color, draw_player_x, draw_player_y
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
    push    bx
    push    cx

    mov     ax, draw_player_color   ; color parameter for draw rect proc
    push    ax

    mov     ax, draw_player_x       ; pdx
    mov     cx, player_w            ; pw
    shr     cx, 1                   ; pw/2
    sub     ax, cx                  ; x1 = pdx - pw/2
    push    ax                      ; draw rect proc parameter

    mov     ax, draw_player_y       ; pdy
    mov     bx, player_h            ; ph
    sub     ax, bx                  ; pdy - ph
    push    ax

    mov     ax, player_draw_x
    add     ax, cx                  ; pdx + pw/2
    push    ax

    mov     ax, player_draw_y
    push    ax

    call    draw_rect

    pop     cx
    pop     bx
    pop     ax
endm


;--------------------------------------------------------------------
erase_player_right macro
;   
;   When player moves left the player is drawn again but
;   one pixel to the right
;   This leaves his last state still on the screen
;   this macro and the ones bellow remove what is left
;   from previous player state by drawing a rect 1 pixel
;   wide/high in color of the ground 
;--------------------------------------------------------------------
    push ax

    mov     ax, 0Ch                 ; ground color
    push    ax

    mov     ax, player_draw_x       ; pdx
    mov     cx, player_w            ; pw
    shr     cx, 1                   ; pw/2
    sub     ax, cx                  ; x1 = pdx + pw/2
    push    ax                      ; draw rect proc parameter

    mov     ax, player_draw_y       ; pdy
    mov     bx, player_h            ; ph
    sub     ax, bx                  ; pdy - ph
    push    ax

    mov     ax, player_draw_x
    add     ax, cx                  ; pdx + pw/2
    inc     ax                      ; pdx + pw/2 + 1
    push    ax

    mov     ax, player_draw_y       ; pdy
    inc     ax                      ; pdy + 1
    push    ax
    call draw_rect

    pop ax
endm

;--------------------------------------------------------------------
erase_player_left macro
;   
;   When player moves left the player is drawn again but
;   one pixel to the right
;   This leaves his last state still on the screen
;   this macro and the ones bellow remove what is left
;   from previous player state by drawing a rect 1 pixel
;   wide/high in color of the ground 
;--------------------------------------------------------------------
    push ax

    mov     cx, player_w            ; pw
    shr     cx, 1                   ; pw/2

    mov     ax, 0F0h
    sub     ax, cx
    cmp     player_draw_x, ax
    jle     ground_color
    mov     ax, 00h
    jmp     color_checked

    ground_color:
    mov     ax, 0Ch                 ; ground color

    color_checked:
    push    ax

    mov     ax, player_draw_x       ; pdx
    sub     ax, cx                  ; x1 = pdx + pw/2
    push    ax                      ; draw rect proc parameter

    mov     ax, player_draw_y       ; pdy
    mov     bx, player_h            ; ph
    sub     ax, bx                  ; pdy - ph
    push    ax

    mov     ax, player_draw_x
    add     ax, cx                  ; pdx + pw/2
    inc     ax                      ; pdx + pw/2 + 1
    push    ax

    mov     ax, player_draw_y       ; pdy
    inc     ax                      ; pdy + 1
    push    ax
    call draw_rect

    pop ax
endm


handle_input macro
    local   dont_exit
    
    ; delete player
    ;draw_player     0Ch player_draw_x player_draw_y

    mov     ax, player_velocity

    cmp     [key_buffer + 01h], 1
    jne     ESC_checked
    call    exit
    ESC_checked:

    cmp     [key_buffer + 011h], 1  ; check W
    jne     W_checked

    cmp     player_pos_y, 014h
    jle     W_checked               ; level border

    sub     player_pos_y, ax        ; decrement positions by velocity
    sub     player_draw_y, ax
    W_checked:

    cmp     [key_buffer + 01Eh], 1  ; check A
    jne     A_checked

    cmp     player_pos_x, 050h      ; level border
    jle     A_checked

    erase_player_right

    sub     player_pos_x, ax
    sub     player_draw_x, ax
    A_checked:

    cmp     [key_buffer + 01Fh], 1  ; check S
    jne     S_checked

    cmp     player_pos_y, 0B4h
    jge     S_checked

    add     player_pos_y, ax
    add     player_draw_y, ax
    S_checked:

    cmp     [key_buffer + 020h], 1  ; check D
    jne     D_checked

    cmp     player_pos_x, 0F0h
    jge     D_checked

    add     player_pos_x, ax
    add     player_draw_x, ax
    D_checked:

    draw_player     0Fh player_draw_x player_draw_y
endm

start:
    mov     ax, @data
	mov     ds, ax      ; init data segment

    call    change_isr

    mov     ax, 0Dh     ; graphics mode, 320x200 16 color graphics (EGA,VGA), 0-7 video pages
    int     010h

    mov     ax, 00501h  ; move to page 1 while stuff is drawing on the screen 
    int     10h

    mov     ah, 02h     ; set cursor coords
    mov     bh, 01h     ; page
    mov     dh, 010h    ; y
    mov     dl, 0Dh     ; x
    int     10h

    lea     dx, loading     ; write loading... while waiting for drawing to finish
    mov     ah, 09h
    int     21h

    call    draw_level

    mov     ax, 00500h          ; finished drawing, move back from loading to page 0
    int     10h

    mov     ax, 0304h
    xor     bx, bx
    int     16h

    game_loop:
        sleep   0211Bh 

        handle_input            ; changes ax, bx, cx

    jmp     game_loop

    call    exit

end start
