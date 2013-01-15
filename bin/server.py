# Copyright 2012 The hookshot Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Profile server."""

import json
import logging

from flask import Flask

APP = Flask(__name__)

DATA = None


def formatNode(node):
  """Formats a node for return to the user."""
  return {'fullName': node.fullName, 'start': node.start, 'finish': node.finish, 'own': node.own, 'tag': node.tag}


@APP.route('/data')
def data():
  """Returns root level data in json format."""
  result = {}
  for thread in DATA.threads:
    result[thread] = [formatNode(node) for node in DATA.threads[thread].tree]
  return json.dumps({
    'checkpoints': DATA.checkpoints,
    'threads': result
  })


@APP.route('/details/<thread>/<path>')
def details(thread, path):
  """Returns a detail drill in in json format."""
  parts = [int(x) for x in path.split('.')]
  node = DATA.threads[thread].tree[parts[0]]
  for part in parts[1:]:
    node = node.children[int(part)]
  result = formatNode(node)
  result['children'] = [formatNode(child) for child in node.children]
  return json.dumps(result)


@APP.route('/')
def home():
  """Home page."""
  return '<link rel="stylesheet" href="/static/style.css"/>' \
         '<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js"></script>' \
         '<script src="/static/view.js"></script>'


def run(d):
  """Main body of the server."""
  global DATA # global is ugly but quick. # pylint: disable=W0603
  DATA = d

  logging.info('Listening on http://localhost:8020')
  APP.run(port=8020, debug=True)
