// Copyright (c) 2013, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

/**
 * 此类封装列表视图。.
 */

library spark.ui.widgets.listview;

import 'dart:async';
import 'dart:collection';
import 'dart:html';

import 'listview_cell.dart';
import 'listview_row.dart';
import 'listview_delegate.dart';
import '../html_utils.dart';

class ListView {
  //包含的项目列表中的HTML元素.
  Element _element;
  //HTML元素展现的亮点，当我们在拖动项目
  // `ListView`.
  DivElement _dragoverVisual;
  // 一种物品的容器将由`ListView` 实现创建.
  DivElement _container;
  //这格将帮助设置滚动区域的大小在容器.
  DivElement _placeholder;
  //实现对所需的回调 `ListView`.
  // 交互时回调将提供数据和行为
  // 清单上.
  ListViewDelegate _delegate;
  // 存储为一组行的索引选择行.
  HashSet<int> _selection;
  //在使用移多重选择的情况下，它的起始行索引.
  // -1 当有没有起始行使用.
  int _selectedRow;
  int _extendedSelectionRow;
  // 当有没有起始行使用.
  List<ListViewRow> _rows;
  // 无论是在下降的ListView项目被允许.
  bool _dropEnabled;
  //dragenter事件监听器.
  StreamSubscription<MouseEvent> _dragEnterSubscription;
  // dragenter事件监听器.
  StreamSubscription<MouseEvent> _dragLeaveSubscription;
  // dragenter事件监听器.
  StreamSubscription<MouseEvent> _dragOverSubscription;
  // 降事件监听器.
  StreamSubscription<MouseEvent> _dropSubscription;
  // 窗口大小调整事件监听器.
  StreamSubscription<Event> _resizeSubscription;
  // 降事件侦听器计数器发生的dragenter/ dragleave活动要解决的行为(Counter for the dragenter/dragleave events to workaround the behavior of)
  // 拖放。见`dropEnabled`二传手了解更多信息。(drag and drop. See `dropEnabled` setter for more information.)
  int _draggingCount;
  // 真当鼠标进入列表视图中拖动某一项时
  bool _draggingOver;
  // 真要是它拖动某一项时，任何细胞被突出显示.
  // 在这种情况下，我们不希望以突出整个列表.
  bool _cellHighlightedOnDragover;
  // 真要是清单应当在拖，没有电池时强调
  // 接受降.
  bool _globalDraggingOverAllowed;

  /**
   * 构造函数`ListView`.
   * `element` 是列表的容器.
   * `delegate` 对于列表和行为时，数据的回调
   * 与列表互动.
   */
  ListView(Element element, ListViewDelegate delegate) {
    _element = element;
    _delegate = delegate;
    _dragoverVisual = new DivElement();
    _dragoverVisual.classes.add('listview-dragover');
    _container = new DivElement();
    _container.tabIndex = 1;
    _container.classes.add('listview-container');
    _container.onKeyDown.listen(_onKeyDown);
    _placeholder = new DivElement();
    _dropEnabled = false;
    _element.children.add(_container);
    _element.children.add(_dragoverVisual);
    _selection = new HashSet();
    _rows = [];
    _selectedRow = -1;
    _extendedSelectionRow = -1;
    _container.onClick.listen((event) {
      _removeCurrentSelectionHighlight();
      _selection.clear();
      _delegate.listViewSelectedChanged(this, _selection.toList());
    });
    _container.onScroll.listen((event) => _showVisible());
    _resizeSubscription = window.onResize.listen((event) => _showVisible());
    _draggingCount = 0;
    _draggingOver = false;
    _cellHighlightedOnDragover = false;
    _globalDraggingOverAllowed = true;
    reloadData();
  }

  void _onKeyDown(KeyboardEvent event) {
    if (!_delegate.listViewKeyDown(event)) {
      return;
    }

    int keyCode = event.which;
    switch (keyCode) {
      case KeyCode.UP:
        if (_selectedRow > 0) {
          if (event.shiftKey) {
            if (_extendedSelectionRow == -1) {
              _extendedSelectionRow = _selectedRow;
            }
            _setSelection(_selectedRow - 1,
                endSelectionIndex: _extendedSelectionRow);
          } else {
            _extendedSelectionRow = -1;
            _setSelection(_selectedRow - 1);
          }
          _makeSureRowIsVisible(_selectedRow);
          cancelEvent(event);
        }
        break;
      case KeyCode.DOWN:
        if (_selectedRow < _rows.length - 1) {
          if (event.shiftKey) {
            if (_extendedSelectionRow == -1) {
              _extendedSelectionRow = _selectedRow;
            }
            _setSelection(_selectedRow + 1,
                endSelectionIndex: _extendedSelectionRow);
          } else {
            _extendedSelectionRow = -1;
            _setSelection(_selectedRow + 1);
          }
          _makeSureRowIsVisible(_selectedRow);
          cancelEvent(event);
        }
        break;
    }
  }

  /**
   * 这种方法可以被称为刷新内容时提供的数据
   * 通过委托改变.
   */
  void reloadData() {
    _rows.clear();
    _container.children.clear();
    _container.children.add(_placeholder);
    int count = _delegate.listViewNumberOfRows(this);
    int y = 0;
    for(int i = 0 ; i < count ; i ++) {
      Element separator = _delegate.listViewSeparatorForRow(this, i);
      int separatorHeight = _delegate.listViewSeparatorHeightForRow(this, i);
      int separatorY = y;
      if (separator != null) {
        separator.style
          ..position = 'absolute'
          ..left = '0'
          ..right = '0'
          ..height = '${separatorHeight}px'
          ..top = '${y}px';
        y += separatorHeight;
      } else {
        separatorHeight = 0;
      }

      int cellHeight = _delegate.listViewHeightForRow(this, i);
      ListViewRow row = new ListViewRow();
      row.cell = _delegate.listViewCellForRow(this, i);
      row.container = new DivElement();
      row.container.classes.add('listview-row');
      row.container.children.add(row.cell.element);
      row.container.style
        ..left = '0'
        ..right = '0'
        ..height = '${cellHeight - 2}px'
        ..position = 'absolute'
        ..top = '${y}px';
      // 组事件回调。
      row.y = y;
      row.height = cellHeight;
      row.separator = separator;
      row.separatorY = separatorY;
      row.separatorHeight = separatorHeight;
      y += cellHeight;
      _rows.add(row);
      row.container.onClick.listen((event) {
        _onClicked(i, event);
        event.stopPropagation();
      });
      row.container.onDoubleClick.listen((event) {
        _onDoubleClicked(i, event);
        event.stopPropagation();
      });
      row.container.onContextMenu.listen((event) {
        _onContextMenu(i, event);
        cancelEvent(event);
      });
    }
    _placeholder.style
      ..position = 'absolute'
      ..top = '0'
      ..left = '0'
      ..right = '0'
      ..height = '${y}px';
    // Fix selection if needed.
    if (_selectedRow >= count) {
      _selectedRow = -1;
    }
    List<int> itemsToRemove = [];
    List<int> selectionList = _selection.toList();
    selectionList.sort();
    selectionList.reversed.forEach((rowIndex) {
      if (rowIndex >= count) {
        itemsToRemove.add(rowIndex);
      }
    });
    itemsToRemove.forEach((rowIndex) {
      _selection.remove(rowIndex);
    });
    _addCurrentSelectionHighlight();
    _showVisible();
  }

  // 此方法执行二分法找出其中y行的位置。
  int _findRow(int y, int left, int right) {
    int middle = ((left + right) / 2).floor();
    if (middle == left) {
      if (y >= _rows[right].separatorY) {
        return right;
      } else {
        return left;
      }
    }

    if (y >= _rows[middle].separatorY) {
      return _findRow(y, middle, right);
    } else {
      return _findRow(y, 0, middle - 1);
    }
  }

  /**
   *这种方法在DOM增加了可见的单元格
   */
  void _showVisible() {
    int scopeTop = _container.scrollTop;
    int scopeBottom = _container.scrollTop + _container.offsetHeight;

    if (_rows.length == 0) {
      return;
    }
    int left = _findRow(scopeTop, 0, _rows.length - 1);
    for(int i = left ; i < _rows.length ; i ++) {
      ListViewRow row = _rows[i];
      if (row.separator != null) {
        int y = row.separatorY;
        if ((row.separator.parent == null) && (y >= scopeTop - row.separatorHeight) && (y < scopeBottom)) {
          _container.children.add(row.separator);
        }
      }
      if (row.container != null) {
        int y = row.y;
        if ((row.container.parent == null) && (y >= scopeTop - row.height) && (y < scopeBottom)) {
          _container.children.add(row.container);
        }
      }
      if (row.y > scopeBottom) {
        break;
      }
    }
  }

  /**
   *回调在一个单一的点击。
   */
  void _onClicked(int rowIndex, Event event) {
    _extendedSelectionRow = -1;
    focus();

    if (!_delegate.listViewRowClicked(event, rowIndex)) {
      // 如果ListView的行点击返回false，不处理
      return;
    }

    if ((event as MouseEvent).shiftKey) {
      // 按住Shift键点击
      _setSelection(
          (_selectedRow != -1) ? _selectedRow : rowIndex,
          endSelectionIndex: rowIndex);
    } else if ((event as MouseEvent).metaKey || (event as MouseEvent).ctrlKey) {
      // 同时按住Ctrl点击 (Mac/Linux) 或 Command (for Mac).
      _toggleSelectedRow(rowIndex);
    } else {
      // 点击无任何修饰。
      _setSelection(rowIndex);
    }
  }

  void _toggleSelectedRow(int rowIndex) {
    _removeCurrentSelectionHighlight();

    _selectedRow = rowIndex;

    if (_selection.contains(rowIndex)) {
      _selection.remove(rowIndex);
    } else {
      _selection.add(rowIndex);
    }

    _addCurrentSelectionHighlight();
    _delegate.listViewSelectedChanged(this, _selection.toList());
  }

  void _makeSureRowIsVisible(int selectionIndex) {
    ListViewRow row = _rows[selectionIndex];
    if (row.container.parent == null) {
      _container.children.add(row.container);
    }
    if (row.container.offsetTop + row.container.offsetHeight >
        _container.scrollTop + _container.offsetHeight) {
      _container.scrollTop = row.container.offsetTop +
          row.container.offsetHeight - _container.offsetHeight;
    }
    if (row.container.offsetTop < _container.scrollTop) {
      _container.scrollTop = row.container.offsetTop;
    }
  }

  void _setSelection(int selectionIndex, {int endSelectionIndex: -1}) {
    _removeCurrentSelectionHighlight();

    // If endSelection is -1 (default for not-provided), one item is being selected.
    if (endSelectionIndex == -1) {
      endSelectionIndex = selectionIndex;
    }

    selectionIndex = selectionIndex.clamp(0, _rows.length);
    endSelectionIndex = endSelectionIndex.clamp(0, _rows.length);

    if (selectionIndex < endSelectionIndex) {
      _selection.clear();
      for(int i = selectionIndex ; i <= endSelectionIndex ; i++) {
        _selection.add(i);
      }
    } else {
      _selection.clear();
      for(int i = endSelectionIndex ; i <= selectionIndex ; i++) {
        _selection.add(i);
      }
    }

    _selectedRow = selectionIndex;

    _addCurrentSelectionHighlight();
    _delegate.listViewSelectedChanged(this, _selection.toList());
  }

  void _onContextMenu(int rowIndex, Event event) {
    _delegate.listViewContextMenu(this, _selection.toList(), rowIndex, event);
  }

  List<int> get selection => _selection.toList();

  set selection(List<int> selection) {
    _removeCurrentSelectionHighlight();
    _selection.clear();
    selection.forEach((rowIndex) {
      _selection.add(rowIndex);
    });
    _addCurrentSelectionHighlight();

    if (selection.length > 0) {
      _selectedRow = selection.first;
    } else {
      _selectedRow = -1;
    }
  }

  void scrollIntoRow(int rowIndex, [ScrollAlignment align]) {
    ListViewRow row = _rows[rowIndex];
    if (row.container.parent == null) {
      _container.children.add(row.container);
    }
    row.cell.element.parent.scrollIntoView(align);
  }

  /**
   * 回调上双击.
   */
  void _onDoubleClicked(int rowIndex, Event event) {
    _delegate.listViewDoubleClicked(this, _selection.toList(), event);
  }

  /**
   * 取消当前行选择的亮点.
   */
  void _removeCurrentSelectionHighlight() {
    _selection.forEach((rowIndex) {
      _rows[rowIndex].cell.highlighted = false;
      _rows[rowIndex].container.classes.remove('listview-cell-highlighted');
    });
  }

  /**
   * 显示当前行选择的亮点。
   */
  void _addCurrentSelectionHighlight() {
    _selection.forEach((rowIndex) {
      _rows[rowIndex].cell.highlighted = true;
      _rows[rowIndex].container.classes.add('listview-cell-highlighted');
    });
  }

  void set dropEnabled(bool enabled) {
    if (_dropEnabled == enabled)
      return;

    _dropEnabled = enabled;
    if (_dropEnabled) {
      _dragEnterSubscription = _container.onDragEnter.listen((event) {
        // 当我们得到更多的dragenter事件时，孩子们忽略
        // entered/left.
        _draggingCount ++;
        if (_draggingCount == 1) {
          cancelEvent(event);
          String effect = _delegate.listViewDropEffect(this, event);
          if (effect == null) {
            return;
          }
          _draggingOver = true;
          _updateDraggingVisual();
          event.dataTransfer.dropEffect = effect;
          _delegate.listViewDragEnter(this, event);
        }
      });
      _dragLeaveSubscription = _container.onDragLeave.listen((event) {
        //当我们得到更多的dragleave活动时，下级忽略
        // 进入/离开。(entered/left.)
        _draggingCount --;
        if (_draggingCount == 0) {
          cancelEvent(event);
          _draggingOver = false;
          _updateDraggingVisual();
          _delegate.listViewDragLeave(this, event);
        }
      });
      _dragOverSubscription = _container.onDragOver.listen((event) {
        cancelEvent(event);
        _delegate.listViewDragOver(this, event);

        String effect = _delegate.listViewDropEffect(this, event);
        if (effect != null) {
          event.dataTransfer.dropEffect = effect;
        }
      });
      _dropSubscription = _container.onDrop.listen((event) {
        cancelEvent(event);
        _draggingCount = 0;
        _draggingOver = false;
        _updateDraggingVisual();
        int dropRowIndex = -1;
        _delegate.listViewDrop(this, dropRowIndex, event.dataTransfer);
      });
    } else {
      _dragEnterSubscription.cancel();
      _dragEnterSubscription = null;
      _dragLeaveSubscription.cancel();
      _dragLeaveSubscription = null;
      _dragOverSubscription.cancel();
      _dragOverSubscription = null;
      _dropSubscription.cancel();
      _dropSubscription = null;
    }
  }

  bool get cellHighlightedOnDragOver => _cellHighlightedOnDragover;

  void set cellHighlightedOnDragOver(bool cellHighlightedOnDragOver) {
    _cellHighlightedOnDragover = cellHighlightedOnDragOver;
    _updateDraggingVisual();
  }

  bool get globalDraggingOverAllowed => _globalDraggingOverAllowed;

  void set globalDraggingOverAllowed(bool allowed) {
    _globalDraggingOverAllowed = allowed;
    _updateDraggingVisual();
  }

  void _updateDraggingVisual() {
    // 我们强调是拖是在列表中，并没有细胞被突出显示。
    if (_draggingOver && !_cellHighlightedOnDragover &&
        _globalDraggingOverAllowed) {
      _dragoverVisual.classes.add('listview-dragover-active');
    } else {
      _dragoverVisual.classes.remove('listview-dragover-active');
    }
  }

  ListViewCell cellForRow(int rowIndex) {
    return _rows[rowIndex].cell;
  }

  /**
   * 这种方法将集中列表视图
   */
  void focus() {
    _container.focus();
  }

  bool get dropEnabled => _dropEnabled;

  int get selectedRow => _selectedRow;
}
