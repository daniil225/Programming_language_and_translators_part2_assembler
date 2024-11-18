.386
.MODEL FLAT, STDCALL

; прототипы внешних функций (процедур) описываются директивой EXTERN,
; после знака @ указывается общая длина передаваемых параметров,
; после двоеточия указывается тип внешнего объекта – процедура
EXTERN GetStdHandle@4: PROC
EXTERN WriteConsoleA@20: PROC
EXTERN CharToOemA@8: PROC
EXTERN ReadConsoleA@20: PROC
EXTERN ExitProcess@4: PROC
EXTERN lstrlenA@4: PROC

.CONST


.DATA ; data segment

tmp_local_var dd 0 ; переменная для хранения внутри функции, каких-либо промежуточных значений

din  dd ? ; Дескриптор ввода
dout dd ? ; Дескриптор вывода dd - резервирет память объемом 4 байта ? - используется для не


strn db "Введите строку: ", 13, 10, 0; Строка для вывода

outbuf db 100 dup(0); Размер буфера на выход
buf db 100 dup(0) ; Размер буфера на вход программы
first_ch db  0 ; Первый символ в строке
second_ch db 0 ; Втророй символ в строке. На него мы будем минять


.CODE

; Инициализация потока ввода данных
; Дескриптор будет сохранен в переменную din
OpenRead proc
	; получить десериптор ввода
	push -10
	call GetStdHandle@4
	mov din, eax
	ret
OpenRead endp

; Получить дескриптор вывода данных
; Дескриптор будет сохранен в переменную dout
OpenWrite proc
	; получить дескриптор выводы
	push -11
	call GetStdHandle@4
	mov dout, eax
	ret
OpenWrite endp

; Функция перекодировки строки для вывода информации
; eax - Адрес строки для перекодировки.
; Результат сохранен в переменную буфер, которая была передана в регистре EAX
ConvertToDOSStr proc
	push eax
	push eax
	call CharToOemA@8 ; Перекодировки
	ret
ConvertToDOSStr endp

; Вывод строки в консоль
; ebx - Указатель на буфер
; ret - eax - Количество действительно выведенных переменных
WriteToConsole proc

	; Получаем длину строки. Длина строки будет в регистре eax
	push ebx
	call lstrlenA@4

	push 0            			; Резервный параметр
	push offset tmp_local_var   ; Адрес переменной куда будут записано количество фактически выведенных значений
	push eax		  			; Размер выводимой строки
	push ebx		  			; Адрес буфера
	push dout         			; Дескриптор консоли для вывода
	call WriteConsoleA@20

	mov eax, tmp_local_var ; Поместить количество выведенных символов в eax
	ret
WriteToConsole endp

; Функция чтения данных из консоли.
; eax - Указатель на буфер куда читаем
; ebx - Максимальный размер буфера - его длина
; ret - В случае успеха в переменной eax будет хранится значение фактически прочитанных символов c учетом перевода каретки и строки
ReadFromConsole proc

	push 0					  ; Резервный параметр
	push offset tmp_local_var ; Адрес переменной, в которую будет помещено еоличество действительно прочитанных символов
	push ebx				  ; Длина буфер
	push eax				  ; Указатель на буфер
	push din 				  ; Дескриптор ввода
	call ReadConsoleA@20      ; Вызво операции чтения

	mov eax, tmp_local_var ; Положить фактически прочитанное количество символов в eax
	ret

ReadFromConsole endp

MAIN PROC


; Базовая настройка
call OpenRead  ;Открываем дескриптор чтения
call OpenWrite ;Открываем дескриптор записи в консоль

mov eax , offset strn; Значение второго операнда перемещается в первый, offset заберает адрес
call ConvertToDOSStr


; Вызов функции для вывода строки приглошения ввести строку
mov ebx, offset strn
call WriteToConsole

; Операция ввода строки
mov eax, offset buf
mov ebx, 100		 ; Размер буфера
call ReadFromConsole ; В регистре eax - фактический размер прочитанной строки с учетом 2 символов
; Валидация размера строки

; В регистре eax содержится количество байт которые были фактически прочитаны
cmp eax, 4
jb end_replace

mov ecx, eax
sub ecx, 2
; Загрузим в esi источник строки
; Загрузим в edi примемник. В сущности это одна и та же переменная
lea edi, buf

; Сохронили значения 1-ого и 2-ого символа в строке
mov al, [edi]
mov first_ch, al
mov al, [edi + 1]
mov second_ch, al

; Сдвинулм на вторую 3-ий элемент в цепочке
inc edi
inc edi
sub ecx, 2

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


; Вывод результата работы программы
mov ebx, offset buf
call WriteToConsole



; return 0;
push 0
call ExitProcess@4


MAIN ENDP
END MAIN
