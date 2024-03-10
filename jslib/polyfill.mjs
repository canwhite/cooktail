import { h } from 'fre'

import { dom } from "./dom.mjs";
const pendingQueue = [];

let COUNTER = 0;

const TO_SANITIZE = [
  "addedNodes",
  "removedNodes",
  "nextSibling",
  "previousSibling",
  "target",
];

const PROP_BLACKLIST = [
  "children",
  "parentNode",
  "__handlers",
  "_component",
  "_componentConstructor",
];

const NODES = new Map();

function getNode(node) {
  let id;
  if (node && typeof node === "object") id = node.__id;
  if (typeof node === "string") id = node;
  if (!id) return null;
  if (node.nodeName === "BODY") return document.body;
  return NODES.get(id);
}

function sanitize(obj) {
  if (!obj || typeof obj !== "object") return obj;

  if (Array.isArray(obj)) return obj.map(sanitize);

  if (obj instanceof document.defaultView.Node) {
    let id = obj.__id;
    if (!id) {
      id = obj.__id = String(++COUNTER);
    }
    NODES.set(id, obj);
  }

  let out = {};
  for (let i in obj) {
    if (obj.hasOwnProperty(i) && PROP_BLACKLIST.indexOf(i) < 0) {
      out[i] = obj[i];
    }
  }
  if (out.childNodes && out.childNodes.length) {
    out.childNodes = sanitize(out.childNodes);
  }
  return out;
}

function polyfill() {
  this.document = dom();
  this.setTimeout = (cb) => cb();
  this.getRenderQueue = function () {
    const direct = pendingQueue.shift();
    if (direct) {
      if (direct.type === "characterData") {
        const ret = JSON.stringify({
          type: "#text",
          data: direct.value,
          x: direct.rect[0].toString(),
          y: direct.rect[1].toString(),
          h: direct.rect[2].toString(),
          w: direct.rect[3].toString(),
        });
        return ret
      }
      if (direct.type == "childList") {
        const ret = JSON.stringify({
          type: direct.addedNodes.nodeName,
          data: direct.addedNodes.data || "",
          x: direct.addedNodes.rect[0].toString(),
          y: direct.addedNodes.rect[1].toString(),
          h: direct.addedNodes.rect[2].toString(),
          w: direct.addedNodes.rect[3].toString(),
        });
        return ret;
      }
    } else {
      return null
    }
  };
  this.bubblingClick = (x, y) => {
    bubbling(x, y, this.document.body, 'click')
  }
  this.performance = Date;
  for (let i in document.defaultView) {
    if (document.defaultView.hasOwnProperty(i)) {
      this[i] = document.defaultView[i];
    }
  }

  new MutationObserver((mutations) => {
    for (let i = mutations.length; i--;) {
      let mutation = mutations[i];
      for (let j = TO_SANITIZE.length; j--;) {
        let prop = TO_SANITIZE[j];
        mutation[prop] = sanitize(mutation[prop]);
      }
      pendingQueue.push(mutation);
    }
  }).observe(document, { subtree: true });
}

polyfill()

function bubbling(fx, fy, node, type) {

  if (node.nodeName !== 'BODY') {
    const [x, y, w, h] = node.rect
    if ((fx > x && fx < x + w) && (fy > y && fy < y + h)) {
      node.dispatchEvent({ type })
    }
  }


  node.childNodes.forEach(item => bubbling(fx, fy, item, type))
}

export { h }