import { measure } from "./flex.mjs";

export function dom() {
    let observers = [],
        pendingMutations = false;

    class Node {
        constructor(nodeType, nodeName) {
            this.nodeType = nodeType;
            this.nodeName = nodeName;
            this.childNodes = [];
        }
        appendChild(child) {
            child.remove();
            child.parentNode = this;
            this.childNodes.push(child);
            if (this.children && child.nodeType === 1) this.children.push(child);


            mutation(this, "childList", {
                addedNodes: child,
                previousSibling: this.childNodes[this.childNodes.length - 2],
            });
        }
        insertBefore(child, ref) {
            child.remove();
            let i = splice(this.childNodes, ref, child),
                ref2;
            if (!ref) {
                this.appendChild(child);
            } else {
                if (~i && child.nodeType === 1) {
                    while (
                        (i < this.childNodes.length &&
                            (ref2 = this.childNodes[i]).nodeType !== 1) ||
                        ref === child
                    )
                        i++;
                    if (ref2) splice(this.children, ref, child);
                }


                mutation(this, "childList", { addedNodes: [child], nextSibling: ref });
            }
        }
        replaceChild(child, ref) {
            if (ref.parentNode === this) {
                this.insertBefore(child, ref);
                ref.remove();
            }
        }
        removeChild(child) {
            let i = splice(this.childNodes, child);
            if (child.nodeType === 1) splice(this.children, child);


            mutation(this, "childList", {
                removedNodes: [child],
                previousSibling: this.childNodes[i - 1],
                nextSibling: this.childNodes[i],
            });
        }
        remove() {
            if (this.parentNode) this.parentNode.removeChild(this);
        }
    }

    class Text extends Node {
        constructor(text) {
            super(3, "#text"); // TEXT_NODE
            // this.textContent = this.nodeValue = text;
            this.data = text;
        }
        get textContent() {
            return this.data;
        }
        set textContent(value) {
            let oldValue = this.data;
            this.data = value;


            mutation(this, "characterData", { oldValue, value, rect: this.rect });
        }
        get nodeValue() {
            return this.data;
        }
        set nodeValue(value) {
            this.textContent = value;
        }
    }

    class Element extends Node {
        constructor(nodeType, nodeName) {
            super(nodeType || 1, nodeName); // ELEMENT_NODE
            this.attributes = [];
            this.children = [];
            this.__handlers = {};
            this.style = {};
            Object.defineProperty(this, "className", {
                set: (val) => {
                    this.setAttribute("class", val);
                },
                get: () => this.getAttribute("style"),
            });
            Object.defineProperty(this.style, "cssText", {
                set: (val) => {
                    this.setAttribute("style", val);
                },
                get: () => this.getAttribute("style"),
            });
        }

        setAttribute(key, value) {
            this.setAttributeNS(null, key, value);
        }
        getAttribute(key) {
            return this.getAttributeNS(null, key);
        }
        removeAttribute(key) {
            this.removeAttributeNS(null, key);
        }

        setAttributeNS(ns, name, value) {
            let attr = findWhere(this.attributes, createAttributeFilter(ns, name)),
                oldValue = attr && attr.value;
            if (!attr) this.attributes.push((attr = { ns, name }));
            attr.value = String(value);


            mutation(this, "attributes", {
                attributeName: name,
                attributeNamespace: ns,
                oldValue,
            });
        }
        getAttributeNS(ns, name) {
            let attr = findWhere(this.attributes, createAttributeFilter(ns, name));
            return attr && attr.value;
        }
        removeAttributeNS(ns, name) {
            splice(this.attributes, createAttributeFilter(ns, name));
            mutation(this, "attributes", {
                attributeName: name,
                attributeNamespace: ns,
                oldValue: this.getAttributeNS(ns, name),
            });
        }

        addEventListener(type, handler) {
            (
                this.__handlers[toLower(type)] || (this.__handlers[toLower(type)] = [])
            ).push(handler);
        }
        removeEventListener(type, handler) {
            splice(this.__handlers[toLower(type)], handler, 0, true);
        }
        dispatchEvent(event) {
            let t = (event.currentTarget = this),
                c = event.cancelable,
                l,
                i;
            do {
                l = t.__handlers && t.__handlers[toLower(event.type)];
                if (l)
                    for (i = l.length; i--;) {
                        if ((l[i].call(t, event) === false || event._end) && c) break;
                    }
            } while (
                event.bubbles &&
                !(c && event._stop) &&
                (event.target = t = t.parentNode)
            );
            return !event.defaultPrevented;
        }
    }

    class SVGElement extends Element { }

    class Document extends Element {
        constructor() {
            super(9, "#document"); // DOCUMENT_NODE
        }
    }

    class Event {
        constructor(type, opts) {
            this.type = type;
            this.bubbles = !!opts.bubbles;
            this.cancelable = !!opts.cancelable;
        }
        stopPropagation() {
            this._stop = true;
        }
        stopImmediatePropagation() {
            this._end = this._stop = true;
        }
        preventDefault() {
            this.defaultPrevented = true;
        }
    }

    function mutation(target, type, record) {
        record.target = target.__id; // 这里暂时只保留 id
        record.type = type;

        const cxy = [0, 0, 0, 0, 0]
        const cwh = [600, 600, 0, 0, 0]
        measure(target, 0, cxy, cwh)
        // layout(element, 1, 0, cxy, cwh, draw);

        for (let i = observers.length; i--;) {
            let ob = observers[i],
                match = target === ob._target;
            if (!match && ob._options.subtree) {
                do {
                    if ((match = target === ob._target)) break;
                } while ((target = target.parentNode));
            }
            if (match) {
                ob._records.push(record);
                if (!pendingMutations) {
                    pendingMutations = true;
                    setTimeout(flushMutations);
                }
            }
        }
    }

    function flushMutations() {
        pendingMutations = false;
        for (let i = observers.length; i--;) {
            let ob = observers[i];
            if (ob._records.length) {
                ob.callback(ob.takeRecords());
            }
        }
    }

    class MutationObserver {
        constructor(callback) {
            this.callback = callback;
            this._records = [];
        }
        observe(target, options) {
            this.disconnect();
            this._target = target;
            this._options = options || {};
            observers.push(this);
        }
        disconnect() {
            this._target = null;
            splice(observers, this);
        }
        takeRecords() {
            return this._records.splice(0, this._records.length);
        }
    }

    function createElement(type) {
        return new Element(null, String(type).toUpperCase());
    }

    function createElementNS(ns, type) {
        let element = createElement(type);
        element.namespace = ns;
        return element;
    }

    function createTextNode(text) {
        return new Text(text);
    }

    function createDocument() {
        let document = new Document();
        assign(
            document,
            (document.defaultView = {
                document,
                MutationObserver,
                Document,
                Node,
                Text,
                Element,
                SVGElement,
                Event,
            })
        );
        assign(document, {
            documentElement: document,
            createElement,
            createElementNS,
            createTextNode,
        });
        document.appendChild((document.body = createElement("body")));
        return document;
    }

    return createDocument();
}

function assign(obj, props) {
    for (let i in props) obj[i] = props[i];
}

function toLower(str) {
    return String(str).toLowerCase();
}

function createAttributeFilter(ns, name) {
    return (o) => o.ns === ns && toLower(o.name) === toLower(name);
}

function splice(arr, item, add, byValueOnly) {
    let i = arr ? findWhere(arr, item, true, byValueOnly) : -1;
    if (~i) add ? arr.splice(i, 0, add) : arr.splice(i, 1);
    return i;
}

function findWhere(arr, fn, returnIndex, byValueOnly) {
    let i = arr.length;
    while (i--)
        if (typeof fn === "function" && !byValueOnly ? fn(arr[i]) : arr[i] === fn)
            break;
    return returnIndex ? i : arr[i];
}
