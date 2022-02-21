// ignore_for_file: implementation_imports

import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart' hide Animation, ClipPath;
import 'package:value_notifier/value_notifier.dart';
import 'package:value_notifier/src/idisposable_change_notifier.dart';
import 'package:value_notifier/src/handle.dart';

class StatusValueListenable extends IDisposableValueNotifier<AnimationStatus> {
  final AnimationController _controller;

  StatusValueListenable(this._controller) : super(_controller.status);

  bool _didListen = false;
  @override
  void addListener(VoidCallback listener) {
    if (!_didListen) {
      _controller.addStatusListener(_onStatus);
      _didListen = true;
    }
    super.addListener(listener);
  }

  void _onStatus(AnimationStatus status) => value = status;

  void dispose() {
    if (_didListen) {
      _controller.removeStatusListener(_onStatus);
    }
    super.dispose();
  }

  @override
  AnimationStatus get value => _didListen ? super.value : _controller.status;
}

class ListenableValueListenable extends IDisposableValueListenable<void>
    with IDisposableMixin {
  final ListenableHandle _base;

  ListenableValueListenable(Listenable base) : _base = ListenableHandle(base);
  @override
  void addListener(VoidCallback listener) => _base.addListener(listener);

  @override
  void removeListener(VoidCallback listener) => _base.removeListener(listener);

  void dispose() {
    _base.dispose();
    super.dispose();
  }

  @override
  void get value => null;
}

extension ListenableE on Listenable {
  ValueListenable<void> get asValueListenable =>
      ListenableValueListenable(this);
}

void ignore(Object _) {}
