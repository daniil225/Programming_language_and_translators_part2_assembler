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

mul_coef dd 10 ; Коэффициент шага при переводе 

.DATA ; data segment

din  dd ? ; Дескриптор ввода 
dout dd ? ; Дескриптор вывода dd - резервирет память объемом 4 байта ? - используется для не



tmp_local_var_byte db ? ; Локальная переменная для работы с символами 
tmp_local_var dd ?      ; Локальная переменная, которая для чего нибудь может понадобиться 


table_char byte 30h, 31h, 32h, 33h, 34h, 35h, 36h, 37h, 38h, 39h, 41h, 42h, 43h, 44h, 45h, 46h

strn db "Введите строку число [минимум 4 знака числа]: ", 13, 10, 0; Строка для вывода
str_overflow_error_msg db "Переполнение регистра при конвертации строки в число", 13, 10, 0
str_overflow_error_msg_mul db "Переполнение регистра при операции умножения", 13, 10, 0
str_not_correct_num_char db "Некоректный символ и/или запись числа. Допустимые символы: [0-9] и знак минуса", 13, 10, 0
str_input_str_short db "Введенное число слишком короткое. Длина должна быть 4 символа и более", 13, 10, 0


outbuf db 12 dup(0); Размер буфера на выход 


inbuf      db 15 dup(?) ; Размер буфера на вход программы 

num1 dd 0 ; Первое число - знаковое
num2 dd 0 ; Второе число - знаковое 
result dd 0 ; Результат умножения 

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

; Конвертация строки в число 
; esi - указатель на буфер 
; ecx - длина строки без учета символов перевода строки и возврата каретки он же счетчик цикла
; edi - Здесь будет храниться наш результат вычисления 
; ret - В случаем успеха в переменной edx будет лежать значение числа 
StringToInt proc
	
	; Проверка длины строки, если она 4 <
	cmp ecx, 4
	jl incorrect_input_data_error

	mov tmp_local_var , 1 ; Коэффициент перевода числа для разрядности
	add esi, ecx
	dec esi ; Нужно на 1 сдвинуть вниз 

	for_start:
		mov al, [esi] ; Получить символ с конца строки 	

		; Обработка знака минус
		cmp al, '-' ; Провераем равны ли знаки 
		; Если равно, то переход на метку обработки знака минус 
		je set_minus_bit

		; Валидация строки 
		cmp al , '0' ; Сравнение символа с '0'
		; Если меньше переход на метку ошибки
		jl not_a_number_char_error
		cmp al, '9' ; Сравнение символа с '9' 
		; Если больше то переход на метку ошибки
		jg not_a_number_char_error
		

		; Обработка символа 
		sub al, '0'   ; Перевод из строки в число 
		imul tmp_local_var ; Передвинул число на нужный разряд 
		jo overflow_reg_error ; Проверка на переполнение регистра, если число > INT_MAX
		add [edi], eax ; Прибавили число к результату 

		mov ebx, eax ; Сохранаем последнее прибавлаемое число, необходимо для контроля записи числа, (отсутсвие нуля в входном формате ) 

		; Проверка флага переполнения регистра. Регистр OV = 1
		jo overflow_reg_error ; Если при сложении произошло переполнение то так же ошибка 

		
		
		dec esi ; Двинули указатель на буфер 
		dec ecx ; уменьшили значение переменной счетчика 
		jecxz for_end ;  Если все закаончилось
		

		mov eax , tmp_local_var ; Загружаем переменную для увеличения базы 
		mul mul_coef					; Сдвиг для десятичного разряда
		mov tmp_local_var, eax  ; Сохранили сдвиг по разрядам 
		;jo overflow_reg_error ; Если при сложении произошло переполнение то так же ошибка 
		xor eax, eax ; Сбросили регистр в ноль 
		
		jmp for_start ; Переход на начало цикла 

	for_end:
		; Проверка полученного числа. Число должно быть больше или равно 1000
		mov eax, 1000
		cmp [edi], eax
		jl not_a_number_char_error

		cmp ebx, 0 ; Сравнение последнего введенного числа и нуля 
		je not_a_number_char_error

		ret

	; Обработка знака минус у числа 
	set_minus_bit:

		cmp ebx, 0 ; Сравнение последнего введенного числа и нуля 
		je not_a_number_char_error

		mov eax, [edi]
		or eax, 80000000h ; Бит знака устанавливаем 
		mov [edi], eax
		; ecx == 1
		cmp ecx, 1
		; Если это не так, то это ошибка и у нас не корректная строка 
		jne not_a_number_char_error

		; Полученное число должно быть  -1000 <
		mov eax, 800003E8h ;  800003E8h = -1000
		cmp [edi], eax
		jl not_a_number_char_error
		
		ret
	; Метка для обработки события некорректно веденного символа или формата числа 
	not_a_number_char_error:
		mov eax, offset str_not_correct_num_char
		call ConvertToDOSStr
		mov ebx, offset str_not_correct_num_char
		call WriteToConsole
		push -2
		call ExitProcess@4

	; Метка обработки переполнения регистра 
	overflow_reg_error:
		mov eax, offset str_overflow_error_msg
		call ConvertToDOSStr
		mov ebx, offset str_overflow_error_msg
		call WriteToConsole
		push -2
		call ExitProcess@4

	; Метка некорректно введенного числа 
	incorrect_input_data_error:
		mov eax, offset str_input_str_short
		call ConvertToDOSStr
		mov ebx, offset str_input_str_short
		call WriteToConsole
		push -2
		call ExitProcess@4
	
StringToInt endp


; Коныертация числа в 16 - ый формат и преобразование его в строку 
; Вывести результат в консоль в 16 формате 
; число лежит в переменной result
IntTo16Str proc

	mov ecx , 0; Счетчик цикла
	mov ebp, -1 ; В случае если в числе есть знак минуса то увеличим его на 1
	

	; Проверка знака.
	mov eax, result
	and eax, 80000000h ; Получить бит знака
	and result, 7FFFFFFFh ; Снять бит знака 
	mov ebx , result ; Загрузили в переменную значение переменной для вывода 

	cmp eax, 80000000h
	je SetMinusSign
	jmp continue
	
	SetMinusSign:
		mov outbuf[0] , '-' 
		inc ebp
		jmp continue

	
	continue:
		mov ecx, 8 ; Количество итераций, которое нужно провести 

	; В цикле проходим по всем числам и цыклически получаем их 
	for_start:
		mov eax, ebx ; Загрузили переменную result в регистр 
		and eax, 0000000Fh ; маска 0000|1111 
		; Получаем из массива символ 
		shr ebx, 4 ; сдвиг на 4 бита впарво  

		; А вот костыль по другому не работает 
		mov al, table_char[eax] ; Поместить по индексу код символа 
		mov outbuf[ecx + ebp], al
		
		
		dec ecx ; i-- 
		jecxz for_end ; Если ecx = 0 конец цикла 

		jmp for_start ; На начало цикла 

	for_end:
		ret

IntTo16Str endp

MAIN PROC


; Базовая настройка
call OpenRead  ;Открываем дескриптор чтения
call OpenWrite ;Открываем дескриптор записи в консоль

mov eax , offset strn; Значение второго операнда перемещается в первый, offset заберает адрес
call ConvertToDOSStr


; Ввод первого числа 

; Вызов функции для вывода строки приглошения ввести число 
mov ebx, offset strn
call WriteToConsole

; Операция ввода строки 
mov eax, offset inbuf
mov ebx, 15		; Размер буфера 
call ReadFromConsole ; В регистре eax - фактический размер прочитанной строки с учетом 2 символов 

; Указатель на буфер
mov esi, offset inbuf
; Размер массива, ровно все цифры + знак 
mov ecx, eax
sub ecx, 2
mov edi, offset num1 ; Указатель на область памяти где будет хранится результат преобразоания 
; Конверация строки в число 
call StringToInt

mov eax, num1

; Ввод второго числа
; Вызов функции для вывода строки приглошения ввести число 
mov ebx, offset strn
call WriteToConsole

; Операция ввода строки 
mov eax, offset inbuf
mov ebx, 15		; Размер буфера 
call ReadFromConsole ; В регистре eax - фактический размер прочитанной строки с учетом 2 символов 

; Указатель на буфер
mov esi, offset inbuf
; Размер массива, ровно все цифры + знак 
mov ecx, eax
sub ecx, 2
mov edi, offset num2 ; Указатель на область памяти где будет хранится результат преобразоания 
; Конверация строки в число 
call StringToInt

; Умножение чисел 
mov eax, num1
and eax, 80000000h ; Получить бит знака 
and num1, 7FFFFFFFh ; Снять бит знака 
mov ecx, eax ; Сохрянить информацию о знаке 

mov eax, num2 
and eax, 80000000h ; Получить бит знака 
and num2, 7FFFFFFFh ; Снять бит знака 
xor ecx, eax ; Оставить знак или нет 

mov eax, num1
imul num2 ; Знаковое умножение, нужно, что бы поймать установку бита переполнения 
; Контроль переполнения регистра 
jo mul_overflow_reg_error

; Востановить бит знака если это необходимо  
or eax , ecx
; Сохранаем результат 
mov result, eax 


call IntTo16Str


; Вывод результата в 16-ом формате 
mov eax, offset outbuf
call ConvertToDOSStr
mov ebx, offset outbuf
call WriteToConsole



; return 0;
push 0
call ExitProcess@4

; В случае переполнения в OV=1 
mul_overflow_reg_error:
	mov eax, offset str_overflow_error_msg_mul
	call ConvertToDOSStr
	mov ebx, offset str_overflow_error_msg_mul
	call WriteToConsole
	push -2
	call ExitProcess@4

MAIN ENDP
END MAIN