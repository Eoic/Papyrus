import 'package:flutter_test/flutter_test.dart';
import 'package:papyrus/acquisition/acquisition_models.dart';
import 'package:papyrus/providers/acquisition_availability_provider.dart';

void main() {
  test('loads and caches enabled capability state by server', () async {
    final calls = <Uri>[];
    final provider = AcquisitionAvailabilityProvider(
      loadCapabilities: (serverBaseUri) async {
        calls.add(serverBaseUri);
        return const AcquisitionCapabilities(
          enabled: true,
          endpointKinds: [],
          indexerKinds: [],
          downloadClientKinds: [],
          arrKinds: [],
          arrCommands: {},
        );
      },
    );
    final server = Uri.parse('https://api.test');

    await provider.refresh(server);
    await provider.refresh(server);

    expect(provider.state, AcquisitionAvailabilityState.available);
    expect(provider.isAvailableFor(server), isTrue);
    expect(calls, [server]);
  });

  test('treats disabled, failed, and unknown servers as unavailable', () async {
    final provider = AcquisitionAvailabilityProvider(
      loadCapabilities: (_) async => const AcquisitionCapabilities(
        enabled: false,
        endpointKinds: [],
        indexerKinds: [],
        downloadClientKinds: [],
        arrKinds: [],
        arrCommands: {},
      ),
    );
    final server = Uri.parse('https://api.test');

    expect(provider.isAvailableFor(server), isFalse);

    await provider.refresh(server);

    expect(provider.state, AcquisitionAvailabilityState.unavailable);
    expect(provider.isAvailableFor(server), isFalse);
    expect(provider.isAvailableFor(Uri.parse('https://another.test')), isFalse);
  });
}
