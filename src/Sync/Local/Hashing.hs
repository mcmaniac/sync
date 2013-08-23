{-# LANGUAGE ConstraintKinds #-}

module Sync.Local.Hashing where

import           Control.Monad.Trans
import qualified Data.ByteString.Lazy         as BL
import           Data.Maybe
import           System.IO

import           Sync.Hashing
import           Sync.Types
import           Sync.IO
import           Sync.Protocol

-- | Get weak (\"rolling\") hashes for each block and send them over the stream
sendRollingHashes
  :: MonadResourceBase m
  => FilePath
  -> BlockSize
  -> NetApp m ()
sendRollingHashes fp s = do
  bs <- liftIO $ BL.readFile fp
  sendList $ toRollingBlocks s bs

-- | Compare local file with incoming hashes, send out unmatched file
-- locations and return matched file locations as lookup list
getMatchingMD5s
  :: MonadResourceBase m
  => FilePath
  -> NetApp m [HashingMatch MD5]
getMatchingMD5s fp = do
  h       <- withBinaryFile' fp ReadMode
  md5s    <- receiveList $ toMsg'
  matches <- mapM (compareMD5 h) md5s
  return $ catMaybes matches
