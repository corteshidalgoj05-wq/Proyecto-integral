-- Parte I: Programación funcional (Haskell)
-- Transformación visible: PBM → bytes → píxeles → f(x) → M → área
--
-- f(x)  = píxeles negros consecutivos desde la base de la columna x
-- M     = map f [0 .. ancho-1]
-- área  = sum M          (Riemann con Δx = 1, en px²)

module Main where

import Data.Bits (testBit)
import Data.Char (chr, isDigit, isSpace)
import Data.Word (Word8)
import System.Environment (getArgs)
import System.IO (hSetEncoding, stdout, utf8)
import qualified Data.ByteString as B

data Imagen = Imagen
  { ancho       :: Int
  , alto        :: Int
  , bytesFila   :: Int
  , raster      :: B.ByteString
  }

main :: IO ()
main = do
  hSetEncoding stdout utf8
  ruta <- fmap cabezaODefecto (getArgs)
  raw  <- B.readFile ruta
  let img     = parsearP4 raw
      dominio = [0 .. ancho img - 1]
      -- M = [f(0), f(1), ..., f(n-1)]
      mAlturas = map (f img) dominio
      -- A = Σ f(x_i) Δx  con Δx = 1
      area     = sum mAlturas
  putStrLn "=== Haskell · suma de Riemann sobre PBM P4 ==="
  putStrLn $ "Archivo: " ++ ruta
  putStrLn $ "Dimensiones: " ++ show (ancho img) ++ " × " ++ show (alto img)
  putStrLn $ "f(x) = negros consecutivos desde la base de la columna x"
  putStrLn $ "M    = map f [0 .. " ++ show (ancho img - 1) ++ "]"
  putStrLn $ "A    = sum M  (Δx = 1)  →  " ++ show area ++ " px²"
  putStrLn ""
  putStrLn "--- Imagen binaria (muestreo espacial + bloques Unicode 2×1) ---"
  putStrLn justificacionVista
  putStr (vistaImagen img 80 24)
  putStrLn ""
  putStrLn "--- Función de altura M[x] = f(x) ---"
  putStr (vistaAlturas mAlturas 80 16)
  putStrLn ""
  putStrLn "--- Muestras x_i → f(x_i) ---"
  mapM_ putStrLn (muestras dominio mAlturas 12)

cabezaODefecto :: [String] -> String
cabezaODefecto (p:_) = p
cabezaODefecto []    = "data/curva_binaria_P4.pbm"

-- ---------------------------------------------------------------------------
-- PBM P4: cabecera ASCII + raster empaquetado (1 = negro, MSB = píxel izquierdo)
-- ---------------------------------------------------------------------------

parsearP4 :: B.ByteString -> Imagen
parsearP4 bs =
  let rest0            = exigirMagia (saltarSeparadores bs)
      (w, rest1)       = leerEntero (saltarSeparadores rest0)
      (h, rest2)       = leerEntero (saltarSeparadores rest1)
      rasterBytes      = saltarUnBlanco rest2
      bpr              = (w + 7) `div` 8
      esperados        = bpr * h
      recorte          = B.take esperados rasterBytes
  in if B.length recorte < esperados
       then error "Raster P4 incompleto"
       else Imagen w h bpr recorte

exigirMagia :: B.ByteString -> B.ByteString
exigirMagia bs
  | B.length bs >= 2 && B.index bs 0 == 80 && B.index bs 1 == 52 = B.drop 2 bs
  | otherwise = error "Se esperaba magia P4"

saltarSeparadores :: B.ByteString -> B.ByteString
saltarSeparadores bs
  | B.null bs = bs
  | B.head bs == 35 = saltarSeparadores (saltarHastaSalto bs) -- comentario #
  | esBlanco (B.head bs) = saltarSeparadores (B.tail bs)
  | otherwise = bs

saltarHastaSalto :: B.ByteString -> B.ByteString
saltarHastaSalto bs =
  let (_, resto) = B.break (== 10) bs
  in if B.null resto then resto else B.tail resto

saltarUnBlanco :: B.ByteString -> B.ByteString
saltarUnBlanco bs
  | B.null bs = bs
  | B.head bs == 35 = saltarUnBlanco (saltarHastaSalto bs)
  | esBlanco (B.head bs) = B.tail bs
  | otherwise = bs

esBlanco :: Word8 -> Bool
esBlanco b = isSpace (chr (fromIntegral b))

leerEntero :: B.ByteString -> (Int, B.ByteString)
leerEntero bs =
  let (digs, resto) = B.span (isDigit . chr . fromIntegral) bs
  in if B.null digs
       then error "Entero esperado en la cabecera PBM"
       else (read (map (chr . fromIntegral) (B.unpack digs)), resto)

-- ---------------------------------------------------------------------------
-- Acceso a un píxel (x, y): y = 0 es la fila superior
-- ---------------------------------------------------------------------------

negro :: Imagen -> Int -> Int -> Bool
negro img x y
  | x < 0 || x >= ancho img || y < 0 || y >= alto img = False
  | otherwise =
      let byteIndice = y * bytesFila img + x `div` 8
          byte       = B.index (raster img) byteIndice
          bit        = 7 - (x `mod` 8) -- bit más significativo = píxel más a la izquierda
      in testBit byte bit

-- f(x): recorrer la columna desde abajo (sin un bucle imperativo:
-- takeWhile + length sobre el dominio vertical invertido)
f :: Imagen -> Int -> Int
f img x =
  length (takeWhile (\y -> negro img x y) [alto img - 1, alto img - 2 .. 0])

-- ---------------------------------------------------------------------------
-- Visualización compacta
-- ---------------------------------------------------------------------------

justificacionVista :: String
justificacionVista =
  "Estrategia: la imagen original no cabe en la terminal. Se reduce por muestreo\n\
  \espacial (cada carácter cubre un bloque de píxeles) y se agrupan 2 filas\n\
  \muestreadas en un glifo Unicode (▀ ▄ █ espacio) para conservar la silueta."

-- Celdas de 80×24 caracteres; cada carácter resume 2 filas muestreadas
vistaImagen :: Imagen -> Int -> Int -> String
vistaImagen img cols filasCar =
  let filasPix = filasCar * 2
      xs = muestrear (ancho img) cols
      ys = muestrear (alto img) filasPix
      pares = agrupar2 ys
      linea (ySup, yInf) =
        map (\x -> glifo2 (negro img x ySup) (negro img x yInf)) xs
  in unlines (map linea pares)

glifo2 :: Bool -> Bool -> Char
glifo2 True  True  = '█'
glifo2 True  False = '▀'
glifo2 False True  = '▄'
glifo2 False False = ' '

vistaAlturas :: [Int] -> Int -> Int -> String
vistaAlturas m cols filas =
  let xs     = muestrear (length m) cols
      vals   = [m !! x | x <- xs]
      tope   = max 1 (maximum (0 : vals))
      niveles y =
        map (\h -> if escala h tope filas >= y then '█' else ' ') vals
  in unlines [niveles y | y <- [filas, filas - 1 .. 1]]
     ++ replicate cols '─' ++ "\n"
     ++ "min=" ++ show (minimum m)
     ++ "  max=" ++ show (maximum m)
     ++ "  |M|=" ++ show (length m) ++ "\n"

escala :: Int -> Int -> Int -> Int
escala h tope filas = (h * filas + tope - 1) `div` tope

-- Índices equiespaciados que cubren [0 .. n-1]
muestrear :: Int -> Int -> [Int]
muestrear n destino
  | n <= destino = [0 .. n - 1]
  | destino <= 1 = [0]
  | otherwise =
      [ (i * (n - 1)) `div` (destino - 1) | i <- [0 .. destino - 1] ]

muestras :: [Int] -> [Int] -> Int -> [String]
muestras dominio m k =
  let xs = muestrear (length dominio) (min k (length dominio))
  in ["x = " ++ show x ++ "  →  f(x) = " ++ show (m !! x) | x <- xs]

agrupar2 :: [a] -> [(a, a)]
agrupar2 (a:b:rs) = (a, b) : agrupar2 rs
agrupar2 []       = []
agrupar2 [_]      = []
