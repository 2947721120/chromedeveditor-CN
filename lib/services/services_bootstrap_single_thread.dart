// Copyright (c) 2014, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

library spark.services_bootstrap;

import 'dart:async';

import 'services_common.dart';
import 'services_impl.dart' as services_impl;

HostToWorkerHandler createHostToWorkerHandler() {
  return new _SingleThreadedHostToWorkerHandler();
}

class SingleThreadedWorkerToHostHandler implements WorkerToHostHandler {
  /// 用于发送消息到主机的数据流。
  final StreamController _hostStreamController = new StreamController();
  /// 用于发送消息到工人的流。
  final StreamController _workerStreamController = new StreamController();

  @override
  void sendToHost(dynamic message) {
    _hostStreamController.add(message);
  }

  @override
  void listenFromHost(void onData(var message)) {
    // Note: We wrap "onData" with our own handler to facilitate
    // manual debugging (and possibly logging down the line).
    _workerStreamController.stream.listen((message) {
      onData(message);
    });
  }

  void sendToWorker(dynamic message) {
    _workerStreamController.add(message);
  }

  void listenFromWorker(void onData(var message)) {
    // 注意：我们包装“onData”用我们自己的处理程序，以方便
    // 手动调试（也可能记录下了线）--manual debugging (and possibly logging down the line).
    _hostStreamController.stream.listen((message) {
      onData(message);
    });
  }
}

/**
 * 实现[HostToWorkerHandler]其中工人在同一分离运行
 *作为主机。这应该用于debuggin/只测试，因为这明显
 *可以使用户界面无响应。
 */
class _SingleThreadedHostToWorkerHandler implements HostToWorkerHandler {
  /** 连接到[服务的ActionEvent]消息的唯一标识符. */
  int _topCallId = 0;

  /** Map of call ID to completer for the active tasks. */
  final Map<String, Completer> _serviceCallCompleters = {};

  /** Stream controller underlying [onceWorkerReady]. */
  final StreamController _readyController = new StreamController.broadcast();

  /** Stream controller underlying [onWorkerMessage]. */
  final StreamController<ServiceActionEvent> _messageController =
      new StreamController<ServiceActionEvent>.broadcast();

  /** Worker to Host IPC implementation. */
  final SingleThreadedWorkerToHostHandler _port =
      new SingleThreadedWorkerToHostHandler();

  @override
  Stream<ServiceActionEvent> onWorkerMessage;

  @override
  Future onceWorkerReady;

  _SingleThreadedHostToWorkerHandler() {
    _port.listenFromWorker(_onWorkerMessage);
    onWorkerMessage = _messageController.stream;
    onceWorkerReady = _readyController.stream.first;

    services_impl.init(_port);

    // 工人立即准备来处理邮件。
    // TODO(rpaquay): Is this correct?
    _readyController
        ..add(null)
        ..close();
  }

  /**
   * Called when a message from the worker process is received.
   * Dispatches [message] to appropriate host component.
   */
  void _onWorkerMessage(dynamic message) {
    if (message is String) {
      // String: handle as print
      print(message);
    } else if (message is int) {
      // int: handle as ping
      _pong(message);
    } else {
      ServiceActionEvent event = new ServiceActionEvent.fromMap(message);

      if (event.response == true) {
        Completer<ServiceActionEvent> completer =
            _serviceCallCompleters.remove(event.callId);
        assert(completer != null);
        if (event.error) {
          completer.completeError(event.getErrorMessage());
        } else {
          completer.complete(event);
        }
      } else {
        _messageController.add(event);
      }
    }
  }

  @override
  Future<String> ping() {
    Completer<String> completer = new Completer();

    int callId = _topCallId;
    _serviceCallCompleters["ping_$callId"] = completer;
    onceWorkerReady.then((_) {
      _port.sendToHost(callId);
    });
    _topCallId += 1;

    return completer.future;
  }

  void _pong(int id) {
    Completer completer = _serviceCallCompleters.remove("ping_$id");
    completer.complete("pong");
  }

  String _getNewCallId() => "host_${_topCallId++}";

  @override
  Future<ServiceActionEvent> sendAction(ServiceActionEvent event) {
    Completer<ServiceActionEvent> completer =
        new Completer<ServiceActionEvent>();

    event.makeRespondable(_getNewCallId());
    _serviceCallCompleters[event.callId] = completer;
    _port.sendToWorker(event.toMap());

    return completer.future;
  }

  @override
  void sendResponse(ServiceActionEvent event) {
    _port.sendToWorker(event.toMap());
  }

  @override
  void dispose() {
    // TODO(rpaquay)
  }
}
