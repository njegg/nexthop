
.model small

.stack 200h

.data
    key_buffer db 128 dup(0)

    key db 'x'

    isr1_address0 dw ?
    isr1_address1 dw ?

    msg_press db "Key pressed$"
    msg1 db "Press and hold ESC$"
    msg2 db "ESC pressed, release ESC$"
    msg3 db "ESC released$"
.code

interupt_request_1_routine:
    push ax
    push bx
    push cx

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

    pop cx
    pop bx
    pop ax
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

start:
    mov ax, @data
    mov ds, ax


    call change_isr

    l:
        cmp key_buffer[1], 1
        jne l

        cmp key_buffer[010h], 1
        jne l

    exit:
        call resotre_isr

        mov ah, 04Ch
        int 21h

end start
