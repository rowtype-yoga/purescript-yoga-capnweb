module Yoga.Capnweb
  ( RpcSession
  , RpcStub
  , connect
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
  ) where

import Prelude

import Control.Promise (Promise, toAff)
import Data.Function.Uncurried (Fn2, Fn3, Fn4, runFn2, runFn3, runFn4)
import Effect (Effect)
import Effect.Aff (Aff, bracket)
import Effect.Class (liftEffect)
import Foreign (Foreign)
import Unsafe.Coerce (unsafeCoerce)

foreign import data RpcSession :: Type

foreign import data RpcStub :: Type

-- Session lifecycle

foreign import connectImpl :: String -> Effect RpcSession

connect :: String -> Effect RpcSession
connect = connectImpl

foreign import disposeImpl :: RpcSession -> Effect Unit

dispose :: RpcSession -> Effect Unit
dispose = disposeImpl

withSession :: forall a. String -> (RpcSession -> Aff a) -> Aff a
withSession url = bracket (liftEffect (connect url)) (liftEffect <<< dispose)

-- Stub lifecycle

foreign import dupImpl :: RpcStub -> Effect RpcStub

dup :: RpcStub -> Effect RpcStub
dup = dupImpl

foreign import disposeStubImpl :: RpcStub -> Effect Unit

disposeStub :: RpcStub -> Effect Unit
disposeStub = disposeStubImpl

-- RPC calls

foreign import callImpl :: Fn3 RpcSession String (Array Foreign) (Promise Foreign)

call :: RpcSession -> String -> Array Foreign -> Aff Foreign
call session method args = runFn3 callImpl session method args # toAff

foreign import call0Impl :: Fn2 RpcSession String (Promise Foreign)

call0 :: forall a. RpcSession -> String -> Aff a
call0 session method = runFn2 call0Impl session method # toAff # map unsafeCoerce

foreign import call1Impl :: Fn3 RpcSession String Foreign (Promise Foreign)

call1 :: forall a b. RpcSession -> String -> a -> Aff b
call1 session method a =
  runFn3 call1Impl session method (unsafeCoerce a) # toAff # map unsafeCoerce

foreign import call2Impl :: Fn4 RpcSession String Foreign Foreign (Promise Foreign)

call2 :: forall a b c. RpcSession -> String -> a -> b -> Aff c
call2 session method a b =
  runFn4 call2Impl session method (unsafeCoerce a) (unsafeCoerce b) # toAff # map unsafeCoerce

-- Callback passing (for server-to-client push)

foreign import callWithCallbackImpl :: Fn3 RpcSession String Foreign (Promise Foreign)

callWithCallback :: forall a. RpcSession -> String -> (a -> Effect Unit) -> Aff Unit
callWithCallback session method callback = do
  let jsCb = unsafeCoerce callback
  _ <- runFn3 callWithCallbackImpl session method jsCb # toAff
  pure unit

-- Diagnostics

type SessionStats = { imports :: Int, exports :: Int }

foreign import getStatsImpl :: RpcSession -> Effect SessionStats

getStats :: RpcSession -> Effect SessionStats
getStats = getStatsImpl
