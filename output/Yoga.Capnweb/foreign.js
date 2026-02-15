import { newWebSocketRpcSession } from "capnweb";

const toPromise = (rpcPromise) => new Promise((resolve, reject) => {
  rpcPromise.then(resolve, reject);
});

export const connectImpl = (url) => () => newWebSocketRpcSession(url);

export const disposeImpl = (session) => () => {
  if (session[Symbol.dispose]) session[Symbol.dispose]();
};

export const dupImpl = (stub) => () => stub.dup();

export const disposeStubImpl = (stub) => () => {
  if (stub[Symbol.dispose]) stub[Symbol.dispose]();
};

export const callImpl = (session, method, args) => toPromise(session[method](...args));

export const call0Impl = (session, method) => toPromise(session[method]());

export const call1Impl = (session, method, a) => toPromise(session[method](a));

export const call2Impl = (session, method, a, b) => toPromise(session[method](a, b));

export const callWithCallbackImpl = (session, method, callback) =>
  toPromise(session[method](callback));

export const getStatsImpl = (session) => () => session.getStats();
