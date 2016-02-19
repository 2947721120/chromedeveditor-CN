// Copyright (c) 2013, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

library spark.ui.widgets.treeview_cell;

import 'dart:html';
import 'dart:convert' show JSON;

import 'listview_cell.dart';
import 'treeview.dart';
import 'treeview_row.dart';

Expando<TreeViewCell> treeViewCellExpando = new Expando<TreeViewCell>();

class TreeViewCell implements ListViewCell {
  // 视图的HTML元素。
  Element _element;
  // 通过细胞树视图的委托返回。
  ListViewCell _embeddedCell;
  // <div>将包含元素 _embeddedCell 元件.
  DivElement _embeddedCellContainer;
  // 披露箭头。
  DivElement _arrow;
  // 节点的高亮显示状态。
  bool _highlighted;
  // 拥有此节点的树视图。
  TreeView _treeView;
  // 所显示节点的信息。
  TreeViewRow _row;
  // 无论披露箭头动画。
  bool _animating;
  // 当用户拖动的项目在 _embeddedCell, 我们展示一个
  // "drag over" 突出
  DivElement _dragOverlay;
  // 是否 "drag over" 亮点是可见的。
  bool _dragOverlayVisible;

  static TreeViewCell TreeViewCellForElement(DivElement element) {
    return treeViewCellExpando[element];
  }

  TreeViewCell(this._treeView, this._embeddedCell, this._row,
               bool hasChildren, bool draggable, int disclosurePosition) {
    DocumentFragment template =
        (querySelector('#treeview-cell-template') as TemplateElement).content;
    DocumentFragment templateClone = template.clone(true);
    _element = templateClone.querySelector('.treeviewcell');

    _embeddedCellContainer = _element.querySelector('.treeviewcell-content');
    int margin = _row.level == 0 ? 0 : _row.level * 25;
    _embeddedCellContainer.classes.add('treeviewcell-content');
    int offsetX = margin + 15;
    _embeddedCellContainer.style.left = '${offsetX}px';
    _embeddedCellContainer.style.width = 'calc(100% - ${offsetX}px)';
    if (draggable) {
      _embeddedCellContainer.setAttribute('draggable', 'true');
    }
    _embeddedCellContainer.children.add(_embeddedCell.element);

    _dragOverlay = _element.querySelector('.treeviewcell-dragoverlay');
    _dragOverlay.style.left = '${margin + 15}px';
    _dragOverlay.style.width = 'calc(100% - ${offsetX}px)';

    // Adds an arrow in front the cell.
    _arrow = _element.querySelector('.treeviewcell-disclosure');
    if (disclosurePosition != -1) {
      _arrow.style.top = '${disclosurePosition}px';
    }
    _arrow.style.left = '${margin + 5}px';
    _applyExpanded(_row.expanded);
    if (!hasChildren) {
      _arrow.style.visibility = 'hidden';
    }

    // Click handler for the arrow: toggle expanded state of the node.
    _arrow.onClick.listen((event) {
      event.stopPropagation();
      toggleExpanded();
    });

    _embeddedCellContainer.onDragStart.listen((event) {
      _treeView.privateCheckSelectNode(_row.nodeUid);
      // Dragged data.
      Map dragInfo = {'uuid': _treeView.uuid, 'selection': _treeView.selection};
      event.dataTransfer.setData('application/x-spark-treeview',
          JSON.encode(dragInfo));
      TreeViewDragImage imageInfo = _treeView.privateDragImage(event);
      if (imageInfo != null) {
        event.dataTransfer.setDragImage(imageInfo.image,
            imageInfo.location.x, imageInfo.location.y);
      }
    });

    _animating = false;
    treeViewCellExpando[_element] = this;
  }

  ListViewCell get embeddedCell => _embeddedCell;

  Element get element => _element;
  set element(Element element) => _element = element;

  bool get highlighted => _highlighted;

  set highlighted(bool value) {
    _highlighted = value;
    _embeddedCell.highlighted = value;
  }

  bool get dragOverlayVisible => _dragOverlayVisible;

  set dragOverlayVisible(bool value) {
    _dragOverlayVisible = value;
    if (_dragOverlayVisible) {
      _dragOverlay.style.opacity = '1';
    } else {
      _dragOverlay.style.opacity = '0';
    }
    // Notify the TreeView that a cell is being highlighted.
    _treeView.listView.cellHighlightedOnDragOver = _dragOverlayVisible;
  }

  String get nodeUid => _row.nodeUid;

  void toggleExpanded() {
    // Don't change the expanded state if it's already animating to change
    // the expanded state.
    if (_animating) {
      return;
    }

    // Change visual appearance.
    _applyExpanded(!_row.expanded);

    // Wait for animation to finished before effectively changing the
    // expanded state.
    _animating = true;
    _arrow.onTransitionEnd.listen((event) {
      _animating = false;
      _treeView.setNodeExpanded(_row.nodeUid, !_row.expanded);
    });
  }

  // Change visual appearance of the disclosure arrow, depending whether the
  // node is expanded or not.
  void _applyExpanded(bool expanded) {
    if (expanded) {
      _arrow.classes.add('treeviewcell-disclosed');
    } else {
      _arrow.classes.remove('treeviewcell-disclosed');
    }
  }

  bool get acceptDrop => _embeddedCell.acceptDrop;
  set acceptDrop(bool value) => _embeddedCell.acceptDrop = value;
}
