"""The `Disconnect` packet (gophertunnel `packet/disconnect.go`)."""

from ..io import IO
from .id import ID_DISCONNECT
from .packet import Packet

comptime DISCONNECT_REASON_UNKNOWN: Int32 = 0
"""Go `DisconnectReasonUnknown`."""
comptime DISCONNECT_REASON_CANT_CONNECT_NO_INTERNET: Int32 = 1
"""Go `DisconnectReasonCantConnectNoInternet`."""
comptime DISCONNECT_REASON_NO_PERMISSIONS: Int32 = 2
"""Go `DisconnectReasonNoPermissions`."""
comptime DISCONNECT_REASON_UNRECOVERABLE_ERROR: Int32 = 3
"""Go `DisconnectReasonUnrecoverableError`."""
comptime DISCONNECT_REASON_THIRD_PARTY_BLOCKED: Int32 = 4
"""Go `DisconnectReasonThirdPartyBlocked`."""
comptime DISCONNECT_REASON_THIRD_PARTY_NO_INTERNET: Int32 = 5
"""Go `DisconnectReasonThirdPartyNoInternet`."""
comptime DISCONNECT_REASON_THIRD_PARTY_BAD_IP: Int32 = 6
"""Go `DisconnectReasonThirdPartyBadIP`."""
comptime DISCONNECT_REASON_THIRD_PARTY_NO_SERVER_OR_SERVER_LOCKED: Int32 = 7
"""Go `DisconnectReasonThirdPartyNoServerOrServerLocked`."""
comptime DISCONNECT_REASON_VERSION_MISMATCH: Int32 = 8
"""Go `DisconnectReasonVersionMismatch`."""
comptime DISCONNECT_REASON_SKIN_ISSUE: Int32 = 9
"""Go `DisconnectReasonSkinIssue`."""
comptime DISCONNECT_REASON_INVITE_SESSION_NOT_FOUND: Int32 = 10
"""Go `DisconnectReasonInviteSessionNotFound`."""
comptime DISCONNECT_REASON_EDU_LEVEL_SETTINGS_MISSING: Int32 = 11
"""Go `DisconnectReasonEduLevelSettingsMissing`."""
comptime DISCONNECT_REASON_LOCAL_SERVER_NOT_FOUND: Int32 = 12
"""Go `DisconnectReasonLocalServerNotFound`."""
comptime DISCONNECT_REASON_LEGACY_DISCONNECT: Int32 = 13
"""Go `DisconnectReasonLegacyDisconnect`."""
comptime DISCONNECT_REASON_USER_LEAVE_GAME_ATTEMPTED: Int32 = 14
"""Go `DisconnectReasonUserLeaveGameAttempted`."""
comptime DISCONNECT_REASON_PLATFORM_LOCKED_SKINS_ERROR: Int32 = 15
"""Go `DisconnectReasonPlatformLockedSkinsError`."""
comptime DISCONNECT_REASON_REALMS_WORLD_UNASSIGNED: Int32 = 16
"""Go `DisconnectReasonRealmsWorldUnassigned`."""
comptime DISCONNECT_REASON_REALMS_SERVER_CANT_CONNECT: Int32 = 17
"""Go `DisconnectReasonRealmsServerCantConnect`."""
comptime DISCONNECT_REASON_REALMS_SERVER_HIDDEN: Int32 = 18
"""Go `DisconnectReasonRealmsServerHidden`."""
comptime DISCONNECT_REASON_REALMS_SERVER_DISABLED_BETA: Int32 = 19
"""Go `DisconnectReasonRealmsServerDisabledBeta`."""
comptime DISCONNECT_REASON_REALMS_SERVER_DISABLED: Int32 = 20
"""Go `DisconnectReasonRealmsServerDisabled`."""
comptime DISCONNECT_REASON_CROSS_PLATFORM_DISABLED: Int32 = 21
"""Go `DisconnectReasonCrossPlatformDisabled`."""
comptime DISCONNECT_REASON_CANT_CONNECT: Int32 = 22
"""Go `DisconnectReasonCantConnect`."""
comptime DISCONNECT_REASON_SESSION_NOT_FOUND: Int32 = 23
"""Go `DisconnectReasonSessionNotFound`."""
comptime DISCONNECT_REASON_SERVER_FULL: Int32 = 24
"""Go `DisconnectReasonServerFull`."""
comptime DISCONNECT_REASON_INVALID_PLATFORM_SKIN: Int32 = 25
"""Go `DisconnectReasonInvalidPlatformSkin`."""
comptime DISCONNECT_REASON_EDITION_VERSION_MISMATCH: Int32 = 26
"""Go `DisconnectReasonEditionVersionMismatch`."""
comptime DISCONNECT_REASON_EDITION_MISMATCH: Int32 = 27
"""Go `DisconnectReasonEditionMismatch`."""
comptime DISCONNECT_REASON_LEVEL_NEWER_THAN_EXE_VERSION: Int32 = 28
"""Go `DisconnectReasonLevelNewerThanExeVersion`."""
comptime DISCONNECT_REASON_NO_FAIL_OCCURRED: Int32 = 29
"""Go `DisconnectReasonNoFailOccurred`."""
comptime DISCONNECT_REASON_BANNED_SKIN: Int32 = 30
"""Go `DisconnectReasonBannedSkin`."""
comptime DISCONNECT_REASON_TIMEOUT: Int32 = 31
"""Go `DisconnectReasonTimeout`."""
comptime DISCONNECT_REASON_SERVER_NOT_FOUND: Int32 = 32
"""Go `DisconnectReasonServerNotFound`."""
comptime DISCONNECT_REASON_OUTDATED_SERVER: Int32 = 33
"""Go `DisconnectReasonOutdatedServer`."""
comptime DISCONNECT_REASON_OUTDATED_CLIENT: Int32 = 34
"""Go `DisconnectReasonOutdatedClient`."""
comptime DISCONNECT_REASON_MULTIPLAYER_DISABLED: Int32 = 35
"""Go `DisconnectReasonMultiplayerDisabled`."""
comptime DISCONNECT_REASON_NO_WI_FI: Int32 = 36
"""Go `DisconnectReasonNoWiFi`."""
comptime DISCONNECT_REASON_NO_REASON: Int32 = 37
"""Go `DisconnectReasonNoReason`."""
comptime DISCONNECT_REASON_DISCONNECTED: Int32 = 38
"""Go `DisconnectReasonDisconnected`."""
comptime DISCONNECT_REASON_INVALID_PLAYER: Int32 = 39
"""Go `DisconnectReasonInvalidPlayer`."""
comptime DISCONNECT_REASON_LOGGED_IN_OTHER_LOCATION: Int32 = 40
"""Go `DisconnectReasonLoggedInOtherLocation`."""
comptime DISCONNECT_REASON_SERVER_ID_CONFLICT: Int32 = 41
"""Go `DisconnectReasonServerIdConflict`."""
comptime DISCONNECT_REASON_NOT_ALLOWED: Int32 = 42
"""Go `DisconnectReasonNotAllowed`."""
comptime DISCONNECT_REASON_NOT_AUTHENTICATED: Int32 = 43
"""Go `DisconnectReasonNotAuthenticated`."""
comptime DISCONNECT_REASON_INVALID_TENANT: Int32 = 44
"""Go `DisconnectReasonInvalidTenant`."""
comptime DISCONNECT_REASON_UNKNOWN_PACKET: Int32 = 45
"""Go `DisconnectReasonUnknownPacket`."""
comptime DISCONNECT_REASON_UNEXPECTED_PACKET: Int32 = 46
"""Go `DisconnectReasonUnexpectedPacket`."""
comptime DISCONNECT_REASON_INVALID_COMMAND_REQUEST_PACKET: Int32 = 47
"""Go `DisconnectReasonInvalidCommandRequestPacket`."""
comptime DISCONNECT_REASON_HOST_SUSPENDED: Int32 = 48
"""Go `DisconnectReasonHostSuspended`."""
comptime DISCONNECT_REASON_LOGIN_PACKET_NO_REQUEST: Int32 = 49
"""Go `DisconnectReasonLoginPacketNoRequest`."""
comptime DISCONNECT_REASON_LOGIN_PACKET_NO_CERT: Int32 = 50
"""Go `DisconnectReasonLoginPacketNoCert`."""
comptime DISCONNECT_REASON_MISSING_CLIENT: Int32 = 51
"""Go `DisconnectReasonMissingClient`."""
comptime DISCONNECT_REASON_KICKED: Int32 = 52
"""Go `DisconnectReasonKicked`."""
comptime DISCONNECT_REASON_KICKED_FOR_EXPLOIT: Int32 = 53
"""Go `DisconnectReasonKickedForExploit`."""
comptime DISCONNECT_REASON_KICKED_FOR_IDLE: Int32 = 54
"""Go `DisconnectReasonKickedForIdle`."""
comptime DISCONNECT_REASON_RESOURCE_PACK_PROBLEM: Int32 = 55
"""Go `DisconnectReasonResourcePackProblem`."""
comptime DISCONNECT_REASON_INCOMPATIBLE_PACK: Int32 = 56
"""Go `DisconnectReasonIncompatiblePack`."""
comptime DISCONNECT_REASON_OUT_OF_STORAGE: Int32 = 57
"""Go `DisconnectReasonOutOfStorage`."""
comptime DISCONNECT_REASON_INVALID_LEVEL: Int32 = 58
"""Go `DisconnectReasonInvalidLevel`."""
comptime DISCONNECT_REASON_BLOCK_MISMATCH: Int32 = 59
"""Go `DisconnectReasonBlockMismatch`."""
comptime DISCONNECT_REASON_INVALID_HEIGHTS: Int32 = 60
"""Go `DisconnectReasonInvalidHeights`."""
comptime DISCONNECT_REASON_INVALID_WIDTHS: Int32 = 61
"""Go `DisconnectReasonInvalidWidths`."""
comptime DISCONNECT_REASON_SHUTDOWN: Int32 = 62
"""Go `DisconnectReasonShutdown`."""
comptime DISCONNECT_REASON_LOADING_STATE_TIMEOUT: Int32 = 63
"""Go `DisconnectReasonLoadingStateTimeout`."""
comptime DISCONNECT_REASON_RESOURCE_PACK_LOADING_FAILED: Int32 = 64
"""Go `DisconnectReasonResourcePackLoadingFailed`."""
comptime DISCONNECT_REASON_SEARCHING_FOR_SESSION_LOADING_SCREEN_FAILED: Int32 = 65
"""Go `DisconnectReasonSearchingForSessionLoadingScreenFailed`."""
comptime DISCONNECT_REASON_NETHER_NET_PROTOCOL_VERSION: Int32 = 66
"""Go `DisconnectReasonNetherNetProtocolVersion`."""
comptime DISCONNECT_REASON_SUBSYSTEM_STATUS_ERROR: Int32 = 67
"""Go `DisconnectReasonSubsystemStatusError`."""
comptime DISCONNECT_REASON_EMPTY_AUTH_FROM_DISCOVERY: Int32 = 68
"""Go `DisconnectReasonEmptyAuthFromDiscovery`."""
comptime DISCONNECT_REASON_EMPTY_URL_FROM_DISCOVERY: Int32 = 69
"""Go `DisconnectReasonEmptyUrlFromDiscovery`."""
comptime DISCONNECT_REASON_EXPIRED_AUTH_FROM_DISCOVERY: Int32 = 70
"""Go `DisconnectReasonExpiredAuthFromDiscovery`."""
comptime DISCONNECT_REASON_UNKNOWN_SIGNAL_SERVICE_SIGN_IN_FAILURE: Int32 = 71
"""Go `DisconnectReasonUnknownSignalServiceSignInFailure`."""
comptime DISCONNECT_REASON_XBL_JOIN_LOBBY_FAILURE: Int32 = 72
"""Go `DisconnectReasonXBLJoinLobbyFailure`."""
comptime DISCONNECT_REASON_UNSPECIFIED_CLIENT_INSTANCE_DISCONNECTION: Int32 = 73
"""Go `DisconnectReasonUnspecifiedClientInstanceDisconnection`."""
comptime DISCONNECT_REASON_NETHER_NET_SESSION_NOT_FOUND: Int32 = 74
"""Go `DisconnectReasonNetherNetSessionNotFound`."""
comptime DISCONNECT_REASON_NETHER_NET_CREATE_PEER_CONNECTION: Int32 = 75
"""Go `DisconnectReasonNetherNetCreatePeerConnection`."""
comptime DISCONNECT_REASON_NETHER_NET_ICE: Int32 = 76
"""Go `DisconnectReasonNetherNetICE`."""
comptime DISCONNECT_REASON_NETHER_NET_CONNECT_REQUEST: Int32 = 77
"""Go `DisconnectReasonNetherNetConnectRequest`."""
comptime DISCONNECT_REASON_NETHER_NET_CONNECT_RESPONSE: Int32 = 78
"""Go `DisconnectReasonNetherNetConnectResponse`."""
comptime DISCONNECT_REASON_NETHER_NET_NEGOTIATION_TIMEOUT: Int32 = 79
"""Go `DisconnectReasonNetherNetNegotiationTimeout`."""
comptime DISCONNECT_REASON_NETHER_NET_INACTIVITY_TIMEOUT: Int32 = 80
"""Go `DisconnectReasonNetherNetInactivityTimeout`."""
comptime DISCONNECT_REASON_STALE_CONNECTION_BEING_REPLACED: Int32 = 81
"""Go `DisconnectReasonStaleConnectionBeingReplaced`."""
comptime DISCONNECT_REASON_BAD_PACKET: Int32 = 82
"""Go `DisconnectReasonBadPacket`."""
comptime DISCONNECT_REASON_NETHER_NET_FAILED_TO_CREATE_OFFER: Int32 = 83
"""Go `DisconnectReasonNetherNetFailedToCreateOffer`."""
comptime DISCONNECT_REASON_NETHER_NET_FAILED_TO_CREATE_ANSWER: Int32 = 84
"""Go `DisconnectReasonNetherNetFailedToCreateAnswer`."""
comptime DISCONNECT_REASON_NETHER_NET_FAILED_TO_SET_LOCAL_DESCRIPTION: Int32 = 85
"""Go `DisconnectReasonNetherNetFailedToSetLocalDescription`."""
comptime DISCONNECT_REASON_NETHER_NET_FAILED_TO_SET_REMOTE_DESCRIPTION: Int32 = 86
"""Go `DisconnectReasonNetherNetFailedToSetRemoteDescription`."""
comptime DISCONNECT_REASON_NETHER_NET_NEGOTIATION_TIMEOUT_WAITING_FOR_RESPONSE: Int32 = 87
"""Go `DisconnectReasonNetherNetNegotiationTimeoutWaitingForResponse`."""
comptime DISCONNECT_REASON_NETHER_NET_NEGOTIATION_TIMEOUT_WAITING_FOR_ACCEPT: Int32 = 88
"""Go `DisconnectReasonNetherNetNegotiationTimeoutWaitingForAccept`."""
comptime DISCONNECT_REASON_NETHER_NET_INCOMING_CONNECTION_IGNORED: Int32 = 89
"""Go `DisconnectReasonNetherNetIncomingConnectionIgnored`."""
comptime DISCONNECT_REASON_NETHER_NET_SIGNALING_PARSING_FAILURE: Int32 = 90
"""Go `DisconnectReasonNetherNetSignalingParsingFailure`."""
comptime DISCONNECT_REASON_NETHER_NET_SIGNALING_UNKNOWN_ERROR: Int32 = 91
"""Go `DisconnectReasonNetherNetSignalingUnknownError`."""
comptime DISCONNECT_REASON_NETHER_NET_SIGNALING_UNICAST_DELIVERY_FAILED: Int32 = 92
"""Go `DisconnectReasonNetherNetSignalingUnicastDeliveryFailed`."""
comptime DISCONNECT_REASON_NETHER_NET_SIGNALING_BROADCAST_DELIVERY_FAILED: Int32 = 93
"""Go `DisconnectReasonNetherNetSignalingBroadcastDeliveryFailed`."""
comptime DISCONNECT_REASON_NETHER_NET_SIGNALING_GENERIC_DELIVERY_FAILED: Int32 = 94
"""Go `DisconnectReasonNetherNetSignalingGenericDeliveryFailed`."""
comptime DISCONNECT_REASON_EDITOR_MISMATCH_EDITOR_WORLD: Int32 = 95
"""Go `DisconnectReasonEditorMismatchEditorWorld`."""
comptime DISCONNECT_REASON_EDITOR_MISMATCH_VANILLA_WORLD: Int32 = 96
"""Go `DisconnectReasonEditorMismatchVanillaWorld`."""
comptime DISCONNECT_REASON_WORLD_TRANSFER_NOT_PRIMARY_CLIENT: Int32 = 97
"""Go `DisconnectReasonWorldTransferNotPrimaryClient`."""
comptime DISCONNECT_REASON_REQUEST_SERVER_SHUTDOWN: Int32 = 98
"""Go `DisconnectReasonRequestServerShutdown`."""
comptime DISCONNECT_REASON_CLIENT_GAME_SETUP_CANCELLED: Int32 = 99
"""Go `DisconnectReasonClientGameSetupCancelled`."""
comptime DISCONNECT_REASON_CLIENT_GAME_SETUP_FAILED: Int32 = 100
"""Go `DisconnectReasonClientGameSetupFailed`."""
comptime DISCONNECT_REASON_NETHER_NET_SIGNALING_SIGNIN_FAILED: Int32 = 101
"""Go `DisconnectReasonNetherNetSignalingSigninFailed`."""
comptime DISCONNECT_REASON_SESSION_ACCESS_DENIED: Int32 = 102
"""Go `DisconnectReasonSessionAccessDenied`."""
comptime DISCONNECT_REASON_SERVICE_SIGNIN_ISSUE: Int32 = 103
"""Go `DisconnectReasonServiceSigninIssue`."""
comptime DISCONNECT_REASON_NETHER_NET_NO_SIGNALING_CHANNEL: Int32 = 104
"""Go `DisconnectReasonNetherNetNoSignalingChannel`."""
comptime DISCONNECT_REASON_NETHER_NET_NOT_LOGGED_IN: Int32 = 105
"""Go `DisconnectReasonNetherNetNotLoggedIn`."""
comptime DISCONNECT_REASON_NETHER_NET_CLIENT_SIGNALING_ERROR: Int32 = 106
"""Go `DisconnectReasonNetherNetClientSignalingError`."""
comptime DISCONNECT_REASON_SUB_CLIENT_LOGIN_DISABLED: Int32 = 107
"""Go `DisconnectReasonSubClientLoginDisabled`."""
comptime DISCONNECT_REASON_DEEP_LINK_TRYING_TO_OPEN_DEMO_WORLD_WHILE_SIGNED_IN: Int32 = 108
"""Go `DisconnectReasonDeepLinkTryingToOpenDemoWorldWhileSignedIn`."""
comptime DISCONNECT_REASON_ASYNC_JOIN_TASK_DENIED: Int32 = 109
"""Go `DisconnectReasonAsyncJoinTaskDenied`."""
comptime DISCONNECT_REASON_REALMS_TIMELINE_REQUIRED: Int32 = 110
"""Go `DisconnectReasonRealmsTimelineRequired`."""
comptime DISCONNECT_REASON_GUEST_WITHOUT_HOST: Int32 = 111
"""Go `DisconnectReasonGuestWithoutHost`."""
comptime DISCONNECT_REASON_FAILED_TO_JOIN_EXPERIENCE: Int32 = 112
"""Go `DisconnectReasonFailedToJoinExperience`."""
comptime DISCONNECT_REASON_NETHER_NET_DATA_CHANNEL_CLOSED: Int32 = 113
"""Go `DisconnectReasonNetherNetDataChannelClosed`."""
comptime DISCONNECT_REASON_DISCOVERY_ENVIRONMENT_MISMATCH: Int32 = 114
"""Go `DisconnectReasonDiscoveryEnvironmentMismatch`."""
comptime DISCONNECT_REASON_HOST_WITHOUT_KEYS: Int32 = 115
"""Go `DisconnectReasonHostWithoutKeys`."""
comptime DISCONNECT_REASON_HOST_SIGNED_OUT: Int32 = 116
"""Go `DisconnectReasonHostSignedOut`."""
comptime DISCONNECT_REASON_SCRIPT_WATCHDOG_EXCEPTION: Int32 = 117
"""Go `DisconnectReasonScriptWatchdogException`."""
comptime DISCONNECT_REASON_SCRIPT_MEMORY_LIMIT_EXCEEDED: Int32 = 118
"""Go `DisconnectReasonScriptMemoryLimitExceeded`."""
comptime DISCONNECT_REASON_STORAGE_LOW_DURING_GAMEPLAY: Int32 = 119
"""Go `DisconnectReasonStorageLowDuringGameplay`."""
comptime DISCONNECT_REASON_STORAGE_FULL_DURING_GAMEPLAY: Int32 = 120
"""Go `DisconnectReasonStorageFullDuringGameplay`."""
comptime DISCONNECT_REASON_LEVEL_STORAGE_CORRUPTION: Int32 = 121
"""Go `DisconnectReasonLevelStorageCorruption`."""
comptime DISCONNECT_REASON_EDITION_MISMATCH_VANILLA_TO_EDU: Int32 = 122
"""Go `DisconnectReasonEditionMismatchVanillaToEdu`."""
comptime DISCONNECT_REASON_EDITION_MISMATCH_EDU_TO_VANILLA: Int32 = 123
"""Go `DisconnectReasonEditionMismatchEduToVanilla`."""
comptime DISCONNECT_REASON_EDITOR_MISMATCH_EDITOR_TO_VANILLA: Int32 = 124
"""Go `DisconnectReasonEditorMismatchEditorToVanilla`."""
comptime DISCONNECT_REASON_EDITOR_MISMATCH_VANILLA_TO_EDITOR: Int32 = 125
"""Go `DisconnectReasonEditorMismatchVanillaToEditor`."""
comptime DISCONNECT_REASON_DENY_LISTED: Int32 = 126
"""Go `DisconnectReasonDenyListed`."""
comptime DISCONNECT_REASON_NONCE_MISSING: Int32 = 127
"""Go `DisconnectReasonNonceMissing`."""
comptime DISCONNECT_REASON_NONCE_NOT_FOUND: Int32 = 128
"""Go `DisconnectReasonNonceNotFound`."""
comptime DISCONNECT_REASON_NONCE_EXPIRED: Int32 = 129
"""Go `DisconnectReasonNonceExpired`."""
comptime DISCONNECT_REASON_NONCE_NOT_VALID: Int32 = 130
"""Go `DisconnectReasonNonceNotValid`."""
comptime DISCONNECT_REASON_HOST_DISCONNECTED: Int32 = 131
"""Go `DisconnectReasonHostDisconnected`."""
comptime DISCONNECT_REASON_EDITOR_JOIN_INTENT_POLICY_FAILURE: Int32 = 132
"""Go `DisconnectReasonEditorJoinIntentPolicyFailure`."""
comptime DISCONNECT_REASON_NETHER_NET_IDENTITY_NOT_ALLOWED: Int32 = 133
"""Go `DisconnectReasonNetherNetIdentityNotAllowed`."""
comptime DISCONNECT_REASON_INVALID_NAME: Int32 = 134
"""Go `DisconnectReasonInvalidName`."""
comptime DISCONNECT_REASON_EXPIRED_TOKEN: Int32 = 135
"""Go `DisconnectReasonExpiredToken`."""
comptime DISCONNECT_REASON_HOST_ACCEPTS_NO_TYPE_OF_AUTH: Int32 = 136
"""Go `DisconnectReasonHostAcceptsNoTypeOfAuth`."""
comptime DISCONNECT_REASON_NOT_AUTHENTICATED_FAST_FAIL: Int32 = 137
"""Go `DisconnectReasonNotAuthenticatedFastFail`."""
comptime DISCONNECT_REASON_EDITOR_NOT_ALLOWED: Int32 = 138
"""Go `DisconnectReasonEditorNotAllowed`."""
comptime DISCONNECT_REASON_MISSING_STRUCTURE_DATA: Int32 = 139
"""Go `DisconnectReasonMissingStructureData`."""
comptime DISCONNECT_REASON_UNSUPPORTED_TRANSPORT: Int32 = 140
"""Go `DisconnectReasonUnsupportedTransport`."""
comptime DISCONNECT_REASON_SUB_CLIENT_LOGIN_NOT_BOUND: Int32 = 141
"""Go `DisconnectReasonSubClientLoginNotBound`."""


struct Disconnect(Packet):
    """Sent by either side before closing the connection."""

    comptime ID: UInt32 = ID_DISCONNECT
    """The packet ID."""
    var reason: Int32
    """The disconnect reason code."""
    var hide_disconnection_screen: Bool
    """Whether the client should skip the disconnection screen."""
    var message: String
    """The message shown on the disconnection screen."""
    var filtered_message: String
    """The profanity-filtered message."""

    def __init__(out self):
        """Creates the packet with every field empty."""
        self.reason = 0
        self.hide_disconnection_screen = False
        self.message = String()
        self.filtered_message = String()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.varint32(self.reason)
        io.bool(self.hide_disconnection_screen)
        if not self.hide_disconnection_screen:
            io.string(self.message)
            io.string(self.filtered_message)
