.model small
.stack 200h

.data
    SCREEN_W dw 0140h
    SCREEN_H dw 0C8h

    loading db 'LOADING...$'

    color db 030h
.code

key_press macro
    push ax
    mov ah, 08h
    int 21h
    pop ax
endm

sleep_1s macro
    mov     cx, 0fh
    mov     dx, 4240h
    mov     ah, 86h
    int     15h 
endm

exit macro
    mov ah, 4ch
    mov al,00h
    int 21h
endm

push_reg macro
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
endm

draw_pixel macro pix_x, pix_y, pix_color, video_page
    push_reg

    mov ax, pix_color
    mov ah, 0Ch
    mov cx, pix_x
    mov dx, pix_y
    mov bx, video_page
    mov bh, bl
    int 010h

    pop_reg
endm

rainbow proc
    push_reg

    mov bx, 0
    mov ax, 020h
    mov dx, 0
    color_y:
        mov cx, 0
        color_x:
            cmp dx, 014h
            jne dont_change_color
            inc ax
            xor dx, dx
            dont_change_color:
            inc dx
            
            draw_pixel cx bx ax 00h

            inc cx
            cmp cx, SCREEN_W
            jne color_x
        
        mov ax, 020h
        inc bx
        cmp bx, SCREEN_H
        jne color_y

    pop_reg
    ret
rainbow endp

draw_level proc
    ret
draw_level endp

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

    call rainbow        ; draw to page 0

    mov ax, 00500h      ; finished drawing, move back to page 0
    int 10h

    key_press
    exit

end start
