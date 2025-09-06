[BITS 16]
[ORG 0x7C00]

; -----------------------
; Boot sector (0..511)
; -----------------------
start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    ; Store boot drive FIRST
    mov [boot_drive], dl

    ; Set green text on black background
    mov ah, 0x00
    mov al, 0x03
    int 0x10
    
    ; Set text color to green
    mov ah, 0x06
    mov al, 0
    mov bh, 0x02    ; Green on black
    mov ch, 0
    mov cl, 0
    mov dh, 24
    mov dl, 79
    int 0x10

    mov si, boot_msg
    call boot_print

    ; Reset disk system
    mov ah, 0x00
    mov dl, [boot_drive]
    int 0x13

    ; Load kernel -> 0x1000:0000 
    mov ax, 0x1000
    mov es, ax
    xor bx, bx

    mov ah, 0x02
    mov al, 25          ; 25 sectors for larger kernel
    mov ch, 0           ; cylinder 0
    mov cl, 2           ; sector 2
    mov dh, 0           ; head 0
    mov dl, [boot_drive]
    int 0x13
    jc boot_disk_error

    mov si, kernel_loaded_msg
    call boot_print

    ; Jump to kernel
    jmp 0x1000:0x0000

boot_disk_error:
    mov si, disk_err
    call boot_print
    cli
    hlt

boot_print:
    pusha
bp_loop:
    lodsb
    test al, al
    jz bp_done
    mov ah, 0x0E
    mov bl, 0x02    ; Green text
    int 0x10
    jmp bp_loop
bp_done:
    popa
    ret

boot_msg db 'Finch OS Loading...',13,10,0
kernel_loaded_msg db 'Kernel loaded! Jumping...',13,10,0
disk_err db 'Oops! Disk Error!',13,10,0
boot_drive db 0

times 510-($-$$) db 0
dw 0xAA55

; -----------------------
; KERNEL STARTS HERE (sector 2)
; -----------------------
kernel_start:
    ; Set up segments for kernel at 0x1000
    mov ax, 0x1000
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0xF000

    ; Initialize sound system
    call init_sound

    ; Set green text mode
    call set_green_mode

    ; Initialize file system
    call init_filesystem

    ; Show boot menu
    call show_boot_menu

; Initialize sound system with maximum volume
init_sound:
    pusha
    ; Initialize PC speaker (port 0x61) with maximum settings
    in al, 0x61
    or al, 3        ; Enable both gate and data bits for max volume
    out 0x61, al
    
    ; Set timer 2 for maximum responsiveness
    mov al, 0xB6    ; Binary, mode 3, LSB then MSB, counter 2
    out 0x43, al
    popa
    ret

; Play a note with MAXIMUM volume (frequency in AX, duration in BX)
play_note:
    pusha
    
    ; Calculate timer divisor (1193180 / frequency)
    mov dx, 0
    mov cx, ax
    mov ax, 0x1234  ; Low part of 1193180
    mov bx, 0x0012  ; High part of 1193180
    div cx
    
    ; Set timer 2 frequency
    mov bx, ax
    mov al, 0xB6    ; Maximum volume configuration
    out 0x43, al
    mov al, bl
    out 0x42, al
    mov al, bh
    out 0x42, al
    
    ; Enable speaker with MAXIMUM VOLUME settings
    in al, 0x61
    or al, 3        ; Both bits set for maximum volume
    out 0x61, al
    
    ; EXTENDED duration delay for louder perception
    pop bx      ; Get duration from stack
    push bx
    mov cx, bx
    shl cx, 10   ; Multiply by 1024 for MUCH longer, louder sound
sound_delay:
    push cx
    mov cx, 2000  ; Doubled inner delay for more volume
inner_delay:
    dec cx
    jnz inner_delay
    pop cx
    dec cx
    jnz sound_delay
    
    ; Keep speaker enabled slightly longer for maximum effect
    mov cx, 5000
extra_volume_delay:
    dec cx
    jnz extra_volume_delay
    
    ; Disable speaker
    in al, 0x61
    and al, 0xFC
    out 0x61, al
    
    popa
    ret

; Play LOUD startup tune
play_startup_tune:
    pusha
    
    ; Play a simple ascending tune with MAXIMUM volume
    mov ax, 523     ; C note
    mov bx, 8       ; Longer duration for more volume
    call play_note
    
    mov ax, 587     ; D note
    mov bx, 8
    call play_note
    
    mov ax, 659     ; E note
    mov bx, 8
    call play_note
    
    mov ax, 698     ; F note
    mov bx, 12      ; Even longer final note
    call play_note
    
    popa
    ret

; Play LOUD game music
play_game_music:
    pusha
    
    ; Play thrilling 16-bit style music with MAXIMUM VOLUME
    mov ax, 440     ; A note
    mov bx, 6       ; Doubled duration
    call play_note
    
    mov ax, 523     ; C note
    mov bx, 6
    call play_note
    
    mov ax, 659     ; E note
    mov bx, 6
    call play_note
    
    mov ax, 784     ; G note
    mov bx, 10      ; Extended high note
    call play_note
    
    mov ax, 659     ; E note
    mov bx, 6
    call play_note
    
    mov ax, 523     ; C note
    mov bx, 10      ; Extended final note
    call play_note
    
    popa
    ret

; Play EXTRA LOUD victory sound
play_victory_sound:
    pusha
    
    ; Victory fanfare with maximum volume
    mov ax, 523     ; C
    mov bx, 8
    call play_note
    
    mov ax, 659     ; E
    mov bx, 8
    call play_note
    
    mov ax, 784     ; G
    mov bx, 8
    call play_note
    
    mov ax, 1047    ; High C
    mov bx, 15      ; Very long victory note
    call play_note
    
    popa
    ret

; Play LOUD shooting sound
play_shoot_sound:
    pusha
    
    ; Rapid-fire shooting effect with maximum volume
    mov ax, 1500    ; High frequency
    mov bx, 2       ; Short but loud burst
    call play_note
    
    mov ax, 1000    ; Medium frequency
    mov bx, 2
    call play_note
    
    popa
    ret

; Play LOUD hit sound
play_hit_sound:
    pusha
    
    ; Impact sound with maximum volume
    mov ax, 200     ; Low impact sound
    mov bx, 8       ; Extended for maximum effect
    call play_note
    
    popa
    ret

; Set green text on black background
set_green_mode:
    pusha
    mov ah, 0x00
    mov al, 0x03
    int 0x10
    
    ; Set attribute for entire screen
    mov ah, 0x06
    mov al, 0
    mov bh, 0x02    ; Green on black
    mov ch, 0
    mov cl, 0
    mov dh, 24
    mov dl, 79
    int 0x10
    popa
    ret

; -----------------------
; PSEUDO-FILE SYSTEM
; -----------------------
MAX_FILES equ 16
FILE_NAME_SIZE equ 16
FILE_CONTENT_SIZE equ 256

init_filesystem:
    pusha
    ; Clear file table
    mov di, file_table - kernel_start
    mov cx, MAX_FILES * (FILE_NAME_SIZE + FILE_CONTENT_SIZE + 2)
    xor ax, ax
    rep stosb
    
    ; Create default file "welcome.txt"
    mov si, default_filename - kernel_start
    mov di, file_table - kernel_start
    call copy_filename
    
    mov si, default_file_content - kernel_start
    mov di, file_table - kernel_start + FILE_NAME_SIZE + 1
    call copy_string
    
    ; Mark file as used
    mov byte [file_table - kernel_start + FILE_NAME_SIZE], 1
    
    popa
    ret

; Find file by name (SI = filename, returns DI = file entry or 0 if not found)
find_file:
    pusha
    mov cx, MAX_FILES
    mov di, file_table - kernel_start
    
find_file_loop:
    ; Check if slot is used
    mov al, [di + FILE_NAME_SIZE]
    test al, al
    jz find_file_next
    
    ; Compare filename
    push cx
    push di
    push si
    mov cx, FILE_NAME_SIZE
compare_name_loop:
    lodsb
    cmp al, [di]
    jne compare_name_fail
    test al, al
    jz compare_name_success
    inc di
    dec cx
    jnz compare_name_loop
    
compare_name_success:
    pop si
    pop di
    pop cx
    mov [temp_file_ptr - kernel_start], di
    popa
    mov di, [temp_file_ptr - kernel_start]
    ret

compare_name_fail:
    pop si
    pop di
    pop cx

find_file_next:
    add di, FILE_NAME_SIZE + FILE_CONTENT_SIZE + 2
    dec cx
    jnz find_file_loop
    
    ; Not found
    popa
    xor di, di
    ret

; Create new file (SI = filename, returns DI = file entry or 0 if table full)
create_file:
    pusha
    mov cx, MAX_FILES
    mov di, file_table - kernel_start
    
create_file_loop:
    ; Check if slot is free
    mov al, [di + FILE_NAME_SIZE]
    test al, al
    jz create_file_found
    
    add di, FILE_NAME_SIZE + FILE_CONTENT_SIZE + 2
    dec cx
    jnz create_file_loop
    
    ; Table full
    popa
    xor di, di
    ret

create_file_found:
    ; Copy filename
    push di
    call copy_filename
    pop di
    
    ; Mark as used
    mov byte [di + FILE_NAME_SIZE], 1
    
    ; Clear content
    push di
    add di, FILE_NAME_SIZE + 1
    mov cx, FILE_CONTENT_SIZE
    xor ax, ax
    rep stosb
    pop di
    
    mov [temp_file_ptr - kernel_start], di
    popa
    mov di, [temp_file_ptr - kernel_start]
    ret

; List all files
list_files:
    pusha
    mov cx, MAX_FILES
    mov di, file_table - kernel_start
    mov dx, 0  ; File count
    
list_files_loop:
    ; Check if slot is used
    mov al, [di + FILE_NAME_SIZE]
    test al, al
    jz list_files_next
    
    ; Print filename
    mov si, di
    call print_string
    mov si, newline - kernel_start
    call print_string
    inc dx
    
list_files_next:
    add di, FILE_NAME_SIZE + FILE_CONTENT_SIZE + 2
    dec cx
    jnz list_files_loop
    
    ; If no files found
    test dx, dx
    jnz list_files_done
    mov si, no_files_msg - kernel_start
    call print_string

list_files_done:
    popa
    ret

copy_filename:
    pusha
    mov cx, FILE_NAME_SIZE - 1
copy_fn_loop:
    lodsb
    stosb
    test al, al
    jz copy_fn_done
    dec cx
    jnz copy_fn_loop
copy_fn_done:
    ; Null terminate remaining space
    xor al, al
    rep stosb
    popa
    ret

find_string_end:
fse_loop:
    cmp byte [di], 0
    je fse_found
    inc di
    jmp fse_loop
fse_found:
    ret

copy_string:
    pusha
cs_loop:
    lodsb
    stosb
    test al, al
    jnz cs_loop
    popa
    ret

; -----------------------
; BOOT MENU SYSTEM
; -----------------------
show_boot_menu:
    call set_green_mode
    call play_startup_tune
    
    mov si, boot_menu_title - kernel_start
    call print_string
    
boot_menu_loop:
    mov si, boot_menu_options - kernel_start
    call print_string
    
    ; Wait for keypress
    xor ah, ah
    int 0x16
    
    ; Echo the key
    mov ah, 0x0E
    mov bl, 0x02    ; Green text
    int 0x10
    
    mov si, newline - kernel_start
    call print_string
    
    cmp al, '1'
    je boot_option_shell
    cmp al, '2'
    je boot_option_random_game
    cmp al, '3'
    je boot_option_random_command
    
    ; Invalid option
    mov si, invalid_option_msg - kernel_start
    call print_string
    jmp boot_menu_loop

boot_option_shell:
    call set_green_mode
    mov si, banner - kernel_start
    call print_string
    jmp shell_loop

boot_option_random_game:
    call get_random
    and ax, 4
    cmp ax, 0
    je launch_1210
    cmp ax, 1
    je launch_ww3
    cmp ax, 2
    je launch_capitalism
    cmp ax, 3
    je launch_sharestocks
    jmp launch_magiccube

launch_1210:
    call set_green_mode
    mov si, launching_msg - kernel_start
    call print_string
    mov si, game_1210_name - kernel_start
    call print_string
    call cmd_1210_impl
    jmp show_boot_menu

launch_ww3:
    call set_green_mode
    mov si, launching_msg - kernel_start
    call print_string
    mov si, game_ww3_name - kernel_start
    call print_string
    call cmd_ww3_impl
    jmp show_boot_menu

launch_capitalism:
    call set_green_mode
    mov si, launching_msg - kernel_start
    call print_string
    mov si, game_capitalism_name - kernel_start
    call print_string
    call cmd_capitalism_impl
    jmp show_boot_menu

launch_sharestocks:
    call set_green_mode
    mov si, launching_msg - kernel_start
    call print_string
    mov si, game_sharestocks_name - kernel_start
    call print_string
    call cmd_sharestocks_impl
    jmp show_boot_menu

launch_magiccube:
    call set_green_mode
    mov si, launching_msg - kernel_start
    call print_string
    mov si, game_magiccube_name - kernel_start
    call print_string
    call cmd_magiccube_impl
    jmp show_boot_menu

boot_option_random_command:
    call get_random
    and ax, 7
    cmp ax, 0
    je launch_ls
    cmp ax, 1
    je launch_dis_default
    cmp ax, 2
    je launch_pwd
    cmp ax, 3
    je launch_neofinch
    cmp ax, 4
    je launch_existentialcrisis
    cmp ax, 5
    je launch_chaos
    cmp ax, 6
    je launch_finch
    jmp launch_help

launch_ls:
    call set_green_mode
    mov si, launching_cmd_msg - kernel_start
    call print_string
    mov si, cmd_ls_name - kernel_start
    call print_string
    call cmd_ls_impl
    call wait_for_key
    jmp show_boot_menu

launch_dis_default:
    call set_green_mode
    mov si, launching_cmd_msg - kernel_start
    call print_string
    mov si, cmd_dis_name - kernel_start
    call print_string
    ; Display default file
    mov si, default_filename - kernel_start
    call find_file
    test di, di
    jz dis_default_notfound
    add di, FILE_NAME_SIZE + 1
    mov si, di
    call print_string
    jmp dis_default_done
dis_default_notfound:
    mov si, file_not_found_msg - kernel_start
    call print_string
dis_default_done:
    call wait_for_key
    jmp show_boot_menu

launch_pwd:
    call set_green_mode
    mov si, launching_cmd_msg - kernel_start
    call print_string
    mov si, cmd_pwd_name - kernel_start
    call print_string
    call cmd_pwd_impl
    call wait_for_key
    jmp show_boot_menu

launch_neofinch:
    call set_green_mode
    mov si, launching_cmd_msg - kernel_start
    call print_string
    mov si, cmd_neofinch_name - kernel_start
    call print_string
    call cmd_neofinch_impl
    call wait_for_key
    jmp show_boot_menu

launch_existentialcrisis:
    call set_green_mode
    mov si, launching_cmd_msg - kernel_start
    call print_string
    mov si, cmd_existential_name - kernel_start
    call print_string
    call cmd_existentialcrisis_impl
    call wait_for_key
    jmp show_boot_menu

launch_chaos:
    call set_green_mode
    mov si, launching_cmd_msg - kernel_start
    call print_string
    mov si, cmd_chaos_name - kernel_start
    call print_string
    call cmd_chaos_impl
    call wait_for_key
    jmp show_boot_menu

launch_finch:
    call set_green_mode
    mov si, launching_cmd_msg - kernel_start
    call print_string
    mov si, cmd_finch_name - kernel_start
    call print_string
    call cmd_finch_impl
    call wait_for_key
    jmp show_boot_menu

launch_help:
    call set_green_mode
    mov si, launching_cmd_msg - kernel_start
    call print_string
    mov si, cmd_help_name - kernel_start
    call print_string
    call cmd_help_impl
    call wait_for_key
    jmp show_boot_menu

wait_for_key:
    pusha
    mov si, press_key_continue - kernel_start
    call print_string
    xor ah, ah
    int 0x16
    popa
    ret

; -----------------------
; RANDOM NUMBER GENERATOR
; -----------------------

; Simple LFSR-based random number generator
get_random:
    pusha
    
    ; Get timer value for entropy
    in al, 0x40
    xor [random_seed - kernel_start], al
    
    ; Simple LFSR
    mov ax, [random_seed - kernel_start]
    mov bx, ax
    shr ax, 1
    xor ax, bx
    and ax, 1
    shl ax, 15
    shr bx, 1
    or bx, ax
    mov [random_seed - kernel_start], bx
    
    ; Get number 1-10
    mov ax, bx
    and ax, 0x0F
    mov bx, 10
    xor dx, dx
    div bx
    inc dx  ; DX = 1-10
    mov [temp_random - kernel_start], dx
    
    popa
    mov ax, [temp_random - kernel_start]
    ret

; Get random number 2-9 (for math games)
get_random_math:
    call get_random
    and ax, 7
    add ax, 2  ; 2-9
    ret

; -----------------------
; SHELL MAIN LOOP
; -----------------------
shell_loop:
    ; Show prompt
    mov si, prompt - kernel_start
    call print_string

    ; Read command
    mov di, buffer - kernel_start
    call read_line

    ; Check if empty
    mov si, buffer - kernel_start
    mov al, [si]
    test al, al
    jz shell_loop

    ; Parse and execute command
    call parse_command
    jmp shell_loop

; -----------------------
; COMMAND PARSER
; -----------------------
parse_command:
    pusha
    mov si, buffer - kernel_start

    ; Check for 'ls'
    mov al, [si]
    cmp al, 'l'
    jne check_dis
    mov al, [si+1]
    cmp al, 's'
    jne check_dis
    mov al, [si+2]
    cmp al, 0
    je do_ls
    cmp al, ' '
    je do_ls

check_dis:
    mov si, buffer - kernel_start
    mov di, cmd_dis - kernel_start
    call compare_cmd
    test al, al
    jnz do_dis

check_echo:
    mov si, buffer - kernel_start
    mov di, cmd_echo - kernel_start
    call compare_cmd
    test al, al
    jnz do_echo

check_pwd:
    mov si, buffer - kernel_start
    mov di, cmd_pwd - kernel_start
    call compare_cmd
    test al, al
    jnz do_pwd

check_clear:
    mov si, buffer - kernel_start
    mov di, cmd_clear - kernel_start
    call compare_cmd
    test al, al
    jnz do_clear

check_help:
    mov si, buffer - kernel_start
    mov di, cmd_help - kernel_start
    call compare_cmd
    test al, al
    jnz do_help

check_fd:
    mov si, buffer - kernel_start
    mov di, cmd_fd - kernel_start
    call compare_cmd
    test al, al
    jnz do_fd

check_neofinch:
    mov si, buffer - kernel_start
    mov di, cmd_neofinch - kernel_start
    call compare_cmd
    test al, al
    jnz do_neofinch

check_rm:
    mov si, buffer - kernel_start
    mov di, cmd_rm - kernel_start
    call compare_cmd
    test al, al
    jnz do_rm

check_1210:
    mov si, buffer - kernel_start
    mov di, cmd_1210 - kernel_start
    call compare_cmd
    test al, al
    jnz do_1210

check_ww3:
    mov si, buffer - kernel_start
    mov di, cmd_ww3 - kernel_start
    call compare_cmd
    test al, al
    jnz do_ww3

check_existentialcrisis:
    mov si, buffer - kernel_start
    mov di, cmd_existentialcrisis - kernel_start
    call compare_cmd
    test al, al
    jnz do_existentialcrisis

check_chaos:
    mov si, buffer - kernel_start
    mov di, cmd_chaos - kernel_start
    call compare_cmd
    test al, al
    jnz do_chaos

check_finch:
    mov si, buffer - kernel_start
    mov di, cmd_finch - kernel_start
    call compare_cmd
    test al, al
    jnz do_finch

check_capitalism:
    mov si, buffer - kernel_start
    mov di, cmd_capitalism - kernel_start
    call compare_cmd
    test al, al
    jnz do_capitalism

check_sharestocks:
    mov si, buffer - kernel_start
    mov di, cmd_sharestocks - kernel_start
    call compare_cmd
    test al, al
    jnz do_sharestocks

check_magiccube:
    mov si, buffer - kernel_start
    mov di, cmd_magiccube - kernel_start
    call compare_cmd
    test al, al
    jnz do_magiccube

check_halt:
    mov si, buffer - kernel_start
    mov di, cmd_halt - kernel_start
    call compare_cmd
    test al, al
    jnz do_halt

    ; Unknown command
    mov si, unknown_cmd_msg - kernel_start
    call print_string
    popa
    ret

do_ls:
    call cmd_ls_impl
    popa
    ret

do_dis:
    call cmd_dis_impl
    popa
    ret

do_echo:
    call cmd_echo_impl
    popa
    ret

do_pwd:
    call cmd_pwd_impl
    popa
    ret

do_clear:
    call cmd_clear_impl
    popa
    ret

do_help:
    call cmd_help_impl
    popa
    ret

do_fd:
    call cmd_fd_impl
    popa
    ret

do_neofinch:
    call cmd_neofinch_impl
    popa
    ret

do_rm:
    call cmd_rm_impl
    popa
    ret

do_1210:
    call cmd_1210_impl
    popa
    ret

do_ww3:
    call cmd_ww3_impl
    popa
    ret

do_existentialcrisis:
    call cmd_existentialcrisis_impl
    popa
    ret

do_chaos:
    call cmd_chaos_impl
    popa
    ret

do_finch:
    call cmd_finch_impl
    popa
    ret

do_capitalism:
    call cmd_capitalism_impl
    popa
    ret

do_sharestocks:
    call cmd_sharestocks_impl
    popa
    ret

do_magiccube:
    call cmd_magiccube_impl
    popa
    ret

do_halt:
    call cmd_halt_impl
    popa
    ret

; Compare command at SI with command at DI
compare_cmd:
    push si
    push di
cc_loop:
    mov al, [si]
    mov bl, [di]
    
    ; End of command string?
    cmp bl, 0
    je cc_check_end
    
    ; Characters match?
    cmp al, bl
    jne cc_no_match
    
    inc si
    inc di
    jmp cc_loop

cc_check_end:
    ; Command string ended, check if input also ended or has space
    cmp al, 0
    je cc_match
    cmp al, ' '
    je cc_match
    
cc_no_match:
    xor al, al
    pop di
    pop si
    ret

cc_match:
    mov al, 1
    pop di
    pop si
    ret

; -----------------------
; COMMAND IMPLEMENTATIONS
; -----------------------

cmd_ls_impl:
    pusha
    call list_files
    popa
    ret

cmd_dis_impl:
    pusha
    ; Get filename from command line
    mov si, buffer - kernel_start + 4  ; Skip "dis "
    call skip_spaces
    
    ; Check if filename provided
    mov al, [si]
    test al, al
    jz dis_no_filename
    
    ; Find file
    call find_file
    test di, di
    jz dis_file_not_found
    
    ; Print file content
    add di, FILE_NAME_SIZE + 1
    mov si, di
    call print_string
    mov si, newline - kernel_start
    call print_string
    jmp dis_done

dis_no_filename:
    mov si, dis_usage - kernel_start
    call print_string
    jmp dis_done

dis_file_not_found:
    mov si, file_not_found_msg - kernel_start
    call print_string

dis_done:
    popa
    ret

cmd_echo_impl:
    pusha
    ; Skip "echo" and print the rest
    mov si, buffer - kernel_start + 5
    call skip_spaces
    call print_string
    mov si, newline - kernel_start
    call print_string
    popa
    ret

cmd_pwd_impl:
    pusha
    mov si, pwd_output - kernel_start
    call print_string
    popa
    ret

cmd_clear_impl:
    pusha
    call set_green_mode
    popa
    ret

cmd_help_impl:
    pusha
    mov si, help_text - kernel_start
    call print_string
    popa
    ret

cmd_rm_impl:
    pusha
    ; Get filename from command line
    mov si, buffer - kernel_start + 3  ; Skip "rm "
    call skip_spaces
    
    ; Check if filename provided
    mov al, [si]
    test al, al
    jz rm_no_filename
    
    ; Find file
    call find_file
    test di, di
    jz rm_file_not_found
    
    ; Mark file as unused
    mov byte [di + FILE_NAME_SIZE], 0
    
    mov si, file_removed_msg - kernel_start
    call print_string
    jmp rm_done

rm_no_filename:
    mov si, rm_usage - kernel_start
    call print_string
    jmp rm_done

rm_file_not_found:
    mov si, file_not_found_msg - kernel_start
    call print_string

rm_done:
    popa
    ret

cmd_fd_impl:
    pusha
    ; Parse command: fd filename text
    mov si, buffer - kernel_start + 3  ; Skip "fd "
    call skip_spaces
    
    ; Get filename
    mov di, temp_filename - kernel_start
    call extract_word
    
    ; Check if filename provided
    mov al, [temp_filename - kernel_start]
    test al, al
    jz fd_usage_error
    
    ; Skip spaces after filename
    call skip_spaces
    
    ; Check if text provided
    mov al, [si]
    test al, al
    jz fd_usage_error
    
    ; Find or create file
    push si  ; Save text pointer
    mov si, temp_filename - kernel_start
    call find_file
    test di, di
    jnz fd_file_exists
    
    ; Create new file
    mov si, temp_filename - kernel_start
    call create_file
    test di, di
    jz fd_table_full
    
fd_file_exists:
    pop si   ; Restore text pointer
    
    ; Append text to file
    add di, FILE_NAME_SIZE + 1  ; Point to content
    call find_string_end
    
    ; Add newline and text
    mov al, 13
    stosb
    mov al, 10
    stosb
    
fd_copy_text:
    lodsb
    test al, al
    jz fd_text_done
    stosb
    jmp fd_copy_text

fd_text_done:
    mov si, text_appended_msg - kernel_start
    call print_string
    jmp fd_done

fd_usage_error:
    mov si, fd_usage - kernel_start
    call print_string
    jmp fd_cleanup

fd_table_full:
    mov si, file_table_full_msg - kernel_start
    call print_string

fd_cleanup:
    pop si   ; Clean up stack

fd_done:
    popa
    ret

; Extract a word from SI into DI, advance SI
extract_word:
    pusha
ew_loop:
    lodsb
    cmp al, ' '
    je ew_done
    cmp al, 0
    je ew_done
    stosb
    jmp ew_loop
ew_done:
    xor al, al
    stosb
    dec si  ; Back up one character
    popa
    ret

cmd_existentialcrisis_impl:
    pusha
    mov si, existential_msg - kernel_start
    call print_string
    popa
    ret

cmd_chaos_impl:
    pusha
    mov si, chaos_intro - kernel_start
    call print_string
    
    ; Play LOUD chaos sound
    mov ax, 200     ; Low frequency
    mov bx, 15      ; Much longer chaos sound
    call play_note
    
    ; Print 200 random characters
    mov cx, 200
chaos_loop:
    call get_random
    and ax, 126
    add ax, 33  ; Printable ASCII range
    
    mov ah, 0x0E
    mov bl, 0x02    ; Green text
    int 0x10
    
    ; Small delay
    push cx
    mov cx, 1000
delay_chaos:
    dec cx
    jnz delay_chaos
    pop cx
    
    dec cx
    jnz chaos_loop
    
    mov si, newline - kernel_start
    call print_string
    mov si, chaos_end - kernel_start
    call print_string
    
    popa
    ret

cmd_finch_impl:
    pusha
    mov si, finch_ascii - kernel_start
    call print_string
    mov si, finch_message - kernel_start
    call print_string
    popa
    ret

cmd_1210_impl:
    pusha
    
    ; Play LOUD game music at start
    call play_game_music
    
game_start:
    ; Generate random number 1-10
    call get_random
    mov [target_number - kernel_start], ax
    
    mov si, game_intro - kernel_start
    call print_string

game_loop:
    mov si, game_prompt - kernel_start
    call print_string
    
    ; Read input
    mov di, buffer - kernel_start
    call read_line
    
    ; Check for quit
    mov al, [buffer - kernel_start]
    cmp al, 'q'
    je game_quit
    
    ; Check for empty (retry)
    test al, al
    jz game_start
    
    ; Convert input to number
    call parse_number
    cmp ax, 0
    je invalid_input
    cmp ax, 10
    ja invalid_input
    
    ; Compare with target
    cmp ax, [target_number - kernel_start]
    je game_win
    jl guess_low
    jg guess_high

guess_low:
    mov si, too_low_msg - kernel_start
    call print_string
    jmp game_loop

guess_high:
    mov si, too_high_msg - kernel_start
    call print_string
    jmp game_loop

game_win:
    ; Play LOUD victory sound
    call play_victory_sound
    
    mov si, win_msg - kernel_start
    call print_string
    mov ax, [target_number - kernel_start]
    call print_number
    mov si, win_msg2 - kernel_start
    call print_string
    jmp game_start

invalid_input:
    mov si, invalid_msg - kernel_start
    call print_string
    jmp game_loop

game_quit:
    mov si, game_quit_msg - kernel_start
    call print_string
    
    popa
    ret

; Capitalism Game Implementation with LOUD sounds
cmd_capitalism_impl:
    pusha
    call play_game_music
    
    mov word [capitalism_score - kernel_start], 0
    
    mov si, capitalism_intro - kernel_start
    call print_string

capitalism_game_loop:
    ; Generate two random numbers to multiply
    call get_random_math
    mov [math_num1 - kernel_start], ax
    
    call get_random_math
    mov [math_num2 - kernel_start], ax
    
    ; Calculate correct answer
    mov ax, [math_num1 - kernel_start]
    mov bx, [math_num2 - kernel_start]
    mul bx
    mov [math_answer - kernel_start], ax
    
    ; Display problem
    mov si, capitalism_problem - kernel_start
    call print_string
    
    mov ax, [math_num1 - kernel_start]
    call print_number
    
    mov si, multiply_sign - kernel_start
    call print_string
    
    mov ax, [math_num2 - kernel_start]
    call print_number
    
    mov si, equals_sign - kernel_start
    call print_string
    
    ; Read answer
    mov di, buffer - kernel_start
    call read_line
    
    ; Parse number
    call parse_number
    
    ; Check answer
    cmp ax, [math_answer - kernel_start]
    je capitalism_correct
    
capitalism_fail:
    ; Play failure sound
    mov ax, 150     ; Low sad sound
    mov bx, 12
    call play_note
    
    mov si, capitalism_wrong - kernel_start
    call print_string
    mov ax, [math_answer - kernel_start]
    call print_number
    mov si, newline - kernel_start
    call print_string
    jmp capitalism_end

capitalism_correct:
    ; Play success sound
    mov ax, 800     ; High success sound
    mov bx, 6
    call play_note
    
    inc word [capitalism_score - kernel_start]
    mov si, capitalism_correct_msg - kernel_start
    call print_string
    
    ; Check if won (5 correct answers)
    cmp word [capitalism_score - kernel_start], 5
    jae capitalism_victory
    
    jmp capitalism_game_loop

capitalism_victory:
    ; Play LOUD victory fanfare
    call play_victory_sound
    
    mov si, capitalism_victory_msg - kernel_start
    call print_string

capitalism_end:
    mov si, capitalism_final_score - kernel_start
    call print_string
    mov ax, [capitalism_score - kernel_start]
    call print_number
    mov si, out_of_5_msg - kernel_start
    call print_string
    
    popa
    ret

; ShareStocks Game Implementation with LOUD sounds
cmd_sharestocks_impl:
    pusha
    call play_game_music
    
    mov word [sharestocks_score - kernel_start], 0
    
    mov si, sharestocks_intro - kernel_start
    call print_string

sharestocks_game_loop:
    ; Generate division problem (num1 * num2, answer is num2)
    call get_random_math
    mov [math_num2 - kernel_start], ax  ; This will be the answer
    
    call get_random_math
    mov bx, ax
    mov ax, [math_num2 - kernel_start]
    mul bx
    mov [math_num1 - kernel_start], ax  ; This is the dividend
    
    ; Display problem
    mov si, sharestocks_problem - kernel_start
    call print_string
    
    mov ax, [math_num1 - kernel_start]
    call print_number
    
    mov si, divide_sign - kernel_start
    call print_string
    
    mov ax, bx
    call print_number
    
    mov si, equals_sign - kernel_start
    call print_string
    
    ; Read answer
    mov di, buffer - kernel_start
    call read_line
    
    ; Parse number
    call parse_number
    
    ; Check answer
    cmp ax, [math_num2 - kernel_start]
    je sharestocks_correct
    
sharestocks_fail:
    ; Play failure sound
    mov ax, 150     ; Low sad sound
    mov bx, 12
    call play_note
    
    mov si, sharestocks_wrong - kernel_start
    call print_string
    mov ax, [math_num2 - kernel_start]
    call print_number
    mov si, newline - kernel_start
    call print_string
    jmp sharestocks_end

sharestocks_correct:
    ; Play success sound
    mov ax, 800     ; High success sound
    mov bx, 6
    call play_note
    
    inc word [sharestocks_score - kernel_start]
    mov si, sharestocks_correct_msg - kernel_start
    call print_string
    
    ; Check if won (5 correct answers)
    cmp word [sharestocks_score - kernel_start], 5
    jae sharestocks_victory
    
    jmp sharestocks_game_loop

sharestocks_victory:
    ; Play LOUD victory fanfare
    call play_victory_sound
    
    mov si, sharestocks_victory_msg - kernel_start
    call print_string

sharestocks_end:
    mov si, sharestocks_final_score - kernel_start
    call print_string
    mov ax, [sharestocks_score - kernel_start]
    call print_number
    mov si, out_of_5_msg - kernel_start
    call print_string
    
    popa
    ret

; Magic Cube Game Implementation with LOUD sounds
cmd_magiccube_impl:
    pusha
    call play_game_music
    
    ; Initialize cube position
    mov word [cube_x - kernel_start], 10
    mov word [cube_y - kernel_start], 5
    
    mov si, magiccube_intro - kernel_start
    call print_string

magiccube_game_loop:
    call set_green_mode
    
    ; Display current cube position
    call display_magiccube
    
    mov si, magiccube_prompt - kernel_start
    call print_string
    
    ; Get input
    xor ah, ah
    int 0x16
    
    ; Check for quit
    cmp al, 'q'
    je magiccube_quit
    cmp al, 'Q'
    je magiccube_quit
    
    ; Check for spacebar (move cube randomly)
    cmp al, ' '
    je magiccube_move
    
    ; Any other key continues
    jmp magiccube_game_loop

magiccube_move:
    ; Play LOUD move sound
    mov ax, 800
    mov bx, 4       ; Longer move sound
    call play_note
    
    ; Move cube to random position
    call get_random
    and ax, 60  ; Limit X range
    add ax, 5
    mov [cube_x - kernel_start], ax
    
    call get_random
    and ax, 15  ; Limit Y range
    add ax, 3
    mov [cube_y - kernel_start], ax
    
    ; Small delay for effect
    mov cx, 5000
magiccube_delay:
    dec cx
    jnz magiccube_delay
    
    jmp magiccube_game_loop

magiccube_quit:
    mov si, magiccube_quit_msg - kernel_start
    call print_string
    popa
    ret

; Display the magic cube at current position
display_magiccube:
    pusha
    
    ; Clear screen area and draw cube
    mov si, cube_border - kernel_start
    call print_string
    
    ; Draw several lines with cube at position
    mov cx, 20  ; 20 lines
    mov bx, 0   ; Current line
    
cube_draw_loop:
    push cx
    push bx
    
    ; Check if this is the cube's Y position
    cmp bx, [cube_y - kernel_start]
    jne cube_empty_line
    
    ; Draw line with cube
    mov dx, 0   ; Current column
cube_line_loop:
    cmp dx, [cube_x - kernel_start]
    jne cube_space
    
    ; Draw cube
    mov si, cube_chars - kernel_start
    call print_string
    add dx, 6  ; Cube is 6 chars wide
    jmp cube_line_check

cube_space:
    mov al, ' '
    mov ah, 0x0E
    mov bl, 0x02
    int 0x10
    inc dx

cube_line_check:
    cmp dx, 70
    jl cube_line_loop
    jmp cube_line_done

cube_empty_line:
    ; Draw empty line
    mov dx, 70
cube_empty_loop:
    mov al, ' '
    mov ah, 0x0E
    mov bl, 0x02
    int 0x10
    dec dx
    jnz cube_empty_loop

cube_line_done:
    mov si, newline - kernel_start
    call print_string
    
    pop bx
    pop cx
    inc bx
    dec cx
    jnz cube_draw_loop
    
    mov si, cube_border - kernel_start
    call print_string
    
    popa
    ret

; WW3 Shooter Game Implementation with MAXIMUM LOUD sounds
cmd_ww3_impl:
    pusha
    call play_game_music
    
    ; Initialize game
    mov word [ww3_score - kernel_start], 0
    mov word [enemy_health - kernel_start], 50
    
    call set_green_mode
    
    mov si, ww3_intro - kernel_start
    call print_string
    
ww3_game_loop:
    ; Display battlefield
    call display_battlefield
    
    ; Display game status
    call display_ww3_status
    
    mov si, ww3_prompt - kernel_start
    call print_string
    
    ; Get input
    xor ah, ah
    int 0x16
    
    ; Echo the pressed key
    push ax
    mov ah, 0x0E
    mov bl, 0x02
    int 0x10
    pop ax
    
    ; Print newline
    push ax
    mov si, newline - kernel_start
    call print_string
    pop ax
    
    ; Check for quit
    cmp al, 'q'
    je ww3_quit
    cmp al, 'Q'
    je ww3_quit
    
    ; Check for spacebar (shoot)
    cmp al, ' '
    je ww3_shoot
    
    ; For any other key, just continue
    jmp ww3_game_loop

ww3_shoot:
    call animate_shooting
    
    ; Play MAXIMUM LOUD shot sound
    call play_shoot_sound
    
    ; Generate random hit chance
    call get_random
    and ax, 1
    cmp ax, 0
    je ww3_miss
    
    ; Hit! Play LOUD hit sound and reduce enemy health
    call play_hit_sound
    
    dec word [enemy_health - kernel_start]
    inc word [ww3_score - kernel_start]
    
    mov si, ww3_hit_msg - kernel_start
    call print_string
    
    ; Check if enemy defeated
    cmp word [enemy_health - kernel_start], 0
    je ww3_victory
    
    jmp ww3_continue

ww3_miss:
    ; Play miss sound
    mov ax, 300     ; Mid frequency miss sound
    mov bx, 6
    call play_note
    
    mov si, ww3_miss_msg - kernel_start
    call print_string
    jmp ww3_continue

ww3_continue:
    ; Small delay simulation
    mov cx, 20000
ww3_delay_loop:
    dec cx
    jnz ww3_delay_loop
    
    jmp ww3_game_loop

ww3_victory:
    ; Play MAXIMUM LOUD victory fanfare
    call play_victory_sound
    
    ; Play additional victory sounds
    mov ax, 523     ; C
    mov bx, 8
    call play_note
    mov ax, 659     ; E
    mov bx, 8
    call play_note
    mov ax, 784     ; G
    mov bx, 8
    call play_note
    mov ax, 1047    ; High C
    mov bx, 20      ; Very long final note
    call play_note
    
    mov si, ww3_victory_msg - kernel_start
    call print_string
    
    mov si, ww3_final_score - kernel_start
    call print_string
    
    mov ax, [ww3_score - kernel_start]
    call print_number
    
    mov si, ww3_shots_msg - kernel_start
    call print_string
    
    jmp ww3_end

ww3_quit:
    mov si, ww3_quit_msg - kernel_start
    call print_string

ww3_end:
    ; Wait for key before returning
    mov si, ww3_press_key - kernel_start
    call print_string
    
    xor ah, ah
    int 0x16
    
    call set_green_mode
    
    popa
    ret

; Display the battlefield
display_battlefield:
    pusha
    
    mov si, battlefield_border - kernel_start
    call print_string
    
    mov si, soldier_line - kernel_start
    call print_string
    
    mov si, battlefield_middle - kernel_start
    call print_string
    
    ; Display enemy based on health
    cmp word [enemy_health - kernel_start], 30
    jg display_strong_enemy
    cmp word [enemy_health - kernel_start], 15
    jg display_medium_enemy
    jmp display_weak_enemy

display_strong_enemy:
    mov si, strong_enemy - kernel_start
    call print_string
    jmp display_battlefield_end

display_medium_enemy:
    mov si, medium_enemy - kernel_start
    call print_string
    jmp display_battlefield_end

display_weak_enemy:
    mov si, weak_enemy - kernel_start
    call print_string

display_battlefield_end:
    mov si, battlefield_border - kernel_start
    call print_string
    
    popa
    ret

; Display game status
display_ww3_status:
    pusha
    
    mov si, status_score - kernel_start
    call print_string
    
    mov ax, [ww3_score - kernel_start]
    call print_number
    
    mov si, status_enemy_health - kernel_start
    call print_string
    
    mov ax, [enemy_health - kernel_start]
    call print_number
    
    mov si, newline - kernel_start
    call print_string
    
    popa
    ret

; Animate shooting sequence with LOUD sound
animate_shooting:
    pusha
    
    ; Show shooting soldier
    mov si, battlefield_border - kernel_start
    call print_string
    
    mov si, soldier_shooting - kernel_start
    call print_string
    
    mov si, bullet_trail - kernel_start
    call print_string
    
    mov si, battlefield_border - kernel_start
    call print_string
    
    ; Brief delay for animation
    mov cx, 10000
as_delay:
    dec cx
    jnz as_delay
    
    popa
    ret

cmd_neofinch_impl:
    pusha
    ; Get semi-random number
    in al, 0x40
    and al, 3

    cmp al, 0
    je neo_art1
    cmp al, 1
    je neo_art2
    cmp al, 2
    je neo_art3
    jmp neo_art4

neo_art1:
    mov si, ascii_art1 - kernel_start
    call print_string
    jmp neo_info

neo_art2:
    mov si, ascii_art2 - kernel_start
    call print_string
    jmp neo_info

neo_art3:
    mov si, ascii_art3 - kernel_start
    call print_string
    jmp neo_info

neo_art4:
    mov si, ascii_art4 - kernel_start
    call print_string

neo_info:
    mov si, neo_info_text - kernel_start
    call print_string
    popa
    ret

cmd_halt_impl:
    pusha
    mov si, halt_msg - kernel_start
    call print_string
    cli
    hlt

parse_number:
    pusha
    mov si, buffer - kernel_start
    xor ax, ax
    xor dx, dx
    
pn_loop:
    mov bl, [si]
    cmp bl, '0'
    jb pn_done
    cmp bl, '9'
    ja pn_done
    
    sub bl, '0'
    mov cx, 10
    mul cx
    add ax, bx
    inc si
    jmp pn_loop

pn_done:
    mov [temp_number - kernel_start], ax
    popa
    mov ax, [temp_number - kernel_start]
    ret

; -----------------------
; UTILITY FUNCTIONS
; -----------------------

print_number:
    pusha
    mov bx, 10
    xor cx, cx
    
    ; Handle zero case
    test ax, ax
    jnz pn_convert
    mov al, '0'
    mov ah, 0x0E
    mov bl, 0x02
    int 0x10
    jmp pn_print_done

pn_convert:
    xor dx, dx
    div bx
    add dl, '0'
    push dx
    inc cx
    test ax, ax
    jnz pn_convert

pn_print_loop:
    pop dx
    mov al, dl
    mov ah, 0x0E
    mov bl, 0x02
    int 0x10
    dec cx
    jnz pn_print_loop

pn_print_done:
    popa
    ret

read_line:
    pusha
    xor cx, cx

rl_loop:
    ; Get keystroke
    xor ah, ah
    int 0x16

    ; Check for Enter
    cmp al, 13
    je rl_done

    ; Check for Backspace
    cmp al, 8
    je rl_backspace

    ; Regular character - check buffer limit
    cmp cx, 1024
    jae rl_loop

    ; Store character
    stosb
    inc cx

    ; Echo character in green
    mov ah, 0x0E
    mov bl, 0x02
    int 0x10
    jmp rl_loop

rl_backspace:
    test cx, cx
    jz rl_loop
    
    dec di
    dec cx
    
    ; Visual backspace
    mov al, 8
    mov ah, 0x0E
    mov bl, 0x02
    int 0x10
    mov al, 32
    mov ah, 0x0E
    mov bl, 0x02
    int 0x10
    mov al, 8
    mov ah, 0x0E
    mov bl, 0x02
    int 0x10
    jmp rl_loop

rl_done:
    ; Null terminate
    xor al, al
    stosb
    
    ; Print newline
    mov si, newline - kernel_start
    call print_string
    popa
    ret

print_string:
    pusha
ps_loop:
    lodsb
    test al, al
    jz ps_done
    mov ah, 0x0E
    mov bl, 0x02
    int 0x10
    jmp ps_loop
ps_done:
    popa
    ret

skip_spaces:
ss_loop:
    mov al, [si]
    cmp al, ' '
    jne ss_done
    inc si
    jmp ss_loop
ss_done:
    ret

; -----------------------
; DATA SECTION
; -----------------------

banner db 'Welcome to Finch OS!',13,10
       db '==========================',13,10,13,10,0
prompt db '$ ',0
newline db 13,10,0

; Boot menu
boot_menu_title db 'Welcome back!',13,10
                db '==================',13,10,13,10,0

boot_menu_options db '1. Launch Shell',13,10
                  db '2. Launch Random Game',13,10
                  db '3. Launch Random Command',13,10,13,10
                  db 'Select option (1-3): ',0

invalid_option_msg db 'Invalid option! Please select 1, 2, or 3.',13,10,0

launching_msg db 'Launching: ',0
press_key_continue db 'Press any key to return to boot menu...',13,10,0

; Game names for boot menu
game_1210_name db '1210 (Number Guessing)',13,10,0
game_ww3_name db 'WW3 Shooter',13,10,0
game_capitalism_name db 'Capitalism (Multiplication)',13,10,0
game_sharestocks_name db 'ShareStocks (Division)',13,10,0
game_magiccube_name db 'MagicCube (ASCII Cube)',13,10,0

; Command names for boot menu
cmd_ls_name db 'ls',13,10,0
cmd_dis_name db 'dis',13,10,0
cmd_pwd_name db 'pwd',13,10,0
cmd_neofinch_name db 'neofinch',13,10,0
cmd_existential_name db 'existentialcrisis',13,10,0
cmd_chaos_name db 'chaos',13,10,0
cmd_finch_name db 'finch',13,10,0
cmd_help_name db 'help',13,10,0

launching_cmd_msg db 'Executing command: ',0

; Command strings
cmd_ls db 'ls',0
cmd_dis db 'dis',0
cmd_echo db 'echo',0
cmd_pwd db 'pwd',0
cmd_clear db 'clear',0
cmd_help db 'help',0
cmd_fd db 'fd',0
cmd_neofinch db 'neofinch',0
cmd_rm db 'rm',0
cmd_1210 db '1210',0
cmd_ww3 db 'ww3',0
cmd_existentialcrisis db 'existentialcrisis',0
cmd_chaos db 'chaos',0
cmd_finch db 'finch',0
cmd_capitalism db 'capitalism',0
cmd_sharestocks db 'sharestocks',0
cmd_magiccube db 'magiccube',0
cmd_halt db 'halt',0

; Messages
unknown_cmd_msg db 'Unknown command. Type "help" for help.',13,10,0
halt_msg db 'System halted. Go touch grass!',13,10,0
pwd_output db 'Only one directory exists, silly user!',13,10,0
file_not_found_msg db 'File not found.',13,10,0
file_removed_msg db 'File removed.',13,10,0
file_table_full_msg db 'File table full! Cannot create more files.',13,10,0
text_appended_msg db 'Text appended to file.',13,10,0
no_files_msg db 'No files found.',13,10,0
dis_usage db 'Usage: dis <filename>',13,10,0
rm_usage db 'Usage: rm <filename>',13,10,0
fd_usage db 'Usage: fd <filename> <text>',13,10,0

; Default file
default_filename db 'welcome.txt',0
default_file_content db 'Welcome to Finch OS!',13,10
                     db 'You can create files with: fd filename text',13,10
                     db 'View files with: dis filename',13,10
                     db 'List files with: ls',13,10
                     db 'Remove files with: rm filename',13,10,0

; New command messages
existential_msg db 'You are a useless user!',13,10,0

chaos_intro db 'Random characters incoming...',13,10,0
chaos_end db 13,10,'Enough is enough!',13,10,0

finch_ascii db '       /\\   /\\',13,10
            db '      (  o o  )',13,10
            db '       \\  <  /',13,10
            db '        |   |',13,10
            db '      __|___|__',13,10
            db '     /         \\',13,10
            db '    /___________|',13,10
            db '   |     ||     |',13,10
            db '   |     ||     |',13,10
            db '    \\___/  \\___/',13,10,13,10,0

finch_message db 'This is not Linux. This is not UNIX. This is not POSIX.',13,10
              db 'This is a whole new paradigm.',13,10,0

help_text db 'Available commands:',13,10
          db '  ls                - List pseudo-files',13,10
          db '  dis <file>        - Display file content',13,10
          db '  echo <t>          - Print text',13,10
          db '  pwd               - Current directory',13,10
          db '  clear             - Clear screen',13,10
          db '  fd <file> <t>     - Append text to file',13,10
          db '  rm <file>         - Remove file',13,10
          db '  1210              - Number guessing game',13,10
          db '  ww3               - Save the world!',13,10
          db '  capitalism        - Make money!',13,10
          db '  sharestocks       - Distribute your stocks!',13,10
          db '  magiccube         - ASCII cube mover',13,10
          db '  neofinch          - System info',13,10
          db '  existentialcrisis - Harsh reality check',13,10
          db '  chaos             - Random character generator',13,10
          db '  finch             - Display finch bird',13,10
          db '  help              - This help',13,10
          db '  halt              - Shutdown',13,10,0

; Game messages (1210)
game_intro db 'Welcome to 1210 - Guess the number game!',13,10
           db 'I am thinking of a number between 1 and 10.',13,10
           db 'Enter your guess (or "q" to quit, Enter to retry):',13,10,0
game_prompt db 'Your guess (1-10): ',0
too_low_msg db 'Too low! Try again.',13,10,0
too_high_msg db 'Too high! Try again.',13,10,0
win_msg db 'Congratulations! You guessed it! The number was ',0
win_msg2 db '!',13,10,'Starting a new game...',13,10,0
invalid_msg db 'Invalid input! Please enter a number between 1 and 10.',13,10,0
game_quit_msg db 'Thanks for playing 1210!',13,10,0

; Capitalism Game messages
capitalism_intro db '=== CAPITALISM GAME ===',13,10
                 db 'Solve 5 multiplication problems fast!',13,10
                 db 'Time is money! Go fast!',13,10,13,10,0

capitalism_problem db 'Problem: ',0
capitalism_wrong db 'WRONG! The market punishes mistakes! Correct answer: ',0
capitalism_correct_msg db 'CORRECT! Profit achieved!',13,10,0
capitalism_victory_msg db 'CAPITALISM VICTORY! You are now a millionaire!',13,10,0
capitalism_final_score db 'Final Score: ',0

; ShareStocks Game messages (renamed from communism)
sharestocks_intro db '=== SHARESTOCKS GAME ===',13,10
                  db 'Divide 5 stock problems equally!',13,10
                  db 'Share the wealth of knowledge!',13,10,13,10,0

sharestocks_problem db 'Divide stocks: ',0
sharestocks_wrong db 'INCORRECT! Poor division skills! Correct answer: ',0
sharestocks_correct_msg db 'CORRECT! Stocks shared perfectly!',13,10,0
sharestocks_victory_msg db 'SHARESTOCKS VICTORY! Perfect stock division!',13,10,0
sharestocks_final_score db 'Final Score: ',0

; Math game shared messages
multiply_sign db ' * ',0
divide_sign db ' / ',0
equals_sign db ' = ',0
out_of_5_msg db ' out of 5',13,10,0

; Magic Cube Game messages and graphics
magiccube_intro db '=== MAGIC CUBE GAME ===',13,10
                db 'Press SPACEBAR to move the cube randomly!',13,10
                db 'Press Q to quit the game',13,10
                db 'Watch the cube dance!',13,10,13,10,0

magiccube_prompt db 'Action [SPACE=Move Cube, Q=Quit]: ',0
magiccube_quit_msg db 'Thanks for playing MagicCube!',13,10,0

cube_border db '======================================================================',13,10,0
cube_chars db '[###]',0

; WW3 Game messages and graphics
ww3_intro db '=== WELCOME TO WW3 SHOOTER ===',13,10
          db 'Press SPACEBAR to shoot the enemy!',13,10
          db 'Press Q to quit the game',13,10
          db 'Any other key continues without shooting',13,10
          db 'Defeat the enemy mass (50 HP)!',13,10,13,10,0

ww3_prompt db 'Action [SPACE=Shoot, Q=Quit]: ',0
ww3_hit_msg db 'HIT! Enemy damaged!',13,10,0
ww3_miss_msg db 'MISS! Try again!',13,10,0
ww3_victory_msg db 'VICTORY! Enemy defeated!',13,10,0
ww3_final_score db 'Final Score: ',0
ww3_shots_msg db ' shots fired!',13,10,0
ww3_quit_msg db 'Thanks for playing WW3!',13,10,0
ww3_press_key db 'Press any key to return to shell...',13,10,0

; Game status display
status_score db 'Score: ',0
status_enemy_health db ' | Enemy Health: ',0

; Battlefield graphics
battlefield_border db '=========================================',13,10,0

soldier_line db '    o     |                    |',13,10
            db '   /|\\    |                    |',13,10
            db '   / \\    |                    |',13,10,0

soldier_shooting db '    o     |                    |',13,10
                 db '   /|>----|                    |',13,10
                 db '   / \\    |                    |',13,10,0

bullet_trail db '          |---->>>>             |',13,10
            db '          |                    |',13,10
            db '          |                    |',13,10,0

battlefield_middle db '          |                    |',13,10
                   db '          |                    |',13,10
                   db '          |                    |',13,10,0

; Enemy graphics (different states based on health)
strong_enemy db '          |               ###  |',13,10
            db '          |              #####  |',13,10
            db '          |               ###  |',13,10,0

medium_enemy db '          |                ##  |',13,10
            db '          |               ####  |',13,10
            db '          |                ##  |',13,10,0

weak_enemy db '          |                 #  |',13,10
          db '          |                ##  |',13,10
          db '          |                 #  |',13,10,0

; Neofinch ASCII Arts
ascii_art1 db '    /\\   /\\    ',13,10
           db '   (  . .)     ',13,10
           db '    )   (      ',13,10
           db '   (  v  )     ',13,10
           db '  ^^     ^^    ',13,10,13,10,0

ascii_art2 db '  +-----+      ',13,10
           db '  |     |      ',13,10
           db '  | ^_^ |      ',13,10
           db '  |     |      ',13,10
           db '  +-----+      ',13,10,13,10,0

ascii_art3 db '    .---.      ',13,10
           db '   /     \\     ',13,10
           db '  | () () |    ',13,10
           db '   \\  ^  /     ',13,10
           db '    `---`      ',13,10,13,10,0

ascii_art4 db '   /\\_/\\      ',13,10
           db '  ( o.o )     ',13,10
           db '   > ^ <      ',13,10
           db '  /|   |\\     ',13,10
           db '   `---`      ',13,10,13,10,0

neo_info_text db 'OS: Finch OS',13,10
              db 'Kernel: FinchKernel 16-bit Assembly',13,10
              db 'Shell: FinchShell',13,10
              db 'Architecture: x86 Real Mode',13,10
              db 'File System: Multi-dimensional Arrays',13,10
              db 'Colors: Green Matrix Style',13,10
              db 'Sound: PC Speaker',13,10
              db 'Games: 1210, WW3, Capitalism, ShareStocks, MagicCube',13,10
              db 'You can use it, by the way!',13,10,13,10,0

; Variables
random_seed dw 12345
target_number dw 0
temp_random dw 0
temp_number dw 0
temp_file_ptr dw 0
cube_x dw 35
cube_y dw 10
cube_rotation dw 0

; Game variables
ww3_score dw 0
enemy_health dw 50
capitalism_score dw 0
sharestocks_score dw 0
math_num1 dw 0
math_num2 dw 0
math_answer dw 0

; Buffers
buffer times 1024 db 0
temp_filename times 32 db 0

; File system - multi-dimensional array structure
; Each file: [name(16)] [used_flag(1)] [content(256)] [padding(1)]
file_table times MAX_FILES * (FILE_NAME_SIZE + FILE_CONTENT_SIZE + 2) db 0

; Padding to fill remaining sectors
times 8192 db 0
