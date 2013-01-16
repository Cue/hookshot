var ZOOM = 100000.0;
var FONT_SIZE = 1.25;
var ROOT, DATA_POINTS;
var TAGS = {};
var TAG_OFFSET = 0;
var ROW_HEIGHT = 38;

var levels = [];
var rows = [];
var controlRows = [];

function div() {
  return document.createElement('DIV');
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
    child.style.left = leftEm(item.start);
    child.style.width = widthEm(item.finish - item.start);
    child.style.marginTop = (count * 8) + 'px';
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
    name.appendChild(document.createTextNode(text));
    child.appendChild(name);

    child._thread = threadName;
    child._threadNumber = threadNumber;
    child._path = path ? (path + '.' + j) : ('' + j);

    rows[threadNumber].appendChild(child);
  }

  if (j) {
    if (count > levels[threadNumber]) {
      levels[threadNumber] = count;
      rows[threadNumber].style.height = (ROW_HEIGHT + 8 * count) + 'px';
      controlRows[threadNumber].style.height = (ROW_HEIGHT + 8 * count) + 'px';
    }
  }
  return max;
}

$(function() {
  document.body.style.padding = '0';
  document.body.style.margin = '0';

  $('#in').click(function() {
    FONT_SIZE *= 1.25;
    ROOT.style.fontSize = FONT_SIZE + 'em';
  });

  $('#out').click(function() {
    FONT_SIZE *= 0.8;
    ROOT.style.fontSize = FONT_SIZE + 'em';
  });

  ROOT = div();
  ROOT.id = 'root';
  ROOT.style.fontSize = FONT_SIZE + 'em';
  document.body.appendChild(ROOT);

  DATA_POINTS = div();
  DATA_POINTS.style.overflow = 'visible';
  ROOT.appendChild(DATA_POINTS);

  $(document.body).click(details);

  $.ajax('/data', {'dataType': 'json'}).done(function(data) {
    var controls = div();
    controls.id = 'controls';
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
      levels[0] = 0;

      key = keys[index];
      rows[index] = div();
      rows[index].className = 'row shade' + (index % 2);
      rows[index].style.height = ROW_HEIGHT + 'px';
      ROOT.appendChild(rows[index]);

      controlRows[index] = div();
      controlRows[index].className = 'row shade' + (index % 2);
      controlRows[index].style.height = ROW_HEIGHT + 'px';
      controlRows[index].appendChild(document.createTextNode(key));
      controls.appendChild(controlRows[index]);

      max = Math.max(renderItems(threads[key], key, index, ''), max);
    }

    for (var offset = 0; offset < max; offset += 250000) {
      var second = div();
      second.className = 'time ' + ((offset + 250000) % 1000000 ? 'quarter' : 'second');
      second.style.left = leftEm(offset + 250000);
      ROOT.appendChild(second);
    }
    for (var index = 0; index < keys.length; index++) {
      rows[index].style.width = leftEm(offset);
    }

    for (var i = 0; i < data.checkpoints.length; i++) {
      var line = div();
      line.className = 'checkpoint';
      line.style.height = '100%';
      // TODO: robbyw
      // line.style.paddingTop = parseInt(topPx(keys.length + 1)) + (i % 2) * 20 + 'px';
      line.style.left = leftEm(data.checkpoints[i].time);
      line.appendChild(div());
      line.firstChild.appendChild(document.createTextNode(data.checkpoints[i].text));
      ROOT.appendChild(line);
    }
  });
});
