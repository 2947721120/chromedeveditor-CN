// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of spark.templates;

class PolymerJSTemplate extends PolymerTemplate {
  PolymerJSTemplate(
      String id, List<TemplateVar> globalVars, List<TemplateVar> localVars)
      : super(id, globalVars, localVars) {
    //一个生成的标签匹配覆盖标准源名称。
    final String sourceName = _vars['tagName'].value;

    _addOrReplaceVars([
        new TemplateVar('sourceName', sourceName)
    ]);
  }
}
