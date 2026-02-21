-- | Capnweb RPC client bindings
module Yoga.Capnweb
  ( RpcConnection
  , RpcStub
  , Subscription
  , CallbackHandle
  , connect
  , connectPair
  , dispose
  , disposeGracefully
  , dup
  , disposeStub
  , withSession
  , call
  , call0
  , call1
  , call2
  , callWithCallback
  , callWithCancellableCallback
  , cancelCallback
  , awaitCallback
  , subscribe
  , SessionStats
  , getStats
  , drain
  ) where

import Prelude

import Control.Promise (Promise, toAff)
import Data.Function.Uncurried (Fn2, Fn3, Fn4, runFn2, runFn3, runFn4)
import Effect (Effect)
import Effect.Aff (Aff, bracket, killFiber)
import Effect.Aff as Aff
import Control.Monad.ST.Global (toEffect)
import Effect.Class (liftEffect)
import Effect.Exception (error)
import Foreign (Foreign)
import FRP.Event (Event)
import FRP.Event as Event
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

disposeGracefully :: RpcConnection -> Aff Unit
disposeGracefully conn = do
  drain conn
  dispose conn # liftEffect

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

foreign import data CallbackHandle :: Type

foreign import callWithCallbackImpl :: Fn3 RpcConnection String Foreign CallbackHandle

foreign import cancelCallbackImpl :: CallbackHandle -> Effect Unit

foreign import awaitCallbackImpl :: CallbackHandle -> Promise Unit

callWithCancellableCallback :: forall a. RpcConnection -> String -> (a -> Effect Unit) -> Effect CallbackHandle
callWithCancellableCallback conn method callback = do
  let jsCb = unsafeCoerce callback
  pure $ runFn3 callWithCallbackImpl conn method jsCb

cancelCallback :: CallbackHandle -> Effect Unit
cancelCallback = cancelCallbackImpl

awaitCallback :: CallbackHandle -> Aff Unit
awaitCallback handle = awaitCallbackImpl handle # toAff # void

callWithCallback :: forall a. RpcConnection -> String -> (a -> Effect Unit) -> Aff Unit
callWithCallback conn method callback = do
  handle <- liftEffect $ callWithCancellableCallback conn method callback
  awaitCallback handle

-- Subscriptions (push-based via Event)

type Subscription a = { event :: Event a, unsubscribe :: Effect Unit }

subscribe :: forall a. String -> RpcConnection -> Effect (Subscription a)
subscribe method conn = do
  { event, push } <- Event.create # toEffect
  let cb = push <<< unsafeCoerce
  fiber <- Aff.launchAff $ callWithCallback conn method cb
  pure { event, unsubscribe: Aff.launchAff_ $ killFiber (error "unsubscribed") fiber }

-- Diagnostics

type SessionStats = { imports :: Int, exports :: Int }

foreign import getStatsImpl :: RpcConnection -> Effect SessionStats

getStats :: RpcConnection -> Effect SessionStats
getStats = getStatsImpl

foreign import drainImpl :: RpcConnection -> Promise Unit

drain :: RpcConnection -> Aff Unit
drain conn = drainImpl conn # toAff
