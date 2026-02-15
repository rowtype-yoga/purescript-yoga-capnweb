module Yoga.Capnweb
  ( RpcSession
  , connect
  , call
  , dispose
  ) where

import Prelude

import Control.Promise (Promise, toAff)
import Data.Function.Uncurried (Fn3, runFn3)
import Effect (Effect)
import Effect.Aff (Aff)
import Foreign (Foreign)

foreign import data RpcSession :: Type

foreign import connectImpl :: String -> Effect RpcSession

connect :: String -> Effect RpcSession
connect = connectImpl

foreign import callImpl :: Fn3 RpcSession String (Array Foreign) (Promise Foreign)

call :: RpcSession -> String -> Array Foreign -> Aff Foreign
call session method args = runFn3 callImpl session method args # toAff

foreign import disposeImpl :: RpcSession -> Effect Unit

dispose :: RpcSession -> Effect Unit
dispose = disposeImpl
