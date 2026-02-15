import { newWebSocketRpcSession } from "capnweb";

export const connectImpl = (url) => () => newWebSocketRpcSession(url);

export const callImpl = (session, method, args) => Promise.resolve(session[method](...args));

export const disposeImpl = (session) => () => {
  if (session[Symbol.dispose]) session[Symbol.dispose]();
};
