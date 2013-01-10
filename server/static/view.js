var ZOOM = 100000.0;
var FONT_SIZE = 1.25;
var ROOT, DATA_POINTS;
var TAGS = {};
var TAG_OFFSET = 0;

function div() {
  var out = document.createElement('DIV');
  out.style.position = 'absolute';
  return out;
}

function topPx(i) {
  return 20 + (i * 70) + 'px';
}

function leftEm(t) {
  return (t / ZOOM) + 'em';
}

function widthEm(micros) {
  return Math.max(micros / ZOOM, 0.05) + 'em';
}

/**
 * @param {string} x The parameter string.
 * @return {boolean} Whether this string starts with the parameter string.
 */
String.prototype.startsWith = function(x) {
  return this.substring(0, x.length) == x;
};

function details(e) {
  if (e.target._path) {
    e.target.style.opacity = 0.2;
    $.ajax('/details/' + e.target._thread + '/' + e.target._path, {'dataType': 'json'}).done(function(data) {
      renderItems(data.children, e.target._thread, e.target._threadNumber, e.target._path);
    });
  }
}

function renderItems(array, threadName, threadNumber, path) {
  var max = 0;
  var count = path.length ? path.split('.').length : 0;
  for (var j = 0; j < array.length; j++) {
    var item = array[j];
    var child = div();
    child.className = 'event';
    child.style.top = topPx(threadNumber);
    child.style.left = leftEm(item.start);
    child.style.width = widthEm(item.finish - item.start);
    child.style.marginTop = (count * 4) + 'px';
    if (item.tag) {
      if (!(item.tag in TAGS)) {
        TAGS[item.tag] = TAG_OFFSET++;
      }
      child.className = 'event tag' + TAGS[item.tag];
    }

    max = Math.max(item.finish || item.start, max);

    var name = document.createElement('span');
    var text = item.fullName + '\n[' + item.start + ' - ' + item.finish + ' : ' + item.own + ']';
    if (item.tag) {
      text += ' #' + item.tag;
    }
    name.innerText = text;
    child.appendChild(name);

    child._thread = threadName;
    child._threadNumber = threadNumber;
    child._path = path ? (path + '.' + j) : ('' + j);

    DATA_POINTS.appendChild(child);
  }
  return max;
}

$(function() {
  document.body.style.padding = '0';
  document.body.style.margin = '0';

  ROOT = div();
  ROOT.style.left = '300px';
  ROOT.style.overflow = 'visible';
  ROOT.style.fontSize = FONT_SIZE + 'em';
  document.body.appendChild(ROOT);

  DATA_POINTS = div();
  DATA_POINTS.style.overflow = 'visible';
  ROOT.appendChild(DATA_POINTS);

  $(document.body).click(details);

  $.ajax('/data', {'dataType': 'json'}).done(function(data) {
    var controls = div();
    controls.style.position = 'fixed';
    controls.style.width = '290px';
    controls.style.height = '100%';
    controls.style.background = 'white';
    controls.style.borderRight = '1px solid black';
    document.body.appendChild(controls);

    var threads = data.threads;
    var max = 0;
    var keys = [];
    for (var key in threads) {
      keys.push(key);
    }
    keys.sort(function(a, b) {
      if (a == b) {
        return 0;
      } else if (a == 'MAIN') {
        return -1;
      } else if (b == 'MAIN') {
        return 1;
      } else if (a.toLowerCase() < b.toLowerCase()) {
        return -1;
      } else {
        return 1;
      }
    });
    for (var index = 0; index < keys.length; index++) {
      key = keys[index];
      var d = div();
      d.style.left = '5px';
      d.style.top = topPx(index);
      d.innerText = key;
      controls.appendChild(d);

      max = Math.max(renderItems(threads[key], key, index, ''), max);
    }

    var zoomIn = div();
    zoomIn.style.top = topPx(keys.length);
    zoomIn.style.left = '5px';
    zoomIn.style.padding = '3px 5px';
    zoomIn.innerText = '+';
    zoomIn.style.background = '#eee';
    zoomIn.style.border = '1px solid #444';
    controls.appendChild(zoomIn);
    $(zoomIn).click(function() {
      FONT_SIZE *= 1.25;
      ROOT.style.fontSize = FONT_SIZE + 'em';
    });

    var zoomOut = div();
    zoomOut.style.top = topPx(keys.length);
    zoomOut.style.left = '35px';
    zoomOut.style.padding = '3px 5px';
    zoomOut.innerText = '-';
    zoomOut.style.background = '#eee';
    zoomOut.style.border = '1px solid #444';
    controls.appendChild(zoomOut);
    $(zoomOut).click(function() {
      FONT_SIZE *= 0.8;
      ROOT.style.fontSize = FONT_SIZE + 'em';
    });

    for (var offset = 0; offset < max; offset += 250000) {
      var second = div();
      second.style.top = 0;
      second.style.height = topPx(keys.length + 1);
      second.style.width = '1px';
      second.style.borderLeft = '1px dashed ' + ((offset + 250000) % 1000000 ? '#bbb' : '#222');
      second.style.left = leftEm(offset + 250000);
      ROOT.appendChild(second);
    }

    for (var i = 0; i < data.checkpoints.length; i++) {
      var line = div();
      line.className = 'checkpoint';
      line.style.height = topPx(keys.length + 1);
      line.style.paddingTop = parseInt(topPx(keys.length + 1)) + (i % 2) * 20 + 'px';
      line.style.left = leftEm(data.checkpoints[i].time);
      line.appendChild(div());
      line.firstChild.innerText = data.checkpoints[i].text;
      ROOT.appendChild(line);
    }

    var extra = div();
    extra.style.top = 0;
    extra.style.height = '100px';
    extra.style.left = leftEm(max);
    extra.style.width = '300px';
    ROOT.appendChild(extra);
  });
});
