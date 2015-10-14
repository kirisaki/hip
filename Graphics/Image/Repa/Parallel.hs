{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE BangPatterns, FlexibleContexts #-}

module Graphics.Image.Repa.Parallel (
  compute, fold, sum, maximum, minimum, normalize, toVector, toLists, toArray,
  writeImage, display, convolve, convolveRows, convolveCols, fft, ifft,
  SaveOption(..)
  ) where

import Prelude hiding (maximum, minimum, sum, map)
import qualified Prelude as P (map)
import Graphics.Image.Conversion (Saveable, SaveOption(..))
import Graphics.Image.Interface (Pixel, Inner)
import Graphics.Image.Pixel.Complex (ComplexInner, Complex)
import qualified Graphics.Image.Repa.Internal as I
import qualified Graphics.Image.IO as IO (writeImage, display)
import qualified Graphics.Image.Processing.Convolution as C
import qualified Graphics.Image.Complex as C
import Data.Array.Repa.Eval (Elt)
import Data.Array.Repa as R hiding ((++))
import Data.Vector.Unboxed (Vector, Unbox)


compute :: (Elt px, Unbox px, Pixel px) =>
           I.Image px
        -> I.Image px
compute = I.compute I.Parallel
{-# INLINE compute #-}


fold :: (Elt px, Unbox px, Pixel px) =>
        (px -> px -> px)
     -> px
     -> I.Image px
     -> px
fold = I.fold I.Parallel
{-# INLINE fold #-}


sum :: (Elt px, Unbox px, Num px, Pixel px) => I.Image px -> px
sum = I.sum I.Parallel
{-# INLINE sum #-}


maximum :: (Elt px, Unbox px, Pixel px, Ord px) =>
           I.Image px
        -> px
maximum = I.maximum I.Parallel
{-# INLINE maximum #-}


minimum :: (Elt px, Unbox px, Pixel px, Ord px) =>
           I.Image px
        -> px
minimum = I.minimum I.Parallel
{-# INLINE minimum #-}


normalize :: (Elt px, Unbox px, Pixel px, Ord px, Fractional px) =>
             I.Image px
          -> I.Image px
normalize = I.normalize I.Parallel
{-# INLINE normalize #-}


convolve :: (Pixel px, Num px, Unbox px, Elt px) => I.Image px -> I.Image px -> I.Image px
convolve krn img = C.convolve C.Wrap (compute krn) (compute img)
{-# INLINE convolve #-}


convolveRows :: (Pixel px, Num px, Unbox px, Elt px) => [px] -> I.Image px -> I.Image px
convolveRows ls = convolve (I.fromLists [ls])
{-# INLINE convolveRows #-}


convolveCols :: (Pixel px, Num px, Unbox px, Elt px) => [px] -> I.Image px -> I.Image px
convolveCols ls = convolve (I.fromLists $ P.map (:[]) ls)
{-# INLINE convolveCols #-}


toVector :: (Elt px, Unbox px, Pixel px) =>
            I.Image px
         -> Vector px
toVector = I.toVector I.Parallel
{-# INLINE toVector #-}


toLists :: (Elt px, Unbox px, Pixel px) =>
           I.Image px
        -> [[px]]
toLists = I.toLists I.Parallel
{-# INLINE toLists #-}


toArray :: (Elt px, Unbox px, Pixel px) =>
           I.Image px
        -> Array U DIM2 px
toArray = I.toArray I.Parallel
{-# INLINE toArray #-}


writeImage :: (Saveable I.Image px, Elt px, Unbox px, Pixel px) =>
              FilePath
           -> I.Image px
           -> [SaveOption I.Image px]
           -> IO ()
writeImage !path !img !options = IO.writeImage I.Parallel path img options
{-# INLINE writeImage #-}


display :: (Saveable I.Image px, Elt px, Unbox px, Pixel px) =>
           I.Image px
        -> IO ()
display = IO.display I.Parallel
{-# INLINE display #-}

fft :: (ComplexInner px, Unbox px, Elt px, Unbox (Inner px), Elt (Inner px)) => I.Image (Complex px) -> I.Image (Complex px)
fft = C.fft I.Parallel

ifft :: (ComplexInner px, Unbox px, Elt px, Unbox (Inner px), Elt (Inner px)) =>
        I.Image (Complex px) -> I.Image (Complex px)
ifft = C.ifft I.Parallel