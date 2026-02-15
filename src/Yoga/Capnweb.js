import { newWebSocketRpcSession } from "capnweb";

const toPromise = (rpcPromise) => new Promise((resolve, reject) => {
  rpcPromise.then(resolve, reject);
});

export const connectImpl = (url) => () => newWebSocketRpcSession(url);

export const callImpl = (session, method, args) => toPromise(session[method](...args));

export const disposeImpl = (session) => () => {
  if (session[Symbol.dispose]) session[Symbol.dispose]();
};
