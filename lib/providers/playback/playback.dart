library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../models/playback_sync_payload.dart';
import '../../models/slide_elements.dart';
import '../../models/style_file.dart';
import '../../models/sub_file.dart';
import '../../services/playback_sync_service.dart';
import '../../services/sub_io.dart';
import '../../services/undo_stack.dart';
import '../order_provider.dart';
import '../settings_provider.dart';
import '../style_provider.dart';

part 'playback_state.dart';
part 'playback_notifier.dart';
part 'playback_slide_ops.dart';
part 'playback_editor_ops.dart';
part 'editor_notifier.dart';
part 'slide_element_style.dart';

final subIoProvider = Provider<SubIo>((ref) => SubIo());

const _uuid = Uuid();

final playbackProvider =
    NotifierProvider<PlaybackNotifier, PlaybackState>(PlaybackNotifier.new);

final editorProvider =
    NotifierProvider<EditorNotifier, EditorState>(EditorNotifier.new);
