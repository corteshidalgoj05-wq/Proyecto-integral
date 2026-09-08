# **Documentación de Entrega: Práctica I \- De los Píxeles a la Integral**

**Integrantes del equipo:** Jerónimo Cortés Hidalgo  
**Materia:** Paradigmas de Programación (ST0244)  
**Docente:** Alexander Narváez Berrío  
**Institución:** Universidad EAFIT \- Escuela de Ciencias Aplicadas e Ingeniería

## **1\. Información General del Proyecto**

El propósito de esta práctica es implementar el cálculo del área bajo una curva definida en una imagen binaria (formato PBM P4) utilizando una suma de Riemann con $ \\Delta x \= 1 $. Se contrastan dos paradigmas de programación:

> * **Paradigma Funcional (Haskell):** Se modela el problema como un pipeline inmutable de transformaciones de datos $ PBM \\rightarrow \\text{bytes} \\rightarrow \\text{píxeles} \\rightarrow f(x) \\rightarrow M \\rightarrow \\text{área} $.  
> * **Paradigma Lógico/Declarativo (Prolog):** Se establecen relaciones y predicados lógicos que deben cumplirse entre los píxeles, la posición $x$ y la altura $f(x)$, derivando la lista de alturas $M$ mediante findall/3.

## **2\. Entorno de Desarrollo**

> * **Lenguaje Funcional:** Haskell (GHC 9.2+ / GHCup)  
> * **Lenguaje Lógico:** SWI-Prolog (v8.4+)  
> * **Sistema Operativo:** Windows / Linux / macOS  
> * **Terminal/Consola:** Compatible con codificación UTF-8 (en Windows ejecutar chcp 65001).

## **3\. Estructura de Archivos del Repositorio**

`/ (Raíz del repositorio)`  
`├── README.md`  
`├── data/`  
`│   └── curva_binaria_P4.pbm`  
`├── Haskell/`  
`│   └── Main.hs`  
`├── prolog/`  
`│   └── riemann.pl`  
`└── tools/`  
    `├── generar_pbm.py`  
    `└── verificar_area.py`

## **4\. Instrucciones de Compilación y Ejecución**

### **Parte I: Haskell**

`# Opción 1: Ejecución directa con runhaskell`  
`runhaskell Haskell/Main.hs data/curva_binaria_P4.pbm`

`# Opción 2: Compilación a ejecutable nativo`  
`ghc -O2 -o Haskell/riemann Haskell/Main.hs`  
`./Haskell/riemann data/curva_binaria_P4.pbm`

Sin argumentos, Haskell usa por defecto `data/curva_binaria_P4.pbm`.

### **Parte II: Prolog**

`# Ejecución con SWI-Prolog desde la terminal`  
`# main/1 se registra con initialization(main, main); no usar -g main.`  
`swipl -q -s prolog/riemann.pl -- data/curva_binaria_P4.pbm`

Sin argumentos, Prolog usa por defecto `data/curva_binaria_P4.pbm`.

## **5\. Estrategia de Muestreo y Escalado en Consola**

Debido a que las dimensiones del archivo PBM (640 × 320 píxeles) exceden la capacidad visual de una ventana de terminal estándar, se diseñó la siguiente estrategia de reducción:

> 1. **Muestreo Espacial Equiespaciado:** Se selecciona un conjunto representativo de columnas y filas distribuidas uniformemente en el dominio $\[0, n-1\]$.  
> 2. **Agrupación de Píxeles 2×1 (Unicode):** Se mapean pares de filas verticales a caracteres de bloques Unicode (█, ▀, ▄ y espacio) para preservar la silueta y reducir la densidad vertical a la mitad.  
> 3. **Histograma de Alturas $M\[x\]$:** Se grafica la función de altura $f(x)$ reescalada verticalmente a \~16 filas de caracteres de bloque █.

## **6\. Resultados Obtenidos**

| Archivo de Entrada | Dimensiones | Área Calculada en Haskell | Área Calculada en Prolog   |
| :---- | :---- | :---- | :---- |
| **curva\_binaria\_P4.pbm** | 640 × 320 | 104,324 px² | 104,324 px² |

## **7\. Comparación Teórica de Paradigmas**

| Componente | Paradigma Funcional (Haskell) | Paradigma Lógico (Prolog)   |
| :---- | :---- | :---- |
| **Unidad básica** | Función pura f :: Imagen \-\> Int \-\> Int | Predicado/Relación f(X, Raster, Alto, BytesFila, Altura) |
| **Construcción de M** | Transformación con map f \[0 .. ancho-1\] | Evaluación declarativa con findall/3 |
| **Suma de Riemann** | Plegado/Fold con sum M | Relación aritmética con sum\_list/2 |
| **Control de Flujo** | Composición de funciones y evaluación perezosa | Unificación, backtracking y resolución de metas |

