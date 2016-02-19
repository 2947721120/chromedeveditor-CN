// Copyright (c) 2013, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
//许可证可在许可证文件中找到。

library spark.ui.widgets.listview_row;

import 'dart:html';

import 'listview_cell.dart';

/**
 * 在`ListView`细胞的名单将被存储为列表 
 * `ListViewRow`.
 * 每个项目将存储的小区和一个容器元素。
 */

class ListViewRow {
  ListViewCell cell;
  Element container;
  //y是该行的垂直位置。
  int y;
  // 高度是该行的高度。
  int height;
  // 分隔符可以是空的，这意味着没有分隔在此之前
  //行。在这种情况下，分= y和隔板高度为0。
  Element separator;
  int separatorY;
  int separatorHeight;
}
