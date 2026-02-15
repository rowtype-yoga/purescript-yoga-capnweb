module Yoga.Capnweb
  ( RpcConnection
  , RpcStub
  , connect
  , connectPair
  , dispose
  , dup
  , disposeStub
  , withSession
  , call
  , call0
  , call1
  , call2
  , callWithCallback
  , SessionStats
  , getStats
  , drain
  ) where

import Prelude

import Control.Promise (Promise, toAff)
import Data.Function.Uncurried (Fn2, Fn3, Fn4, runFn2, runFn3, runFn4)
import Effect (Effect)
import Effect.Aff (Aff, bracket)
import Effect.Class (liftEffect)
import Foreign (Foreign)
import Unsafe.Coerce (unsafeCoerce)
import Yoga.Capnweb.Server (RpcTarget)

foreign import data RpcConnection :: Type

foreign import data RpcStub :: Type

-- Session lifecycle

foreign import connectImpl :: String -> Effect RpcConnection

connect :: String -> Effect RpcConnection
connect = connectImpl

foreign import connectPairImpl :: RpcTarget -> Effect RpcConnection

connectPair :: RpcTarget -> Effect RpcConnection
connectPair = connectPairImpl

foreign import disposeImpl :: RpcConnection -> Effect Unit

dispose :: RpcConnection -> Effect Unit
dispose = disposeImpl

withSession :: forall a. String -> (RpcConnection -> Aff a) -> Aff a
withSession url = bracket (liftEffect (connect url)) (liftEffect <<< dispose)

-- Stub lifecycle

foreign import dupImpl :: RpcStub -> Effect RpcStub

dup :: RpcStub -> Effect RpcStub
dup = dupImpl

foreign import disposeStubImpl :: RpcStub -> Effect Unit

disposeStub :: RpcStub -> Effect Unit
disposeStub = disposeStubImpl

-- RPC calls

foreign import callImpl :: Fn3 RpcConnection String (Array Foreign) (Promise Foreign)

call :: RpcConnection -> String -> Array Foreign -> Aff Foreign
call conn method args = runFn3 callImpl conn method args # toAff

foreign import call0Impl :: Fn2 RpcConnection String (Promise Foreign)

call0 :: forall a. RpcConnection -> String -> Aff a
call0 conn method = runFn2 call0Impl conn method # toAff # map unsafeCoerce

foreign import call1Impl :: Fn3 RpcConnection String Foreign (Promise Foreign)

call1 :: forall a b. RpcConnection -> String -> a -> Aff b
call1 conn method a =
  runFn3 call1Impl conn method (unsafeCoerce a) # toAff # map unsafeCoerce

foreign import call2Impl :: Fn4 RpcConnection String Foreign Foreign (Promise Foreign)

call2 :: forall a b c. RpcConnection -> String -> a -> b -> Aff c
call2 conn method a b =
  runFn4 call2Impl conn method (unsafeCoerce a) (unsafeCoerce b) # toAff # map unsafeCoerce

-- Callback passing (for server-to-client push)

foreign import callWithCallbackImpl :: Fn3 RpcConnection String Foreign (Promise Foreign)

callWithCallback :: forall a. RpcConnection -> String -> (a -> Effect Unit) -> Aff Unit
callWithCallback conn method callback = do
  let jsCb = unsafeCoerce callback
  _ <- runFn3 callWithCallbackImpl conn method jsCb # toAff
  pure unit

-- Diagnostics

type SessionStats = { imports :: Int, exports :: Int }

foreign import getStatsImpl :: RpcConnection -> Effect SessionStats

getStats :: RpcConnection -> Effect SessionStats
getStats = getStatsImpl

foreign import drainImpl :: RpcConnection -> Promise Unit

drain :: RpcConnection -> Aff Unit
drain conn = drainImpl conn # toAff
