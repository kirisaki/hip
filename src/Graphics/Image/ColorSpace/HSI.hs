{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeFamilies #-}
-- |
-- Module      : Graphics.Image.ColorSpace.HSI
-- Copyright   : (c) Alexey Kuleshevich 2017
-- License     : BSD3
-- Maintainer  : Alexey Kuleshevich <lehins@yandex.ru>
-- Stability   : experimental
-- Portability : non-portable
--
module Graphics.Image.ColorSpace.HSI (
  HSI(..), HSIA(..), Pixel(..), 
  ToHSI(..), ToHSIA(..)
  ) where

import Prelude hiding (map)
import Control.Applicative
import Data.Foldable
import Data.Typeable (Typeable)
import Foreign.Ptr
import Foreign.Storable

import Graphics.Image.Interface

-----------
--- HSI ---
-----------

-- | Hue, Saturation and Intensity color space.
data HSI = HueHSI -- ^ Hue
         | SatHSI -- ^ Saturation 
         | IntHSI -- ^ Intensity
         deriving (Eq, Enum, Typeable)

data instance Pixel HSI e = PixelHSI !e !e !e deriving Eq


instance Show HSI where
  show HueHSI = "Hue"
  show SatHSI = "Saturation"
  show IntHSI = "Intensity"
  
instance Show e => Show (Pixel HSI e) where
  show (PixelHSI h s i) = "<HSI:("++show h++"|"++show s++"|"++show i++")>"


instance (Elevator e, Typeable e) => ColorSpace HSI e where
  type Components HSI e = (e, e, e)

  toComponents (PixelHSI h s i) = (h, s, i)
  {-# INLINE toComponents #-}
  fromComponents !(h, s, i) = PixelHSI h s i
  {-# INLINE fromComponents #-}
  broadcastC = pure
  {-# INLINE broadcastC #-}
  getPxC (PixelHSI h _ _) HueHSI = h
  getPxC (PixelHSI _ s _) SatHSI = s
  getPxC (PixelHSI _ _ i) IntHSI = i
  {-# INLINE getPxC #-}
  setPxC (PixelHSI _ s i) HueHSI h = PixelHSI h s i
  setPxC (PixelHSI h _ i) SatHSI s = PixelHSI h s i
  setPxC (PixelHSI h s _) IntHSI i = PixelHSI h s i
  {-# INLINE setPxC #-}
  mapPxC f (PixelHSI h s i) = PixelHSI (f HueHSI h) (f SatHSI s) (f IntHSI i)
  {-# INLINE mapPxC #-}
  mapPx = fmap
  {-# INLINE mapPx #-}
  zipWithPx = liftA2
  {-# INLINE zipWithPx #-}
  foldlPx = foldl'
  {-# INLINE foldlPx #-}


instance Functor (Pixel HSI) where
  fmap f (PixelHSI h s i) = PixelHSI (f h) (f s) (f i)
  {-# INLINE fmap #-}


instance Applicative (Pixel HSI) where
  pure !e = PixelHSI e e e
  {-# INLINE pure #-}
  (PixelHSI fh fs fi) <*> (PixelHSI h s i) = PixelHSI (fh h) (fs s) (fi i)
  {-# INLINE (<*>) #-}


instance Foldable (Pixel HSI) where
  foldr f !z (PixelHSI h s i) = f h (f s (f i z))
  {-# INLINE foldr #-}

instance Num e => Num (Pixel HSI e) where
  (+)         = liftA2 (+)
  {-# INLINE (+) #-}
  (-)         = liftA2 (-)
  {-# INLINE (-) #-}
  (*)         = liftA2 (*)
  {-# INLINE (*) #-}
  abs         = liftA abs
  {-# INLINE abs #-}
  signum      = liftA signum
  {-# INLINE signum #-}
  fromInteger = pure . fromInteger
  {-# INLINE fromInteger #-}
  

instance Fractional e => Fractional (Pixel HSI e) where
  (/)          = liftA2 (/)
  {-# INLINE (/) #-}
  recip        = liftA recip
  {-# INLINE recip #-}
  fromRational = pure . fromRational
  {-# INLINE fromRational #-}


instance Floating e => Floating (Pixel HSI e) where
  pi      = pure pi
  {-# INLINE pi #-}
  exp     = liftA exp
  {-# INLINE exp #-}
  log     = liftA log
  {-# INLINE log #-}
  sin     = liftA sin
  {-# INLINE sin #-}
  cos     = liftA cos
  {-# INLINE cos #-}
  asin    = liftA asin
  {-# INLINE asin #-}
  atan    = liftA atan
  {-# INLINE atan #-}
  acos    = liftA acos
  {-# INLINE acos #-}
  sinh    = liftA sinh
  {-# INLINE sinh #-}
  cosh    = liftA cosh
  {-# INLINE cosh #-}
  asinh   = liftA asinh
  {-# INLINE asinh #-}
  atanh   = liftA atanh
  {-# INLINE atanh #-}
  acosh   = liftA acosh
  {-# INLINE acosh #-}


instance Storable e => Storable (Pixel HSI e) where

  sizeOf _ = 3 * sizeOf (undefined :: e)
  alignment _ = alignment (undefined :: e)
  peek p = do
    q <- return $ castPtr p
    r <- peek q
    g <- peekElemOff q 1
    b <- peekElemOff q 2
    return (PixelHSI r g b)
  poke p (PixelHSI r g b) = do
    q <- return $ castPtr p
    poke q r
    pokeElemOff q 1 g
    pokeElemOff q 2 b

------------
--- HSIA ---
------------

-- | Hue, Saturation and Intensity color space with Alpha channel.
data HSIA = HueHSIA   -- ^ Hue
          | SatHSIA   -- ^ Saturation
          | IntHSIA   -- ^ Intensity
          | AlphaHSIA -- ^ Alpha
          deriving (Eq, Enum, Typeable)


data instance Pixel HSIA e = PixelHSIA !e !e !e !e deriving Eq


-- | Conversion to `HSI` color space.
class ColorSpace cs Double => ToHSI cs where

  -- | Convert to an `HSI` pixel.
  toPixelHSI :: Pixel cs Double -> Pixel HSI Double

  -- | Convert to an `HSI` image.
  toImageHSI :: (Array arr cs Double, Array arr HSI Double) =>
                Image arr cs Double
             -> Image arr HSI Double
  toImageHSI = map toPixelHSI
  {-# INLINE toImageHSI #-}



instance Show HSIA where
  show HueHSIA   = "Hue"
  show SatHSIA   = "Saturation"
  show IntHSIA   = "Intensity"
  show AlphaHSIA = "Alpha"

  
instance Show e => Show (Pixel HSIA e) where
  show (PixelHSIA h s i a) = "<HSIA:("++show h++"|"++show s++"|"++show i++"|"++show a++")>"


instance (Elevator e, Typeable e) => ColorSpace HSIA e where
  type Components HSIA e = (e, e, e, e)

  toComponents (PixelHSIA h s i a) = (h, s, i, a)
  {-# INLINE toComponents #-}
  fromComponents !(h, s, i, a) = PixelHSIA h s i a
  {-# INLINE fromComponents #-}
  broadcastC = pure
  {-# INLINE broadcastC #-}
  getPxC (PixelHSIA h _ _ _) HueHSIA   = h
  getPxC (PixelHSIA _ s _ _) SatHSIA   = s
  getPxC (PixelHSIA _ _ i _) IntHSIA   = i
  getPxC (PixelHSIA _ _ _ a) AlphaHSIA = a
  {-# INLINE getPxC #-}
  setPxC (PixelHSIA _ s i a) HueHSIA h   = PixelHSIA h s i a
  setPxC (PixelHSIA h _ i a) SatHSIA s   = PixelHSIA h s i a
  setPxC (PixelHSIA h s _ a) IntHSIA i   = PixelHSIA h s i a
  setPxC (PixelHSIA h s i _) AlphaHSIA a = PixelHSIA h s i a
  {-# INLINE setPxC #-}
  mapPxC f (PixelHSIA h s i a) =
    PixelHSIA (f HueHSIA h) (f SatHSIA s) (f IntHSIA i) (f AlphaHSIA a)
  {-# INLINE mapPxC #-}
  mapPx = fmap
  {-# INLINE mapPx #-}
  zipWithPx = liftA2
  {-# INLINE zipWithPx #-}
  foldlPx = foldl'
  {-# INLINE foldlPx #-}


instance (Elevator e, Typeable e) => AlphaSpace HSIA e where
  type Opaque HSIA = HSI

  getAlpha (PixelHSIA _ _ _ a) = a
  {-# INLINE getAlpha #-}
  addAlpha !a (PixelHSI h s i) = PixelHSIA h s i a
  {-# INLINE addAlpha #-}
  dropAlpha (PixelHSIA h s i _) = PixelHSI h s i
  {-# INLINE dropAlpha #-}


-- | Conversion to `HSIA` from another color space with Alpha channel.
class (ToHSI (Opaque cs), AlphaSpace cs Double) => ToHSIA cs where

  -- | Convert to an `HSIA` pixel.
  toPixelHSIA :: Pixel cs Double -> Pixel HSIA Double
  toPixelHSIA px = addAlpha (getAlpha px) (toPixelHSI (dropAlpha px))
  {-# INLINE toPixelHSIA #-}

  -- | Convert to an `HSIA` image.
  toImageHSIA :: (Array arr cs Double, Array arr HSIA Double) =>
                 Image arr cs Double
              -> Image arr HSIA Double
  toImageHSIA = map toPixelHSIA
  {-# INLINE toImageHSIA #-}


instance Functor (Pixel HSIA) where
  fmap f (PixelHSIA h s i a) = PixelHSIA (f h) (f s) (f i) (f a)
  {-# INLINE fmap #-}


instance Applicative (Pixel HSIA) where
  pure !e = PixelHSIA e e e e
  {-# INLINE pure #-}
  (PixelHSIA fh fs fi fa) <*> (PixelHSIA h s i a) = PixelHSIA (fh h) (fs s) (fi i) (fa a)
  {-# INLINE (<*>) #-}


instance Foldable (Pixel HSIA) where
  foldr f !z (PixelHSIA h s i a) = f h (f s (f i (f a z)))
  {-# INLINE foldr #-}


instance Num e => Num (Pixel HSIA e) where
  (+)         = liftA2 (+)
  {-# INLINE (+) #-}
  (-)         = liftA2 (-)
  {-# INLINE (-) #-}
  (*)         = liftA2 (*)
  {-# INLINE (*) #-}
  abs         = liftA abs
  {-# INLINE abs #-}
  signum      = liftA signum
  {-# INLINE signum #-}
  fromInteger = pure . fromInteger
  {-# INLINE fromInteger #-}


instance Fractional e => Fractional (Pixel HSIA e) where
  (/)          = liftA2 (/)
  {-# INLINE (/) #-}
  recip        = liftA recip
  {-# INLINE recip #-}
  fromRational = pure . fromRational
  {-# INLINE fromRational #-}


instance Floating e => Floating (Pixel HSIA e) where
  pi      = pure pi
  {-# INLINE pi #-}
  exp     = liftA exp
  {-# INLINE exp #-}
  log     = liftA log
  {-# INLINE log #-}
  sin     = liftA sin
  {-# INLINE sin #-}
  cos     = liftA cos
  {-# INLINE cos #-}
  asin    = liftA asin
  {-# INLINE asin #-}
  atan    = liftA atan
  {-# INLINE atan #-}
  acos    = liftA acos
  {-# INLINE acos #-}
  sinh    = liftA sinh
  {-# INLINE sinh #-}
  cosh    = liftA cosh
  {-# INLINE cosh #-}
  asinh   = liftA asinh
  {-# INLINE asinh #-}
  atanh   = liftA atanh
  {-# INLINE atanh #-}
  acosh   = liftA acosh
  {-# INLINE acosh #-}


instance Storable e => Storable (Pixel HSIA e) where

  sizeOf _ = 3 * sizeOf (undefined :: e)
  alignment _ = alignment (undefined :: e)
  peek p = do
    q <- return $ castPtr p
    h <- peek q
    s <- peekElemOff q 1
    i <- peekElemOff q 2
    a <- peekElemOff q 3
    return (PixelHSIA h s i a)
  poke p (PixelHSIA h s i a) = do
    q <- return $ castPtr p
    poke q h
    pokeElemOff q 1 s
    pokeElemOff q 2 i
    pokeElemOff q 3 a
