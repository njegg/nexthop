.model small
.stack 200h

.data
    SCREEN_W dw 0140h
    SCREEN_H dw 0C8h

    loading db 'LOADING...$'


    W_pressed db 0
    S_pressed db 0
    A_pressed db 0
    D_pressed db 0
    ESC_pressed db 0

    KEY_W db 011h
    KEY_S db 01Fh
    KEY_A db 01Eh
    KEY_D db 020h
    KEY_ESC db 01h

    player_pos_x dw 0A0h
    player_pos_y dw 064h

    player_draw_x dw 0A0h
    player_draw_y dw 064h

    player_move_x dw 0
    player_move_y dw 0

    player_w dw 05h
    player_h dw 0Ah

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

exit macro
    mov ah, 4ch
    mov al,00h
    int 21h
endm

push_reg macro
    push bp
    push ax
    push bx
    push cx
    push dx
endm

pop_reg macro
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
endm

draw_pixel macro pix_x, pix_y, pix_color, video_page
    push ax
    push bx
    push cx
    push dx

    mov cx, pix_x
    mov dx, pix_y
    mov al, pix_color
    mov ah, 0Ch
    mov bx, video_page
    mov bh, bl
    int 010h

    pop dx
    pop cx
    pop bx
    pop ax
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
    push_reg    

    mov bp, sp
    mov di, 0Ah

    mov bx, [bp+di +2]
    sub bx, [bp+di +6]
    mov cx, bx                      ; rect height

    mov bx, [bp+di +4]
    sub bx, [bp+di +8]              ; rect width
    mov [bp+di +2], bx

    mov ax, [bp+di +6]
    mov dx, [bp+di +10]
    mov rec_color, dx
    draw_y:
        push cx
        mov cx, [bp+di +2]          ; loop through width
        mov bx, [bp+di +8]          ; x1

        draw_x:
            mov dx, 0Ch            ; color
            draw_pixel bx ax rec_color 0
            inc bx
            loop draw_x
        
        inc ax
        pop cx
        loop draw_y

    pop_reg
    ret 0Ah
draw_rect endp

;--------------------------------------------------------------------
draw_level proc
; 
;   draws a 160x160 square
;   starts at (80, 40)   
;--------------------------------------------------------------------
    mov al, ground_color
    xor ah, ah
    push ax

    mov ax, 050h
    push ax
    mov ax, 014h
    push ax
    mov ax, 0F0h
    push ax
    mov ax, 0B4h
    push ax
    call draw_rect

    ret
draw_level endp

if_pressed macro ascii
    LOCAL pressed
    LOCAL not_pressed
    LOCAL end_if_pressed
    
    mov ah, 01h         ; read keyboard buffer
    int 16h            
    
    cmp al, ascii      
    jne not_pressed
    
    pressed:
    mov ax, 1
    jmp end_if_pressed
    
    not_pressed:
    mov ax, 0
    sti
    end_if_pressed:
endm

draw_player macro color
    push ax
    push bx

    mov ax, 0Fh
    push ax

    push player_draw_x
    push player_draw_y

    mov ax, player_draw_x
    add ax, player_w
    push ax

    mov ax, player_draw_y
    add ax, player_h
    push ax

    call draw_rect
    pop ax
endm

check_key macro, key, status
    local end_check
    local released

    in al, 060h         ; get stuff from port 60h
    mov ah, al          ; save for the pressed/released flag
    and al, 07Fh        ; remove pressed/released flag
    
    cmp al, key         
    jne end_check

    and ah, 080h        ; leaves last bit - pressed/released flag
    cmp ah, 0
    jne released

    ; pressed:
    mov status, 1 
    jmp end_check

    released:
    mov status, 0
    jmp end_check

    end_check:
endm

handle_input proc
    check_key KEY_ESC ESC_pressed

    cmp ESC_pressed, 1
    jne check_keys
    exit

    check_keys:

    check_key KEY_W W_pressed
    cmp W_pressed, 1
    jne W_handled
    
    dec player_draw_y
    dec player_pos_y

    W_handled:

    check_key KEY_A A_pressed
    cmp A_pressed, 1
    jne A_handled
    
    dec player_draw_x
    dec player_pos_x

    A_handled:

    check_key KEY_D D_pressed
    cmp D_pressed, 1
    jne D_handled
    
    inc player_draw_x
    inc player_pos_x

    D_handled:

    check_key KEY_S S_pressed
    cmp S_pressed, 1
    jne S_handled
    
    inc player_draw_y
    inc player_pos_y
    
    S_handled:

    ret
handle_input endp

start:
    mov ax, @data
	mov ds, ax      ; init data segment


    mov ax, 0Dh     ; graphics mode, 320x200 16 color graphics (EGA,VGA), 0-7 video pages
    int 010h

    mov ax, 00501h  ; move to page 1 while stuff is drawing on the screen 
    int 10h

    mov ah, 02h     ; set cursor coords
    mov bh, 01h     ; page
    mov dh, 010h    ; y
    mov dl, 0Dh     ; x
    int 10h

    lea dx, loading     ; write loading... while waiting for drawing to finish
    mov ah, 09h
    int 21h

    ;call rainbow            ; draw to page 0
    call draw_level

    mov ax, 00500h          ; finished drawing, move back to page 0
    int 10h

    mov ax, 0304h
    xor bx, bx
    int 16h

    game_loop:
        sleep 04100h

        call handle_input

        draw_player

        jmp game_loop

    quit_game:
        exit

end start
