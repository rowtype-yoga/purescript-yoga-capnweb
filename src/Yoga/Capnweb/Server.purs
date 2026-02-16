module Yoga.Capnweb.Server
  ( RpcTarget
  , mkRpcTarget
  , mkDisposableRpcTarget
  , handleWebSocket
  ) where

import Prelude

import Data.Function.Uncurried (Fn2, runFn2)
import Effect (Effect)
import Foreign (Foreign)
import Unsafe.Coerce (unsafeCoerce)
import Yoga.Capnweb.Bun (BunWsBridge)

foreign import data RpcTarget :: Type

foreign import mkRpcTargetImpl :: Foreign -> Effect RpcTarget

mkRpcTarget :: forall r. Record r -> Effect RpcTarget
mkRpcTarget record = mkRpcTargetImpl (unsafeCoerce record)

foreign import mkDisposableRpcTargetImpl :: Fn2 Foreign (Effect Unit) (Effect RpcTarget)

mkDisposableRpcTarget :: forall r. Record r -> Effect Unit -> Effect RpcTarget
mkDisposableRpcTarget record onDispose =
  runFn2 mkDisposableRpcTargetImpl (unsafeCoerce record) onDispose

foreign import handleWebSocketImpl :: Fn2 BunWsBridge RpcTarget (Effect Unit)

handleWebSocket :: BunWsBridge -> RpcTarget -> Effect Unit
handleWebSocket ws target = runFn2 handleWebSocketImpl ws target
