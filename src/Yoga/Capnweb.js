import { RpcSession as RpcSessionClass } from "capnweb";

const toPromise = (rpcPromise) => new Promise((resolve, reject) => {
  rpcPromise.then(resolve, reject);
});

class WebSocketTransport {
  #ws; #sendQueue; #receiveQueue = []; #resolver = null; #rejecter = null; #error = null;
  constructor(ws) {
    this.#ws = ws;
    if (ws.readyState === WebSocket.CONNECTING) {
      this.#sendQueue = [];
      ws.addEventListener("open", () => {
        for (const msg of this.#sendQueue) ws.send(msg);
        this.#sendQueue = null;
      });
    }
    ws.addEventListener("message", (e) => {
      if (this.#error) return;
      if (typeof e.data !== "string") { this.#receivedError(new TypeError("Non-string message")); return; }
      if (this.#resolver) { const r = this.#resolver; this.#resolver = null; this.#rejecter = null; r(e.data); }
      else this.#receiveQueue.push(e.data);
    });
    ws.addEventListener("close", (e) => this.#receivedError(new Error(`Peer closed WebSocket: ${e.code}`)));
    ws.addEventListener("error", () => this.#receivedError(new Error("WebSocket connection failed")));
  }
  send(msg) {
    if (this.#sendQueue) this.#sendQueue.push(msg);
    else this.#ws.send(msg);
    return Promise.resolve();
  }
  receive() {
    if (this.#receiveQueue.length > 0) return Promise.resolve(this.#receiveQueue.shift());
    if (this.#error) return Promise.reject(this.#error);
    return new Promise((resolve, reject) => { this.#resolver = resolve; this.#rejecter = reject; });
  }
  abort() {
    if (this.#ws.readyState === WebSocket.OPEN || this.#ws.readyState === WebSocket.CONNECTING) {
      this.#ws.close(3000, "abort");
    }
  }
  close() {
    if (this.#ws.readyState === WebSocket.OPEN || this.#ws.readyState === WebSocket.CONNECTING) {
      this.#ws.close();
    }
  }
  #receivedError(err) {
    if (this.#error) return;
    this.#error = err;
    if (this.#rejecter) { const r = this.#rejecter; this.#resolver = null; this.#rejecter = null; r(err); }
  }
}

class MessagePortTransport {
  #port; #queue = []; #waiting = null;
  constructor(port) {
    this.#port = port;
    port.start();
    port.addEventListener("message", (e) => {
      if (this.#waiting) { const w = this.#waiting; this.#waiting = null; w(e.data); }
      else this.#queue.push(e.data);
    });
  }
  send(msg) { this.#port.postMessage(msg); return Promise.resolve(); }
  receive() {
    if (this.#queue.length > 0) return Promise.resolve(this.#queue.shift());
    return new Promise(r => { this.#waiting = r; });
  }
  abort() { this.#port.close(); }
  close() { this.#port.close(); }
}

export const connectImpl = (url) => () => {
  const ws = new WebSocket(url);
  const transport = new WebSocketTransport(ws);
  const session = new RpcSessionClass(transport);
  const stub = session.getRemoteMain();
  session.drain().catch(() => {});
  return { stub, close: () => transport.close(), session };
};

export const connectPairImpl = (localMain) => () => {
  const { port1, port2 } = new MessageChannel();
  const serverTransport = new MessagePortTransport(port1);
  const serverSession = new RpcSessionClass(serverTransport, localMain);
  const clientTransport = new MessagePortTransport(port2);
  const clientSession = new RpcSessionClass(clientTransport);
  const stub = clientSession.getRemoteMain();
  serverSession.drain().catch(() => {});
  clientSession.drain().catch(() => {});
  return {
    stub,
    close: () => { serverTransport.close(); clientTransport.close(); },
    session: clientSession,
  };
};

export const disposeImpl = (conn) => () => conn.close();

export const dupImpl = (stub) => () => stub.dup();

export const disposeStubImpl = (stub) => () => {
  if (stub[Symbol.dispose]) stub[Symbol.dispose]();
};

export const callImpl = (conn, method, args) => toPromise(conn.stub[method](...args));
export const call0Impl = (conn, method) => toPromise(conn.stub[method]());
export const call1Impl = (conn, method, a) => toPromise(conn.stub[method](a));
export const call2Impl = (conn, method, a, b) => toPromise(conn.stub[method](a, b));

export const callWithCallbackImpl = (conn, method, callback) => {
  const wrappedCb = (value) => {
    if (wrappedCb._cancelled) return Promise.reject(new Error("cancelled"));
    return callback(value)();
  };
  wrappedCb._cancelled = false;
  const promise = toPromise(conn.stub[method](wrappedCb));
  return { promise, wrappedCb };
};

export const cancelCallbackImpl = (handle) => () => {
  handle.wrappedCb._cancelled = true;
};

export const awaitCallbackImpl = (handle) => handle.promise;

export const getStatsImpl = (conn) => () => conn.session.getStats();

export const drainImpl = (conn) => conn.session.drain();
