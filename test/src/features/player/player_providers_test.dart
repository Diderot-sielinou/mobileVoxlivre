import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voxlivre/src/features/player/application/clear_positions.dart';
import 'package:voxlivre/src/features/player/application/load_parts.dart';
import 'package:voxlivre/src/features/player/application/open_book.dart';
import 'package:voxlivre/src/features/player/application/save_position.dart';
import 'package:voxlivre/src/features/player/infrastructure/api_player_gateway.dart';
import 'package:voxlivre/src/features/player/infrastructure/drift_position_store.dart';
import 'package:voxlivre/src/features/player/infrastructure/player_database.dart';
import 'package:voxlivre/src/features/player/player_providers.dart';
import 'package:voxlivre/src/shared/http/http_providers.dart';

import '../../../helpers/fake_http.dart';

void main() {
  test('la composition relie base, API et cas d’usage', () {
    final db = PlayerDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [
        playerDatabaseProvider.overrideWithValue(db),
        apiClientProvider.overrideWithValue(
          FakeHttp((_) => reply(200)).client(),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(positionStoreProvider), isA<DriftPositionStore>());
    expect(container.read(playerGatewayProvider), isA<ApiPlayerGateway>());
    expect(container.read(loadPartsProvider), isA<LoadParts>());
    expect(container.read(openBookProvider), isA<OpenBook>());
    expect(container.read(savePositionProvider), isA<SavePosition>());
    expect(container.read(clearPositionsProvider), isA<ClearPositions>());
  });
}
