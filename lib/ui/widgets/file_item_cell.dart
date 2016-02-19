// Copyright (c) 2013, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

/**
 * 这个类实现单元格中显示一个文件。
 */

library spark.ui.widgets.fileitem_cell;

import 'dart:core' hide Resource;
import 'dart:html' hide File;

import 'listview_cell.dart';
import '../../workspace.dart';

class FileItemCell implements ListViewCell {
  static const int HEIGHT = 25;
  final Resource resource;
  Element _element;
  bool _highlighted;
  bool acceptDrop;

  FileItemCell(this.resource) {
    DocumentFragment template =
        (querySelector('#fileview-filename-template') as TemplateElement).content;
    DocumentFragment templateClone = template.clone(true);
    _element = templateClone.querySelector('.fileview-filename-container');
    if (resource is Project) {
      _element.classes.add('project');
    }
    fileNameElement.text = resource.name;
    acceptDrop = false;
    updateFileStatus();

    //更新节点时插入到树中有些国家我们(Update the node when we're inserted into the tree. Some of the state we)
    // 修改包含在父节点（文件状态）。(modify is contained in parent nodes (the file status).)
    element.on['DOMNodeInserted'].listen((e) => updateFileStatus());
  }

  Element get element => _element;

  set element(Element element) => _element = element;

  bool get highlighted => _highlighted;

  set highlighted(bool value) => _highlighted = value;

  Element get fileNameElement => _element.querySelector('.nameField');

  Element get fileInfoElement => _element.querySelector('.infoField');

  Element get fileStatusElement {
    if (_element.parent == null) return null;
    return _element.parent.parent.querySelector('.treeviewcell-status');
  }

  Element get gitStatusElement => _element.querySelector('.gitStatus');

  void setFileInfo(String infoString) {
    fileInfoElement.innerHtml = infoString;
  }

  void updateFileStatus() {
    Element element = fileStatusElement;
    if (element == null) return;

    element.classes.removeAll(['warning', 'error']);

    int severity = resource.findMaxProblemSeverity();

    if (severity == Marker.SEVERITY_ERROR) {
      element.classes.add('error');
      if (resource is Project) {
        element.title = 'This project has errors';
      } else if (resource is Folder) {
        element.title = '此文件夹中的一些文件有错误';
      } else {
        element.title = '这个文件有错误';
      }
    } else if (severity == Marker.SEVERITY_WARNING) {
      element.classes.add('warning');
      if (resource is Project) {
        element.title = '该项目的警告';
      } else if (resource is Folder) {
        element.title = '此文件夹中的一些文件有警告';
      } else {
        element.title = '该文件有一些警告';
      }
    }
    else {
      element.title = '';
    }

    if (resource is Project) {
      element.classes.toggle('project', true);
    }
  }

  void setGitStatus({bool dirty: false, bool added: false}) {
    Element element = gitStatusElement;
    element.classes.toggle('dirty', dirty);
    if (dirty) {
      if (resource is Project) {
        element.title = '在这个项目中的一些文件已被添加或修改';
      } else if (resource is Folder) {
        element.title = '此文件夹中的一些文件已被添加或修改';
      } else {
        if (added) {
          element.title = '该文件已经被添加';
        } else {
          element.title = '本文件已被修改';
        }
      }
    } else {
      element.title = '';
    }
  }
}
