% Parte II: Programación lógica (Prolog)
% Relaciones: pixel negro, f(X, Altura), M = {f(X)}, area(M, A)
%
% imagen(Ancho, Alto, BytesFila, Raster)
% f(X, Imagen, Altura)  ≡  negros consecutivos desde la base de la columna X
% M se obtiene con findall/3;  A con sum_list/2  (Riemann, Δx = 1).

:- initialization(main, main).

main(Argv) :-
    ( Argv = [Ruta|_] -> true ; Ruta = 'data/curva_binaria_P4.pbm' ),
    cargar_p4(Ruta, Imagen),
    Imagen = imagen(Ancho, Alto, _Bpr, _R),
    Last is Ancho - 1,
    findall(H, (between(0, Last, X), f(X, Imagen, H)), M),
    sum_list(M, Area),
    format('=== Prolog · relaciones sobre PBM P4 ===~n'),
    format('Archivo: ~w~n', [Ruta]),
    format('Dimensiones: ~d × ~d~n', [Ancho, Alto]),
    format('Relación f(X, Imagen, Altura): negros consecutivos desde la base~n'),
    format('M = findall(H, (between(0,W-1,X), f(X,Imagen,H)), M)~n'),
    format('A = sum_list(M, A)  (Δx = 1)  →  ~d px²~n~n', [Area]),
    format('--- Imagen binaria (muestreo espacial + bloques Unicode 2×1) ---~n'),
    format('Estrategia: la imagen no cabe en la terminal; se muestrean columnas~n'),
    format('y filas y se agrupan 2 filas en un glifo (▀ ▄ █ espacio).~n'),
    vista_imagen(Imagen, 80, 24),
    nl,
    format('--- Función de altura M[x] = f(x) ---~n'),
    vista_alturas(M, 80, 16),
    nl,
    format('--- Muestras x_i → f(x_i) ---~n'),
    muestras(M, 12).

% ---------- Carga P4 (binario; raster como término arg/3, acceso O(1)) ----------

cargar_p4(Ruta, imagen(Ancho, Alto, BytesFila, Raster)) :-
    open(Ruta, read, S, [type(binary)]),
    leer_bytes(S, Bytes),
    close(S),
    parsear_p4(Bytes, Ancho, Alto, ListaRaster),
    BytesFila is (Ancho + 7) // 8,
    lista_a_raster(ListaRaster, Raster).

leer_bytes(S, Bytes) :-
    get_byte(S, B),
    ( B =:= -1 -> Bytes = [] ; Bytes = [B|R], leer_bytes(S, R) ).

parsear_p4(Bytes, Ancho, Alto, Raster) :-
    saltar_sep(Bytes, B1),
    exigir_p4(B1, B2),
    saltar_sep(B2, B3),
    leer_entero(B3, Ancho, B4),
    saltar_sep(B4, B5),
    leer_entero(B5, Alto, B6),
    saltar_un_blanco(B6, Raster).

exigir_p4([80,52|Rest], Rest) :- !.
exigir_p4(_, _) :- throw(error(pbm, 'Se esperaba magia P4')).

saltar_sep([35|T], Rest) :- !,
    saltar_linea(T, T2),
    saltar_sep(T2, Rest).
saltar_sep([B|T], Rest) :-
    blanco(B), !,
    saltar_sep(T, Rest).
saltar_sep(L, L).

saltar_linea([10|T], T) :- !.
saltar_linea([_|T], R) :- saltar_linea(T, R).
saltar_linea([], []).

saltar_un_blanco([35|T], Rest) :- !,
    saltar_linea(T, T2),
    saltar_un_blanco(T2, Rest).
saltar_un_blanco([B|T], T) :- blanco(B), !.
saltar_un_blanco(L, L).

blanco(9). blanco(10). blanco(13). blanco(32).

leer_entero([C|T], N, Rest) :-
    digito(C),
    leer_digitos(T, [C], Digs, Rest),
    number_codes(N, Digs).

leer_digitos([C|T], Acc, Digs, Rest) :-
    digito(C), !,
    append(Acc, [C], Acc2),
    leer_digitos(T, Acc2, Digs, Rest).
leer_digitos(L, Acc, Acc, L).

digito(C) :- C >= 48, C =< 57.

lista_a_raster(List, Term) :-
    length(List, N),
    functor(Term, raster, N),
    rellenar(1, List, Term).

rellenar(_, [], _) :- !.
rellenar(I, [B|Bs], Term) :-
    arg(I, Term, B),
    I2 is I + 1,
    rellenar(I2, Bs, Term).

% ---------- Píxel y relación f/3 ----------

% negro(X, Y, Imagen): Y = 0 es la fila superior.
% Bit 7 del byte = píxel más a la izquierda (especificación P4).
negro(X, Y, imagen(Ancho, Alto, BytesFila, Raster)) :-
    X >= 0, X < Ancho, Y >= 0, Y < Alto,
    ByteIdx is Y * BytesFila + X // 8,
    Arg is ByteIdx + 1,
    arg(Arg, Raster, Byte),
    Bit is 7 - (X mod 8),
    Mask is 1 << Bit,
    Byte /\ Mask =\= 0.

% f(X, Imagen, Altura)
f(X, Imagen, Altura) :-
    Imagen = imagen(_Ancho, Alto, _Bpr, _R),
    Y0 is Alto - 1,
    contar_desde(X, Y0, Imagen, 0, Altura).

contar_desde(_X, Y, imagen(_A, Alto, _B, _R), Acc, Acc) :-
    (Y < 0 ; Y >= Alto), !.
contar_desde(X, Y, Imagen, Acc, Altura) :-
    (  negro(X, Y, Imagen)
    -> Acc1 is Acc + 1,
       Y1 is Y - 1,
       contar_desde(X, Y1, Imagen, Acc1, Altura)
    ;  Altura = Acc
    ).

% ---------- Visualización ----------

vista_imagen(Imagen, Cols, FilasCar) :-
    Imagen = imagen(Ancho, Alto, _B, _R),
    FilasPix is FilasCar * 2,
    muestrear(Ancho, Cols, Xs),
    muestrear(Alto, FilasPix, Ys),
    agrupar2(Ys, Pares),
    maplist(imprimir_linea_img(Imagen, Xs), Pares).

imprimir_linea_img(Imagen, Xs, (YSup, YInf)) :-
    maplist(glifo_px(Imagen, YSup, YInf), Xs, Chars),
    string_chars(S, Chars),
    format('~w~n', [S]).

glifo_px(Imagen, YSup, YInf, X, G) :-
    (negro(X, YSup, Imagen) -> Sup = 1 ; Sup = 0),
    (negro(X, YInf, Imagen) -> Inf = 1 ; Inf = 0),
    glifo2(Sup, Inf, G).

glifo2(1, 1, '█').
glifo2(1, 0, '▀').
glifo2(0, 1, '▄').
glifo2(0, 0, ' ').

vista_alturas(M, Cols, Filas) :-
    length(M, N),
    muestrear(N, Cols, Xs),
    maplist(nth0_m(M), Xs, Vals),
    max_list([0|Vals], Max0),
    Tope is max(1, Max0),
    forall(between(1, Filas, K),
           ( Y is Filas + 1 - K,
             maplist(celda_altura(Tope, Filas, Y), Vals, Chars),
             string_chars(S, Chars),
             format('~w~n', [S]) )),
    maplist(eje_char, Vals, EjeChars),
    string_chars(Eje, EjeChars),
    format('~w~n', [Eje]),
    min_list(M, Min),
    max_list(M, Max),
    format('min=~d  max=~d  |M|=~d~n', [Min, Max, N]).

eje_char(_, '─').
nth0_m(M, X, H) :- nth0(X, M, H).

celda_altura(Tope, Filas, Y, H, C) :-
    Esc is (H * Filas + Tope - 1) // Tope,
    ( Esc >= Y -> C = '█' ; C = ' ' ).

muestras(M, K) :-
    length(M, N),
    Lim is min(K, N),
    muestrear(N, Lim, Xs),
    maplist(imprimir_muestra(M), Xs).

imprimir_muestra(M, X) :-
    nth0(X, M, H),
    format('x = ~d  →  f(x) = ~d~n', [X, H]).

muestrear(N, Destino, Xs) :-
    N =< Destino, !,
    Last is N - 1,
    findall(I, between(0, Last, I), Xs).
muestrear(_N, Destino, [0]) :- Destino =< 1, !.
muestrear(N, Destino, Xs) :-
    LastI is Destino - 1,
    findall(X,
            (between(0, LastI, I),
             X is (I * (N - 1)) // LastI),
            Xs).

agrupar2([], []).
agrupar2([_], []).
agrupar2([A,B|Rs], [(A,B)|T]) :- agrupar2(Rs, T).
