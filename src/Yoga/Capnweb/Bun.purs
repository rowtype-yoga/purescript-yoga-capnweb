module Yoga.Capnweb.Bun
  ( BunWsBridge
  , toBrowserWebSocket
  , dispatchMessage
  , dispatchClose
  , dispatchError
  ) where

import Prelude

import Data.Function.Uncurried (Fn2, Fn3, runFn2, runFn3)
import Effect (Effect)

foreign import data BunWsBridge :: Type

foreign import toBrowserWebSocketImpl :: forall ws. ws -> Effect BunWsBridge

toBrowserWebSocket :: forall ws. ws -> Effect BunWsBridge
toBrowserWebSocket = toBrowserWebSocketImpl

foreign import dispatchMessageImpl :: forall a. Fn2 BunWsBridge a (Effect Unit)

dispatchMessage :: forall a. BunWsBridge -> a -> Effect Unit
dispatchMessage bridge msg = runFn2 dispatchMessageImpl bridge msg

foreign import dispatchCloseImpl :: Fn3 BunWsBridge Int String (Effect Unit)

dispatchClose :: BunWsBridge -> Int -> String -> Effect Unit
dispatchClose bridge code reason = runFn3 dispatchCloseImpl bridge code reason

foreign import dispatchErrorImpl :: forall a. Fn2 BunWsBridge a (Effect Unit)

dispatchError :: forall a. BunWsBridge -> a -> Effect Unit
dispatchError bridge err = runFn2 dispatchErrorImpl bridge err
