library app_bootstrap;

import 'package:polymer/polymer.dart';

import 'commit_message_view.dart' as i0;
import 'package:smoke/smoke.dart' show Declaration, PROPERTY, METHOD;
import 'package:smoke/static.dart' show useGeneratedCode, StaticConfiguration;
import 'commit_message_view.dart' as smoke_0;
import 'package:spark_widgets/common/spark_widget.dart' as smoke_1;
import 'package:polymer/polymer.dart' as smoke_2;
import 'package:observe/src/metadata.dart' as smoke_3;
import '../../scm.dart' as smoke_4;
abstract class _M0 {} // SparkWidget与变更通知

void main() {
  useGeneratedCode(new StaticConfiguration(
      checkedMode: false,
      getters: {
        #authorEmail: (o) => o.authorEmail,
        #authorName: (o) => o.authorName,
        #commitInfo: (o) => o.commitInfo,
        #dateString: (o) => o.dateString,
        #identifier: (o) => o.identifier,
        #message: (o) => o.message,
      },
      setters: {
        #commitInfo: (o, v) { o.commitInfo = v; },
      },
      parents: {
        smoke_0.CommitMessageView: _M0,
        smoke_1.SparkWidget: smoke_2.PolymerElement,
        _M0: smoke_1.SparkWidget,
      },
      declarations: {
        smoke_0.CommitMessageView: {
          #commitInfo: const Declaration(#commitInfo, smoke_4.CommitInfo, kind: PROPERTY, annotations: const [smoke_3.reflectable, smoke_3.observable]),
        },
      },
      names: {
        #authorEmail: r'authorEmail',
        #authorName: r'authorName',
        #commitInfo: r'commitInfo',
        #dateString: r'dateString',
        #identifier: r'identifier',
        #message: r'message',
      }));
  configureForDeployment([
      () => Polymer.register('commit-message-view', i0.CommitMessageView),
    ]);
  i0.main();
}
