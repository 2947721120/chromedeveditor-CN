// Copyright (c) 2013, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

/**
 * This library is a wrapper around the Dart to JavaScript (dart2js) compiler.
 */
library spark.compiler;

import 'dart:async';
import 'dart:html' as html;

import 'package:compiler_unsupported/compiler.dart' as compiler;
export 'package:compiler_unsupported/compiler.dart' show Diagnostic;

import 'services_common.dart' as common;
import '../dart/sdk.dart';

/**
 * An interface to the dart2js compiler. A compiler object can process one
 * compile at a time. They are heavy-weight objects, and can be re-used once
 * a compile finishes. Subsequent compiles after the first one will be faster,
 * on the order of a 2x speedup.
 */
class Compiler {
  final DartSdk _sdk;
  final common.ContentsProvider _contentsProvider;

  static Compiler createCompilerFrom(DartSdk sdk,
                                     common.ContentsProvider contentsProvider) {
    return new Compiler._(sdk, contentsProvider);
  }

  Compiler._(this._sdk, this._contentsProvider);

  Future<CompilerResultHolder> compileFile(String fileUuid, {bool csp: false}) {
    _CompilerProvider provider =
        new _CompilerProvider.fromUuid(_sdk, _contentsProvider, fileUuid);

    CompilerResultHolder result = new CompilerResultHolder(csp: csp);

    return compiler.compile(
        provider.getInitialUri(),
        new Uri(scheme: 'sdk', path: '/'),
        new Uri(scheme: 'package', path: '/'),
        provider.inputProvider,
        result._diagnosticHandler,
        [],
        result._outputProvider).then((_) => result);
  }

  /**
   * 编译给定的字符串，并返回结果 [CompilerResult].
   */
  Future<CompilerResultHolder> compileString(String input) {
    _CompilerProvider provider = new _CompilerProvider.fromString(_sdk, input);

    CompilerResultHolder result = new CompilerResultHolder();

    return compiler.compile(
        provider.getInitialUri(),
        new Uri(scheme: 'sdk', path: '/'),
        new Uri(scheme: 'package', path: '/'),
        provider.inputProvider,
        result._diagnosticHandler,
        [],
        result._outputProvider).then((_) => result);
  }
}

/**
 * 一个dart2js编译的结果
 */
class CompilerResultHolder {
  final bool csp;
  final List<CompilerProblem> _problems = [];
  StringBuffer _output;

  CompilerResultHolder({this.csp: false});

  List<CompilerProblem> get problems => _problems;

  String get output => _output == null ? null : _output.toString();

  bool get hasOutput => output != null;

  /**
   * 这是真实的，如果没有的报告的问题是错误.
   */
  bool getSuccess() {
    return !_problems.any((p) => p.kind == compiler.Diagnostic.ERROR);
  }

  void _diagnosticHandler(Uri uri, int begin, int end, String message,
      compiler.Diagnostic kind) {
    // 转换dart2js碰撞类型，以我们的错误类型.
    if (kind == compiler.Diagnostic.CRASH) kind = compiler.Diagnostic.ERROR;

    if (kind == compiler.Diagnostic.WARNING || kind == compiler.Diagnostic.ERROR) {
      _problems.add(new CompilerProblem._(uri, begin, end, message, kind));
    }
  }

  EventSink<String> _outputProvider(String name, String extension) {
    if (!csp && name.isEmpty && extension == 'js') {
      _output = new StringBuffer();
      return new _StringSink(_output);
    } else if (csp && name.isEmpty && extension == 'precompiled.js') {
      _output = new StringBuffer();
      return new _StringSink(_output);
    } else {
      return new _NullSink('$name.$extension');
    }
  }

  Map toMap() {
    List responseProblems = problems.map((p) => p.toMap()).toList();

    return {
      "output": output,
      "problems": responseProblems,
    };
  }
}

/**
 *错误，警告，提示，或与一个关联 [CompilerResult].
 */
class CompilerProblem {
  ///的URI编译单元; 可 `null`.
  final Uri uri;

  /// 起始（从0开始）字符偏移; 可(The starting (0-based) character offset; can be `null`.)
  final int begin;

  /// 起始（从0开始）字符偏移; 可(The starting (0-based) character offset; can be `null`.)
  final int end;

  final String message;
  final compiler.Diagnostic kind;

  CompilerProblem._(this.uri, this.begin, this.end, this.message, this.kind);

  bool get isWarningOrError => kind == compiler.Diagnostic.WARNING
      || kind == compiler.Diagnostic.ERROR;

  String toString() {
    if (uri == null) {
      return "[${kind}] ${message}";
    } else {
      return "[${kind}] ${message} (${uri})";
    }
  }

  Map toMap() {
    return {
      "begin": begin,
      "end": end,
      "message": message,
      "uri": (uri == null) ? "" : uri.path,
      "kind": kind.name
    };
  }
}

/**
 * 排水渠成A片(A sink that drains into /dev/null.)
 */
class _NullSink implements EventSink<String> {
  final String name;

  _NullSink(this.name);

  add(String value) { }

  void addError(Object error, [StackTrace stackTrace]) { }

  void close() { }

  String toString() => name;
}

/**
 * Used to hold the output from dart2js.
 */
class _StringSink implements EventSink<String> {
  final StringBuffer buffer;

  _StringSink(this.buffer);

  add(String value) => buffer.write(value);

  void addError(Object error, [StackTrace stackTrace]) { }

  void close() { }
}

/**
 * Instances of this class allow dart2js to resolve Uris to input sources.
 */
class _CompilerProvider {
  static const String _INPUT_URI_TEXT = 'resource:/foo.dart';

  final String textInput;
  final String uuidInput;
  final DartSdk sdk;
  final common.ContentsProvider provider;

  _CompilerProvider.fromString(this.sdk, this.textInput)
      : uuidInput = null,
        provider = null;

  _CompilerProvider.fromUuid(this.sdk, this.provider, this.uuidInput) :
      textInput = null;

  Uri getInitialUri() {
    if (textInput != null) {
      return Uri.parse(_CompilerProvider._INPUT_URI_TEXT);
    } else {
      return new Uri(scheme: 'file', path: uuidInput);
    }
  }

  Future<String> inputProvider(Uri uri) {
    if (uri.scheme == 'resource') {
      if (uri.toString() == _INPUT_URI_TEXT) {
        return new Future.value(textInput);
      } else {
        return new Future.error('unhandled: ${uri.scheme}');
      }
    } else if (uri.scheme == 'sdk') {
      final prefix = '/lib/';

      String path = uri.path;
      if (path.startsWith(prefix)) {
        path = path.substring(prefix.length);
      }

      String contents = sdk.getSourceForPath(path);
      if (contents != null) {
        return new Future.value(contents);
      } else {
        return new Future.error('file not found');
      }
    } else if (uri.scheme == 'file') {
      // 我们为了得到使用uri.path Segments.join（'/'）代替uri.path(We use uri.pathSegments.join('/') instead of uri.path in order to get)
      // 该编码的路径（我们想要的空间，而不是20％）(the unencoded path (we want spaces, not %20).)
      return provider.getFileContents(uri.pathSegments.join('/'));
    } else if (uri.scheme == 'package') {
      if (uuidInput == null) return new Future.error('file not found');

      // 转换 `package:/foo/foo.dart` 到 `package:foo/foo.dart`.
      return provider.getPackageContents(
          uuidInput, 'package:${uri.path.substring(1)}');
    } else {
      return html.HttpRequest.getString(uri.toString());
    }
  }
}
