module Yoga.Capnweb.Server
  ( RpcTarget
  , mkRpcTarget
  , handleWebSocket
  ) where

import Prelude

import Data.Function.Uncurried (Fn2, runFn2)
import Effect (Effect)
import Foreign (Foreign)
import Unsafe.Coerce (unsafeCoerce)

foreign import data RpcTarget :: Type

foreign import mkRpcTargetImpl :: Foreign -> Effect RpcTarget

mkRpcTarget :: forall r. Record r -> Effect RpcTarget
mkRpcTarget record = mkRpcTargetImpl (unsafeCoerce record)

foreign import handleWebSocketImpl :: Fn2 Foreign RpcTarget (Effect Unit)

handleWebSocket :: Foreign -> RpcTarget -> Effect Unit
handleWebSocket ws target = runFn2 handleWebSocketImpl ws target
