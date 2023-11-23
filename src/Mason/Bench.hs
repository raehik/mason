{-# LANGUAGE OverloadedStrings #-}

module Mason.Bench where

import Test.Tasty.Bench

import Mason.Builder
import Data.Text ( Text )
import qualified Data.Text.Encoding as Text
import Data.ByteString ( ByteString)

textBytestringCopy :: Text -> ByteString
textBytestringCopy = toStrictByteString . byteString . Text.encodeUtf8

textDirect :: Text -> ByteString
textDirect = toStrictByteString . textUtf8

textDirectFast :: Text -> ByteString
textDirectFast = toStrictByteString . textUtf8Fast

textDirectFast2 :: Text -> ByteString
textDirectFast2 = toStrictByteString . textUtf8Fast2

main :: IO ()
main = defaultMain
  [ bench "text-bytestring-copy" $ nf textBytestringCopy "12345678901234567890"
  , bench "text-direct"          $ nf textDirect         "12345678901234567890"
  , bench "text-direct-fast"     $ nf textDirectFast     "12345678901234567890"
  , bench "text-direct-fast2"    $ nf textDirectFast2    "12345678901234567890"
  ]
