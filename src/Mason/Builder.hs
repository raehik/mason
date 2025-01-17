{-# LANGUAGE MagicHash, CPP, UnboxedTuples #-}
{-# LANGUAGE ForeignFunctionInterface #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE LambdaCase #-}
----------------------------------------------------------------------------
-- |
-- Module      :  Mason.Builder
-- Copyright   :  (c) Fumiaki Kinoshita 2019-
-- License     :  BSD3
--
-- Maintainer  :  Fumiaki Kinoshita <fumiexcel@gmail.com>
--
----------------------------------------------------------------------------
module Mason.Builder
  ( Builder
  , BuilderFor
  , Buildable
  -- * Runners
  , StrictByteStringBackend
  , toStrictByteString
  , LazyByteStringBackend
  , toLazyByteString
  , BufferedIOBackend
  , hPutBuilderLen
  , hPutBuilder
  , sendBuilder
  , withPopper
  , StreamingBackend
  , toStreamingBody
  -- * Primitives
  , flush
  -- * Bytes
  , byteString
  , lazyByteString
  , shortByteString
  -- * Text
  , textUtf8
  , encodeUtf8Builder
  , encodeUtf8BuilderEscaped
  , char7
  , string7
  , char8
  , string8
  , charUtf8
  , stringUtf8
  -- * Primitive
  , storable
  , int8
  , word8
  , int16LE
  , int32LE
  , int64LE
  , word16LE
  , word32LE
  , word64LE
  , floatLE
  , doubleLE
  , int16BE
  , int32BE
  , int64BE
  , word16BE
  , word32BE
  , word64BE
  , floatBE
  , doubleBE
  -- * Numeral
  , floatDec
  , doubleDec
  , doubleSI
  , doubleExp
  , doubleFixed
  , word8Dec
  , word16Dec
  , word32Dec
  , word64Dec
  , wordDec
  , int8Dec
  , int16Dec
  , int32Dec
  , int64Dec
  , intDec
  , intDecPadded
  , integerDec
  , word8Hex
  , word16Hex
  , word32Hex
  , word64Hex
  , wordHex
  , int8HexFixed
  , int16HexFixed
  , int32HexFixed
  , int64HexFixed
  , word8HexFixed
  , word16HexFixed
  , word32HexFixed
  , word64HexFixed
  , floatHexFixed
  , doubleHexFixed
  , byteStringHex
  , lazyByteStringHex
  -- * Variable-length encoding
  , intVLQ
  , intVLQBP
  , wordVLQ
  , wordVLQBP
  , prefixVarInt
  , prefixVarIntBP
  -- * Combinators
  , intersperse
  , Mason.Builder.unwords
  , Mason.Builder.unlines
  , viaShow
  -- * Advanced
  , paddedBoundedPrim
  , zeroPaddedBoundedPrim
  , primFixed
  , primBounded
  , lengthPrefixedWithin

  ) where

import Control.Monad
import qualified Data.Array as A
import Data.Bits
import Data.Foldable (toList)
import Data.Word
import Data.Int
import qualified Data.Text as T
import Foreign.C.Types
import Foreign.Ptr (Ptr, plusPtr, castPtr)
import Foreign.Storable
import qualified Data.ByteString as B
import qualified Data.ByteString.Internal as B
import qualified Data.ByteString.Lazy as BL
import Mason.Builder.Internal as B
import qualified Data.ByteString.Builder.Prim as P
import qualified Data.ByteString.Builder.Prim.Internal as P
#if !MIN_VERSION_bytestring(0,10,12)
import Data.ByteString.Builder.Prim (boudedPrim)
#endif
import System.IO (Handle)

-- | Put the content of a 'Builder' to a 'Handle'.
hPutBuilder :: Handle -> BuilderFor PutEnv -> IO ()
hPutBuilder h b = void $ hPutBuilderLen h b
{-# INLINE hPutBuilder #-}

-- | Combine chunks of a lazy 'BL.ByteString'
lazyByteString :: BL.ByteString -> Builder
lazyByteString x = foldMap byteString (BL.toChunks x)
{-# INLINE lazyByteString #-}

------------------------------------------------------------------------------
-- Binary encodings
------------------------------------------------------------------------------

-- | Encode a single signed byte as-is.
--
{-# INLINE int8 #-}
int8 :: Int8 -> Builder
int8 x = B.primFixed P.int8 x

-- | Encode a single unsigned byte as-is.
--
{-# INLINE word8 #-}
word8 :: Word8 -> Builder
word8 x = B.primFixed P.word8 x


------------------------------------------------------------------------------
-- Binary little-endian encodings
------------------------------------------------------------------------------

-- | Encode an 'Int16' in little endian format.
{-# INLINE int16LE #-}
int16LE :: Int16 -> Builder
int16LE x = B.primFixed P.int16LE x

-- | Encode an 'Int32' in little endian format.
{-# INLINE int32LE #-}
int32LE :: Int32 -> Builder
int32LE x = B.primFixed P.int32LE x

-- | Encode an 'Int64' in little endian format.
{-# INLINE int64LE #-}
int64LE :: Int64 -> Builder
int64LE x = B.primFixed P.int64LE x

-- | Encode a 'Word16' in little endian format.
{-# INLINE word16LE #-}
word16LE :: Word16 -> Builder
word16LE x = B.primFixed P.word16LE x

-- | Encode a 'Word32' in little endian format.
{-# INLINE word32LE #-}
word32LE :: Word32 -> Builder
word32LE x = B.primFixed P.word32LE x

-- | Encode a 'Word64' in little endian format.
{-# INLINE word64LE #-}
word64LE :: Word64 -> Builder
word64LE x = B.primFixed P.word64LE x

-- | Encode a 'Float' in little endian format.
{-# INLINE floatLE #-}
floatLE :: Float -> Builder
floatLE x = B.primFixed P.floatLE x

-- | Encode a 'Double' in little endian format.
{-# INLINE doubleLE #-}
doubleLE :: Double -> Builder
doubleLE x = B.primFixed P.doubleLE x


------------------------------------------------------------------------------
-- Binary big-endian encodings
------------------------------------------------------------------------------

-- | Encode an 'Int16' in big endian format.
{-# INLINE int16BE #-}
int16BE :: Int16 -> Builder
int16BE x = B.primFixed P.int16BE x

-- | Encode an 'Int32' in big endian format.
{-# INLINE int32BE #-}
int32BE :: Int32 -> Builder
int32BE x = B.primFixed P.int32BE x

-- | Encode an 'Int64' in big endian format.
{-# INLINE int64BE #-}
int64BE :: Int64 -> Builder
int64BE x = B.primFixed P.int64BE x

-- | Encode a 'Word16' in big endian format.
{-# INLINE word16BE #-}
word16BE :: Word16 -> Builder
word16BE x = B.primFixed P.word16BE x

-- | Encode a 'Word32' in big endian format.
{-# INLINE word32BE #-}
word32BE :: Word32 -> Builder
word32BE x = B.primFixed P.word32BE x

-- | Encode a 'Word64' in big endian format.
{-# INLINE word64BE #-}
word64BE :: Word64 -> Builder
word64BE x = B.primFixed P.word64BE x

-- | Encode a 'Float' in big endian format.
{-# INLINE floatBE #-}
floatBE :: Float -> Builder
floatBE x = B.primFixed P.floatBE x

-- | Encode a 'Double' in big endian format.
{-# INLINE doubleBE #-}
doubleBE :: Double -> Builder
doubleBE x = B.primFixed P.doubleBE x

------------------------------------------------------------------------------
-- ASCII encoding
------------------------------------------------------------------------------

-- | Char7 encode a 'Char'.
{-# INLINE char7 #-}
char7 :: Char -> Builder
char7 x = B.primFixed P.char7 x

-- | Char7 encode a 'String'.
{-# INLINE string7 #-}
string7 :: String -> Builder
string7 x = B.primMapListFixed P.char7 x

------------------------------------------------------------------------------
-- ISO/IEC 8859-1 encoding
------------------------------------------------------------------------------

-- | Char8 encode a 'Char'.
{-# INLINE char8 #-}
char8 :: Char -> Builder
char8 x = B.primFixed P.char8 x

-- | Char8 encode a 'String'.
{-# INLINE string8 #-}
string8 :: String -> Builder
string8 x = B.primMapListFixed P.char8 x

------------------------------------------------------------------------------
-- UTF-8 encoding
------------------------------------------------------------------------------

-- | UTF-8 encode a 'Char'.
{-# INLINE charUtf8 #-}
charUtf8 :: Char -> Builder
charUtf8 x = B.primBounded P.charUtf8 x

-- | Encode 'T.Text' as a UTF-8 byte stream. Synonym for 'textUtf8'.
encodeUtf8Builder :: T.Text -> Builder
encodeUtf8Builder x = textUtf8 x
{-# INLINE encodeUtf8Builder #-}

-- | Encode 'T.Text' as a UTF-8 byte stream.
textUtf8 :: T.Text -> Builder
textUtf8 x = B.encodeUtf8BuilderEscaped (P.liftFixedToBounded P.word8) x
{-# INLINE textUtf8 #-}

--------------------
-- Unsigned integers
--------------------

-- | Decimal encoding of a 'Word8' using the ASCII digits.
{-# INLINE word8Dec #-}
word8Dec :: Word8 -> Builder
word8Dec x = B.primBounded P.word8Dec x

-- | Decimal encoding of a 'Word16' using the ASCII digits.
{-# INLINE word16Dec #-}
word16Dec :: Word16 -> Builder
word16Dec x = B.primBounded P.word16Dec x

-- | Decimal encoding of a 'Word32' using the ASCII digits.
{-# INLINE word32Dec #-}
word32Dec :: Word32 -> Builder
word32Dec x = B.primBounded P.word32Dec x

-- | Decimal encoding of a 'Word64' using the ASCII digits.
{-# INLINE word64Dec #-}
word64Dec :: Word64 -> Builder
word64Dec x = B.primBounded P.word64Dec x

-- | Decimal encoding of a 'Word' using the ASCII digits.
{-# INLINE wordDec #-}
wordDec :: Word -> Builder
wordDec x = B.primBounded P.wordDec x

-- Floating point numbers
-------------------------

-- | /Currently slow./ Decimal encoding of an IEEE 'Float'.
{-# INLINE floatDec #-}
floatDec :: Float -> Builder
floatDec x = string7 (show x)

wrapDoubleDec :: Double -> (Double -> Builder) -> Builder
wrapDoubleDec x k
  | isNaN x = string7 "NaN"
  | isInfinite x = if x < 0 then string7 "-Infinity" else string7 "Infinity"
  | isNegativeZero x = char7 '-' <> k 0.0
  | x < 0 = char7 '-' <> k (-x)
  | otherwise = k x
{-# INLINE wrapDoubleDec #-}

-- | Decimal encoding of an IEEE 'Double'.
{-# INLINE doubleDec #-}
doubleDec :: Double -> Builder
doubleDec val = wrapDoubleDec val $ \case
  0 -> string7 "0.0"
  x -> grisu x
  where
    grisu v = withPtr 24 $ \ptr -> do
      n <- dtoa_grisu3 v ptr
      return $ plusPtr ptr (fromIntegral n)

foreign import ccall unsafe "static dtoa_grisu3"
  dtoa_grisu3 :: Double -> Ptr Word8 -> IO CInt

-- | Attach an SI prefix so that abs(mantissa) is within [1, 1000). Omits c, d, da and h.
doubleSI :: Int -- ^ precision: must be equal or greater than 3
  -> Double
  -> Builder
doubleSI prec _ | prec < 3 = error "Mason.Builder.doubleSI: precision less than 3"
doubleSI prec val = wrapDoubleDec val $ \case
  0 -> zeroes prec
  val' -> Builder $ \env buf -> withGrisu3Rounded prec val' $ \ptr len e -> do
    let (pindex, dp) = divMod (e - 1) 3
    print (dp, prec, len)
    let mantissa
          -- when the decimal separator would be at the end
          | dp + 1 == prec = withPtr (prec + dp - 2) $ \dst -> do
            _ <- B.memset dst 48 $ fromIntegral (prec + dp - 2)
            B.memcpy dst ptr $ min len prec
            return $ dst `plusPtr` (prec + dp - 2)
          | otherwise = withPtr (prec + 1) $ \dst -> do
            _ <- B.memset dst 48 $ fromIntegral (prec + 1)
            B.memcpy dst ptr $ min len $ dp + 1
            pokeElemOff dst (dp + 1) 46
            B.memcpy (dst `plusPtr` (dp + 2)) (ptr `plusPtr` (dp + 1)) $ max 0 $ len - dp - 1
            return $ dst `plusPtr` (prec + 1)
    let prefix
          | pindex == 0 = mempty
          | pindex > 8 || pindex < (-8) = char7 'e' <> intDec (3 * pindex)
          | otherwise = charUtf8 (prefices A.! pindex)
    unBuilder (mantissa <> prefix) env buf
  where
    prefices = A.listArray (-8,8) "yzafpnμm\NULkMGTPEZY"

zeroes :: Int -> Builder
zeroes n = withPtr (n + 1) $ \dst -> do
  _ <- B.memset dst 48 $ fromIntegral $ n + 1
  pokeElemOff dst 1 46
  return $ dst `plusPtr` (n + 1)

-- | Always use exponents
doubleExp :: Int -- ^ number of digits in the mantissa
  -> Double
  -> Builder
doubleExp prec _ | prec < 1 = error "Mason.Builder.doubleFixed: precision too small"
doubleExp prec val = wrapDoubleDec val $ \case
  0 -> zeroes prec <> string7 "e0"
  val' -> Builder $ \env buf -> withGrisu3Rounded prec val' $ \ptr len dp -> do
    let len' = 1 + prec

    firstDigit <- peek ptr

    unBuilder (withPtr len' (\dst -> do
      _ <- B.memset dst 48 $ fromIntegral len'
      poke dst firstDigit
      poke (dst `plusPtr` 1) (46 :: Word8)
      B.memcpy (dst `plusPtr` 2) (ptr `plusPtr` 1) (min (len - 1) len')
      return (dst `plusPtr` len'))
      <> char7 'e' <> intDec (dp - 1)) env buf

-- | Fixed precision
doubleFixed :: Int -- ^ decimal points
  -> Double
  -> Builder
doubleFixed 0 val = intDec (round val)
doubleFixed prec _ | prec < 0 = error "Mason.Builder.doubleFixed: negative precision"
doubleFixed prec val = wrapDoubleDec val $ \case
  0 -> zeroes (prec + 1)
  val' -> Builder $ \env buf -> withGrisu3 val' (unBuilder (doubleDec val) env buf) $ \ptr0 len e0 -> do
    bump <- roundDigit (prec + e0) len ptr0
    let dp
          | bump = e0 + 1
          | otherwise = e0
    let ptr
          | bump = ptr0
          | otherwise = ptr0 `plusPtr` 1
    let len' = 1 + prec + max 1 dp

    unBuilder (withPtr len' $ \dst -> do
      _ <- B.memset dst 48 $ fromIntegral len'
      if dp >= 1
        then do
          B.memcpy dst ptr $ min len dp
          pokeElemOff dst dp 46
          B.memcpy (dst `plusPtr` (dp + 1)) (ptr `plusPtr` dp) $ max 0 (len - dp)
        else do
          pokeElemOff dst 1 46
          B.memcpy (dst `plusPtr` (2 - dp)) ptr len
      return $ dst `plusPtr` len'
      ) env buf

------------------------------------------------------------------------------
-- Decimal Encoding
------------------------------------------------------------------------------

-- Signed integers
------------------

-- | Decimal encoding of an 'Int8' using the ASCII digits.
--
-- e.g.
--
-- > toLazyByteString (int8Dec 42)   = "42"
-- > toLazyByteString (int8Dec (-1)) = "-1"
--
{-# INLINE int8Dec #-}
int8Dec :: Int8 -> Builder
int8Dec x = B.primBounded P.int8Dec x

-- | Decimal encoding of an 'Int16' using the ASCII digits.
{-# INLINE int16Dec #-}
int16Dec :: Int16 -> Builder
int16Dec x = B.primBounded P.int16Dec x

-- | Decimal encoding of an 'Int32' using the ASCII digits.
{-# INLINE int32Dec #-}
int32Dec :: Int32 -> Builder
int32Dec x = B.primBounded P.int32Dec x

-- | Decimal encoding of an 'Int64' using the ASCII digits.
{-# INLINE int64Dec #-}
int64Dec :: Int64 -> Builder
int64Dec x = B.primBounded P.int64Dec x

-- | Decimal encoding of an 'Int' using the ASCII digits.
{-# INLINE intDec #-}
intDec :: Int -> Builder
intDec x = B.primBounded P.intDec x

-- | 'intDec' with 0 padding
intDecPadded :: Int -> Int -> Builder
intDecPadded n = zeroPaddedBoundedPrim n P.intDec
{-# INLINE intDecPadded #-}

------------------------------------------------------------------------------
-- Hexadecimal Encoding
------------------------------------------------------------------------------

-- without lead
---------------

-- | Shortest hexadecimal encoding of a 'Word8' using lower-case characters.
{-# INLINE word8Hex #-}
word8Hex :: Word8 -> Builder
word8Hex x = B.primBounded P.word8Hex x

-- | Shortest hexadecimal encoding of a 'Word16' using lower-case characters.
{-# INLINE word16Hex #-}
word16Hex :: Word16 -> Builder
word16Hex x = B.primBounded P.word16Hex x

-- | Shortest hexadecimal encoding of a 'Word32' using lower-case characters.
{-# INLINE word32Hex #-}
word32Hex :: Word32 -> Builder
word32Hex x = B.primBounded P.word32Hex x

-- | Shortest hexadecimal encoding of a 'Word64' using lower-case characters.
{-# INLINE word64Hex #-}
word64Hex :: Word64 -> Builder
word64Hex x = B.primBounded P.word64Hex x

-- | Shortest hexadecimal encoding of a 'Word' using lower-case characters.
{-# INLINE wordHex #-}
wordHex :: Word -> Builder
wordHex x = B.primBounded P.wordHex x

-- fixed width; leading zeroes
------------------------------

-- | Encode a 'Int8' using 2 nibbles (hexadecimal digits).
{-# INLINE int8HexFixed #-}
int8HexFixed :: Int8 -> Builder
int8HexFixed x = B.primFixed P.int8HexFixed x

-- | Encode a 'Int16' using 4 nibbles.
{-# INLINE int16HexFixed #-}
int16HexFixed :: Int16 -> Builder
int16HexFixed x = B.primFixed P.int16HexFixed x

-- | Encode a 'Int32' using 8 nibbles.
{-# INLINE int32HexFixed #-}
int32HexFixed :: Int32 -> Builder
int32HexFixed x = B.primFixed P.int32HexFixed x

-- | Encode a 'Int64' using 16 nibbles.
{-# INLINE int64HexFixed #-}
int64HexFixed :: Int64 -> Builder
int64HexFixed x = B.primFixed P.int64HexFixed x

-- | Encode a 'Word8' using 2 nibbles (hexadecimal digits).
{-# INLINE word8HexFixed #-}
word8HexFixed :: Word8 -> Builder
word8HexFixed x = B.primFixed P.word8HexFixed x

-- | Encode a 'Word16' using 4 nibbles.
{-# INLINE word16HexFixed #-}
word16HexFixed :: Word16 -> Builder
word16HexFixed x = B.primFixed P.word16HexFixed x

-- | Encode a 'Word32' using 8 nibbles.
{-# INLINE word32HexFixed #-}
word32HexFixed :: Word32 -> Builder
word32HexFixed x = B.primFixed P.word32HexFixed x

-- | Encode a 'Word64' using 16 nibbles.
{-# INLINE word64HexFixed #-}
word64HexFixed :: Word64 -> Builder
word64HexFixed x = B.primFixed P.word64HexFixed x

-- | Encode an IEEE 'Float' using 8 nibbles.
{-# INLINE floatHexFixed #-}
floatHexFixed :: Float -> Builder
floatHexFixed x = B.primFixed P.floatHexFixed x

-- | Encode an IEEE 'Double' using 16 nibbles.
{-# INLINE doubleHexFixed #-}
doubleHexFixed :: Double -> Builder
doubleHexFixed x = B.primFixed P.doubleHexFixed x

-- | Encode each byte of a 'S.ByteString' using its fixed-width hex encoding.
{-# NOINLINE byteStringHex #-} -- share code
byteStringHex :: B.ByteString -> Builder
byteStringHex x = B.primMapByteStringFixed P.word8HexFixed x

-- | Encode each byte of a lazy 'L.ByteString' using its fixed-width hex encoding.
{-# NOINLINE lazyByteStringHex #-} -- share code
lazyByteStringHex :: BL.ByteString -> Builder
lazyByteStringHex x = B.primMapLazyByteStringFixed P.word8HexFixed x

-- | Select an implementation depending on the bit-size of 'Word's.
-- Currently, it produces a runtime failure if the bitsize is different.
-- This is detected by the testsuite.
{-# INLINE caseWordSize_32_64 #-}
caseWordSize_32_64 :: a -- Value to use for 32-bit 'Word's
                   -> a -- Value to use for 64-bit 'Word's
                   -> a
caseWordSize_32_64 f32 f64 =
#if MIN_VERSION_base(4,7,0)
  case finiteBitSize (undefined :: Word) of
#else
  case bitSize (undefined :: Word) of
#endif
    32 -> f32
    64 -> f64
    s  -> error $ "caseWordSize_32_64: unsupported Word bit-size " ++ show s

maxPow10 :: Integer
maxPow10 = toInteger $ (10 :: Int) ^ caseWordSize_32_64 (9 :: Int) 18

-- | Decimal encoding of an 'Integer' using the ASCII digits.
-- Simon Meier's improved implementation from https://github.com/haskell/bytestring/commit/92f19a5d94761042b44a433d7331107611e4d717
integerDec :: Integer -> Builder
integerDec i
    | i' <- fromInteger i, toInteger i' == i = intDec i'
    | i < 0     = primFixed P.char8 '-' `mappend` go (-i)
    | otherwise =                                   go i
  where
    errImpossible fun =
        error $ "integerDec: " ++ fun ++ ": the impossible happened."

    go :: Integer -> Builder
    go n | n < maxPow10 = intDec (fromInteger n)
         | otherwise    =
             case putH (splitf (maxPow10 * maxPow10) n) of
               (x:xs) -> intDec x `mappend` primMapListBounded intDecPadded18 xs
               []     -> errImpossible "integerDec: go"

    splitf :: Integer -> Integer -> [Integer]
    splitf pow10 n0
      | pow10 > n0  = [n0]
      | otherwise   = splith (splitf (pow10 * pow10) n0)
      where
        splith []     = errImpossible "splith"
        splith (n:ns) =
            case n `quotRem` pow10 of
                (q,r) | q > 0     -> q : r : splitb ns
                      | otherwise ->     r : splitb ns

        splitb []     = []
        splitb (n:ns) = case n `quotRem` pow10 of
                            (q,r) -> q : r : splitb ns

    putH :: [Integer] -> [Int]
    putH []     = errImpossible "putH"
    putH (n:ns) = case n `quotRem` maxPow10 of
                    (x,y)
                        | q > 0     -> q : r : putB ns
                        | otherwise ->     r : putB ns
                        where q = fromInteger x
                              r = fromInteger y

    putB :: [Integer] -> [Int]
    putB []     = []
    putB (n:ns) = case n `quotRem` maxPow10 of
                    (q,r) -> fromInteger q : fromInteger r : putB ns
{-# INLINE integerDec #-}

foreign import ccall unsafe "static _hs_bytestring_int_dec_padded9"
    c_int_dec_padded9 :: CInt -> Ptr Word8 -> IO ()

foreign import ccall unsafe "static _hs_bytestring_long_long_int_dec_padded18"
    c_long_long_int_dec_padded18 :: CLLong -> Ptr Word8 -> IO ()

{-# INLINE intDecPadded18 #-}
intDecPadded18 :: P.BoundedPrim Int
intDecPadded18 = P.liftFixedToBounded $ caseWordSize_32_64
    (P.fixedPrim  9 $ c_int_dec_padded9            . fromIntegral)
    (P.fixedPrim 18 $ c_long_long_int_dec_padded18 . fromIntegral)

#if !MIN_VERSION_bytestring(0,10,12)
boundedPrim :: Int -> (a -> Ptr Word8 -> IO (Ptr Word8)) -> BoundedPrim a
boundedPrim = boudedPrim
#endif

-- Variable-length encoding
----

-- | Signed VLQ encoding (the first bit is a sign)
intVLQ :: Int -> Builder
intVLQ x = primBounded intVLQBP x
{-# INLINE intVLQ #-}

intVLQBP :: P.BoundedPrim Int
intVLQBP = P.boundedPrim 10 writeIntFinite
{-# INLINE CONLIKE intVLQBP #-}

-- | Unsigned VLQ encoding
wordVLQ :: Word -> Builder
wordVLQ x = primBounded wordVLQBP x

wordVLQBP :: P.BoundedPrim Word
wordVLQBP = P.boundedPrim 10 (writeUnsignedFinite pure)

writeWord8 :: Word8 -> Ptr Word8 -> IO (Ptr Word8)
writeWord8 w p = do
  poke p w
  return $! plusPtr p 1

writeIntFinite :: Int -> Ptr Word8 -> IO (Ptr Word8)
writeIntFinite n
  | n < 0 = case negate n of
    n'
      | n' < 0x40 -> writeWord8 (fromIntegral n' `setBit` 6)
      | otherwise ->
          writeWord8 (0xc0 .|. fromIntegral n') >=>
            writeUnsignedFinite pure (unsafeShiftR n' 6)
  | n < 0x40 = writeWord8 (fromIntegral n)
  | otherwise = writeWord8 (fromIntegral n `setBit` 7 `clearBit` 6) >=>
      writeUnsignedFinite pure (unsafeShiftR n 6)
{-# INLINE writeIntFinite #-}

writeUnsignedFinite :: (Bits a, Integral a) => (Ptr Word8 -> IO r) -> a -> Ptr Word8 -> IO r
writeUnsignedFinite k = go
  where
    go m
      | m < 0x80 = writeWord8 (fromIntegral m) >=> k
      | otherwise = writeWord8 (setBit (fromIntegral m) 7) >=> go (unsafeShiftR m 7)
{-# INLINE writeUnsignedFinite #-}

-- | Encode a Word in <https://github.com/stoklund/varint#prefixvarint PrefixVarInt>
prefixVarInt :: Word -> Builder
prefixVarInt x = primBounded prefixVarIntBP x

prefixVarIntBP :: P.BoundedPrim Word
prefixVarIntBP = P.boundedPrim 9 $ \x ptr0 -> do
  let bits = 64 - countLeadingZeros (x .|. 1)
  if bits > 56
    then do
      poke ptr0 0
      poke (castPtr ptr0 `plusPtr` 1) x
      return $! ptr0 `plusPtr` 9
    else do
      let bytes = 1 + (bits - 1) `div` 7
      let end = ptr0 `plusPtr` bytes
      let go ptr n
            | ptr == end = pure ptr
            | otherwise = do
              poke ptr (fromIntegral n .&. 0xff)
              go (ptr `plusPtr` 1) (n `shiftR` 8)
      go ptr0 $! (2 * x + 1) `shiftL` (bytes - 1)
{-# INLINE CONLIKE prefixVarIntBP #-}

intersperse :: (Foldable f, Buildable e) => BuilderFor e -> f (BuilderFor e) -> BuilderFor e
intersperse d = go . toList where
  go (x0 : xs) = x0 <> foldr (\x r -> d <> x <> r) mempty xs
  go [] = mempty
{-# INLINE intersperse #-}

unwords :: (Foldable f, Buildable e) => f (BuilderFor e) -> BuilderFor e
unwords = intersperse (word8 32)
{-# INLINE unwords #-}

unlines :: (Foldable f, Buildable e) => f (BuilderFor e) -> BuilderFor e
unlines = foldMap (<>word8 10)
{-# INLINE unlines #-}

-- | Turn a value into a 'Builder' using the 'Show' instance.
viaShow :: Show a => a -> Builder
viaShow x = string8 (show x)
{-# INLINE viaShow #-}