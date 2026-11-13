"""Packet IDs (gophertunnel `packet/id.go`)."""

comptime ID_LOGIN: UInt32 = 1
"""ID of `Login`."""
comptime ID_PLAY_STATUS: UInt32 = 2
"""ID of `PlayStatus`."""
comptime ID_SERVER_TO_CLIENT_HANDSHAKE: UInt32 = 3
"""ID of `ServerToClientHandshake`."""
comptime ID_CLIENT_TO_SERVER_HANDSHAKE: UInt32 = 4
"""ID of `ClientToServerHandshake`."""
comptime ID_DISCONNECT: UInt32 = 5
"""ID of `Disconnect`."""
comptime ID_RESOURCE_PACKS_INFO: UInt32 = 6
"""ID of `ResourcePacksInfo`."""
comptime ID_RESOURCE_PACK_STACK: UInt32 = 7
"""ID of `ResourcePackStack`."""
comptime ID_RESOURCE_PACK_CLIENT_RESPONSE: UInt32 = 8
"""ID of `ResourcePackClientResponse`."""
comptime ID_TEXT: UInt32 = 9
"""ID of `Text`."""
comptime ID_SET_TIME: UInt32 = 10
"""ID of `SetTime`."""
comptime ID_START_GAME: UInt32 = 11
"""ID of `StartGame`."""
comptime ID_ADD_PLAYER: UInt32 = 12
"""ID of `AddPlayer`."""
comptime ID_ADD_ACTOR: UInt32 = 13
"""ID of `AddActor`."""
comptime ID_REMOVE_ACTOR: UInt32 = 14
"""ID of `RemoveActor`."""
comptime ID_ADD_ITEM_ACTOR: UInt32 = 15
"""ID of `AddItemActor`."""
comptime ID_SERVER_PLAYER_POST_MOVE_POSITION: UInt32 = 16
"""ID of `ServerPlayerPostMovePosition`."""
comptime ID_TAKE_ITEM_ACTOR: UInt32 = 17
"""ID of `TakeItemActor`."""
comptime ID_MOVE_ACTOR_ABSOLUTE: UInt32 = 18
"""ID of `MoveActorAbsolute`."""
comptime ID_MOVE_PLAYER: UInt32 = 19
"""ID of `MovePlayer`."""
comptime ID_UPDATE_BLOCK: UInt32 = 21
"""ID of `UpdateBlock`."""
comptime ID_ADD_PAINTING: UInt32 = 22
"""ID of `AddPainting`."""
comptime ID_LEVEL_EVENT: UInt32 = 25
"""ID of `LevelEvent`."""
comptime ID_BLOCK_EVENT: UInt32 = 26
"""ID of `BlockEvent`."""
comptime ID_ACTOR_EVENT: UInt32 = 27
"""ID of `ActorEvent`."""
comptime ID_MOB_EFFECT: UInt32 = 28
"""ID of `MobEffect`."""
comptime ID_UPDATE_ATTRIBUTES: UInt32 = 29
"""ID of `UpdateAttributes`."""
comptime ID_INVENTORY_TRANSACTION: UInt32 = 30
"""ID of `InventoryTransaction`."""
comptime ID_MOB_EQUIPMENT: UInt32 = 31
"""ID of `MobEquipment`."""
comptime ID_MOB_ARMOUR_EQUIPMENT: UInt32 = 32
"""ID of `MobArmourEquipment`."""
comptime ID_INTERACT: UInt32 = 33
"""ID of `Interact`."""
comptime ID_BLOCK_PICK_REQUEST: UInt32 = 34
"""ID of `BlockPickRequest`."""
comptime ID_ACTOR_PICK_REQUEST: UInt32 = 35
"""ID of `ActorPickRequest`."""
comptime ID_PLAYER_ACTION: UInt32 = 36
"""ID of `PlayerAction`."""
comptime ID_HURT_ARMOUR: UInt32 = 38
"""ID of `HurtArmour`."""
comptime ID_SET_ACTOR_DATA: UInt32 = 39
"""ID of `SetActorData`."""
comptime ID_SET_ACTOR_MOTION: UInt32 = 40
"""ID of `SetActorMotion`."""
comptime ID_SET_ACTOR_LINK: UInt32 = 41
"""ID of `SetActorLink`."""
comptime ID_SET_HEALTH: UInt32 = 42
"""ID of `SetHealth`."""
comptime ID_SET_SPAWN_POSITION: UInt32 = 43
"""ID of `SetSpawnPosition`."""
comptime ID_ANIMATE: UInt32 = 44
"""ID of `Animate`."""
comptime ID_RESPAWN: UInt32 = 45
"""ID of `Respawn`."""
comptime ID_CONTAINER_OPEN: UInt32 = 46
"""ID of `ContainerOpen`."""
comptime ID_CONTAINER_CLOSE: UInt32 = 47
"""ID of `ContainerClose`."""
comptime ID_PLAYER_HOT_BAR: UInt32 = 48
"""ID of `PlayerHotBar`."""
comptime ID_INVENTORY_CONTENT: UInt32 = 49
"""ID of `InventoryContent`."""
comptime ID_INVENTORY_SLOT: UInt32 = 50
"""ID of `InventorySlot`."""
comptime ID_CONTAINER_SET_DATA: UInt32 = 51
"""ID of `ContainerSetData`."""
comptime ID_CRAFTING_DATA: UInt32 = 52
"""ID of `CraftingData`."""
comptime ID_GUI_DATA_PICK_ITEM: UInt32 = 54
"""ID of `GUIDataPickItem`."""
comptime ID_ADVENTURE_SETTINGS: UInt32 = 55
"""ID of `AdventureSettings`."""
comptime ID_BLOCK_ACTOR_DATA: UInt32 = 56
"""ID of `BlockActorData`."""
comptime ID_LEVEL_CHUNK: UInt32 = 58
"""ID of `LevelChunk`."""
comptime ID_SET_COMMANDS_ENABLED: UInt32 = 59
"""ID of `SetCommandsEnabled`."""
comptime ID_SET_DIFFICULTY: UInt32 = 60
"""ID of `SetDifficulty`."""
comptime ID_CHANGE_DIMENSION: UInt32 = 61
"""ID of `ChangeDimension`."""
comptime ID_SET_PLAYER_GAME_TYPE: UInt32 = 62
"""ID of `SetPlayerGameType`."""
comptime ID_PLAYER_LIST: UInt32 = 63
"""ID of `PlayerList`."""
comptime ID_SIMPLE_EVENT: UInt32 = 64
"""ID of `SimpleEvent`."""
comptime ID_EVENT: UInt32 = 65
"""ID of `Event`."""
comptime ID_SPAWN_EXPERIENCE_ORB: UInt32 = 66
"""ID of `SpawnExperienceOrb`."""
comptime ID_CLIENT_BOUND_MAP_ITEM_DATA: UInt32 = 67
"""ID of `ClientBoundMapItemData`."""
comptime ID_MAP_INFO_REQUEST: UInt32 = 68
"""ID of `MapInfoRequest`."""
comptime ID_REQUEST_CHUNK_RADIUS: UInt32 = 69
"""ID of `RequestChunkRadius`."""
comptime ID_CHUNK_RADIUS_UPDATED: UInt32 = 70
"""ID of `ChunkRadiusUpdated`."""
comptime ID_GAME_RULES_CHANGED: UInt32 = 72
"""ID of `GameRulesChanged`."""
comptime ID_CAMERA: UInt32 = 73
"""ID of `Camera`."""
comptime ID_BOSS_EVENT: UInt32 = 74
"""ID of `BossEvent`."""
comptime ID_SHOW_CREDITS: UInt32 = 75
"""ID of `ShowCredits`."""
comptime ID_AVAILABLE_COMMANDS: UInt32 = 76
"""ID of `AvailableCommands`."""
comptime ID_COMMAND_REQUEST: UInt32 = 77
"""ID of `CommandRequest`."""
comptime ID_COMMAND_BLOCK_UPDATE: UInt32 = 78
"""ID of `CommandBlockUpdate`."""
comptime ID_COMMAND_OUTPUT: UInt32 = 79
"""ID of `CommandOutput`."""
comptime ID_UPDATE_TRADE: UInt32 = 80
"""ID of `UpdateTrade`."""
comptime ID_UPDATE_EQUIP: UInt32 = 81
"""ID of `UpdateEquip`."""
comptime ID_RESOURCE_PACK_DATA_INFO: UInt32 = 82
"""ID of `ResourcePackDataInfo`."""
comptime ID_RESOURCE_PACK_CHUNK_DATA: UInt32 = 83
"""ID of `ResourcePackChunkData`."""
comptime ID_RESOURCE_PACK_CHUNK_REQUEST: UInt32 = 84
"""ID of `ResourcePackChunkRequest`."""
comptime ID_TRANSFER: UInt32 = 85
"""ID of `Transfer`."""
comptime ID_PLAY_SOUND: UInt32 = 86
"""ID of `PlaySound`."""
comptime ID_STOP_SOUND: UInt32 = 87
"""ID of `StopSound`."""
comptime ID_SET_TITLE: UInt32 = 88
"""ID of `SetTitle`."""
comptime ID_ADD_BEHAVIOUR_TREE: UInt32 = 89
"""ID of `AddBehaviourTree`."""
comptime ID_STRUCTURE_BLOCK_UPDATE: UInt32 = 90
"""ID of `StructureBlockUpdate`."""
comptime ID_SHOW_STORE_OFFER: UInt32 = 91
"""ID of `ShowStoreOffer`."""
comptime ID_PURCHASE_RECEIPT: UInt32 = 92
"""ID of `PurchaseReceipt`."""
comptime ID_PLAYER_SKIN: UInt32 = 93
"""ID of `PlayerSkin`."""
comptime ID_SUB_CLIENT_LOGIN: UInt32 = 94
"""ID of `SubClientLogin`."""
comptime ID_AUTOMATION_CLIENT_CONNECT: UInt32 = 95
"""ID of `AutomationClientConnect`."""
comptime ID_SET_LAST_HURT_BY: UInt32 = 96
"""ID of `SetLastHurtBy`."""
comptime ID_BOOK_EDIT: UInt32 = 97
"""ID of `BookEdit`."""
comptime ID_NPC_REQUEST: UInt32 = 98
"""ID of `NPCRequest`."""
comptime ID_PHOTO_TRANSFER: UInt32 = 99
"""ID of `PhotoTransfer`."""
comptime ID_MODAL_FORM_REQUEST: UInt32 = 100
"""ID of `ModalFormRequest`."""
comptime ID_MODAL_FORM_RESPONSE: UInt32 = 101
"""ID of `ModalFormResponse`."""
comptime ID_SERVER_SETTINGS_REQUEST: UInt32 = 102
"""ID of `ServerSettingsRequest`."""
comptime ID_SERVER_SETTINGS_RESPONSE: UInt32 = 103
"""ID of `ServerSettingsResponse`."""
comptime ID_SHOW_PROFILE: UInt32 = 104
"""ID of `ShowProfile`."""
comptime ID_SET_DEFAULT_GAME_TYPE: UInt32 = 105
"""ID of `SetDefaultGameType`."""
comptime ID_REMOVE_OBJECTIVE: UInt32 = 106
"""ID of `RemoveObjective`."""
comptime ID_SET_DISPLAY_OBJECTIVE: UInt32 = 107
"""ID of `SetDisplayObjective`."""
comptime ID_SET_SCORE: UInt32 = 108
"""ID of `SetScore`."""
comptime ID_LAB_TABLE: UInt32 = 109
"""ID of `LabTable`."""
comptime ID_UPDATE_BLOCK_SYNCED: UInt32 = 110
"""ID of `UpdateBlockSynced`."""
comptime ID_MOVE_ACTOR_DELTA: UInt32 = 111
"""ID of `MoveActorDelta`."""
comptime ID_SET_SCOREBOARD_IDENTITY: UInt32 = 112
"""ID of `SetScoreboardIdentity`."""
comptime ID_SET_LOCAL_PLAYER_AS_INITIALISED: UInt32 = 113
"""ID of `SetLocalPlayerAsInitialised`."""
comptime ID_UPDATE_SOFT_ENUM: UInt32 = 114
"""ID of `UpdateSoftEnum`."""
comptime ID_NETWORK_STACK_LATENCY: UInt32 = 115
"""ID of `NetworkStackLatency`."""
comptime ID_SCRIPT_CUSTOM_EVENT: UInt32 = 117
"""ID of `ScriptCustomEvent`."""
comptime ID_SPAWN_PARTICLE_EFFECT: UInt32 = 118
"""ID of `SpawnParticleEffect`."""
comptime ID_AVAILABLE_ACTOR_IDENTIFIERS: UInt32 = 119
"""ID of `AvailableActorIdentifiers`."""
comptime ID_NETWORK_CHUNK_PUBLISHER_UPDATE: UInt32 = 121
"""ID of `NetworkChunkPublisherUpdate`."""
comptime ID_BIOME_DEFINITION_LIST: UInt32 = 122
"""ID of `BiomeDefinitionList`."""
comptime ID_LEVEL_SOUND_EVENT: UInt32 = 123
"""ID of `LevelSoundEvent`."""
comptime ID_LEVEL_EVENT_GENERIC: UInt32 = 124
"""ID of `LevelEventGeneric`."""
comptime ID_LECTERN_UPDATE: UInt32 = 125
"""ID of `LecternUpdate`."""
comptime ID_CLIENT_CACHE_STATUS: UInt32 = 129
"""ID of `ClientCacheStatus`."""
comptime ID_ON_SCREEN_TEXTURE_ANIMATION: UInt32 = 130
"""ID of `OnScreenTextureAnimation`."""
comptime ID_MAP_CREATE_LOCKED_COPY: UInt32 = 131
"""ID of `MapCreateLockedCopy`."""
comptime ID_STRUCTURE_TEMPLATE_DATA_REQUEST: UInt32 = 132
"""ID of `StructureTemplateDataRequest`."""
comptime ID_STRUCTURE_TEMPLATE_DATA_RESPONSE: UInt32 = 133
"""ID of `StructureTemplateDataResponse`."""
comptime ID_CLIENT_CACHE_BLOB_STATUS: UInt32 = 135
"""ID of `ClientCacheBlobStatus`."""
comptime ID_CLIENT_CACHE_MISS_RESPONSE: UInt32 = 136
"""ID of `ClientCacheMissResponse`."""
comptime ID_EDUCATION_SETTINGS: UInt32 = 137
"""ID of `EducationSettings`."""
comptime ID_EMOTE: UInt32 = 138
"""ID of `Emote`."""
comptime ID_MULTI_PLAYER_SETTINGS: UInt32 = 139
"""ID of `MultiPlayerSettings`."""
comptime ID_SETTINGS_COMMAND: UInt32 = 140
"""ID of `SettingsCommand`."""
comptime ID_ANVIL_DAMAGE: UInt32 = 141
"""ID of `AnvilDamage`."""
comptime ID_COMPLETED_USING_ITEM: UInt32 = 142
"""ID of `CompletedUsingItem`."""
comptime ID_NETWORK_SETTINGS: UInt32 = 143
"""ID of `NetworkSettings`."""
comptime ID_PLAYER_AUTH_INPUT: UInt32 = 144
"""ID of `PlayerAuthInput`."""
comptime ID_CREATIVE_CONTENT: UInt32 = 145
"""ID of `CreativeContent`."""
comptime ID_PLAYER_ENCHANT_OPTIONS: UInt32 = 146
"""ID of `PlayerEnchantOptions`."""
comptime ID_ITEM_STACK_REQUEST: UInt32 = 147
"""ID of `ItemStackRequest`."""
comptime ID_ITEM_STACK_RESPONSE: UInt32 = 148
"""ID of `ItemStackResponse`."""
comptime ID_PLAYER_ARMOUR_DAMAGE: UInt32 = 149
"""ID of `PlayerArmourDamage`."""
comptime ID_CODE_BUILDER: UInt32 = 150
"""ID of `CodeBuilder`."""
comptime ID_UPDATE_PLAYER_GAME_TYPE: UInt32 = 151
"""ID of `UpdatePlayerGameType`."""
comptime ID_EMOTE_LIST: UInt32 = 152
"""ID of `EmoteList`."""
comptime ID_POSITION_TRACKING_DB_SERVER_BROADCAST: UInt32 = 153
"""ID of `PositionTrackingDBServerBroadcast`."""
comptime ID_POSITION_TRACKING_DB_CLIENT_REQUEST: UInt32 = 154
"""ID of `PositionTrackingDBClientRequest`."""
comptime ID_DEBUG_INFO: UInt32 = 155
"""ID of `DebugInfo`."""
comptime ID_PACKET_VIOLATION_WARNING: UInt32 = 156
"""ID of `PacketViolationWarning`."""
comptime ID_MOTION_PREDICTION_HINTS: UInt32 = 157
"""ID of `MotionPredictionHints`."""
comptime ID_ANIMATE_ENTITY: UInt32 = 158
"""ID of `AnimateEntity`."""
comptime ID_CAMERA_SHAKE: UInt32 = 159
"""ID of `CameraShake`."""
comptime ID_PLAYER_FOG: UInt32 = 160
"""ID of `PlayerFog`."""
comptime ID_CORRECT_PLAYER_MOVE_PREDICTION: UInt32 = 161
"""ID of `CorrectPlayerMovePrediction`."""
comptime ID_ITEM_REGISTRY: UInt32 = 162
"""ID of `ItemRegistry`."""
comptime ID_FILTER_TEXT: UInt32 = 163
"""ID of `FilterText`."""
comptime ID_CLIENT_BOUND_DEBUG_RENDERER: UInt32 = 164
"""ID of `ClientBoundDebugRenderer`."""
comptime ID_SYNC_ACTOR_PROPERTY: UInt32 = 165
"""ID of `SyncActorProperty`."""
comptime ID_ADD_VOLUME_ENTITY: UInt32 = 166
"""ID of `AddVolumeEntity`."""
comptime ID_REMOVE_VOLUME_ENTITY: UInt32 = 167
"""ID of `RemoveVolumeEntity`."""
comptime ID_SIMULATION_TYPE: UInt32 = 168
"""ID of `SimulationType`."""
comptime ID_NPC_DIALOGUE: UInt32 = 169
"""ID of `NPCDialogue`."""
comptime ID_EDUCATION_RESOURCE_URI: UInt32 = 170
"""ID of `EducationResourceURI`."""
comptime ID_CREATE_PHOTO: UInt32 = 171
"""ID of `CreatePhoto`."""
comptime ID_UPDATE_SUB_CHUNK_BLOCKS: UInt32 = 172
"""ID of `UpdateSubChunkBlocks`."""
comptime ID_PHOTO_INFO_REQUEST: UInt32 = 173
"""ID of `PhotoInfoRequest`."""
comptime ID_SUB_CHUNK: UInt32 = 174
"""ID of `SubChunk`."""
comptime ID_SUB_CHUNK_REQUEST: UInt32 = 175
"""ID of `SubChunkRequest`."""
comptime ID_CLIENT_START_ITEM_COOLDOWN: UInt32 = 176
"""ID of `ClientStartItemCooldown`."""
comptime ID_SCRIPT_MESSAGE: UInt32 = 177
"""ID of `ScriptMessage`."""
comptime ID_CODE_BUILDER_SOURCE: UInt32 = 178
"""ID of `CodeBuilderSource`."""
comptime ID_TICKING_AREAS_LOAD_STATUS: UInt32 = 179
"""ID of `TickingAreasLoadStatus`."""
comptime ID_DIMENSION_DATA: UInt32 = 180
"""ID of `DimensionData`."""
comptime ID_AGENT_ACTION: UInt32 = 181
"""ID of `AgentAction`."""
comptime ID_CHANGE_MOB_PROPERTY: UInt32 = 182
"""ID of `ChangeMobProperty`."""
comptime ID_LESSON_PROGRESS: UInt32 = 183
"""ID of `LessonProgress`."""
comptime ID_REQUEST_ABILITY: UInt32 = 184
"""ID of `RequestAbility`."""
comptime ID_REQUEST_PERMISSIONS: UInt32 = 185
"""ID of `RequestPermissions`."""
comptime ID_TOAST_REQUEST: UInt32 = 186
"""ID of `ToastRequest`."""
comptime ID_UPDATE_ABILITIES: UInt32 = 187
"""ID of `UpdateAbilities`."""
comptime ID_UPDATE_ADVENTURE_SETTINGS: UInt32 = 188
"""ID of `UpdateAdventureSettings`."""
comptime ID_DEATH_INFO: UInt32 = 189
"""ID of `DeathInfo`."""
comptime ID_EDITOR_NETWORK: UInt32 = 190
"""ID of `EditorNetwork`."""
comptime ID_FEATURE_REGISTRY: UInt32 = 191
"""ID of `FeatureRegistry`."""
comptime ID_SERVER_STATS: UInt32 = 192
"""ID of `ServerStats`."""
comptime ID_REQUEST_NETWORK_SETTINGS: UInt32 = 193
"""ID of `RequestNetworkSettings`."""
comptime ID_GAME_TEST_REQUEST: UInt32 = 194
"""ID of `GameTestRequest`."""
comptime ID_GAME_TEST_RESULTS: UInt32 = 195
"""ID of `GameTestResults`."""
comptime ID_UPDATE_CLIENT_INPUT_LOCKS: UInt32 = 196
"""ID of `UpdateClientInputLocks`."""
comptime ID_CLIENT_CHEAT_ABILITY: UInt32 = 197
"""ID of `ClientCheatAbility`."""
comptime ID_CAMERA_PRESETS: UInt32 = 198
"""ID of `CameraPresets`."""
comptime ID_UNLOCKED_RECIPES: UInt32 = 199
"""ID of `UnlockedRecipes`."""
comptime ID_CAMERA_INSTRUCTION: UInt32 = 300
"""ID of `CameraInstruction`."""
comptime ID_TRIM_DATA: UInt32 = 302
"""ID of `TrimData`."""
comptime ID_OPEN_SIGN: UInt32 = 303
"""ID of `OpenSign`."""
comptime ID_AGENT_ANIMATION: UInt32 = 304
"""ID of `AgentAnimation`."""
comptime ID_REFRESH_ENTITLEMENTS: UInt32 = 305
"""ID of `RefreshEntitlements`."""
comptime ID_PLAYER_TOGGLE_CRAFTER_SLOT_REQUEST: UInt32 = 306
"""ID of `PlayerToggleCrafterSlotRequest`."""
comptime ID_SET_PLAYER_INVENTORY_OPTIONS: UInt32 = 307
"""ID of `SetPlayerInventoryOptions`."""
comptime ID_SET_HUD: UInt32 = 308
"""ID of `SetHud`."""
comptime ID_AWARD_ACHIEVEMENT: UInt32 = 309
"""ID of `AwardAchievement`."""
comptime ID_CLIENT_BOUND_CLOSE_FORM: UInt32 = 310
"""ID of `ClientBoundCloseForm`."""
comptime ID_SERVER_BOUND_LOADING_SCREEN: UInt32 = 312
"""ID of `ServerBoundLoadingScreen`."""
comptime ID_JIGSAW_STRUCTURE_DATA: UInt32 = 313
"""ID of `JigsawStructureData`."""
comptime ID_CURRENT_STRUCTURE_FEATURE: UInt32 = 314
"""ID of `CurrentStructureFeature`."""
comptime ID_SERVER_BOUND_DIAGNOSTICS: UInt32 = 315
"""ID of `ServerBoundDiagnostics`."""
comptime ID_CAMERA_AIM_ASSIST: UInt32 = 316
"""ID of `CameraAimAssist`."""
comptime ID_CONTAINER_REGISTRY_CLEANUP: UInt32 = 317
"""ID of `ContainerRegistryCleanup`."""
comptime ID_MOVEMENT_EFFECT: UInt32 = 318
"""ID of `MovementEffect`."""
comptime ID_CAMERA_AIM_ASSIST_PRESETS: UInt32 = 320
"""ID of `CameraAimAssistPresets`."""
comptime ID_CLIENT_CAMERA_AIM_ASSIST: UInt32 = 321
"""ID of `ClientCameraAimAssist`."""
comptime ID_CLIENT_MOVEMENT_PREDICTION_SYNC: UInt32 = 322
"""ID of `ClientMovementPredictionSync`."""
comptime ID_UPDATE_CLIENT_OPTIONS: UInt32 = 323
"""ID of `UpdateClientOptions`."""
comptime ID_PLAYER_VIDEO_CAPTURE: UInt32 = 324
"""ID of `PlayerVideoCapture`."""
comptime ID_PLAYER_UPDATE_ENTITY_OVERRIDES: UInt32 = 325
"""ID of `PlayerUpdateEntityOverrides`."""
comptime ID_PLAYER_LOCATION: UInt32 = 326
"""ID of `PlayerLocation`."""
comptime ID_CLIENT_BOUND_CONTROL_SCHEME_SET: UInt32 = 327
"""ID of `ClientBoundControlSchemeSet`."""
comptime ID_PRIMITIVE_SHAPES: UInt32 = 328
"""ID of `PrimitiveShapes`."""
comptime ID_SERVER_BOUND_PACK_SETTING_CHANGE: UInt32 = 329
"""ID of `ServerBoundPackSettingChange`."""
comptime ID_CLIENT_BOUND_DATA_STORE: UInt32 = 330
"""ID of `ClientBoundDataStore`."""
comptime ID_GRAPHICS_OVERRIDE_PARAMETER: UInt32 = 331
"""ID of `GraphicsOverrideParameter`."""
comptime ID_SERVER_BOUND_DATA_STORE: UInt32 = 332
"""ID of `ServerBoundDataStore`."""
comptime ID_CLIENT_BOUND_DATA_DRIVEN_UI_SHOW_SCREEN: UInt32 = 333
"""ID of `ClientBoundDataDrivenUIShowScreen`."""
comptime ID_CLIENT_BOUND_DATA_DRIVEN_UI_CLOSE_SCREEN: UInt32 = 334
"""ID of `ClientBoundDataDrivenUICloseScreen`."""
comptime ID_CLIENT_BOUND_DATA_DRIVEN_UI_RELOAD: UInt32 = 335
"""ID of `ClientBoundDataDrivenUIReload`."""
comptime ID_CLIENT_BOUND_TEXTURE_SHIFT: UInt32 = 336
"""ID of `ClientBoundTextureShift`."""
comptime ID_VOXEL_SHAPES: UInt32 = 337
"""ID of `VoxelShapes`."""
comptime ID_CAMERA_SPLINE: UInt32 = 338
"""ID of `CameraSpline`."""
comptime ID_CAMERA_AIM_ASSIST_ACTOR_PRIORITY: UInt32 = 339
"""ID of `CameraAimAssistActorPriority`."""
comptime ID_RESOURCE_PACKS_READY_FOR_VALIDATION: UInt32 = 340
"""ID of `ResourcePacksReadyForValidation`."""
comptime ID_LOCATOR_BAR: UInt32 = 341
"""ID of `LocatorBar`."""
comptime ID_PARTY_CHANGED: UInt32 = 342
"""ID of `PartyChanged`."""
comptime ID_SERVER_BOUND_DATA_DRIVEN_SCREEN_CLOSED: UInt32 = 343
"""ID of `ServerBoundDataDrivenScreenClosed`."""
comptime ID_SYNC_WORLD_CLOCKS: UInt32 = 344
"""ID of `SyncWorldClocks`."""
comptime ID_CLIENT_BOUND_ATTRIBUTE_LAYER_SYNC: UInt32 = 345
"""ID of `ClientBoundAttributeLayerSync`."""
comptime ID_SERVER_STORE_INFO: UInt32 = 346
"""ID of `ServerStoreInfo`."""
comptime ID_SERVER_PRESENCE_INFO: UInt32 = 347
"""ID of `ServerPresenceInfo`."""
comptime ID_CLIENTBOUND_UPDATE_SOUND_DATA: UInt32 = 348
"""ID of `ClientboundUpdateSoundData`."""
comptime ID_SEND_PARTY_DESTINATION_COOKIE: UInt32 = 349
"""ID of `SendPartyDestinationCookie`."""
comptime ID_PARTY_DESTINATION_COOKIE_RESPONSE: UInt32 = 350
"""ID of `PartyDestinationCookieResponse`."""
comptime ID_SET_PLAYER_FURNACE_OPTIONS: UInt32 = 351
"""ID of `SetPlayerFurnaceOptions`."""
comptime ID_RECORD_STARTED: UInt32 = 352
"""ID of `RecordStarted`."""
comptime ID_CLIENTBOUND_MATCHMAKING_STATE: UInt32 = 353
"""ID of `ClientboundMatchmakingState`."""
comptime ID_SERVERBOUND_STONECUTTER_SET_RECIPE: UInt32 = 354
"""ID of `ServerboundStonecutterSetRecipe`."""
comptime ID_CLIENTBOUND_STONECUTTER_SET_RECIPE: UInt32 = 355
"""ID of `ClientboundStonecutterSetRecipe`."""
comptime ID_SERVERBOUND_MATCHMAKING_CANCEL: UInt32 = 356
"""ID of `ServerboundMatchmakingCancel`."""
comptime ID_SET_PASSENGER_OF_BLOCK: UInt32 = 357
"""ID of `SetPassengerOfBlock`."""
comptime ID_SERVERBOUND_CURSOR_ITEM_DRAG: UInt32 = 358
"""ID of `ServerboundCursorItemDrag`."""
comptime ID_CLIENTBOUND_PLAY_AUDIO_CONTENT: UInt32 = 359
"""ID of `ClientboundPlayAudioContent`."""
comptime ID_SERVERBOUND_REGISTER_AUDIO_CONTENT: UInt32 = 360
"""ID of `ServerboundRegisterAudioContent`."""
