module Test.Yoga.CapnwebSpec where

import Prelude

import Control.Promise (Promise, toAff)
import Effect (Effect)
import Effect.Class (liftEffect)
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual)
import Yoga.Capnweb (connectPair, call1, call2, getStats, dispose, disposeStub)
import Yoga.Capnweb.Server (RpcTarget)
import Unsafe.Coerce (unsafeCoerce)

foreign import mkTestTarget :: Effect RpcTarget

foreign import delayMs :: Int -> Promise Unit

spec :: Spec Unit
spec = describe "Yoga.Capnweb" do
  describe "basic RPC" do
    it "call1 round-trips a value" do
      target <- liftEffect mkTestTarget
      conn <- liftEffect $ connectPair target
      result :: String <- call1 conn "ping" "hello"
      result `shouldEqual` "pong: hello"
      liftEffect $ dispose conn

    it "call2 passes two arguments" do
      target <- liftEffect mkTestTarget
      conn <- liftEffect $ connectPair target
      result :: Int <- call2 conn "add" 3 4
      result `shouldEqual` 7
      liftEffect $ dispose conn

  describe "stub lifecycle" do
    it "disposing a returned stub decreases imports" do
      target <- liftEffect mkTestTarget
      conn <- liftEffect $ connectPair target
      before <- liftEffect $ getStats conn
      stub <- call1 conn "makeCounter" 10
      afterCreate <- liftEffect $ getStats conn
      afterCreate.imports `shouldEqual` (before.imports + 1)
      liftEffect $ disposeStub (unsafeCoerce stub)
      delayMs 50 # toAff
      afterDispose <- liftEffect $ getStats conn
      afterDispose.imports `shouldEqual` before.imports
      liftEffect $ dispose conn

    it "undisposed stubs leak" do
      target <- liftEffect mkTestTarget
      conn <- liftEffect $ connectPair target
      before <- liftEffect $ getStats conn
      _ <- call1 conn "makeCounter" 1
      _ <- call1 conn "makeCounter" 2
      _ <- call1 conn "makeCounter" 3
      delayMs 50 # toAff
      after <- liftEffect $ getStats conn
      after.imports `shouldEqual` (before.imports + 3)
      liftEffect $ dispose conn
