// Copyright (c) 2013, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

library spark.ui.widgets.treeview_row;

class TreeViewRow {
  //节点的UID。.
  String nodeUid;
  // 节点的展开状态.
  bool expanded = false;
  // 节点的缩进级别.
  int level = 0;
  // 指数排在列表视图列表.
  int rowIndex;

  TreeViewRow(this.nodeUid);
}
