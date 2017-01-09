{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE ScopedTypeVariables #-}
module Algorithms.Geometry.DelaunayTriangulation.Types where

import           Control.Lens
import qualified Data.CircularList as C
import           Data.Ext
import           Data.Geometry
import           Data.Geometry.Ipe
import           Data.Geometry.PlanarSubdivision
import qualified Data.IntMap.Strict as IM
import qualified Data.Map as M
import qualified Data.Map.Strict as SM
import           Data.PlaneGraph
import qualified Data.Vector as V

--------------------------------------------------------------------------------

-- We store all adjacency lists in clockwise order

-- : If v on the convex hull, then its first entry in the adj. lists is its CCW
-- successor (i.e. its predecessor) on the convex hull

-- | Rotating Right <-> rotate clockwise

type VertexID = Int

type Vertex    = C.CList VertexID

type Adj = IM.IntMap (C.CList VertexID)

-- | Neighbours are stored in clockwise order: i.e. rotating right moves to the
-- next clockwise neighbour.
data Triangulation p r = Triangulation { _vertexIds  :: M.Map (Point 2 r) VertexID
                                       , _positions  :: V.Vector (Point 2 r :+ p)
                                       , _neighbours :: V.Vector (C.CList VertexID)
                                       }
                         deriving (Show,Eq)
makeLenses ''Triangulation


type Mapping p r = (M.Map (Point 2 r) VertexID, V.Vector (Point 2 r :+ p))




showDT :: (Show p, Show r)  => Triangulation p r -> IO ()
showDT = mapM_ print . triangulationEdges


triangulationEdges   :: Triangulation p r -> [(Point 2 r :+ p, Point 2 r :+ p)]
triangulationEdges t = let pts = _positions t
                       in map (\(u,v) -> (pts V.! u, pts V.! v)) . tEdges $ t


tEdges :: Triangulation p r -> [(VertexID,VertexID)]
tEdges = concatMap (\(i,ns) -> map (i,) . filter (> i) . C.toList $ ns)
       . zip [0..] . V.toList . _neighbours

drawTriangulation :: IpeOut (Triangulation p r) (IpeObject r)
drawTriangulation = IpeOut $ \tr ->
    let es = map (uncurry ClosedLineSegment) . triangulationEdges $ tr
    in asIpeGroup $ map (\e -> asIpeObjectWith ipeLineSegment e mempty) es


--------------------------------------------------------------------------------

data ST a b c = ST { fst' :: !a, snd' :: !b , trd' :: !c}

type ArcID = Int

-- | ST' is a strict triple (m,a,x) containing:
--
-- - m: a Map, mapping edges, represented by a pair of vertexId's (u,v) with
--            u < v, to arcId's.
-- - a: the next available unused arcID
-- - x: the data value we are interested in computing
type ST' a = ST (SM.Map (VertexID,VertexID) ArcID) ArcID a


-- | convert the triangulation into a planarsubdivision
--
-- running time: $O(n\log n)$.
toPlanarSubdivision :: proxy s -> Triangulation p r -> PlanarSubdivision s p () () r
toPlanarSubdivision px tr = PlanarSubdivision g
  where
    g = toPlaneGraph px tr & vertexData.traverse  %~ (\(v :+ e) -> VertexData v e)
                           & dartData.traverse._2 %~ EdgeData Visible
                           & faceData.traverse    %~ FaceData []

-- | convert the triangulation into a plane graph
--
-- running time: $O(n\log n)$.
toPlaneGraph    :: forall proxy s p r.
                   proxy s -> Triangulation p r -> PlaneGraph s Primal_ p () () r
toPlaneGraph _ tr = g & vertexData .~ tr^.positions
  where
    g       = fromAdjacencyLists . V.toList . V.imap f $ tr^.neighbours
    f i adj = (VertexId i, VertexId <$> adj)


  -- (planarGraph' . P.toCycleRep n $ perm)&vertexData .~ tr^.positions
  -- where
  --   neighs    = C.rightElements <$> tr^.neighbours
  --   n         = sum . fmap length $ neighs

  --   vtxIDs = [0..]
  --   perm = trd' . foldr toOrbit (ST mempty 0 mempty) $ zip vtxIDs (V.toList neighs)

  --   -- | Given a vertex with its adjacent vertices (u,vs) (in CCW order) convert this
  --   -- vertex with its adjacent vertices into an Orbit
  --   toOrbit                     :: (VertexID,[VertexID]) -> ST' [[Dart s]]
  --                               -> ST' [[Dart s]]
  --   toOrbit (u,vs) (ST m a dss) =
  --     let (ST m' a' ds') = foldr (toDart . (u,)) (ST m a mempty) vs
  --     in ST m' a' (ds':dss)


  --   -- | Given an edge (u,v) and a triplet (m,a,ds) we construct a new dart
  --   -- representing this edge.
  --   toDart                   :: (VertexID,VertexID) -> ST' [Dart s] -> ST' [Dart s]
  --   toDart (u,v) (ST m a ds) = let dir = if u < v then Positive else Negative
  --                                  t'  = (min u v, max u v)
  --                              in case M.lookup t' m of
  --     Just a' -> ST m                  a     (Dart (Arc a') dir : ds)
  --     Nothing -> ST (SM.insert t' a m) (a+1) (Dart (Arc a)  dir : ds)
