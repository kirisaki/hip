{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE ViewPatterns #-}
-- |
-- Module      : Graphics.Image.Processing.Interpolation
-- Copyright   : (c) Alexey Kuleshevich 2017
-- License     : BSD3
-- Maintainer  : Alexey Kuleshevich <lehins@yandex.ru>
-- Stability   : experimental
-- Portability : non-portable
--
module Graphics.Image.Processing.Interpolation (
  Interpolation(..), Nearest(..), Bilinear(..), Bicubic(..)
  ) where

import Graphics.Image.Interface

-- | Implementation for an interpolation method.
class Interpolation method where

  -- | Construct a new pixel by using information from neighboring pixels.
  interpolate :: ColorSpace cs e =>
                 method -- ^ Interpolation method
              -> Border (Pixel cs e) -- ^ Border resolution strategy
              -> (Int, Int)          -- ^ Image dimensions @m@ rows and @n@ columns.
              -> ((Int, Int) -> Pixel cs e)
                 -- ^ Lookup function that returns a pixel at @i@th and @j@th
                 -- location.
              -> (Double, Double) -- ^ Real values of @i@ and @j@ index
              -> Pixel cs e


-- | Nearest Neighbor interpolation method.
data Nearest = Nearest deriving Show


-- | Bilinear interpolation method.
data Bilinear = Bilinear deriving Show


-- | Bicubic interpolation method.
--   The parameter is usually set from -0.5 to -1.0.
data Bicubic = Bicubic Double deriving Show


instance Interpolation Nearest where

  interpolate Nearest border !sz getPx !(i, j) =
    handleBorderIndex border sz getPx (round i, round j)
  {-# INLINE interpolate #-}


instance Interpolation Bilinear where

  interpolate Bilinear border !sz getPx !(i, j) = fi0 + jPx*(fi1-fi0) where
    getPx' = handleBorderIndex border sz getPx
    {-# INLINE getPx' #-}
    !(i0, j0) = (floor i, floor j)
    !(i1, j1) = (i0 + 1, j0 + 1)
    !iPx = promote $ fromDouble (i - fromIntegral i0)
    !jPx = promote $ fromDouble (j - fromIntegral j0)
    !f00 = getPx' (i0, j0)
    !f10 = getPx' (i1, j0)
    !f01 = getPx' (i0, j1)
    !f11 = getPx' (i1, j1)
    !fi0 = f00 + iPx*(f10-f00)
    !fi1 = f01 + iPx*(f11-f01)
  {-# INLINE interpolate #-}


instance Interpolation Bicubic where

  interpolate (Bicubic a) border !sz getPx !(i, j) = ( f00 + f10 + f20 + f30
                                                     + f01 + f11 + f21 + f31
                                                     + f02 + f12 + f22 + f32
                                                     + f03 + f13 + f23 + f33
                                                     ) * w  where
    getPx' = handleBorderIndex border sz getPx
    {-# INLINE getPx' #-}
    distX x = fromIntegral x - i
    {-# INLINE distX #-}
    distY y = fromIntegral y - j
    {-# INLINE distY #-}
    weight x
        | x' <= 1 = (a + 2) * x' ** 3 - (a + 3) * x' ** 2 + 1
        | x' <  2 = a * x' ** 3 - 5 * a * x' ** 2 + 8 * a * x' - 4 * a
        | otherwise = 0
        where x' = abs x
    {-# INLINE weight #-}
    !(i1, j1) = (floor i, floor j)
    !(i0, j0) = (i1 - 1, j1 - 1)
    !(i2, j2) = (i1 + 1, j1 + 1)
    !(i3, j3) = (i1 + 2, j1 + 2)

    !weightX0 = weight (distX i0)
    !weightY0 = weight (distY i0)
    !weightX1 = weight (distX i1)
    !weightY1 = weight (distY i1)
    !weightX2 = weight (distX i2)
    !weightY2 = weight (distY i2)
    !weightX3 = weight (distX i3)
    !weightY3 = weight (distY i3)

    !weightX0Y0 = weightX0 * weightY0
    !weightX1Y0 = weightX1 * weightY0
    !weightX2Y0 = weightX2 * weightY0
    !weightX3Y0 = weightX3 * weightY0

    !weightX0Y1 = weightX0 * weightY1
    !weightX1Y1 = weightX1 * weightY1
    !weightX2Y1 = weightX2 * weightY1
    !weightX3Y1 = weightX3 * weightY1

    !weightX0Y2 = weightX0 * weightY2
    !weightX1Y2 = weightX1 * weightY2
    !weightX2Y2 = weightX2 * weightY2
    !weightX3Y2 = weightX3 * weightY2

    !weightX0Y3 = weightX0 * weightY3
    !weightX1Y3 = weightX1 * weightY3
    !weightX2Y3 = weightX2 * weightY3
    !weightX3Y3 = weightX3 * weightY3

    !f00 = getPx' (i0, j0) * promote (fromDouble weightX0Y0)
    !f10 = getPx' (i1, j0) * promote (fromDouble weightX1Y0)
    !f20 = getPx' (i2, j0) * promote (fromDouble weightX2Y0)
    !f30 = getPx' (i3, j0) * promote (fromDouble weightX3Y0)

    !f01 = getPx' (i0, j1) * promote (fromDouble weightX0Y1)
    !f11 = getPx' (i1, j1) * promote (fromDouble weightX1Y1)
    !f21 = getPx' (i2, j1) * promote (fromDouble weightX2Y1)
    !f31 = getPx' (i3, j1) * promote (fromDouble weightX3Y1)

    !f02 = getPx' (i0, j2) * promote (fromDouble weightX0Y2)
    !f12 = getPx' (i1, j2) * promote (fromDouble weightX1Y2)
    !f22 = getPx' (i2, j2) * promote (fromDouble weightX2Y2)
    !f32 = getPx' (i3, j2) * promote (fromDouble weightX3Y2)

    !f03 = getPx' (i0, j3) * promote (fromDouble weightX0Y3)
    !f13 = getPx' (i1, j3) * promote (fromDouble weightX1Y3)
    !f23 = getPx' (i2, j3) * promote (fromDouble weightX2Y3)
    !f33 = getPx' (i3, j3) * promote (fromDouble weightX3Y3)

    !w = promote . fromDouble . (1 /) $
          weightX0Y0 + weightX1Y0 + weightX2Y0 + weightX3Y0
        + weightX0Y1 + weightX1Y1 + weightX2Y1 + weightX3Y1
        + weightX0Y2 + weightX1Y2 + weightX2Y2 + weightX3Y2
        + weightX0Y3 + weightX1Y3 + weightX2Y3 + weightX3Y3
  {-# INLINE interpolate #-}

