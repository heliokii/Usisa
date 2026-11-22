import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:usisa/app.dart';
import 'package:usisa/features/history/history_store.dart';

/// A fake gateway that records every request and answers link checks with [destination].
class FakeGateway {
  FakeGateway({this.status = 'noMatch', this.destination = 'https://shopee.ph/sale'});
  final String status;
  final String destination;
  final requests = <http.Request>[];
  late final client = MockClient((r) async {
    requests.add(r);
    final body = r.url.path == '/healthz'
        ? {'status': 'ok'}
        : {
            'status': status,
            'threatTypes': status == 'matched' ? ['SOCIAL_ENGINEERING'] : [],
            'flaggedUrls': [],
            'checkedAt': DateTime.now().toUtc().toIso8601String(),
            'expiresAt': null,
            'provider': 'Google Safe Browsing',
            'expansion': 'expanded',
            'destination': destination,
            'hops': [destination],
          };
    return http.Response(jsonEncode(body), 200, headers: {'content-type': 'application/json'});
  });
  Iterable<http.Request> get linkChecks => requests.where((r) => r.url.path == '/v1/link-check');
  Iterable<http.Request> get pings => requests.where((r) => r.url.path == '/healthz');
}

MemoryStorage consented(bool allow) => MemoryStorage()
  ..values['settings'] = jsonEncode({'onlineConsentAsked': true, 'onlineLinkChecks': allow, 'onlineDisclosure': 2});

Future<void> startApp(WidgetTester tester, FakeGateway gateway, {MemoryStorage? storage}) async {
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(UsisaApp(storage: storage ?? MemoryStorage(), gatewayClient: gateway.client));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

Future<void> checkLink(WidgetTester tester, String link) async {
  await Scrollable.ensureVisible(tester.element(find.text('Check a link')), alignment: .5);
  await tester.pump();
  await tester.tap(find.text('Check a link'));
  await settle(tester);
  // Large text can push the field below the fold.
  await tester.ensureVisible(find.byType(TextField, skipOffstage: false));
  await tester.pump();
  await tester.enterText(find.byType(TextField), link);
  await tester.pump();
  await tester.tap(find.textContaining(RegExp(r'^Check (message|link|screenshot)$')));
  await settle(tester);
}

Future<void> goHome(WidgetTester tester) async {
  await tester.pageBack();
  await settle(tester);
  await tester.tap(find.text('Back to check'));
  await settle(tester);
}

void main() {
  testWidgets('first link check asks for consent once; allowing shows where the link really goes', (tester) async {
    final gateway = FakeGateway();
    await startApp(tester, gateway);
    await checkLink(tester, 'bit.ly/shopee-sale');

    expect(find.text('Check links online?'), findsOneWidget);
    expect(gateway.linkChecks, isEmpty);
    await tester.tap(find.text('Yes, check online'));
    await settle(tester);

    expect(gateway.linkChecks, hasLength(1));
    expect(find.text('Looks safe'), findsOneWidget);
    expect(find.text('Really goes to https://shopee.ph/sale'), findsOneWidget);
    expect(find.text('Checked on your phone'), findsNothing);

    await goHome(tester);
    await checkLink(tester, 'bit.ly/shopee-sale');
    expect(find.text('Check links online?'), findsNothing);
    expect(gateway.linkChecks, hasLength(2));
  });

  testWidgets('declining keeps checks on the phone and is not asked again', (tester) async {
    final gateway = FakeGateway();
    await startApp(tester, gateway);
    await checkLink(tester, 'bit.ly/shopee-sale');
    await tester.tap(find.text('No, phone only'));
    await settle(tester);

    expect(find.text('Checked on your phone'), findsOneWidget);
    await goHome(tester);
    await checkLink(tester, 'bit.ly/shopee-sale');
    expect(find.text('Check links online?'), findsNothing);
    expect(gateway.requests, isEmpty);
  });

  testWidgets('a flagged link is Dangerous and shows its real destination', (tester) async {
    final gateway = FakeGateway(status: 'matched', destination: 'https://gcash-verify-ph.xyz/login');
    await startApp(tester, gateway, storage: consented(true));
    await checkLink(tester, 'bit.ly/abc');

    expect(find.text('Dangerous'), findsOneWidget);
    expect(find.text('Google lists this link as unsafe'), findsOneWidget);
    expect(find.text('Really goes to https://gcash-verify-ph.xyz/login'), findsOneWidget);
  });

  testWidgets('the app pings /healthz once on open when online checks are on', (tester) async {
    final gateway = FakeGateway();
    await startApp(tester, gateway, storage: consented(true));
    expect(gateway.pings, hasLength(1));
    await tester.pump(const Duration(seconds: 5));
    expect(gateway.pings, hasLength(1));
  });

  testWidgets('no ping when online checks are off', (tester) async {
    final gateway = FakeGateway();
    await startApp(tester, gateway, storage: consented(false));
    expect(gateway.requests, isEmpty);
  });

  testWidgets('the consent screen lays out with 200% text', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await startApp(tester, FakeGateway());
    await checkLink(tester, 'bit.ly/abc');
    expect(tester.takeException(), isNull);
    await tester.dragUntilVisible(find.text('No, phone only'), find.byType(Scrollable).last, const Offset(0, -200));
    expect(tester.takeException(), isNull);
  });
}
