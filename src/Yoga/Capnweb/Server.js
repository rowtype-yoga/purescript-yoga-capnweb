import { RpcTarget as RpcTargetClass, newWebSocketRpcSession } from "capnweb";

function makeTarget(record) {
  const proto = Object.create(RpcTargetClass.prototype);
  for (const [key, val] of Object.entries(record)) {
    proto[key] = val;
  }
  function Target() { RpcTargetClass.call(this); }
  Target.prototype = proto;
  Target.prototype.constructor = Target;
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
