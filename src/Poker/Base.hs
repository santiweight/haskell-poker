{-# LANGUAGE DataKinds #-}
{-# LANGUAGE KindSignatures #-}

-- BIG IMPORTANT TODO GET RID OF EQ INSTANCE FOR INDEX

module Poker.Base
  ( module Poker.Types
  , isTableAction, isDealerAction, isPlayerAction
  , inIndex
  , atPosition
  , sortPreflop, sortPostflop
  , listCard, listRank, listSuit, listShape, listPosition, listHoldemHoldings
  , allShapedHands
  , newDeck
  ) where

import Control.Monad (guard)
import Data.List (sort)
import Poker.Types

isTableAction :: Action t -> Bool
isTableAction act = case act of
  MkPlayerAction _ -> True
  _                -> False

isPlayerAction :: Action t -> Bool
isPlayerAction act = case act of
  MkPlayerAction _ -> True
  _                -> False

isDealerAction :: Action t -> Bool
isDealerAction act = case act of
  MkDealerAction _ -> True
  _ -> False

atPosition :: Position -> PlayerAction t -> Bool
atPosition pos = (pos ==) . position

-- Sort a list of positions according to preflop ordering
sortPreflop :: [Position] -> [Position]
sortPreflop = fmap toEnum . sort . fmap fromEnum

-- Sort a list of positions acccording to postflop ordering
sortPostflop :: [Position] -> [Position]
sortPostflop =
  fmap (toEnum . fromPostFlopOrder)
    . sort
    . fmap (toPostFlopOrder . fromEnum)
  where
    fromPostFlopOrder = flip mod 6 . (+ 4)
    toPostFlopOrder = flip mod 6 . (+ 2)

listCard :: [Card]
listCard = reverse (take 52 (enumFrom (toEnum 0)))

listRank :: [Rank]
listRank = listEnum

listSuit :: [Suit]
listSuit = listEnum

listPosition :: [Position]
listPosition = listEnum :: [Position]

listShape :: [Shape]
listShape = listEnum :: [Shape]

listHoldemHoldings :: [Holding]
listHoldemHoldings = reverse $ do
  rank1 <- listRank
  rank2 <- drop (fromEnum rank1) listRank
  suit1 <- listEnum
  suit2 <-
    if rank1 == rank2
      then drop (fromEnum suit1) listSuit
      else listSuit
  guard (not $ rank1 == rank2 && suit1 == suit2)
  return $ newCombo [Card rank1 suit1, Card rank2 suit2]

allShapedHands :: [ShapedHand]
allShapedHands = reverse $ do
    rank1 <- listRank
    rank2 <- listRank
    return $ newShapedHand (rank1, rank2) $ case compare rank1 rank2 of
        GT -> Suited
        EQ -> Pair
        LT -> Offsuit

listEnum :: (Enum a) => [a]
listEnum = enumFrom (toEnum 0)

newDeck :: Deck
newDeck = Deck $ [Card val su | val <- [Two .. Ace], su <- [Club .. Spade]]

newCombo :: [Card] -> Holding
newCombo [card1, card2] | card1 == card2 = error $ "Cards in combo must be different" ++ show card1 ++ show card2
                          | otherwise      = if card1 > card2
                                               then Holdem card1 card2
                                               else Holdem card2 card1
newCombo _ = error "incorrect number of cards passed to newCombo"

newShapedHand :: (Rank, Rank) -> Shape -> ShapedHand
newShapedHand (rank1, rank2) shape
    | rank1 == rank2 && shape /= Pair = error $ "Pair must be shaped pair, not " ++ show shape
    | rank1 /= rank2 && shape == Pair = error "Non-pair cannot have shape Pair"
    | otherwise      = if rank1 > rank2
                            then ShapedHand (rank1, rank2) shape
                            else ShapedHand (rank2, rank1) shape

-- -- this kinda feels like a mess but might be totally correct?
-- findPositionHolding :: Hand -> Position -> Holding
-- findPositionHolding hand pos =
--   case M.lookup pos (_handSeatMap hand) of
--     Nothing -> error "player given card but no seat"
--     Just posSeat -> case M.lookup posSeat (_handPlayerMap hand) of
--       Nothing -> error "player given position but no such player exists"
--       Just player -> case _playerHolding player of
--         Nothing -> error "player given position but no holding"
--         Just holding -> holding

-- prettyShow :: Hand -> String
-- prettyShow hand = unlines
--     [ show . _handNetwork $ hand
--     , show . _handStakes $ hand
--     , indent <$> unlines $ show <$> _handActions hand
--     ]

inIndex :: (IsBetSize b) => ActionIx BetSize -> BetAction b -> Bool
inIndex AnyIx _ = True
inIndex CheckIx Check = True
inIndex (RaiseIx range) (Raise from to) = (to - from) `within` range
inIndex (RaiseOrAllInIx range) (Raise from to) = within (to - from) range
inIndex (RaiseOrAllInIx range) (AllIn bet) = within bet range
inIndex (AllInIx range) (AllIn allIn) = within allIn range
inIndex (BetIx range) (Bet bet) = within bet range
inIndex CallIx (Call _) = True
inIndex FoldIx Fold = True
inIndex _ _ = False



-- inRangeAny :: IsBetSize a => IxRange a -> a -> Bool
-- inRangeAny (BetweenRn low up) bet = low `below` bet && bet `below` up
-- inRangeAny (ExactlyRn amount) bet = bet == amount
-- inRangeAny (AboveRn low) bet = low `leq` bet
-- inRangeAny (BelowRn up) bet = bet `leq` up
-- inRangeAny AnyRn _ = True
