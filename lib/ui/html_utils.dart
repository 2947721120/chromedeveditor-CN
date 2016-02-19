// Copyright (c) 2013, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

library spark.ui.utils.html_utils;

import 'dart:html';

/**
 * 返回页面中的元素的位置。.
 */
Point getAbsolutePosition(Element element) {
  Point result = new Point(0, 0);
  while (element != null) {
    result += element.offset.topLeft;
    result -= new Point(element.scrollLeft, element.scrollTop);
    element = element.offsetParent;
  }
  return result;
}

/**
 * 返回页面中的鼠标光标位置.
 */
Point getEventAbsolutePosition(MouseEvent event) {
  return getAbsolutePosition(event.target) + event.offset;
}

/**
 *如果鼠标光标的元素中，则返回true.
 * `marginX` 和 `marginY`将定义一个垂直和水平余量
 * 增加的匹配区域的大小.
 */
bool isMouseLocationInElement(MouseEvent event,
                              Element element,
                              int marginX,
                              int marginY) {
  var rect = element.getBoundingClientRect();
  int width = rect.width + marginX * 2;
  int left = rect.left - marginX;
  int height = rect.height + marginY * 2;
  int top = rect.top - marginY;
  rect = new Rectangle(left, top, width, height);

  return rect.containsPoint(event.client);
}

/**
 * 通过停止传播和预防默认操作取消给定的事件.
 */
void cancelEvent(Event event) {
  event.stopPropagation();
  event.preventDefault();
}

/**
 *在画布上绘制一个圆角矩形。
 */
void roundRect(CanvasRenderingContext2D ctx, Rectangle rect,
               {int radius: 5, bool fill: false, bool stroke: true}) {
  ctx.beginPath();
  ctx.moveTo(rect.left + radius, rect.top);
  ctx.lineTo(rect.left + rect.width - radius, rect.top);
  ctx.quadraticCurveTo(rect.left + rect.width,
      rect.top,
      rect.left + rect.width,
      rect.top + radius);
  ctx.lineTo(rect.left + rect.width, rect.top + rect.height - radius);
  ctx.quadraticCurveTo(rect.left + rect.width,
      rect.top + rect.height,
      rect.left + rect.width - radius,
      rect.top + rect.height);
  ctx.lineTo(rect.left + radius, rect.top + rect.height);
  ctx.quadraticCurveTo(rect.left,
      rect.top + rect.height,
      rect.left,
      rect.top + rect.height - radius);
  ctx.lineTo(rect.left, rect.top + radius);
  ctx.quadraticCurveTo(rect.left, rect.top, rect.left + radius, rect.top);
  ctx.closePath();
  if (stroke) {
    ctx.stroke();
  }
  if (fill) {
    ctx.fill();
  }
}
