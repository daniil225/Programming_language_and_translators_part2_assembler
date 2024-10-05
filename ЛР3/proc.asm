.386
.MODEL FLAT
.DATA ;  data segment 

first_ch db  0 ; Первый символ в строке
second_ch db 0 ; Втророй символ в строке. На него мы будем минять

.CODE ; code segment. Proc here

@change_str@8 proc
; Сохраним в стеке значение в переменной edi
push edi

; Проверка входных данных. Валидируем только размер входной строки
cmp edx, 2
jb end_replace

; Распределим входные параметры по нужным регистрам 
mov edi, ecx ; 1-ый аргумент. Указатель на первый элемент в буфере 
mov ecx, edx ; 2-ой аргумент. Размер строки 

; Сохраним первые 2 символа в строке в переменные 
mov al, [edi]
mov first_ch, al
mov al, [edi + 1]
mov second_ch, al

; Сдвиг на 2 символа вперед и уменьшение на 2 счеткика для итерациям по строке 
add edi, 2
sub ecx, 2

; Обработка символов 
mov al, first_ch

replace_str:
    repne scasb
    je equel
    jne end_replace
equel:
    mov al, second_ch
    dec edi
    stosb
    inc ecx
    mov al, first_ch
    jecxz end_replace
    jmp replace_str

end_replace:
    ; Восстановление регистров из стека 
    pop edi 
    ret
@change_str@8 endp

end