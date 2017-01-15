{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeFamilies #-}
-- |
-- Module      : Graphics.Image.ColorSpace.RGB
-- Copyright   : (c) Alexey Kuleshevich 2017
-- License     : BSD3
-- Maintainer  : Alexey Kuleshevich <lehins@yandex.ru>
-- Stability   : experimental
-- Portability : non-portable
--
module Graphics.Image.ColorSpace.RGB (
  RGB(..), RGBA(..), Pixel(..),
  ToRGB(..), ToRGBA(..),
  -- RGB16 -- Experimental  
  ) where

import Prelude hiding (map)
import Control.Applicative
import Foreign.Ptr
import Foreign.Storable
import Data.Foldable
import Data.Typeable (Typeable)

import Graphics.Image.Interface

-----------
--- RGB ---
-----------

-- | Red, Green and Blue color space.
data RGB = RedRGB
         | GreenRGB
         | BlueRGB deriving (Eq, Enum, Typeable)

instance Show RGB where
  show RedRGB   = "Red"
  show GreenRGB = "Green"
  show BlueRGB  = "Blue"


data instance Pixel RGB e = PixelRGB !e !e !e deriving Eq

instance Show e => Show (Pixel RGB e) where
  show (PixelRGB r g b) = "<RGB:("++show r++"|"++show g++"|"++show b++")>"


-- | Conversion to `RGB` color space.
class ColorSpace cs Double => ToRGB cs where

  -- | Convert to an `RGB` pixel.
  toPixelRGB :: Pixel cs Double -> Pixel RGB Double

  -- | Convert to an `RGB` image.
  toImageRGB :: (Array arr cs Double, Array arr RGB Double) =>
                Image arr cs Double
             -> Image arr RGB Double
  toImageRGB = map toPixelRGB
  {-# INLINE toImageRGB #-}



instance (Elevator e, Typeable e) => ColorSpace RGB e where
  type Components RGB e = (e, e, e)

  toComponents (PixelRGB r g b) = (r, g, b)
  {-# INLINE toComponents #-}
  
  fromComponents !(r, g, b) = PixelRGB r g b
  {-# INLINE fromComponents #-}

  broadcastC = pure
  {-# INLINE broadcastC #-}

  getPxC (PixelRGB r _ _) RedRGB   = r
  getPxC (PixelRGB _ g _) GreenRGB = g
  getPxC (PixelRGB _ _ b) BlueRGB  = b
  {-# INLINE getPxC #-}

  setPxC (PixelRGB _ g b) RedRGB   r = PixelRGB r g b
  setPxC (PixelRGB r _ b) GreenRGB g = PixelRGB r g b
  setPxC (PixelRGB r g _) BlueRGB  b = PixelRGB r g b
  {-# INLINE setPxC #-}

  mapPxC f (PixelRGB r g b) = PixelRGB (f RedRGB r) (f GreenRGB g) (f BlueRGB b)
  {-# INLINE mapPxC #-}

  mapPx = fmap
  {-# INLINE mapPx #-}

  zipWithPx = liftA2
  {-# INLINE zipWithPx #-}

  foldlPx = foldl'
  {-# INLINE foldlPx #-}




instance Functor (Pixel RGB) where
  fmap f (PixelRGB r g b) = PixelRGB (f r) (f g) (f b)
  {-# INLINE fmap #-}


instance Applicative (Pixel RGB) where
  pure !e = PixelRGB e e e
  {-# INLINE pure #-}
  (PixelRGB fr fg fb) <*> (PixelRGB r g b) = PixelRGB (fr r) (fg g) (fb b)
  {-# INLINE (<*>) #-}


instance Foldable (Pixel RGB) where
  foldr f !z (PixelRGB r g b) = f r (f g (f b z))
  {-# INLINE foldr #-}


instance Num e => Num (Pixel RGB e) where
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
  

instance Fractional e => Fractional (Pixel RGB e) where
  (/)          = liftA2 (/)
  {-# INLINE (/) #-}
  recip        = liftA recip
  {-# INLINE recip #-}
  fromRational = pure . fromRational
  {-# INLINE fromRational #-}


instance Floating e => Floating (Pixel RGB e) where
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


instance Storable e => Storable (Pixel RGB e) where

  sizeOf _ = 3 * sizeOf (undefined :: e)
  alignment _ = alignment (undefined :: e)
  peek p = do
    q <- return $ castPtr p
    r <- peek q
    g <- peekElemOff q 1
    b <- peekElemOff q 2
    return (PixelRGB r g b)
  poke p (PixelRGB r g b) = do
    q <- return $ castPtr p
    poke q r
    pokeElemOff q 1 g
    pokeElemOff q 2 b




------------
--- RGBA ---
------------


-- | Red, Green and Blue color space with Alpha channel.
data RGBA = RedRGBA
          | GreenRGBA
          | BlueRGBA
          | AlphaRGBA deriving (Eq, Enum, Typeable)

instance Show RGBA where
  show RedRGBA   = "Red"
  show GreenRGBA = "Green"
  show BlueRGBA  = "Blue"
  show AlphaRGBA = "Alpha"

data instance Pixel RGBA e = PixelRGBA !e !e !e !e deriving Eq


instance Show e => Show (Pixel RGBA e) where
  show (PixelRGBA r g b a) = "<RGBA:("++show r++"|"++show g++"|"++show b++"|"++show a++")>"


-- | Conversion to `RGBA` from another color space with Alpha channel.
class (ToRGB (Opaque cs), AlphaSpace cs Double) => ToRGBA cs where

  -- | Convert to an `RGBA` pixel.
  toPixelRGBA :: Pixel cs Double -> Pixel RGBA Double
  toPixelRGBA px = addAlpha (getAlpha px) (toPixelRGB (dropAlpha px))
  {-# INLINE toPixelRGBA #-}

  -- | Convert to an `RGBA` image.
  toImageRGBA :: (Array arr cs Double, Array arr RGBA Double) =>
                Image arr cs Double
             -> Image arr RGBA Double
  toImageRGBA = map toPixelRGBA
  {-# INLINE toImageRGBA #-}


instance (Elevator e, Typeable e) => ColorSpace RGBA e where
  type Components RGBA e = (e, e, e, e)

  toComponents (PixelRGBA r g b a) = (r, g, b, a)
  {-# INLINE toComponents #-}
  
  fromComponents !(r, g, b, a) = PixelRGBA r g b a
  {-# INLINE fromComponents #-}

  broadcastC = pure
  {-# INLINE broadcastC #-}

  getPxC (PixelRGBA r _ _ _) RedRGBA   = r
  getPxC (PixelRGBA _ g _ _) GreenRGBA = g
  getPxC (PixelRGBA _ _ b _) BlueRGBA  = b
  getPxC (PixelRGBA _ _ _ a) AlphaRGBA = a
  {-# INLINE getPxC #-}

  setPxC (PixelRGBA _ g b a) RedRGBA   r = PixelRGBA r g b a
  setPxC (PixelRGBA r _ b a) GreenRGBA g = PixelRGBA r g b a
  setPxC (PixelRGBA r g _ a) BlueRGBA  b = PixelRGBA r g b a
  setPxC (PixelRGBA r g b _) AlphaRGBA a = PixelRGBA r g b a
  {-# INLINE setPxC #-}

  mapPxC f (PixelRGBA r g b a) =
    PixelRGBA (f RedRGBA r) (f GreenRGBA g) (f BlueRGBA b) (f AlphaRGBA a)
  {-# INLINE mapPxC #-}

  mapPx = fmap
  {-# INLINE mapPx #-}

  zipWithPx = liftA2
  {-# INLINE zipWithPx #-}

  foldlPx = foldl'
  {-# INLINE foldlPx #-}


instance (Elevator e, Typeable e) => AlphaSpace RGBA e where
  type Opaque RGBA = RGB

  getAlpha (PixelRGBA _ _ _ a) = a
  {-# INLINE getAlpha #-}
  addAlpha !a (PixelRGB r g b) = PixelRGBA r g b a
  {-# INLINE addAlpha #-}
  dropAlpha (PixelRGBA r g b _) = PixelRGB r g b
  {-# INLINE dropAlpha #-}



instance Functor (Pixel RGBA) where
  fmap f (PixelRGBA r g b a) = PixelRGBA (f r) (f g) (f b) (f a)
  {-# INLINE fmap #-}

instance Applicative (Pixel RGBA) where
  pure !e = PixelRGBA e e e e
  {-# INLINE pure #-}
  (PixelRGBA fr fg fb fa) <*> (PixelRGBA r g b a) = PixelRGBA (fr r) (fg g) (fb b) (fa a)
  {-# INLINE (<*>) #-}

instance Foldable (Pixel RGBA) where
  foldr f !z (PixelRGBA r g b a) = f r (f g (f b (f a z)))
  {-# INLINE foldr #-}



instance Num e => Num (Pixel RGBA e) where
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


instance Fractional e => Fractional (Pixel RGBA e) where
  (/)          = liftA2 (/)
  {-# INLINE (/) #-}
  recip        = liftA recip
  {-# INLINE recip #-}
  fromRational = pure . fromRational
  {-# INLINE fromRational #-}


instance Floating e => Floating (Pixel RGBA e) where
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

 
instance Storable e => Storable (Pixel RGBA e) where

  sizeOf _ = 3 * sizeOf (undefined :: e)
  alignment _ = alignment (undefined :: e)
  peek p = do
    q <- return $ castPtr p
    r <- peek q
    g <- peekElemOff q 1
    b <- peekElemOff q 2
    a <- peekElemOff q 3
    return (PixelRGBA r g b a)
  poke p (PixelRGBA r g b a) = do
    q <- return $ castPtr p
    poke q r
    pokeElemOff q 1 g
    pokeElemOff q 2 b
    pokeElemOff q 3 a





------------------------------------------------

-- -- | Red, Green and Blue color space.
-- data RGB16 = RedRGB16
--           | GreenRGB16
--           | BlueRGB16 deriving (Eq, Enum, Typeable, Show)


-- --data instance Pixel RGB16 Word16 = PixelRGB16 !Word16 !Word16 !Word16 deriving Eq
-- data instance Pixel RGB16 Word16 = PixelRGB16
--                                    {-# UNPACK #-} !Word16
--                                    {-# UNPACK #-} !Word16
--                                    {-# UNPACK #-} !Word16 deriving Eq
-- --data instance Pixel RGB16 Word16 = PixelRGB16 

-- instance ColorSpace RGB16 Word16 where
--   type Components RGB16 Word16 = (Word16, Word16, Word16)

--   broadcastC !e = PixelRGB16 e e e
--   {-# INLINE broadcastC #-}

--   toComponents (PixelRGB16 r g b) = (r, g, b)
--   {-# INLINE toComponents #-}
  
--   fromComponents !(r, g, b) = PixelRGB16 r g b
--   {-# INLINE fromComponents #-}


--   getPxC (PixelRGB16 r _ _) RedRGB16   = r
--   getPxC (PixelRGB16 _ g _) GreenRGB16 = g
--   getPxC (PixelRGB16 _ _ b) BlueRGB16  = b
--   {-# INLINE getPxC #-}

--   setPxC (PixelRGB16 _ g b) RedRGB16   r = PixelRGB16 r g b
--   setPxC (PixelRGB16 r _ b) GreenRGB16 g = PixelRGB16 r g b
--   setPxC (PixelRGB16 r g _) BlueRGB16  b = PixelRGB16 r g b
--   {-# INLINE setPxC #-}

--   mapPxC f (PixelRGB16 r g b) = PixelRGB16 (f RedRGB16 r) (f GreenRGB16 g) (f BlueRGB16 b)
--   {-# INLINE mapPxC #-}

--   mapPx f (PixelRGB16 r g b) = PixelRGB16 (f r) (f g) (f b)
--   {-# INLINE mapPx #-}

--   zipWithPx f (PixelRGB16 r1 g1 b1) (PixelRGB16 r2 g2 b2) =
--     PixelRGB16 (f r1 r2) (f g1 g2) (f b1 b2)
--   {-# INLINE zipWithPx #-}

--   foldlPx f !acc (PixelRGB16 r g b) = f (f (f acc r) g) b


-- instance Num (Pixel RGB16 Word16) where
--   (+)         = zipWithPx (+)
  
--   (-)         = zipWithPx (-)
--   {-# INLINE (-) #-}
  
--   (*)         = zipWithPx (*)
--   {-# INLINE (*) #-}
  
--   abs         = mapPx abs
--   {-# INLINE abs #-}
  
--   signum      = mapPx signum
--   {-# INLINE signum #-}
  
--   fromInteger = broadcastC . fromInteger
--   {-# INLINE fromInteger #-}


-- -- instance Fractional (Pixel RGB16 Word16) where
-- --   (/)          = zipWithPx (/)
-- --   {-# INLINE (/) #-}
  
-- --   recip        = mapPx recip
-- --   {-# INLINE recip #-}

-- --   fromRational = broadcastC . fromRational
-- --   {-# INLINE fromRational #-}


-- -- instance Floating (Pixel RGB16 Word16) where
-- --   pi      = broadcastC pi
-- --   {-# INLINE pi #-}

-- --   exp     = mapPx exp
-- --   {-# INLINE exp #-}

-- --   log     = mapPx log
-- --   {-# INLINE log #-}
  
-- --   sin     = mapPx sin
-- --   {-# INLINE sin #-}
  
-- --   cos     = mapPx cos
-- --   {-# INLINE cos #-}
  
-- --   asin    = mapPx asin
-- --   {-# INLINE asin #-}
  
-- --   atan    = mapPx atan
-- --   {-# INLINE atan #-}
  
-- --   acos    = mapPx acos
-- --   {-# INLINE acos #-}
  
-- --   sinh    = mapPx sinh
-- --   {-# INLINE sinh #-}
  
-- --   cosh    = mapPx cosh
-- --   {-# INLINE cosh #-}
  
-- --   asinh   = mapPx asinh
-- --   {-# INLINE asinh #-}
  
-- --   atanh   = mapPx atanh
-- --   {-# INLINE atanh #-}
  
-- --   acosh   = mapPx acosh
-- --   {-# INLINE acosh #-}


-- -- instance Show RGB16 where
-- --   show RedRGB16   = "Red"
-- --   show GreenRGB16 = "Green"
-- --   show BlueRGB16  = "Blue"

-- -- instance Show (Pixel RGB16 Word16) where
-- --   show (PixelRGB16 r g b) = "<RGB:("++show r++"|"++show g++"|"++show b++")>"


-- -- instance Storable (Pixel RGB16 Word16) where

-- --   sizeOf _ = 3 * sizeOf (undefined :: Word16)
-- --   alignment _ = alignment (undefined :: Word16)
-- --   peek p = do
-- --     q <- return $ castPtr p
-- --     r <- peek q
-- --     g <- peekElemOff q 1
-- --     b <- peekElemOff q 2
-- --     return (PixelRGB16 r g b)
-- --   poke p (PixelRGB16 r g b) = do
-- --     q <- return $ castPtr p
-- --     poke q r
-- --     pokeElemOff q 1 g
-- --     pokeElemOff q 2 b
