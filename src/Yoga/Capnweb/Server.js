import { RpcTarget as RpcTargetClass, newWebSocketRpcSession } from "capnweb";

export const mkRpcTargetImpl = (record) => () => {
  const target = new RpcTargetClass();
  for (const [key, val] of Object.entries(record)) {
    target[key] = val;
  }
  return target;
};

export const handleWebSocketImpl = (ws, target) => () => {
  newWebSocketRpcSession(ws, target);
};
