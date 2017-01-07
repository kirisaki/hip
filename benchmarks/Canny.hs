{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE BangPatterns #-}
module Main where

import Prelude as P
import Criterion.Main
import Graphics.Image as I
import Graphics.Image.Interface as I
import Graphics.Image.Interface.Repa
import Graphics.Image.Interface.Map
import Graphics.Image.Interface.Vector

import Data.Array.Repa as R
import Data.Array.Repa.Eval
import Data.Array.Repa.Repr.Unboxed
import Data.Array.Repa.Stencil
import Data.Array.Repa.Stencil.Dim2


sobelGx :: I.Array arr cs e => Image arr cs e -> Image arr cs e
sobelGx =
  convolve Edge (fromLists [[-1, 0, 1], [-2, 0, 2], [-1, 0, 1]])

sobelGy :: I.Array arr cs e => Image arr cs e -> Image arr cs e
sobelGy =
  convolve Edge (fromLists [[-1,-2,-1], [ 0, 0, 0], [ 1, 2, 1]])

sobelSGx :: (I.Array arr cs e, I.Array VS cs e) => Image arr cs e -> Image arr cs e
sobelSGx =
  convolveSparse Edge (fromListsR VS [[-1, 0, 1], [-2, 0, 2], [-1, 0, 1]])

sobelSGy :: (I.Array arr cs e, I.Array VS cs e) => Image arr cs e -> Image arr cs e
sobelSGy =
  convolveSparse Edge (fromListsR VS [[-1,-2,-1], [ 0, 0, 0], [ 1, 2, 1]])


sobelMSGx :: (I.Array arr cs e, I.Array MS cs e) => Image arr cs e -> Image arr cs e
sobelMSGx =
  convolveSparse Edge (fromListsR MS [[-1, 0, 1], [-2, 0, 2], [-1, 0, 1]])

sobelMSGy :: (I.Array arr cs e, I.Array MS cs e) => Image arr cs e -> Image arr cs e
sobelMSGy =
  convolveSparse Edge (fromListsR MS [[-1,-2,-1], [ 0, 0, 0], [ 1, 2, 1]])

sobelIMSGx :: (I.Array arr cs e, I.Array IMS cs e) => Image arr cs e -> Image arr cs e
sobelIMSGx =
  convolveSparse Edge (fromListsR IMS [[-1, 0, 1], [-2, 0, 2], [-1, 0, 1]])

sobelIMSGy :: (I.Array arr cs e, I.Array IMS cs e) => Image arr cs e -> Image arr cs e
sobelIMSGy =
  convolveSparse Edge (fromListsR IMS [[-1,-2,-1], [ 0, 0, 0], [ 1, 2, 1]])


sobelHMSGx :: (I.Array arr cs e, I.Array HMS cs e) => Image arr cs e -> Image arr cs e
sobelHMSGx =
  convolveSparse Edge (fromListsR HMS [[-1, 0, 1], [-2, 0, 2], [-1, 0, 1]])

sobelHMSGy :: (I.Array arr cs e, I.Array HMS cs e) => Image arr cs e -> Image arr cs e
sobelHMSGy =
  convolveSparse Edge (fromListsR HMS [[-1,-2,-1], [ 0, 0, 0], [ 1, 2, 1]])



sobelGx' :: I.Array arr cs e => Image arr cs e -> Image arr cs e
sobelGx' =
  convolveCols Edge [1, 2, 1] . convolveRows Edge [1, 0, -1]

sobelGy' :: I.Array arr cs e => Image arr cs e -> Image arr cs e
sobelGy' =
  convolveCols Edge [1, 0, -1] . convolveRows Edge [1, 2, 1]


sobelGxR
  :: R.Array U DIM2 (Pixel Y Double)
     -> R.Array PC5 DIM2 (Pixel Y Double)
sobelGxR = mapStencil2 BoundClamp stencil 
  where stencil = makeStencil2 3 3
                  (\ix -> case ix of
                      Z :. -1 :. -1  -> Just (-1)
                      Z :.  0 :. -1  -> Just (-2)
                      Z :.  1 :. -1  -> Just (-1)
                      Z :. -1 :.  1  -> Just 1
                      Z :.  0 :.  1  -> Just 2
                      Z :.  1 :.  1  -> Just 1
                      _              -> Nothing)

sobelGyR
  :: R.Array U DIM2 (Pixel Y Double)
     -> R.Array PC5 DIM2 (Pixel Y Double)
sobelGyR = mapStencil2 BoundClamp stencil 
  where stencil = makeStencil2 3 3
                  (\ix -> case ix of
                      Z :.  1 :. -1  -> Just (-1)
                      Z :.  1 :.  0  -> Just (-2)
                      Z :.  1 :.  1  -> Just (-1)
                      Z :. -1 :. -1  -> Just 1
                      Z :. -1 :.  0  -> Just 2
                      Z :. -1 :.  1  -> Just 1
                      _              -> Nothing)

force
  :: (Load r1 sh e, Unbox e, Monad m)
  => R.Array r1 sh e -> m (R.Array U sh e)
force arr = do
    forcedArr <- computeUnboxedP arr
    forcedArr `deepSeqArray` return forcedArr

main :: IO ()
main = do
  img' <- readImageY RP "images/downloaded/frog-1280x824.jpg"
  let !img = compute img'
  let sobel = sobelGx img
  let sobelSep = sobelGx' img
  let sobelVS = sobelSGx img
  -- let sobelMS = sobelMSGx img
  -- let sobelIMS = sobelIMSGx img
  -- let sobelHMS = sobelHMSGx img
  let imgR = toRepaArray img
  let sobelR = sobelGxR imgR
  defaultMain
    [ bgroup
        "Sobel"
        [ bench "naive" $ whnf compute sobel
        , bench "separated" $ whnf compute sobelSep
        , bench "sparse VS" $ whnf compute sobelVS
        -- , bench "sparse MS" $ whnf compute sobelMS
        -- , bench "sparse IMS" $ whnf compute sobelIMS
        -- , bench "sparse HMS" $ whnf compute sobelHMS
        --, bench "repa" $ whnf (compute . fromRepaArrayP) sobelR
        , bench "repa" $ whnfIO (force sobelR)
        ]
    ]
  -- img' <- readImageY RS "images/downloaded/frog-1280x824.jpg"
  -- let !imgR = compute img'
  -- let !imgV = toManifest imgR
  -- -- let sobel = sobelGx imgV
  -- -- let sobel' = sobelGx' imgV
  -- -- let sobel'' = sobelSGx imgV
  -- let arrR = toRepaArray imgR
  -- let sobelR = sobelGxR arrR
  -- defaultMain
  --   [ bgroup
  --       "Sobel"
  --       [ bench "naive" $ nf sobelGx imgV
  --       , bench "separated" $ nf sobelGx' imgV
  --       , bench "sparse" $ nf sobelSGx imgV
  --       --, bench "repa" $ whnf (compute . fromRepaArrayP) sobelR
  --       , bench "repa" $ whnfIO (force sobelR)
  --       ]
  --   ]

  -- let sobel = sqrt (sobelGx img ^ (2 :: Int) + sobelGy img ^ (2 :: Int))
  -- let sobel' = sqrt (sobelGx' img ^ (2 :: Int) + sobelGy' img ^ (2 :: Int))
  -- let sobel'' = sqrt (sobelSGx img ^ (2 :: Int) + sobelSGy img ^ (2 :: Int))
  -- let sobel''' = sqrt (sobelMSGx img ^ (2 :: Int) + sobelMSGy img ^ (2 :: Int))
  -- let imgR = toRepaArray img
  -- let sobelR =
  --       R.map
  --         sqrt
  --         (R.map (^ (2 :: Int)) (sobelGxR imgR) +^
  --          R.map (^ (2 :: Int)) (sobelGyR imgR))
  -- defaultMain
  --   [ bgroup
  --       "Sobel"
  --       [ bench "naive" $ whnf compute sobel
  --       , bench "separated" $ whnf compute sobel'
  --       , bench "sparse VS" $ whnf compute sobel''
  --       , bench "sparse MS" $ whnf compute sobel'''
  --       --, bench "repa" $ whnf (compute . fromRepaArrayP) sobelR
  --       , bench "repa" $ whnfIO (force sobelR)
  --       ]
  --   ]

