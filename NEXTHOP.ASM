.model small
.stack 200h

.code

; key_press macro
;     push ax
;     mov ah, 01h
;     int 21h
;     pop ax
; endm
; 
; sleep_1s macro
;     mov     cx, 0fh
;     mov     dx, 4240h
;     mov     ah, 86h
;     int     15h 
; endm

start:
    xor ah, ah
    mov al, 013h
    int 010h

    mov ah, 0Ch
    mov al, 030h
    mov cx, 010h
    mov dx, 010h
    mov bx, 00h
    int 010h

    mov ah, 1
    int 21h

    mov ah, 4ch
    mov al,00h
    int 21h

end start
