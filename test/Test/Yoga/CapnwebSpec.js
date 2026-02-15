import { RpcTarget } from "capnweb";

class Counter extends RpcTarget {
  #n;
  constructor(n) { super(); this.#n = n; }
  get() { return this.#n; }
}

class TestApi extends RpcTarget {
  ping(msg) { return "pong: " + msg; }
  makeCounter(n) { return new Counter(n); }
  add(a, b) { return a + b; }
}

export const mkTestTarget = () => new TestApi();

export const delayMs = (ms) => new Promise(r => setTimeout(r, ms));
