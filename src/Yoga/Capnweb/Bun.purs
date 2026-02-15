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
import Foreign (Foreign)

foreign import data BunWsBridge :: Type

foreign import toBrowserWebSocketImpl :: Foreign -> Effect BunWsBridge

toBrowserWebSocket :: Foreign -> Effect BunWsBridge
toBrowserWebSocket = toBrowserWebSocketImpl

foreign import dispatchMessageImpl :: Fn2 BunWsBridge Foreign (Effect Unit)

dispatchMessage :: BunWsBridge -> Foreign -> Effect Unit
dispatchMessage bridge msg = runFn2 dispatchMessageImpl bridge msg

foreign import dispatchCloseImpl :: Fn3 BunWsBridge Int String (Effect Unit)

dispatchClose :: BunWsBridge -> Int -> String -> Effect Unit
dispatchClose bridge code reason = runFn3 dispatchCloseImpl bridge code reason

foreign import dispatchErrorImpl :: Fn2 BunWsBridge Foreign (Effect Unit)

dispatchError :: BunWsBridge -> Foreign -> Effect Unit
dispatchError bridge err = runFn2 dispatchErrorImpl bridge err
