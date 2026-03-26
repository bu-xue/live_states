import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../live/live_view.dart';

enum WidgetType { provider, widget, scope }

enum NodeType { scope, computed, livedata }

const widgetMount = 'live_states:widget_mount';
const widgetUnmount = 'live_states:widget_unmount';
const nodeCreated = 'live_states:node_created';
const nodeDisposed = 'live_states:node_disposed';
const subscriptionCreated = 'live_states:subscription_created';
const subscriptionDisposed = 'live_states:subscription_disposed';
const notifyHappened = 'live_states:notify_happened';
const dataChanged = 'live_states:data_changed';

/// A mixin that provides debugging capabilities to classes.
/// Helper class for DevTools Extension integration.
@internal
class DevToolsHelper {

  bool enable;

  DevToolsHelper({required this.enable});

  void _postEvent(String eventKind, Map eventData) {
    if (!enable) return;
    if (enable) print('🚀 [LiveStates DevTools] post Event($eventKind): ${eventData}.');
    developer.postEvent(eventKind, eventData);
  }

  void _postWidgetMount({
    required String debugId,
    required WidgetType type,
    String? parentId,
    String? debugName,
  }) {
    if (!enable) return;
    if (enable)
      _postEvent(widgetMount, {
        'id': debugId,
        'type': type.name,
        'debugName': debugName,
        'parentId': parentId,
      });
  }

  void _postWidgetUnmount(String debugId) {
    if (!enable) return;
    _postEvent(widgetUnmount, {'id': debugId});
  }

  void _postNodeCreated({
    required String debugId,
    required String type,
    String? debugName,
    String? parentId,
    String? value,
    Map<String, dynamic>? extra,
  }) {
    if (!enable) return;
    _postEvent(nodeCreated, {
      'id': debugId,
      'type': type,
      'debugName': debugName,
      'parentId': parentId,
      'value': value,
      ...?extra,
    });
  }

  void _postNodeDisposed(String id) {
    if (!enable) return;
    _postEvent(nodeDisposed, {'id': id});
  }

  void _postSubscriptionCreated(String observerId, String subjectId) {
    if (!enable) return;
    _postEvent(subscriptionCreated, {
      'observerId': observerId,
      'subjectId': subjectId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  void _postSubscriptionDisposed(String observerId, String subjectId) {
    if (!enable) return;
    _postEvent(subscriptionDisposed, {
      'observerId': observerId,
      'subjectId': subjectId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  void _postNotifyHappened(String senderId, String recipientId) {
    if (!enable) return;
    _postEvent(notifyHappened, {
      'senderId': senderId,
      'recipientId': recipientId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  void _postDataChanged(String debugId, String? value) {
    if (!enable) return;
    _postEvent(dataChanged, {
      'debugId': debugId,
      'value': value,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  void debugWidgetMount(LiveViewModel viewModel) {
    if (!enable) return;
    final isProvider = viewModel is InnerLiveProviderVM;
    final widgetType = isProvider ? WidgetType.provider : WidgetType.widget;
    final debugName =
        viewModel.debugName ??
        (isProvider
            ? (viewModel.widget.debugName ?? viewModel.provider.runtimeType.toString())
            : (viewModel.widget.debugName ?? viewModel.widget.runtimeType.toString()));
    _postWidgetMount(
      debugId: viewModel.debugId,
      type: widgetType,
      debugName: debugName,
      parentId: viewModel.parent?.debugId,
    );
  }

  void debugWidgetUnmount(LiveViewModel viewModel) {
    if (!enable) return;
    _postWidgetUnmount(viewModel.debugId);
  }

  void debugScopeMount(BaseLiveScopeElement scope) {
    if (!enable) return;
    final widgetType = WidgetType.scope;
    String? parentId;
    scope.visitAncestorElements((element) {
      if (element is LiveElement) {
        parentId = element.viewModel.debugId;
        return false;
      }
      if (element is BaseLiveScopeElement) {
        parentId = element.debugId;
        return false;
      }
      return true;
    });
    _postWidgetMount(
      debugId: scope.debugId,
      type: widgetType,
      debugName: scope.debugName,
      parentId: parentId,
    );
  }

  void debugScopeUnmount(BaseLiveScopeElement scope) {
    if (!enable) return;
    _postWidgetUnmount(scope.debugId);
  }

  void debugLiveDataRegister(String vmDebugId, LiveData data) {
    if (!enable) return;
    _postNodeCreated(
      debugId: data.debugId,
      type: (data is LiveCompute) ? NodeType.computed.name : NodeType.livedata.name,
      debugName: data.debugName ?? data.name,
      parentId: vmDebugId,
      value: data.onlyValue == null ? null : '${data.onlyValue}',
    );
  }

  void debugLiveDataUnregister(LiveData data) {
    if (!enable) return;
    _postNodeDisposed(data.name);
  }

  void debugSubscribe({required String observerId, required String subjectId}) {
    if (!enable) return;
    _postSubscriptionCreated(observerId, subjectId);
  }

  void debugUnsubscribe({required String observerId, required String subjectId}) {
    if (!enable) return;
    _postSubscriptionDisposed(observerId, subjectId);
  }

  void debugNotify({required String senderId, required String recipientId}) {
    if (!enable) return;
    _postNotifyHappened(senderId, recipientId);
  }

  void debugDataChanged({required String debugId, String? value}) {
    if (!enable) return;
    _postDataChanged(debugId, value);
  }

  void debugObserverUpdate({required String debugId}) {
    if (!enable) return;
    _postDataChanged(debugId, null);
  }
}
