// thats right! there's N/Sig too! Fuck me...

// plagerized from https://github.com/LuanRT/YouTube.js/blob/86f28b3c178648b8670fd398d59bd4c9c86e2b2e/src/core/Player.ts#L38


// libraries include
// https://github.com/meriyah/meriyah.git


// some of the same polyfills from botguard. hopefully these will be good here too!

var self = globalThis;
var window = globalThis;

if (typeof globalThis.TextEncoder === 'undefined') {
  globalThis.TextEncoder = function() { this.encoding = 'utf-8'; };
  globalThis.TextEncoder.prototype.encode = function(string) {
    var utf8 = unescape(encodeURIComponent(string));
    var arr = new Uint8Array(utf8.length);
    for (var i = 0; i < utf8.length; i++) { arr[i] = utf8.charCodeAt(i); }
    return arr;
  };
}

if (typeof globalThis.TextDecoder === 'undefined') {
  globalThis.TextDecoder = function() { this.encoding = 'utf-8'; };
  globalThis.TextDecoder.prototype.decode = function(uint8array) {
    var encodedString = '';
    for (var i = 0; i < uint8array.length; i++) {
      encodedString += String.fromCharCode(uint8array[i]);
    }
    try {
      return decodeURIComponent(escape(encodedString));
    } catch (e) {
      return encodedString;
    }
  };
}

if (typeof globalThis.console === 'undefined') {
  globalThis.console = {};
}

// Helper to safely format arguments into a single scannable string
const formatArgs = (args) => {
  return args.map(arg => {
    if (typeof arg === 'object' && arg !== null) {
      try {
        return JSON.stringify(arg, null, 2);
      } catch (e) {
        return String(arg);
      }
    }
    return String(arg);
  }).join(' ');
};

// Route each logging method to the native execution hook
globalThis.console.log = function(...args) {
  if (typeof globalThis.__nativeNSLog === 'function') {
    globalThis.__nativeNSLog('[JS LOG]: ' + formatArgs(args));
  }
};

globalThis.console.warn = function(...args) {
  if (typeof globalThis.__nativeNSLog === 'function') {
    globalThis.__nativeNSLog('[JS WARN]: ' + formatArgs(args));
  }
};

globalThis.console.error = function(...args) {
  if (typeof globalThis.__nativeNSLog === 'function') {
    globalThis.__nativeNSLog('[JS ERROR]: ' + formatArgs(args));
  }
};

// Mirror across global environment boundaries
window.console = globalThis.console;
self.console = globalThis.console;

globalThis.btoa = globalThis.btoa || function (str) {
  let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
  let output = "";
  let i = 0;
  str = String(str);
  while (i < str.length) {
    let c1 = str.charCodeAt(i++);
    let c2 = str.charCodeAt(i++);
    let c3 = str.charCodeAt(i++);
    let enc1 = c1 >> 2;
    let enc2 = ((c1 & 3) << 4) | (c2 >> 4);
    let enc3 = ((c2 & 15) << 2) | (c3 >> 6);
    let enc4 = c3 & 63;
    if (isNaN(c2)) { enc3 = enc4 = 64; }
    else if (isNaN(c3)) { enc4 = 64; }
    output += chars.charAt(enc1) + chars.charAt(enc2) + 
              (enc3 === 64 ? "=" : chars.charAt(enc3)) + 
              (enc4 === 64 ? "=" : chars.charAt(enc4));
  }
  return output;
};

globalThis.atob = globalThis.atob || function (str) {
  let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
  let output = "";
  str = String(str).replace(/=+$/, "");
  let i = 0;
  while (i < str.length) {
    let enc1 = chars.indexOf(str.charAt(i++));
    let enc2 = chars.indexOf(str.charAt(i++));
    let enc3 = chars.indexOf(str.charAt(i++));
    let enc4 = chars.indexOf(str.charAt(i++));
    let c1 = (enc1 << 2) | (enc2 >> 4);
    let c2 = ((enc2 & 15) << 4) | (enc3 >> 2);
    let c3 = ((enc3 & 3) << 6) | enc4;
    output += String.fromCharCode(c1);
    if (enc3 !== 64) output += String.fromCharCode(c2);
    if (enc4 !== 64) output += String.fromCharCode(c3);
  }
  return output;
};

// Add this at the top of your JS script so it's globally accessible
globalThis.base64ToU8 = function(base64) {
  // Handle URL-safe base64 strings if necessary
  const normalized = base64.replace(/-/g, '+').replace(/_/g, '/');
  const binaryString = atob(normalized);
  const len = binaryString.length;
  const bytes = new Uint8Array(len);
  for (let i = 0; i < len; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }
  return bytes;
};

globalThis.u8ToBase64 = function(u8Array, urlSafe = false) {
  let binary = '';
  const len = u8Array.byteLength;
  for (let i = 0; i < len; i++) {
    binary += String.fromCharCode(u8Array[i]);
  }
  let base64 = btoa(binary);
  if (urlSafe) {
    base64 = base64.replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
  }
  return base64;
};

if (typeof globalThis.setTimeout === 'undefined') {
  globalThis.setTimeout = function(callback, delay) {
    var args = Array.prototype.slice.call(arguments, 2);
    try {
      callback.apply(null, args);
    } catch (e) {
      if (globalThis.console && globalThis.console.error) {
        globalThis.console.error('Error in setTimeout callback:', e);
      }
    }
    return 1;
  };
}

if (typeof globalThis.clearTimeout === 'undefined') {
  globalThis.clearTimeout = function(id) {};
}

