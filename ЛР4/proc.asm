.586
.model flat, C
.data
    tmp_val real8 0.0                   ; Переменная для хранения значения tan(x)
.code

PUBLIC f

f PROC
    finit
    ; Пролог функции
    fld qword ptr [esp+4]      ; Загрузить аргумент x в регистр стека FPU (ST(0))

    ; Вычисляем тангенс с использованием fptan:
    fptan                      ; ST(0) = 1.0, ST(1) = tan(x)
    fxch st(1)                 ; ST(0) = tan(x), ST(1) = 1.0
    fst tmp_val                ; Занести значение tan(x)

    ; Проверка на малый тангенс (|tan(x)| <= 1e-15):
    fld tmp_val                ; ST(0) = tan(x)
    fabs                       ; ST(0) = |tan(x)|, ST(1) = tan(x)
    fld qword ptr [epsilon_small] ; Загрузить 1e-15 (ST(0) = 1e-15, ST(1) = |tan(x)|, ST(2) = tan(x))
    fcomi st(0), st(1)         ; Сравниваем |tan(x)| с 1e-15
    fstp st(0)                 ; Удаляем 1e-15 из стека
    jae tan_is_small           ; Если |tan(x)| <= 1e-15, переходим

    ; Проверка на большой тангенс (|tan(x)| >= 1e+15):
    fld tmp_val                ; ST(0) = tan(x)
    fabs                       ; ST(0) = |tan(x)|
    fld qword ptr [epsilon_large] ; Загрузить 1e+15 (ST(0) = 1e+15, ST(1) = |tan(x)|, ST(2) = tan(x))
    fcomi st(0), st(1)         ; Сравниваем |tan(x)| с 1e+15
    fstp st(0)                 ; Удаляем 1e+15 из стека
    jbe tan_is_large           ; Если |tan(x)| >= 1e+15, переходим

    ; Обычное вычисление ctg(x) = 1 / tan(x):
    fld1                      ; ST(0) = 1.0
    fld tmp_val                ; ST(0) = tan(x), ST(1) = 1.0
    fdivp st(1), st(0)         ; ST(0) = ctg(x)

    jmp compute_result         ; Переходим к вычислению результата

tan_is_small:
    ; Если |tan(x)| <= 1e-15, считаем cot(x) бесконечностью:
    fld1                       ; ST(0) = 0.0 (загружаем 0)
    fldz                       ; ST(0) = 0.0, ST(1) = 0.0
    fdivp st(1), st(0)         ; ST(0) = Infinity
    jmp compute_result         ; Переходим к вычислению результата

tan_is_large:
    ; Если |tan(x)| >= 1e+15, считаем cot(x) равным 0:
    fldz                       ; ST(0) = 0.0
    jmp compute_result         ; Переходим к вычислению результата

compute_result:
    ; Вычисляем 2 * x:
    fld qword ptr [esp+4]      ; Загрузить x заново в стек (ST(0) = x, ST(1) = ctg(x))
    fld1                       ; Загружаем 1.0
    fadd st(0), st(0)          ; ST(0) = 2.0
    fmulp st(1), st(0)         ; ST(0) = 2 * x, ST(1) = ctg(x)

    ; Вычисляем ctg(x) - 2 * x:
    fsubp st(1), st(0)         ; ST(0) = ctg(x) - 2 * x

    ; Возврат результата:
    ret

epsilon_small real8 1.0e-15       ; Константа для проверки малого значения
epsilon_large real8 1.0e+15       ; Константа для проверки большого значения


f ENDP

END