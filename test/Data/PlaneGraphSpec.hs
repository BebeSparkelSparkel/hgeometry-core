{-# LANGUAGE PartialTypeSignatures #-}
module Data.PlaneGraphSpec where


import           Control.Lens
import           Data.Ext
import           Data.Geometry.LineSegment
import           Data.Geometry.Point
import           Data.Geometry.Polygon
import           Data.PlaneGraph
import           Data.Util
import qualified Data.Vector as V
import           Test.Hspec

--------------------------------------------------------------------------------

spec :: Spec
spec = describe "PlaneGraph tests" $ do
         it "fromConnectedSegments, correct handling of high degree vertex" $
           draw test `shouldBe` mempty
         it "fromConnectedSegments, correct handling of high degree vertex; test 2" $
           draw test2 `shouldBe` mempty

data Test1 = Test1

draw  :: PlaneGraph s p e extra r -> V.Vector (FaceId' s, Polygon 'Simple p r :+ extra)
draw = V.filter isEmpty . rawFacePolygons
  where
    isEmpty (_,p :+ _) = (< 3) . length . polygonVertices $ p

test :: PlaneGraph Test1 _ () () Integer
test = fromConnectedSegments (Identity Test1) testSegs

test2 :: PlaneGraph Test1 _ () () Integer
test2 = fromConnectedSegments (Identity Test1) testSegs2

testSegs :: [LineSegment 2 () Integer :+ ()]
testSegs = map (\(p,q) -> ClosedLineSegment (ext p) (ext q) :+ ())
                   [ (origin, Point2 10 10)
                   , (origin, Point2 12 10)
                   , (origin, Point2 20 5)
                   , (origin, Point2 13 20)
                   , (Point2 10 10, Point2 12 10)
                   , (Point2 10 10, Point2 13 20)
                   , (Point2 12 10, Point2 20 5)
                   ]
testSegs2 :: [LineSegment 2 () Integer :+ ()]
testSegs2 = map (\(p,q) -> ClosedLineSegment (ext p) (ext q) :+ ())
                   [ (origin, Point2 10 0)
                   , (Point2 10 0, Point2 10 10)
                   , (origin, Point2 10 10)

                   , (origin, Point2 (-10) 0)
                   , (Point2 (-10) 0, Point2 (-10) (-10))
                   , (origin, Point2 (-10) (-10))
                   ]

-- segs2 =