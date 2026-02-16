import { RpcTarget as RpcTargetClass, newWebSocketRpcSession } from "capnweb";

function makeTarget(record) {
  class Target extends RpcTargetClass {
    constructor() {
      super();
    }
  }
  for (const [key, val] of Object.entries(record)) {
    Target.prototype[key] = val;
  }
  return new Target();
}

export const mkRpcTargetImpl = (record) => () => {
  return makeTarget(record);
};

export const mkDisposableRpcTargetImpl = (record, onDispose) => () => {
  const target = makeTarget(record);
  target[Symbol.dispose] = () => onDispose();
  return target;
};

export const handleWebSocketImpl = (ws, target) => () => {
  newWebSocketRpcSession(ws, target);
};
