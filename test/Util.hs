module Util where

import           Control.Exception.Base (bracket)
import           Control.Monad (when)
import qualified Data.ByteString as B
import qualified Data.ByteString.Lazy as LB
import           Data.Ext
import           Data.Function (on)
import qualified Data.List as L
import           Data.Proxy
import           Data.Vinyl
import           System.Directory (removeFile, getTemporaryDirectory)
import           System.FilePath (takeExtension)
import           System.IO (hClose,openTempFile, Handle)
import           Test.Hspec

--------------------------------------------------------------------------------

-- | Computes all elements on which the two lists differ
difference :: Eq a => [a] -> [a] -> [a]
difference xs ys = (xs L.\\ ys) ++ (ys L.\\ xs)
