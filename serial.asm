section .data
    msg db 'Value: ', 0
    int_buffer db '00000000', 0  ; Buffer untuk menyimpan string integer

section .text
    global _start

_start:
    ; Set baud rate (Assuming COM1, which is at port 0x3F8)
    mov dx, 0x3F8      ; COM1 port
    mov al, 0x00      ; Set Divisor Latch Access Bit (DLAB)
    out dx, al        ; Write to the line control register

    ; Set baud rate to 9600 (Divisor = 9600 / 115200 = 0x0C)
    mov dx, 0x3F8
    mov al, 0x0C      ; Set baud rate to 9600
    out dx, al        ; Write to the divisor latch low byte
    inc dx
    mov al, 0x00      ; High byte
    out dx, al        ; Write to the divisor latch high byte

    ; Set line control register
    mov dx, 0x3FB     ; Line Control Register
    mov al, 0x03      ; 8 bits, no parity, 1 stop bit
    out dx, al

    ; Contoh integer yang akan dikirim
    mov ecx, 1234     ; Integer yang ingin dikirim
    call int_to_string ; Konversi integer ke string

    ; Kirim pesan
    mov si, msg
.send_msg:
    mov al, [si]      ; Load character
    test al, al       ; Check for null terminator
    jz .send_int      ; Jika nol, kirim integer
    call send_char    ; Kirim karakter
    inc si            ; Move to next character
    jmp .send_msg

.send_int:
    mov si, int_buffer
.send_int_msg:
    mov al, [si]      ; Load character
    test al, al       ; Check for null terminator
    jz .done          ; Jika nol, selesai
    call send_char    ; Kirim karakter
    inc si            ; Move to next character
    jmp .send_int_msg

.done:
    ; Exit program (for DOS)
    mov ax, 0x4C00
    int 0x21

send_char:
    ; Wait for the transmit buffer to be empty
    mov dx, 0x3FD     ; Line Status Register
.wait:
    in al, dx
    test al, 0x20     ; Check if the transmit buffer is empty
    jz .wait

    ; Send the character
    mov dx, 0x3F8     ; COM1 port
    out dx, al        ; Write character to the port
    ret

int_to_string:
    ; Konversi integer di ECX ke string di int_buffer
    mov ebx, 10       ; Basis desimal
    mov edi, int_buffer + 8 ; Mulai dari belakang buffer
    mov byte [edi], 0 ; Null terminator

.convert:
    xor edx, edx      ; Clear edx
    div ebx            ; Bagi ECX dengan 10
    add dl, '0'       ; Konversi ke karakter
    dec edi           ; Pindah ke belakang buffer
    mov [edi], dl     ; Simpan karakter
    test eax, eax     ; Cek apakah hasil bagi nol
    jnz .convert      ; Jika tidak nol, lanjutkan

    ; Pindahkan pointer ke awal string
    mov esi, edi
    ret