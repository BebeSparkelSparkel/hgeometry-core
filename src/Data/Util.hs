--------------------------------------------------------------------------------
-- |
-- Module      :  Data.Util
-- Copyright   :  (C) Frank Staals
-- License     :  see the LICENSE file
-- Maintainer  :  Frank Staals
--
-- Some basic types, mostly strict triples and pairs.
--
--------------------------------------------------------------------------------
module Data.Util where

import Control.DeepSeq
import Control.Lens
import GHC.Generics (Generic)
import qualified Data.List as List

--------------------------------------------------------------------------------
-- * Strict Triples

-- |  strict triple
data STR a b c = STR { fst' :: !a, snd' :: !b , trd' :: !c}
               deriving (Show,Eq,Ord,Functor,Generic)

instance (Semigroup a, Semigroup b, Semigroup c) => Semigroup (STR a b c) where
  (STR a b c) <> (STR d e f) = STR (a <> d) (b <> e) (c <> f)

instance (Semigroup a, Semigroup b, Semigroup c
         , Monoid a, Monoid b, Monoid c) => Monoid (STR a b c) where
  mempty = STR mempty mempty mempty
  mappend = (<>)

instance (NFData a, NFData b, NFData c) => NFData (STR a b c)

instance Field1 (STR a b c) (STR d b c) a d where
  _1 = lens fst' (\(STR _ b c) d -> STR d b c)

instance Field2 (STR a b c) (STR a d c) b d where
  _2 = lens snd' (\(STR a _ c) d -> STR a d c)

instance Field3 (STR a b c) (STR a b d) c d where
  _3 = lens trd' (\(STR a b _) d -> STR a b d)

-- | Generate All unique unordered triplets.
--
uniqueTriplets    :: [a] -> [STR a a a]
uniqueTriplets xs = [ STR x y z | (x:ys) <- nonEmptyTails xs, SP y z <- uniquePairs ys]


--------------------------------------------------------------------------------
-- * Strict Pairs


-- | Strict pair
data SP a b = SP !a !b deriving (Show,Eq,Ord,Functor,Generic)

instance (Semigroup a, Semigroup b) => Semigroup (SP a b) where
  (SP a b) <> (SP c d) = SP (a <> c) (b <> d)

instance (Semigroup a, Semigroup b, Monoid a, Monoid b) => Monoid (SP a b) where
  mempty = SP mempty mempty
  mappend = (<>)

instance (NFData a, NFData b) => NFData (SP a b)


instance Field1 (SP a b) (SP c b) a c where
  _1 = lens (\(SP a _) -> a) (\(SP _ b) c -> SP c b)

instance Field2 (SP a b) (SP a c) b c where
  _2 = lens (\(SP _ b) -> b) (\(SP a _) c -> SP a c)

instance Bifunctor SP where
  bimap f g (SP a b) = SP (f a) (g b)

--------------------------------------------------------------------------------
-- | * Strict pair whose elements are of the same type.

-- | Strict pair with both items the same
type Two a = SP a a

pattern Two :: a -> a -> Two a
pattern Two a b = SP a b
{-# COMPLETE Two #-}

-- | Given a list xs, generate all unique (unordered) pairs.
--
--
uniquePairs    :: [a] -> [Two a]
uniquePairs xs = [ Two x y | (x:ys) <- nonEmptyTails xs, y <- ys ]

--------------------------------------------------------------------------------

-- | A version of List.tails in which we remove the emptylist
nonEmptyTails :: [a] -> [[a]]
nonEmptyTails = List.init . List.tails
