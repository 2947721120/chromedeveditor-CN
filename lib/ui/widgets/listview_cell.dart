// Copyright (c) 2013, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

/**
 * 这个类是为ListView细胞的接口。
 */

library spark.ui.widgets.listview_cell;

import 'dart:html';

abstract class ListViewCell {
  /**
   * HTML Element used to display an item of the list.
   * read-only
   */
  Element element;

  /**
   * Set highlighted to true to highlight the selection of this cell.
   * Override the setter to reflect highlighted state.
   */
  bool highlighted;

  /**
   * Set acceptDrop to true to notify the ListView that the cell is accepting
   * dropping items on it.
   */
  bool acceptDrop;
}
