.386
.MODEL FLAT, STDCALL

; ��������� ������� ������� (��������) ����������� ���������� EXTERN,
; ����� ����� @ ����������� ����� ����� ������������ ����������,
; ����� ��������� ����������� ��� �������� ������� � ���������
EXTERN GetStdHandle@4: PROC
EXTERN WriteConsoleA@20: PROC
EXTERN CharToOemA@8: PROC
EXTERN ReadConsoleA@20: PROC
EXTERN ExitProcess@4: PROC
EXTERN lstrlenA@4: PROC

.CONST


.DATA ; data segment

tmp_local_var dd 0 ; ���������� ��� �������� ������ �������, �����-���� ������������� ��������

din  dd ? ; ���������� �����
dout dd ? ; ���������� ������ dd - ���������� ������ ������� 4 ����� ? - ������������ ��� ��


strn db "������� ������: ", 13, 10, 0; ������ ��� ������

outbuf db 100 dup(0); ������ ������ �� �����
buf db 100 dup(0) ; ������ ������ �� ���� ���������
first_ch db  0 ; ������ ������ � ������
second_ch db 0 ; ������� ������ � ������. �� ���� �� ����� ������


.CODE

; ������������� ������ ����� ������
; ���������� ����� �������� � ���������� din
OpenRead proc
	; �������� ���������� �����
	push -10
	call GetStdHandle@4
	mov din, eax
	ret
OpenRead endp

; �������� ���������� ������ ������
; ���������� ����� �������� � ���������� dout
OpenWrite proc
	; �������� ���������� ������
	push -11
	call GetStdHandle@4
	mov dout, eax
	ret
OpenWrite endp

; ������� ������������� ������ ��� ������ ����������
; eax - ����� ������ ��� �������������.
; ��������� �������� � ���������� �����, ������� ���� �������� � �������� EAX
ConvertToDOSStr proc
	push eax
	push eax
	call CharToOemA@8 ; �������������
	ret
ConvertToDOSStr endp

; ����� ������ � �������
; ebx - ��������� �� �����
; ret - eax - ���������� ������������� ���������� ����������
WriteToConsole proc

	; �������� ����� ������. ����� ������ ����� � �������� eax
	push ebx
	call lstrlenA@4

	push 0            			; ��������� ��������
	push offset tmp_local_var   ; ����� ���������� ���� ����� �������� ���������� ���������� ���������� ��������
	push eax		  			; ������ ��������� ������
	push ebx		  			; ����� ������
	push dout         			; ���������� ������� ��� ������
	call WriteConsoleA@20

	mov eax, tmp_local_var ; ��������� ���������� ���������� �������� � eax
	ret
WriteToConsole endp

; ������� ������ ������ �� �������.
; eax - ��������� �� ����� ���� ������
; ebx - ������������ ������ ������ - ��� �����
; ret - � ������ ������ � ���������� eax ����� �������� �������� ���������� ����������� �������� c ������ �������� ������� � ������
ReadFromConsole proc

	push 0					  ; ��������� ��������
	push offset tmp_local_var ; ����� ����������, � ������� ����� �������� ���������� ������������� ����������� ��������
	push ebx				  ; ����� �����
	push eax				  ; ��������� �� �����
	push din 				  ; ���������� �����
	call ReadConsoleA@20      ; ����� �������� ������

	mov eax, tmp_local_var ; �������� ���������� ����������� ���������� �������� � eax
	ret

ReadFromConsole endp

MAIN PROC


; ������� ���������
call OpenRead  ;��������� ���������� ������
call OpenWrite ;��������� ���������� ������ � �������

mov eax , offset strn; �������� ������� �������� ������������ � ������, offset �������� �����
call ConvertToDOSStr


; ����� ������� ��� ������ ������ ����������� ������ ������
mov ebx, offset strn
call WriteToConsole

; �������� ����� ������
mov eax, offset buf
mov ebx, 100		 ; ������ ������
call ReadFromConsole ; � �������� eax - ����������� ������ ����������� ������ � ������ 2 ��������
; ��������� ������� ������

; � �������� eax ���������� ���������� ���� ������� ���� ���������� ���������
cmp eax, 4
jb end_replace

mov ecx, eax
sub ecx, 2
; �������� � esi �������� ������
; �������� � edi ���������. � �������� ��� ���� � �� �� ����������
lea edi, buf

; ��������� �������� 1-��� � 2-��� ������� � ������
mov al, [edi]
mov first_ch, al
mov al, [edi + 1]
mov second_ch, al

; �������� �� ������ 3-�� ������� � �������
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


; ����� ���������� ������ ���������
mov ebx, offset buf
call WriteToConsole



; return 0;
push 0
call ExitProcess@4


MAIN ENDP
END MAIN
