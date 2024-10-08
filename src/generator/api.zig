const TLID = enum(u32) {
    ProtoResPQ = 85337187,
    ProtoPQInnerDataDc = 2851430293,
    ProtoPQInnerDataTempDc = 1459478408,
    ProtoServerDHParamsOk = 3504867164,
    ProtoServerDHInnerData = 3045658042,
    ProtoClientDHInnerData = 1715713620,
    ProtoDhGenOk = 1003222836,
    ProtoDhGenRetry = 1188831161,
    ProtoDhGenFail = 2795351554,
    ProtoBindAuthKeyInner = 1973679973,
    ProtoRpcResult = 4082920705,
    ProtoRpcError = 558156313,
    ProtoRpcAnswerUnknown = 1579864942,
    ProtoRpcAnswerDroppedRunning = 3447252358,
    ProtoRpcAnswerDropped = 2755319991,
    ProtoFutureSalt = 155834844,
    ProtoPong = 880243653,
    ProtoDestroySessionOk = 3793765884,
    ProtoDestroySessionNone = 1658015945,
    ProtoNewSessionCreated = 2663516424,
    ProtoMessage = 3065852031,
    ProtoGzipPacked = 812830625,
    ProtoMsgsAck = 1658238041,
    ProtoBadMsgNotification = 2817521681,
    ProtoBadServerSalt = 3987424379,
    ProtoMsgResendReq = 2105940488,
    ProtoMsgsStateReq = 3664378706,
    ProtoMsgsStateInfo = 81704317,
    ProtoMsgsAllInfo = 2361446705,
    ProtoMsgDetailedInfo = 661470918,
    ProtoMsgNewDetailedInfo = 2157819615,
    ProtoDestroyAuthKeyOk = 4133544404,
    ProtoDestroyAuthKeyNone = 178201177,
    ProtoDestroyAuthKeyFail = 3926956819,
    ProtoHttpWait = 2459514271,
    ProtoReqDHParams = 3608339646,
    ProtoSetClientDHParams = 4110704415,
    ProtoRpcDropAnswer = 1491380032,
    ProtoGetFutureSalts = 3105996036,
    ProtoPing = 2059302892,
    ProtoPingDelayDisconnect = 4081220492,
    ProtoDestroySession = 3880853798,
    ProtoDestroyAuthKey = 3510849888,
    InputPeerEmpty = 2134579434,
    InputPeerSelf = 2107670217,
    InputPeerChat = 900291769,
    InputPeerUser = 3723011404,
    InputPeerChannel = 666680316,
    InputPeerUserFromMessage = 2826635804,
    InputPeerChannelFromMessage = 3173648448,
    InputUserEmpty = 3112732367,
    InputUserSelf = 4156666175,
    InputUser = 4061223110,
    InputUserFromMessage = 497305826,
    InputPhoneContact = 4086478836,
    InputFile = 4113560191,
    InputFileBig = 4199484341,
    InputFileStoryDocument = 1658620744,
    InputMediaEmpty = 2523198847,
    InputMediaUploadedPhoto = 505969924,
    InputMediaPhoto = 3015312949,
    InputMediaGeoPoint = 4190388548,
    InputMediaContact = 4171988475,
    InputMediaUploadedDocument = 1530447553,
    InputMediaDocument = 860303448,
    InputMediaVenue = 3242007569,
    InputMediaPhotoExternal = 3854302746,
    InputMediaDocumentExternal = 4216511641,
    InputMediaGame = 3544138739,
    InputMediaInvoice = 1080028941,
    InputMediaGeoLive = 2535434307,
    InputMediaPoll = 261416433,
    InputMediaDice = 3866083195,
    InputMediaStory = 2315114360,
    InputMediaWebPage = 3256584265,
    InputMediaPaidMedia = 3289396102,
    InputChatPhotoEmpty = 480546647,
    InputChatUploadedPhoto = 3184373440,
    InputChatPhoto = 2303962423,
    InputGeoPointEmpty = 3837862870,
    InputGeoPoint = 1210199983,
    InputPhotoEmpty = 483901197,
    InputPhoto = 1001634122,
    InputFileLocation = 3755650017,
    InputEncryptedFileLocation = 4112735573,
    InputDocumentFileLocation = 3134223748,
    InputSecureFileLocation = 3418877480,
    InputTakeoutFileLocation = 700340377,
    InputPhotoFileLocation = 1075322878,
    InputPhotoLegacyFileLocation = 3627312883,
    InputPeerPhotoFileLocation = 925204121,
    InputStickerSetThumb = 2642736091,
    InputGroupCallStream = 93890858,
    PeerUser = 1498486562,
    PeerChat = 918946202,
    PeerChannel = 2728736542,
    StorageFileUnknown = 2861972229,
    StorageFilePartial = 1086091090,
    StorageFileJpeg = 8322574,
    StorageFileGif = 3403786975,
    StorageFilePng = 172975040,
    StorageFilePdf = 2921222285,
    StorageFileMp3 = 1384777335,
    StorageFileMov = 1258941372,
    StorageFileMp4 = 3016663268,
    StorageFileWebp = 276907596,
    UserEmpty = 3552332666,
    User = 2201046986,
    UserProfilePhotoEmpty = 1326562017,
    UserProfilePhoto = 2194798342,
    UserStatusEmpty = 164646985,
    UserStatusOnline = 3988339017,
    UserStatusOffline = 9203775,
    UserStatusRecently = 2065268168,
    UserStatusLastWeek = 1410997530,
    UserStatusLastMonth = 1703516023,
    ChatEmpty = 693512293,
    Chat = 1103884886,
    ChatForbidden = 1704108455,
    Channel = 4265900221,
    ChannelForbidden = 399807445,
    ChatFull = 640893467,
    ChannelFull = 3148559501,
    ChatParticipant = 3224190983,
    ChatParticipantCreator = 3832270564,
    ChatParticipantAdmin = 2694004571,
    ChatParticipantsForbidden = 2271466465,
    ChatParticipants = 1018991608,
    ChatPhotoEmpty = 935395612,
    ChatPhoto = 476978193,
    MessageEmpty = 2426849924,
    Message = 2486456898,
    MessageService = 721967202,
    MessageMediaEmpty = 1038967584,
    MessageMediaPhoto = 1766936791,
    MessageMediaGeo = 1457575028,
    MessageMediaContact = 1882335561,
    MessageMediaUnsupported = 2676290718,
    MessageMediaDocument = 3713469397,
    MessageMediaWebPage = 3723562043,
    MessageMediaVenue = 784356159,
    MessageMediaGame = 4256272392,
    MessageMediaInvoice = 4138027219,
    MessageMediaGeoLive = 3108030054,
    MessageMediaPoll = 1272375192,
    MessageMediaDice = 1065280907,
    MessageMediaStory = 1758159491,
    MessageMediaGiveaway = 2852600811,
    MessageMediaGiveawayResults = 3467263649,
    MessageMediaPaidMedia = 2827297937,
    MessageActionEmpty = 3064919984,
    MessageActionChatCreate = 3175599021,
    MessageActionChatEditTitle = 3047280218,
    MessageActionChatEditPhoto = 2144015272,
    MessageActionChatDeletePhoto = 2514746351,
    MessageActionChatAddUser = 365886720,
    MessageActionChatDeleteUser = 2755604684,
    MessageActionChatJoinedByLink = 51520707,
    MessageActionChannelCreate = 2513611922,
    MessageActionChatMigrateTo = 3775102866,
    MessageActionChannelMigrateFrom = 3929622761,
    MessageActionPinMessage = 2495428845,
    MessageActionHistoryClear = 2679813636,
    MessageActionGameScore = 2460428406,
    MessageActionPaymentSentMe = 2402399015,
    MessageActionPaymentSent = 2518040406,
    MessageActionPhoneCall = 2162236031,
    MessageActionScreenshotTaken = 1200788123,
    MessageActionCustomAction = 4209418070,
    MessageActionBotAllowed = 3306608249,
    MessageActionSecureValuesSentMe = 455635795,
    MessageActionSecureValuesSent = 3646710100,
    MessageActionContactSignUp = 4092747638,
    MessageActionGeoProximityReached = 2564871831,
    MessageActionGroupCall = 2047704898,
    MessageActionInviteToGroupCall = 1345295095,
    MessageActionSetMessagesTTL = 1007897979,
    MessageActionGroupCallScheduled = 3013637729,
    MessageActionSetChatTheme = 2860016453,
    MessageActionChatJoinedByRequest = 3955008459,
    MessageActionWebViewDataSentMe = 1205698681,
    MessageActionWebViewDataSent = 3032714421,
    MessageActionGiftPremium = 3359468268,
    MessageActionTopicCreate = 228168278,
    MessageActionTopicEdit = 3230943264,
    MessageActionSuggestProfilePhoto = 1474192222,
    MessageActionRequestedPeer = 827428507,
    MessageActionSetChatWallPaper = 1348510708,
    MessageActionGiftCode = 1737240073,
    MessageActionGiveawayLaunch = 2819576292,
    MessageActionGiveawayResults = 2279797077,
    MessageActionBoostApply = 3422726765,
    MessageActionRequestedPeerSentMe = 2477987912,
    MessageActionPaymentRefunded = 1102307842,
    MessageActionGiftStars = 1171632161,
    MessageActionPrizeStars = 2953594786,
    MessageActionStarGift = 2612260676,
    Dialog = 3582593222,
    DialogFolder = 1908216652,
    PhotoEmpty = 590459437,
    Photo = 4212750949,
    PhotoSizeEmpty = 236446268,
    PhotoSize = 1976012384,
    PhotoCachedSize = 35527382,
    PhotoStrippedSize = 3769678894,
    PhotoSizeProgressive = 4198431637,
    PhotoPathSize = 3626061121,
    GeoPointEmpty = 286776671,
    GeoPoint = 2997024355,
    AuthSentCode = 1577067778,
    AuthSentCodeSuccess = 596704836,
    AuthAuthorization = 782418132,
    AuthAuthorizationSignUpRequired = 1148485274,
    AuthExportedAuthorization = 3023364792,
    InputNotifyPeer = 3099351820,
    InputNotifyUsers = 423314455,
    InputNotifyChats = 1251338318,
    InputNotifyBroadcasts = 2983951486,
    InputNotifyForumTopic = 1548122514,
    InputPeerNotifySettings = 3402328802,
    PeerNotifySettings = 2573347852,
    PeerSettings = 2899733598,
    WallPaper = 2755118061,
    WallPaperNoFile = 3766501654,
    InputReportReasonSpam = 1490799288,
    InputReportReasonViolence = 505595789,
    InputReportReasonPornography = 777640226,
    InputReportReasonChildAbuse = 2918469347,
    InputReportReasonOther = 3252986545,
    InputReportReasonCopyright = 2609510714,
    InputReportReasonGeoIrrelevant = 3688169197,
    InputReportReasonFake = 4124956391,
    InputReportReasonIllegalDrugs = 177124030,
    InputReportReasonPersonalDetails = 2663876157,
    UserFull = 525919081,
    Contact = 341499403,
    ImportedContact = 3242081360,
    ContactStatus = 383348795,
    ContactsContactsNotModified = 3075189202,
    ContactsContacts = 3941105218,
    ContactsImportedContacts = 2010127419,
    ContactsBlocked = 182326673,
    ContactsBlockedSlice = 3781575060,
    MessagesDialogs = 364538944,
    MessagesDialogsSlice = 1910543603,
    MessagesDialogsNotModified = 4041467286,
    MessagesMessages = 2356252295,
    MessagesMessagesSlice = 978610270,
    MessagesChannelMessages = 3346446926,
    MessagesMessagesNotModified = 1951620897,
    MessagesChats = 1694474197,
    MessagesChatsSlice = 2631405892,
    MessagesChatFull = 3856126364,
    MessagesAffectedHistory = 3025955281,
    InputMessagesFilterEmpty = 1474492012,
    InputMessagesFilterPhotos = 2517214492,
    InputMessagesFilterVideo = 2680163941,
    InputMessagesFilterPhotoVideo = 1458172132,
    InputMessagesFilterDocument = 2665345416,
    InputMessagesFilterUrl = 2129714567,
    InputMessagesFilterGif = 4291323271,
    InputMessagesFilterVoice = 1358283666,
    InputMessagesFilterMusic = 928101534,
    InputMessagesFilterChatPhotos = 975236280,
    InputMessagesFilterPhoneCalls = 2160695144,
    InputMessagesFilterRoundVoice = 2054952868,
    InputMessagesFilterRoundVideo = 3041516115,
    InputMessagesFilterMyMentions = 3254314650,
    InputMessagesFilterGeo = 3875695885,
    InputMessagesFilterContacts = 3764575107,
    InputMessagesFilterPinned = 464520273,
    UpdateNewMessage = 522914557,
    UpdateMessageID = 1318109142,
    UpdateDeleteMessages = 2718806245,
    UpdateUserTyping = 3223225727,
    UpdateChatUserTyping = 2202565360,
    UpdateChatParticipants = 125178264,
    UpdateUserStatus = 3854432478,
    UpdateUserName = 2810480932,
    UpdateNewAuthorization = 2303831023,
    UpdateNewEncryptedMessage = 314359194,
    UpdateEncryptedChatTyping = 386986326,
    UpdateEncryption = 3030575245,
    UpdateEncryptedMessagesRead = 956179895,
    UpdateChatParticipantAdd = 1037718609,
    UpdateChatParticipantDelete = 3811523959,
    UpdateDcOptions = 2388564083,
    UpdateNotifySettings = 3200411887,
    UpdateServiceNotification = 3957614617,
    UpdatePrivacy = 3996854058,
    UpdateUserPhone = 88680979,
    UpdateReadHistoryInbox = 2627162079,
    UpdateReadHistoryOutbox = 791617983,
    UpdateWebPage = 2139689491,
    UpdateReadMessagesContents = 4163006849,
    UpdateChannelTooLong = 277713951,
    UpdateChannel = 1666927625,
    UpdateNewChannelMessage = 1656358105,
    UpdateReadChannelInbox = 2452516368,
    UpdateDeleteChannelMessages = 3274529554,
    UpdateChannelMessageViews = 4062620680,
    UpdateChatParticipantAdmin = 3620364706,
    UpdateNewStickerSet = 1753886890,
    UpdateStickerSetsOrder = 196268545,
    UpdateStickerSets = 834816008,
    UpdateSavedGifs = 2473931806,
    UpdateBotInlineQuery = 1232025500,
    UpdateBotInlineSend = 317794823,
    UpdateEditChannelMessage = 457133559,
    UpdateBotCallbackQuery = 3117401229,
    UpdateEditMessage = 3825430691,
    UpdateInlineBotCallbackQuery = 1763610706,
    UpdateReadChannelOutbox = 3076495785,
    UpdateDraftMessage = 457829485,
    UpdateReadFeaturedStickers = 1461528386,
    UpdateRecentStickers = 2588027936,
    UpdateConfig = 2720652550,
    UpdatePtsChanged = 861169551,
    UpdateChannelWebPage = 791390623,
    UpdateDialogPinned = 1852826908,
    UpdatePinnedDialogs = 4195302562,
    UpdateBotWebhookJSON = 2199371971,
    UpdateBotWebhookJSONQuery = 2610053286,
    UpdateBotShippingQuery = 3048144253,
    UpdateBotPrecheckoutQuery = 2359990934,
    UpdatePhoneCall = 2869914398,
    UpdateLangPackTooLong = 1180041828,
    UpdateLangPack = 1442983757,
    UpdateFavedStickers = 3843135853,
    UpdateChannelReadMessagesContents = 3928556893,
    UpdateContactsReset = 1887741886,
    UpdateChannelAvailableMessages = 2990524056,
    UpdateDialogUnreadMark = 3781450179,
    UpdateMessagePoll = 2896258427,
    UpdateChatDefaultBannedRights = 1421875280,
    UpdateFolderPeers = 422972864,
    UpdatePeerSettings = 1786671974,
    UpdatePeerLocated = 3031420848,
    UpdateNewScheduledMessage = 967122427,
    UpdateDeleteScheduledMessages = 2424728814,
    UpdateTheme = 2182544291,
    UpdateGeoLiveViewed = 2267003193,
    UpdateLoginToken = 1448076945,
    UpdateMessagePollVote = 619974263,
    UpdateDialogFilter = 654302845,
    UpdateDialogFilterOrder = 2782339333,
    UpdateDialogFilters = 889491791,
    UpdatePhoneCallSignalingData = 643940105,
    UpdateChannelMessageForwards = 3533318132,
    UpdateReadChannelDiscussionInbox = 3601962310,
    UpdateReadChannelDiscussionOutbox = 1767677564,
    UpdatePeerBlocked = 3957356370,
    UpdateChannelUserTyping = 2357774627,
    UpdatePinnedMessages = 3984976565,
    UpdatePinnedChannelMessages = 1538885128,
    UpdateChat = 4170869326,
    UpdateGroupCallParticipants = 4075543374,
    UpdateGroupCall = 347227392,
    UpdatePeerHistoryTTL = 3147544997,
    UpdateChatParticipant = 3498534458,
    UpdateChannelParticipant = 2556246715,
    UpdateBotStopped = 3297184329,
    UpdateGroupCallConnection = 192428418,
    UpdateBotCommands = 1299263278,
    UpdatePendingJoinRequests = 1885586395,
    UpdateBotChatInviteRequester = 299870598,
    UpdateMessageReactions = 1578843320,
    UpdateAttachMenuBots = 397910539,
    UpdateWebViewResultSent = 361936797,
    UpdateBotMenuButton = 347625491,
    UpdateSavedRingtones = 1960361625,
    UpdateTranscribedAudio = 8703322,
    UpdateReadFeaturedEmojiStickers = 4216080748,
    UpdateUserEmojiStatus = 674706841,
    UpdateRecentEmojiStatuses = 821314523,
    UpdateRecentReactions = 1870160884,
    UpdateMoveStickerSetToTop = 2264715141,
    UpdateMessageExtendedMedia = 3584300836,
    UpdateChannelPinnedTopic = 422509539,
    UpdateChannelPinnedTopics = 4263085570,
    UpdateUser = 542282808,
    UpdateAutoSaveSettings = 3959795863,
    UpdateStory = 1974712216,
    UpdateReadStories = 4149121835,
    UpdateStoryID = 468923833,
    UpdateStoriesStealthMode = 738741697,
    UpdateSentStoryReaction = 2103604867,
    UpdateBotChatBoost = 2421019804,
    UpdateChannelViewForumAsMessages = 129403168,
    UpdatePeerWallpaper = 2923368477,
    UpdateBotMessageReaction = 2887898062,
    UpdateBotMessageReactions = 164329305,
    UpdateSavedDialogPinned = 2930744948,
    UpdatePinnedSavedDialogs = 1751942566,
    UpdateSavedReactionTags = 969307186,
    UpdateSmsJob = 4049758676,
    UpdateQuickReplies = 4182182578,
    UpdateNewQuickReply = 4114458391,
    UpdateDeleteQuickReply = 1407644140,
    UpdateQuickReplyMessage = 1040518415,
    UpdateDeleteQuickReplyMessages = 1450174413,
    UpdateBotBusinessConnect = 2330315130,
    UpdateBotNewBusinessMessage = 2648388732,
    UpdateBotEditBusinessMessage = 132077692,
    UpdateBotDeleteBusinessMessage = 2687146030,
    UpdateNewStoryReaction = 405070859,
    UpdateBroadcastRevenueTransactions = 3755565557,
    UpdateStarsBalance = 263737752,
    UpdateBusinessBotCallbackQuery = 513998247,
    UpdateStarsRevenueStatus = 2776936473,
    UpdateBotPurchasedPaidMedia = 675009298,
    UpdatePaidReactionPrivacy = 1372224236,
    UpdatesState = 2775329342,
    UpdatesDifferenceEmpty = 1567990072,
    UpdatesDifference = 16030880,
    UpdatesDifferenceSlice = 2835028353,
    UpdatesDifferenceTooLong = 1258196845,
    UpdatesTooLong = 3809980286,
    UpdateShortMessage = 826001400,
    UpdateShortChatMessage = 1299050149,
    UpdateShort = 2027216577,
    UpdatesCombined = 1918567619,
    Updates = 1957577280,
    UpdateShortSentMessage = 2417352961,
    PhotosPhotos = 2378853029,
    PhotosPhotosSlice = 352657236,
    PhotosPhoto = 539045032,
    UploadFile = 157948117,
    UploadFileCdnRedirect = 4052539972,
    DcOption = 414687501,
    Config = 3424265246,
    NearestDc = 2384074613,
    HelpAppUpdate = 3434860080,
    HelpNoAppUpdate = 3294258486,
    HelpInviteText = 415997816,
    EncryptedChatEmpty = 2877210784,
    EncryptedChatWaiting = 1722964307,
    EncryptedChatRequested = 1223809356,
    EncryptedChat = 1643173063,
    EncryptedChatDiscarded = 505183301,
    InputEncryptedChat = 4047615457,
    EncryptedFileEmpty = 3256830334,
    EncryptedFile = 2818608344,
    InputEncryptedFileEmpty = 406307684,
    InputEncryptedFileUploaded = 1690108678,
    InputEncryptedFile = 1511503333,
    InputEncryptedFileBigUploaded = 767652808,
    EncryptedMessage = 3977822488,
    EncryptedMessageService = 594758406,
    MessagesDhConfigNotModified = 3236054581,
    MessagesDhConfig = 740433629,
    MessagesSentEncryptedMessage = 1443858741,
    MessagesSentEncryptedFile = 2492727090,
    InputDocumentEmpty = 1928391342,
    InputDocument = 448771445,
    DocumentEmpty = 922273905,
    Document = 2413085912,
    HelpSupport = 398898678,
    NotifyPeer = 2681474008,
    NotifyUsers = 3033021260,
    NotifyChats = 3221737155,
    NotifyBroadcasts = 3591563503,
    NotifyForumTopic = 577659656,
    SendMessageTypingAction = 381645902,
    SendMessageCancelAction = 4250847477,
    SendMessageRecordVideoAction = 2710034031,
    SendMessageUploadVideoAction = 3916839660,
    SendMessageRecordAudioAction = 3576656887,
    SendMessageUploadAudioAction = 4082227115,
    SendMessageUploadPhotoAction = 3520285222,
    SendMessageUploadDocumentAction = 2852968932,
    SendMessageGeoLocationAction = 393186209,
    SendMessageChooseContactAction = 1653390447,
    SendMessageGamePlayAction = 3714748232,
    SendMessageRecordRoundAction = 2297593788,
    SendMessageUploadRoundAction = 608050278,
    SpeakingInGroupCallAction = 3643548293,
    SendMessageHistoryImportAction = 3688534598,
    SendMessageChooseStickerAction = 2958739121,
    SendMessageEmojiInteraction = 630664139,
    SendMessageEmojiInteractionSeen = 3060109358,
    ContactsFound = 3004386717,
    InputPrivacyKeyStatusTimestamp = 1335282456,
    InputPrivacyKeyChatInvite = 3187344422,
    InputPrivacyKeyPhoneCall = 4206550111,
    InputPrivacyKeyPhoneP2P = 3684593874,
    InputPrivacyKeyForwards = 2765966344,
    InputPrivacyKeyProfilePhoto = 1461304012,
    InputPrivacyKeyPhoneNumber = 55761658,
    InputPrivacyKeyAddedByPhone = 3508640733,
    InputPrivacyKeyVoiceMessages = 2934349160,
    InputPrivacyKeyAbout = 941870144,
    InputPrivacyKeyBirthday = 3596227020,
    PrivacyKeyStatusTimestamp = 3157175088,
    PrivacyKeyChatInvite = 1343122938,
    PrivacyKeyPhoneCall = 1030105979,
    PrivacyKeyPhoneP2P = 961092808,
    PrivacyKeyForwards = 1777096355,
    PrivacyKeyProfilePhoto = 2517966829,
    PrivacyKeyPhoneNumber = 3516589165,
    PrivacyKeyAddedByPhone = 1124062251,
    PrivacyKeyVoiceMessages = 110621716,
    PrivacyKeyAbout = 2760292193,
    PrivacyKeyBirthday = 536913176,
    InputPrivacyValueAllowContacts = 218751099,
    InputPrivacyValueAllowAll = 407582158,
    InputPrivacyValueAllowUsers = 320652927,
    InputPrivacyValueDisallowContacts = 195371015,
    InputPrivacyValueDisallowAll = 3597362889,
    InputPrivacyValueDisallowUsers = 2417034343,
    InputPrivacyValueAllowChatParticipants = 2215004623,
    InputPrivacyValueDisallowChatParticipants = 3914272646,
    InputPrivacyValueAllowCloseFriends = 793067081,
    InputPrivacyValueAllowPremium = 2009975281,
    PrivacyValueAllowContacts = 4294843308,
    PrivacyValueAllowAll = 1698855810,
    PrivacyValueAllowUsers = 3096469426,
    PrivacyValueDisallowContacts = 4169726490,
    PrivacyValueDisallowAll = 2339628899,
    PrivacyValueDisallowUsers = 3831632193,
    PrivacyValueAllowChatParticipants = 1796427406,
    PrivacyValueDisallowChatParticipants = 1103656293,
    PrivacyValueAllowCloseFriends = 4159232155,
    PrivacyValueAllowPremium = 3974725963,
    AccountPrivacyRules = 1352683077,
    AccountDaysTTL = 3100684255,
    DocumentAttributeImageSize = 1815593308,
    DocumentAttributeAnimated = 297109817,
    DocumentAttributeSticker = 1662637586,
    DocumentAttributeVideo = 1137015880,
    DocumentAttributeAudio = 2555574726,
    DocumentAttributeFilename = 358154344,
    DocumentAttributeHasStickers = 2550256375,
    DocumentAttributeCustomEmoji = 4245985433,
    MessagesStickersNotModified = 4050950690,
    MessagesStickers = 816245886,
    StickerPack = 313694676,
    MessagesAllStickersNotModified = 3898999491,
    MessagesAllStickers = 3451637435,
    MessagesAffectedMessages = 2228326789,
    WebPageEmpty = 555358088,
    WebPagePending = 2966502983,
    WebPage = 3902555570,
    WebPageNotModified = 1930545681,
    Authorization = 2902578717,
    AccountAuthorizations = 1275039392,
    AccountPassword = 2507886843,
    AccountPasswordSettings = 2589733861,
    AccountPasswordInputSettings = 3258394569,
    AuthPasswordRecovery = 326715557,
    ReceivedNotifyMessage = 2743383929,
    ChatInviteExported = 2720841110,
    ChatInvitePublicJoinRequests = 3977280183,
    ChatInviteAlready = 1516793212,
    ChatInvite = 4268046493,
    ChatInvitePeek = 1634294960,
    InputStickerSetEmpty = 4290128789,
    InputStickerSetID = 2649203305,
    InputStickerSetShortName = 2250033312,
    InputStickerSetAnimatedEmoji = 42402760,
    InputStickerSetDice = 3867103758,
    InputStickerSetAnimatedEmojiAnimations = 215889721,
    InputStickerSetPremiumGifts = 3364567810,
    InputStickerSetEmojiGenericAnimations = 80008398,
    InputStickerSetEmojiDefaultStatuses = 701560302,
    InputStickerSetEmojiDefaultTopicIcons = 1153562857,
    InputStickerSetEmojiChannelDefaultStatuses = 1232373075,
    StickerSet = 768691932,
    MessagesStickerSet = 1846886166,
    MessagesStickerSetNotModified = 3556320491,
    BotCommand = 3262826695,
    BotInfo = 2185461364,
    KeyboardButton = 2734311552,
    KeyboardButtonUrl = 629866245,
    KeyboardButtonCallback = 901503851,
    KeyboardButtonRequestPhone = 2976541737,
    KeyboardButtonRequestGeoLocation = 4235815743,
    KeyboardButtonSwitchInline = 2478439349,
    KeyboardButtonGame = 1358175439,
    KeyboardButtonBuy = 2950250427,
    KeyboardButtonUrlAuth = 280464681,
    InputKeyboardButtonUrlAuth = 3492708308,
    KeyboardButtonRequestPoll = 3150401885,
    InputKeyboardButtonUserProfile = 3918005115,
    KeyboardButtonUserProfile = 814112961,
    KeyboardButtonWebView = 326529584,
    KeyboardButtonSimpleWebView = 2696958044,
    KeyboardButtonRequestPeer = 1406648280,
    InputKeyboardButtonRequestPeer = 3378916613,
    KeyboardButtonCopy = 1976723854,
    KeyboardButtonRow = 2002815875,
    ReplyKeyboardHide = 2688441221,
    ReplyKeyboardForceReply = 2259946248,
    ReplyKeyboardMarkup = 2245892561,
    ReplyInlineMarkup = 1218642516,
    MessageEntityUnknown = 3146955413,
    MessageEntityMention = 4194588573,
    MessageEntityHashtag = 1868782349,
    MessageEntityBotCommand = 1827637959,
    MessageEntityUrl = 1859134776,
    MessageEntityEmail = 1692693954,
    MessageEntityBold = 3177253833,
    MessageEntityItalic = 2188348256,
    MessageEntityCode = 681706865,
    MessageEntityPre = 1938967520,
    MessageEntityTextUrl = 1990644519,
    MessageEntityMentionName = 3699052864,
    InputMessageEntityMentionName = 546203849,
    MessageEntityPhone = 2607407947,
    MessageEntityCashtag = 1280209983,
    MessageEntityUnderline = 2622389899,
    MessageEntityStrike = 3204879316,
    MessageEntityBankCard = 1981704948,
    MessageEntitySpoiler = 852137487,
    MessageEntityCustomEmoji = 3369010680,
    MessageEntityBlockquote = 4056722092,
    InputChannelEmpty = 4002160262,
    InputChannel = 4082822184,
    InputChannelFromMessage = 1536380829,
    ContactsResolvedPeer = 2131196633,
    MessageRange = 182649427,
    UpdatesChannelDifferenceEmpty = 1041346555,
    UpdatesChannelDifferenceTooLong = 2763835134,
    UpdatesChannelDifference = 543450958,
    ChannelMessagesFilterEmpty = 2496933607,
    ChannelMessagesFilter = 3447183703,
    ChannelParticipant = 3409540633,
    ChannelParticipantSelf = 1331723247,
    ChannelParticipantCreator = 803602899,
    ChannelParticipantAdmin = 885242707,
    ChannelParticipantBanned = 1844969806,
    ChannelParticipantLeft = 453242886,
    ChannelParticipantsRecent = 3728686201,
    ChannelParticipantsAdmins = 3026225513,
    ChannelParticipantsKicked = 2746567045,
    ChannelParticipantsBots = 2966521435,
    ChannelParticipantsBanned = 338142689,
    ChannelParticipantsSearch = 106343499,
    ChannelParticipantsContacts = 3144345741,
    ChannelParticipantsMentions = 3763035371,
    ChannelsChannelParticipants = 2595290799,
    ChannelsChannelParticipantsNotModified = 4028055529,
    ChannelsChannelParticipant = 3753378583,
    HelpTermsOfService = 2013922064,
    MessagesSavedGifsNotModified = 3892468898,
    MessagesSavedGifs = 2225089037,
    InputBotInlineMessageMediaAuto = 864077702,
    InputBotInlineMessageText = 1036876423,
    InputBotInlineMessageMediaGeo = 2526190213,
    InputBotInlineMessageMediaVenue = 1098628881,
    InputBotInlineMessageMediaContact = 2800599037,
    InputBotInlineMessageGame = 1262639204,
    InputBotInlineMessageMediaInvoice = 3622273573,
    InputBotInlineMessageMediaWebPage = 3185362192,
    InputBotInlineResult = 2294256409,
    InputBotInlineResultPhoto = 2832753831,
    InputBotInlineResultDocument = 4294507972,
    InputBotInlineResultGame = 1336154098,
    BotInlineMessageMediaAuto = 1984755728,
    BotInlineMessageText = 2357159394,
    BotInlineMessageMediaGeo = 85477117,
    BotInlineMessageMediaVenue = 2324063644,
    BotInlineMessageMediaContact = 416402882,
    BotInlineMessageMediaInvoice = 894081801,
    BotInlineMessageMediaWebPage = 2157631910,
    BotInlineResult = 295067450,
    BotInlineMediaResult = 400266251,
    MessagesBotResults = 3760321270,
    ExportedMessageLink = 1571494644,
    MessageFwdHeader = 1313731771,
    AuthCodeTypeSms = 1923290508,
    AuthCodeTypeCall = 1948046307,
    AuthCodeTypeFlashCall = 577556219,
    AuthCodeTypeMissedCall = 3592083182,
    AuthCodeTypeFragmentSms = 116234636,
    AuthSentCodeTypeApp = 1035688326,
    AuthSentCodeTypeSms = 3221273506,
    AuthSentCodeTypeCall = 1398007207,
    AuthSentCodeTypeFlashCall = 2869151449,
    AuthSentCodeTypeMissedCall = 2181063812,
    AuthSentCodeTypeEmailCode = 4098946459,
    AuthSentCodeTypeSetUpEmailRequired = 2773032426,
    AuthSentCodeTypeFragmentSms = 3646315577,
    AuthSentCodeTypeFirebaseSms = 10475318,
    AuthSentCodeTypeSmsWord = 2752949377,
    AuthSentCodeTypeSmsPhrase = 3010958511,
    MessagesBotCallbackAnswer = 911761060,
    MessagesMessageEditData = 649453030,
    InputBotInlineMessageID = 2299280777,
    InputBotInlineMessageID64 = 3067680215,
    InlineBotSwitchPM = 1008755359,
    MessagesPeerDialogs = 863093588,
    TopPeer = 3989684315,
    TopPeerCategoryBotsPM = 2875595611,
    TopPeerCategoryBotsInline = 344356834,
    TopPeerCategoryCorrespondents = 104314861,
    TopPeerCategoryGroups = 3172442442,
    TopPeerCategoryChannels = 371037736,
    TopPeerCategoryPhoneCalls = 511092620,
    TopPeerCategoryForwardUsers = 2822794409,
    TopPeerCategoryForwardChats = 4226728176,
    TopPeerCategoryBotsApp = 4255022060,
    TopPeerCategoryPeers = 4219683473,
    ContactsTopPeersNotModified = 3727060725,
    ContactsTopPeers = 1891070632,
    ContactsTopPeersDisabled = 3039597469,
    DraftMessageEmpty = 453805082,
    DraftMessage = 761606687,
    MessagesFeaturedStickersNotModified = 3336309862,
    MessagesFeaturedStickers = 3191351558,
    MessagesRecentStickersNotModified = 186120336,
    MessagesRecentStickers = 2295561302,
    MessagesArchivedStickers = 1338747336,
    MessagesStickerSetInstallResultSuccess = 946083368,
    MessagesStickerSetInstallResultArchive = 904138920,
    StickerSetCovered = 1678812626,
    StickerSetMultiCovered = 872932635,
    StickerSetFullCovered = 1087454222,
    StickerSetNoCovered = 2008112412,
    MaskCoords = 2933316530,
    InputStickeredMediaPhoto = 1251549527,
    InputStickeredMediaDocument = 70813275,
    Game = 3187238203,
    InputGameID = 53231223,
    InputGameShortName = 3274827786,
    HighScore = 1940093419,
    MessagesHighScores = 2587622809,
    TextEmpty = 3695018575,
    TextPlain = 1950782688,
    TextBold = 1730456516,
    TextItalic = 3641877916,
    TextUnderline = 3240501956,
    TextStrike = 2616769429,
    TextFixed = 1816074681,
    TextUrl = 1009288385,
    TextEmail = 3730443734,
    TextConcat = 2120376535,
    TextSubscript = 3983181060,
    TextSuperscript = 3355139585,
    TextMarked = 55281185,
    TextPhone = 483104362,
    TextImage = 136105807,
    TextAnchor = 894777186,
    PageBlockUnsupported = 324435594,
    PageBlockTitle = 1890305021,
    PageBlockSubtitle = 2415565343,
    PageBlockAuthorDate = 3132089824,
    PageBlockHeader = 3218105580,
    PageBlockSubheader = 4046173921,
    PageBlockParagraph = 1182402406,
    PageBlockPreformatted = 3228621118,
    PageBlockFooter = 1216809369,
    PageBlockDivider = 3676352904,
    PageBlockAnchor = 3456972720,
    PageBlockList = 3840442385,
    PageBlockBlockquote = 641563686,
    PageBlockPullquote = 1329878739,
    PageBlockPhoto = 391759200,
    PageBlockVideo = 2089805750,
    PageBlockCover = 972174080,
    PageBlockEmbed = 2826014149,
    PageBlockEmbedPost = 4065961995,
    PageBlockCollage = 1705048653,
    PageBlockSlideshow = 52401552,
    PageBlockChannel = 4011282869,
    PageBlockAudio = 2151899626,
    PageBlockKicker = 504660880,
    PageBlockTable = 3209554562,
    PageBlockOrderedList = 2592793057,
    PageBlockDetails = 1987480557,
    PageBlockRelatedArticles = 370236054,
    PageBlockMap = 2756656886,
    PhoneCallDiscardReasonMissed = 2246320897,
    PhoneCallDiscardReasonDisconnect = 3767910816,
    PhoneCallDiscardReasonHangup = 1471006352,
    PhoneCallDiscardReasonBusy = 4210550985,
    DataJSON = 2104790276,
    LabeledPrice = 3408489464,
    Invoice = 1572428309,
    PaymentCharge = 3926049406,
    PostAddress = 512535275,
    PaymentRequestedInfo = 2426158996,
    PaymentSavedCredentialsCard = 3452074527,
    WebDocument = 475467473,
    WebDocumentNoProxy = 4190682310,
    InputWebDocument = 2616017741,
    InputWebFileLocation = 3258570374,
    InputWebFileGeoPointLocation = 2669814217,
    InputWebFileAudioAlbumThumbLocation = 4100974884,
    UploadWebFile = 568808380,
    PaymentsPaymentForm = 2684716881,
    PaymentsPaymentFormStars = 2079764828,
    PaymentsPaymentFormStarGift = 3022376929,
    PaymentsValidatedRequestedInfo = 3510966403,
    PaymentsPaymentResult = 1314881805,
    PaymentsPaymentVerificationNeeded = 3628142905,
    PaymentsPaymentReceipt = 1891958275,
    PaymentsPaymentReceiptStars = 3669751866,
    PaymentsSavedInfo = 4220511292,
    InputPaymentCredentialsSaved = 3238965967,
    InputPaymentCredentials = 873977640,
    InputPaymentCredentialsApplePay = 178373535,
    InputPaymentCredentialsGooglePay = 2328045569,
    AccountTmpPassword = 3680828724,
    ShippingOption = 3055631583,
    InputStickerSetItem = 853188252,
    InputPhoneCall = 506920429,
    PhoneCallEmpty = 1399245077,
    PhoneCallWaiting = 3307368215,
    PhoneCallRequested = 347139340,
    PhoneCallAccepted = 912311057,
    PhoneCall = 810769141,
    PhoneCallDiscarded = 1355435489,
    PhoneConnection = 2629903303,
    PhoneConnectionWebrtc = 1667228533,
    PhoneCallProtocol = 4236742600,
    PhonePhoneCall = 3968000320,
    UploadCdnFileReuploadNeeded = 4004045934,
    UploadCdnFile = 2845821519,
    CdnPublicKey = 3380800186,
    CdnConfig = 1462101002,
    LangPackString = 3402727926,
    LangPackStringPluralized = 1816636575,
    LangPackStringDeleted = 695856818,
    LangPackDifference = 4085629430,
    LangPackLanguage = 4006239459,
    ChannelAdminLogEventActionChangeTitle = 3873421349,
    ChannelAdminLogEventActionChangeAbout = 1427671598,
    ChannelAdminLogEventActionChangeUsername = 1783299128,
    ChannelAdminLogEventActionChangePhoto = 1129042607,
    ChannelAdminLogEventActionToggleInvites = 460916654,
    ChannelAdminLogEventActionToggleSignatures = 648939889,
    ChannelAdminLogEventActionUpdatePinned = 3924306968,
    ChannelAdminLogEventActionEditMessage = 1889215493,
    ChannelAdminLogEventActionDeleteMessage = 1121994683,
    ChannelAdminLogEventActionParticipantJoin = 405815507,
    ChannelAdminLogEventActionParticipantLeave = 4170676210,
    ChannelAdminLogEventActionParticipantInvite = 3810276568,
    ChannelAdminLogEventActionParticipantToggleBan = 3872931198,
    ChannelAdminLogEventActionParticipantToggleAdmin = 3580323600,
    ChannelAdminLogEventActionChangeStickerSet = 2982398631,
    ChannelAdminLogEventActionTogglePreHistoryHidden = 1599903217,
    ChannelAdminLogEventActionDefaultBannedRights = 771095562,
    ChannelAdminLogEventActionStopPoll = 2399639107,
    ChannelAdminLogEventActionChangeLinkedChat = 84703944,
    ChannelAdminLogEventActionChangeLocation = 241923758,
    ChannelAdminLogEventActionToggleSlowMode = 1401984889,
    ChannelAdminLogEventActionStartGroupCall = 589338437,
    ChannelAdminLogEventActionDiscardGroupCall = 3684667712,
    ChannelAdminLogEventActionParticipantMute = 4179895506,
    ChannelAdminLogEventActionParticipantUnmute = 3863226816,
    ChannelAdminLogEventActionToggleGroupCallSetting = 1456906823,
    ChannelAdminLogEventActionParticipantJoinByInvite = 4271882584,
    ChannelAdminLogEventActionExportedInviteDelete = 1515256996,
    ChannelAdminLogEventActionExportedInviteRevoke = 1091179342,
    ChannelAdminLogEventActionExportedInviteEdit = 3910056793,
    ChannelAdminLogEventActionParticipantVolume = 1048537159,
    ChannelAdminLogEventActionChangeHistoryTTL = 1855199800,
    ChannelAdminLogEventActionParticipantJoinByRequest = 2947945546,
    ChannelAdminLogEventActionToggleNoForwards = 3408578406,
    ChannelAdminLogEventActionSendMessage = 663693416,
    ChannelAdminLogEventActionChangeAvailableReactions = 3192786680,
    ChannelAdminLogEventActionChangeUsernames = 4031755177,
    ChannelAdminLogEventActionToggleForum = 46949251,
    ChannelAdminLogEventActionCreateTopic = 1483767080,
    ChannelAdminLogEventActionEditTopic = 4033864200,
    ChannelAdminLogEventActionDeleteTopic = 2920712457,
    ChannelAdminLogEventActionPinTopic = 1569535291,
    ChannelAdminLogEventActionToggleAntiSpam = 1693675004,
    ChannelAdminLogEventActionChangePeerColor = 1469507456,
    ChannelAdminLogEventActionChangeProfilePeerColor = 1581742885,
    ChannelAdminLogEventActionChangeWallpaper = 834362706,
    ChannelAdminLogEventActionChangeEmojiStatus = 1051328177,
    ChannelAdminLogEventActionChangeEmojiStickerSet = 1188577451,
    ChannelAdminLogEventActionToggleSignatureProfiles = 1621597305,
    ChannelAdminLogEventActionParticipantSubExtend = 1684286899,
    ChannelAdminLogEvent = 531458253,
    ChannelsAdminLogResults = 3985307469,
    ChannelAdminLogEventsFilter = 3926948580,
    PopularContact = 1558266229,
    MessagesFavedStickersNotModified = 2660214483,
    MessagesFavedStickers = 750063767,
    RecentMeUrlUnknown = 1189204285,
    RecentMeUrlUser = 3106671074,
    RecentMeUrlChat = 3000660434,
    RecentMeUrlChatInvite = 3947431965,
    RecentMeUrlStickerSet = 3154794460,
    HelpRecentMeUrls = 235081943,
    InputSingleMedia = 482797855,
    WebAuthorization = 2801333330,
    AccountWebAuthorizations = 3981887996,
    InputMessageID = 2792792866,
    InputMessageReplyTo = 3134751637,
    InputMessagePinned = 2257003832,
    InputMessageCallbackQuery = 2902071934,
    InputDialogPeer = 4239064759,
    InputDialogPeerFolder = 1684014375,
    DialogPeer = 3849174789,
    DialogPeerFolder = 1363483106,
    MessagesFoundStickerSetsNotModified = 223655517,
    MessagesFoundStickerSets = 2331024850,
    FileHash = 4087022428,
    InputClientProxy = 1968737087,
    HelpTermsOfServiceUpdateEmpty = 3811614591,
    HelpTermsOfServiceUpdate = 686618977,
    InputSecureFileUploaded = 859091184,
    InputSecureFile = 1399317950,
    SecureFileEmpty = 1679398724,
    SecureFile = 2097791614,
    SecureData = 2330640067,
    SecurePlainPhone = 2103482845,
    SecurePlainEmail = 569137759,
    SecureValueTypePersonalDetails = 2636808675,
    SecureValueTypePassport = 1034709504,
    SecureValueTypeDriverLicense = 115615172,
    SecureValueTypeIdentityCard = 2698015819,
    SecureValueTypeInternalPassport = 2577698595,
    SecureValueTypeAddress = 3420659238,
    SecureValueTypeUtilityBill = 4231435598,
    SecureValueTypeBankStatement = 2299755533,
    SecureValueTypeRentalAgreement = 2340959368,
    SecureValueTypePassportRegistration = 2581823594,
    SecureValueTypeTemporaryRegistration = 3926060083,
    SecureValueTypePhone = 3005262555,
    SecureValueTypeEmail = 2386339822,
    SecureValue = 411017418,
    InputSecureValue = 3676426407,
    SecureValueHash = 3978218928,
    SecureValueErrorData = 3903065049,
    SecureValueErrorFrontSide = 12467706,
    SecureValueErrorReverseSide = 2257201829,
    SecureValueErrorSelfie = 3845639894,
    SecureValueErrorFile = 2054162547,
    SecureValueErrorFiles = 1717706985,
    SecureValueError = 2258466191,
    SecureValueErrorTranslationFile = 2702460784,
    SecureValueErrorTranslationFiles = 878931416,
    SecureCredentialsEncrypted = 871426631,
    AccountAuthorizationForm = 2905480408,
    AccountSentEmailCode = 2166326607,
    HelpDeepLinkInfoEmpty = 1722786150,
    HelpDeepLinkInfo = 1783556146,
    SavedPhoneContact = 289586518,
    AccountTakeout = 1304052993,
    PasswordKdfAlgoUnknown = 3562713238,
    PasswordKdfAlgoSHA256SHA256PBKDF2HMACSHA512iter100000SHA256ModPow = 982592842,
    SecurePasswordKdfAlgoUnknown = 4883767,
    SecurePasswordKdfAlgoPBKDF2HMACSHA512iter100000 = 3153255840,
    SecurePasswordKdfAlgoSHA512 = 2252807570,
    SecureSecretSettings = 354925740,
    InputCheckPasswordEmpty = 2558588504,
    InputCheckPasswordSRP = 3531600002,
    SecureRequiredType = 2191366618,
    SecureRequiredTypeOneOf = 41187252,
    HelpPassportConfigNotModified = 3216634967,
    HelpPassportConfig = 2694370991,
    InputAppEvent = 488313413,
    JsonObjectValue = 3235781593,
    JsonNull = 1064139624,
    JsonBool = 3342098026,
    JsonNumber = 736157604,
    JsonString = 3072226938,
    JsonArray = 4148447075,
    JsonObject = 2579616925,
    PageTableCell = 878078826,
    PageTableRow = 3770729957,
    PageCaption = 1869903447,
    PageListItemText = 3106911949,
    PageListItemBlocks = 635466748,
    PageListOrderedItemText = 1577484359,
    PageListOrderedItemBlocks = 2564655414,
    PageRelatedArticle = 3012615176,
    Page = 2556788493,
    HelpSupportName = 2349199817,
    HelpUserInfoEmpty = 4088278765,
    HelpUserInfo = 32192344,
    PollAnswer = 4279689930,
    Poll = 1484026161,
    PollAnswerVoters = 997055186,
    PollResults = 2061444128,
    ChatOnlines = 4030849616,
    StatsURL = 1202287072,
    ChatAdminRights = 1605510357,
    ChatBannedRights = 2668758040,
    InputWallPaper = 3861952889,
    InputWallPaperSlug = 1913199744,
    InputWallPaperNoFile = 2524595758,
    AccountWallPapersNotModified = 471437699,
    AccountWallPapers = 3452142988,
    CodeSettings = 2904898936,
    WallPaperSettings = 925826256,
    AutoDownloadSettings = 3131405864,
    AccountAutoDownloadSettings = 1674235686,
    EmojiKeyword = 3585325561,
    EmojiKeywordDeleted = 594408994,
    EmojiKeywordsDifference = 1556570557,
    EmojiURL = 2775937949,
    EmojiLanguage = 3019592545,
    Folder = 4283715173,
    InputFolderPeer = 4224893590,
    FolderPeer = 3921323624,
    MessagesSearchCounter = 3896830975,
    UrlAuthResultRequest = 2463316494,
    UrlAuthResultAccepted = 2408320590,
    UrlAuthResultDefault = 2849430303,
    ChannelLocationEmpty = 3216354699,
    ChannelLocation = 547062491,
    PeerLocated = 3393592157,
    PeerSelfLocated = 4176226379,
    RestrictionReason = 3497176244,
    InputTheme = 1012306921,
    InputThemeSlug = 4119399921,
    Theme = 2685298646,
    AccountThemesNotModified = 4095653410,
    AccountThemes = 2587724909,
    AuthLoginToken = 1654593920,
    AuthLoginTokenMigrateTo = 110008598,
    AuthLoginTokenSuccess = 957176926,
    AccountContentSettings = 1474462241,
    MessagesInactiveChats = 2837970629,
    BaseThemeClassic = 3282117730,
    BaseThemeDay = 4225242760,
    BaseThemeNight = 3081969320,
    BaseThemeTinted = 1834973166,
    BaseThemeArctic = 1527845466,
    InputThemeSettings = 2413711439,
    ThemeSettings = 4200117972,
    WebPageAttributeTheme = 1421174295,
    WebPageAttributeStory = 781501415,
    WebPageAttributeStickerSet = 1355547603,
    MessagesVotesList = 1218005070,
    BankCardOpenUrl = 4117234314,
    PaymentsBankCardData = 1042605427,
    DialogFilter = 1605718587,
    DialogFilterDefault = 909284270,
    DialogFilterChatlist = 2682424996,
    DialogFilterSuggested = 2004110666,
    StatsDateRangeDays = 3057118639,
    StatsAbsValueAndPrev = 3410210014,
    StatsPercentValue = 3419287520,
    StatsGraphAsync = 1244130093,
    StatsGraphError = 3202127906,
    StatsGraph = 2393138358,
    StatsBroadcastStats = 963421692,
    HelpPromoDataEmpty = 2566302837,
    HelpPromoData = 2352576831,
    VideoSize = 3727929492,
    VideoSizeEmojiMarkup = 4166795580,
    VideoSizeStickerMarkup = 228623102,
    StatsGroupTopPoster = 2634330011,
    StatsGroupTopAdmin = 3612888199,
    StatsGroupTopInviter = 1398765469,
    StatsMegagroupStats = 4018141462,
    GlobalPrivacySettings = 1934380235,
    HelpCountryCode = 1107543535,
    HelpCountry = 3280440867,
    HelpCountriesListNotModified = 2479628082,
    HelpCountriesList = 2278585758,
    MessageViews = 1163625789,
    MessagesMessageViews = 3066361155,
    MessagesDiscussionMessage = 2788431746,
    MessageReplyHeader = 2948336091,
    MessageReplyStoryHeader = 240843065,
    MessageReplies = 2211844034,
    PeerBlocked = 3908927508,
    StatsMessageStats = 2145983508,
    GroupCallDiscarded = 2004925620,
    GroupCall = 3583468812,
    InputGroupCall = 3635053583,
    GroupCallParticipant = 3953538814,
    PhoneGroupCall = 2658302637,
    PhoneGroupParticipants = 4101460406,
    InlineQueryPeerTypeSameBotPM = 813821341,
    InlineQueryPeerTypePM = 2201751468,
    InlineQueryPeerTypeChat = 3613836554,
    InlineQueryPeerTypeMegagroup = 1589952067,
    InlineQueryPeerTypeBroadcast = 1664413338,
    InlineQueryPeerTypeBotPM = 238759180,
    MessagesHistoryImport = 375566091,
    MessagesHistoryImportParsed = 1578088377,
    MessagesAffectedFoundMessages = 4019011180,
    ChatInviteImporter = 2354765785,
    MessagesExportedChatInvites = 3183881676,
    MessagesExportedChatInvite = 410107472,
    MessagesExportedChatInviteReplaced = 572915951,
    MessagesChatInviteImporters = 2176233482,
    ChatAdminWithInvites = 4075613987,
    MessagesChatAdminsWithInvites = 3063640791,
    MessagesCheckedHistoryImportPeer = 2723014423,
    PhoneJoinAsPeers = 2951045695,
    PhoneExportedGroupCallInvite = 541839704,
    GroupCallParticipantVideoSourceGroup = 3702593719,
    GroupCallParticipantVideo = 1735736008,
    StickersSuggestedShortName = 2248056895,
    BotCommandScopeDefault = 795652779,
    BotCommandScopeUsers = 1011811544,
    BotCommandScopeChats = 1877059713,
    BotCommandScopeChatAdmins = 3114950762,
    BotCommandScopePeer = 3684534653,
    BotCommandScopePeerAdmins = 1071145937,
    BotCommandScopePeerUser = 169026035,
    AccountResetPasswordFailedWait = 3816265825,
    AccountResetPasswordRequestedWait = 3924819069,
    AccountResetPasswordOk = 3911636542,
    SponsoredMessage = 1301522832,
    MessagesSponsoredMessages = 3387825543,
    MessagesSponsoredMessagesEmpty = 406407439,
    SearchResultsCalendarPeriod = 3383776159,
    MessagesSearchResultsCalendar = 343859772,
    SearchResultPosition = 2137295719,
    MessagesSearchResultsPositions = 1404185519,
    ChannelsSendAsPeers = 4103516358,
    UsersUserFull = 997004590,
    MessagesPeerSettings = 1753266509,
    AuthLoggedOut = 3282207583,
    ReactionCount = 2748435328,
    MessageReactions = 171155211,
    MessagesMessageReactionsList = 834488621,
    AvailableReaction = 3229084673,
    MessagesAvailableReactionsNotModified = 2668042583,
    MessagesAvailableReactions = 1989032621,
    MessagePeerReaction = 2356786748,
    GroupCallStreamChannel = 2162903215,
    PhoneGroupCallStreamChannels = 3504636594,
    PhoneGroupCallStreamRtmpUrl = 767505458,
    AttachMenuBotIconColor = 1165423600,
    AttachMenuBotIcon = 2997303403,
    AttachMenuBot = 3641544190,
    AttachMenuBotsNotModified = 4057500252,
    AttachMenuBots = 1011024320,
    AttachMenuBotsBot = 2478794367,
    WebViewResultUrl = 1294139288,
    WebViewMessageSent = 211046684,
    BotMenuButtonDefault = 1966318984,
    BotMenuButtonCommands = 1113113093,
    BotMenuButton = 3350559974,
    AccountSavedRingtonesNotModified = 4227262641,
    AccountSavedRingtones = 3253284037,
    NotificationSoundDefault = 2548612798,
    NotificationSoundNone = 1863070943,
    NotificationSoundLocal = 2198575844,
    NotificationSoundRingtone = 4285300809,
    AccountSavedRingtone = 3072737133,
    AccountSavedRingtoneConverted = 523271863,
    AttachMenuPeerTypeSameBotPM = 2104224014,
    AttachMenuPeerTypeBotPM = 3274439194,
    AttachMenuPeerTypePM = 4047950623,
    AttachMenuPeerTypeChat = 84480319,
    AttachMenuPeerTypeBroadcast = 2080104188,
    InputInvoiceMessage = 3317000281,
    InputInvoiceSlug = 3274099439,
    InputInvoicePremiumGiftCode = 2560125965,
    InputInvoiceStars = 1710230755,
    InputInvoiceChatInviteSubscription = 887591921,
    InputInvoiceStarGift = 634962392,
    PaymentsExportedInvoice = 2932919257,
    MessagesTranscribedAudio = 3485063511,
    HelpPremiumPromo = 1395946908,
    InputStorePaymentPremiumSubscription = 2792693350,
    InputStorePaymentGiftPremium = 1634697192,
    InputStorePaymentPremiumGiftCode = 2743099199,
    InputStorePaymentPremiumGiveaway = 369444042,
    InputStorePaymentStarsTopup = 3722252118,
    InputStorePaymentStarsGift = 494149367,
    InputStorePaymentStarsGiveaway = 1964968186,
    PremiumGiftOption = 1958953753,
    PaymentFormMethod = 2298016283,
    EmojiStatusEmpty = 769727150,
    EmojiStatus = 2459656605,
    EmojiStatusUntil = 4197492935,
    AccountEmojiStatusesNotModified = 3498894917,
    AccountEmojiStatuses = 2428790737,
    ReactionEmpty = 2046153753,
    ReactionEmoji = 455247544,
    ReactionCustomEmoji = 2302016627,
    ReactionPaid = 1379771627,
    ChatReactionsNone = 3942396604,
    ChatReactionsAll = 1385335754,
    ChatReactionsSome = 1713193015,
    MessagesReactionsNotModified = 2960120799,
    MessagesReactions = 3942512406,
    EmailVerifyPurposeLoginSetup = 1128644211,
    EmailVerifyPurposeLoginChange = 1383932651,
    EmailVerifyPurposePassport = 3153401477,
    EmailVerificationCode = 2452510121,
    EmailVerificationGoogle = 3683688130,
    EmailVerificationApple = 2530243837,
    AccountEmailVerified = 731303195,
    AccountEmailVerifiedLogin = 3787132257,
    PremiumSubscriptionOption = 1596792306,
    SendAsPeer = 3088871476,
    MessageExtendedMediaPreview = 2908916936,
    MessageExtendedMedia = 3997670500,
    StickerKeyword = 4244550300,
    Username = 3020371527,
    ForumTopicDeleted = 37687451,
    ForumTopic = 1903173033,
    MessagesForumTopics = 913709011,
    DefaultHistoryTTL = 1135897376,
    ExportedContactToken = 1103040667,
    RequestPeerTypeUser = 1597737472,
    RequestPeerTypeChat = 3387977243,
    RequestPeerTypeBroadcast = 865857388,
    EmojiListNotModified = 1209970170,
    EmojiList = 2048790993,
    EmojiGroup = 2056961449,
    EmojiGroupGreeting = 2161274055,
    EmojiGroupPremium = 154914612,
    MessagesEmojiGroupsNotModified = 1874111879,
    MessagesEmojiGroups = 2283780427,
    TextWithEntities = 1964978502,
    MessagesTranslateResult = 870003448,
    AutoSaveSettings = 3360175310,
    AutoSaveException = 2170563911,
    AccountAutoSaveSettings = 1279133341,
    HelpAppConfigNotModified = 2094949405,
    HelpAppConfig = 3709368366,
    InputBotAppID = 2837495162,
    InputBotAppShortName = 2425095175,
    BotAppNotModified = 1571189943,
    BotApp = 2516373974,
    MessagesBotApp = 3947933173,
    InlineBotWebView = 3044185557,
    ReadParticipantDate = 1246753138,
    InputChatlistDialogFilter = 4091599411,
    ExportedChatlistInvite = 206668204,
    ChatlistsExportedChatlistInvite = 283567014,
    ChatlistsExportedInvites = 279670215,
    ChatlistsChatlistInviteAlready = 4203214425,
    ChatlistsChatlistInvite = 500007837,
    ChatlistsChatlistUpdates = 2478671757,
    BotsBotInfo = 3903288752,
    MessagePeerVote = 3066834268,
    MessagePeerVoteInputOption = 1959634180,
    MessagePeerVoteMultiple = 1177089766,
    StoryViews = 2371443926,
    StoryItemDeleted = 1374088783,
    StoryItemSkipped = 4289579283,
    StoryItem = 2041735716,
    StoriesAllStoriesNotModified = 291044926,
    StoriesAllStories = 1862033025,
    StoriesStories = 1673780490,
    StoryView = 2965236421,
    StoryViewPublicForward = 2424530699,
    StoryViewPublicRepost = 3178549065,
    StoriesStoryViewsList = 1507299269,
    StoriesStoryViews = 3734957341,
    InputReplyToMessage = 583071445,
    InputReplyToStory = 1484862010,
    ExportedStoryLink = 1070138683,
    StoriesStealthMode = 1898850301,
    MediaAreaCoordinates = 3486113794,
    MediaAreaVenue = 3196246940,
    InputMediaAreaVenue = 2994872703,
    MediaAreaGeoPoint = 3402974509,
    MediaAreaSuggestedReaction = 340088945,
    MediaAreaChannelPost = 1996756655,
    InputMediaAreaChannelPost = 577893055,
    MediaAreaUrl = 926421125,
    MediaAreaWeather = 1235637404,
    PeerStories = 2587224473,
    StoriesPeerStories = 3404105576,
    MessagesWebPage = 4250800829,
    PremiumGiftCodeOption = 629052971,
    PaymentsCheckedGiftCode = 675942550,
    PaymentsGiveawayInfo = 1130879648,
    PaymentsGiveawayInfoResults = 3782600303,
    PrepaidGiveaway = 2991824212,
    PrepaidStarsGiveaway = 2594011104,
    Boost = 1262359766,
    PremiumBoostsList = 2264424764,
    MyBoost = 3293069660,
    PremiumMyBoosts = 2598512866,
    PremiumBoostsStatus = 1230586490,
    StoryFwdHeader = 3089555792,
    PostInteractionCountersMessage = 3875901055,
    PostInteractionCountersStory = 2319978023,
    StatsStoryStats = 1355613820,
    PublicForwardMessage = 32685898,
    PublicForwardStory = 3992169936,
    StatsPublicForwards = 2466479648,
    PeerColor = 3041614543,
    HelpPeerColorSet = 639736408,
    HelpPeerColorProfileSet = 1987928555,
    HelpPeerColorOption = 2917953214,
    HelpPeerColorsNotModified = 732034510,
    HelpPeerColors = 16313608,
    StoryReaction = 1620104917,
    StoryReactionPublicForward = 3148555843,
    StoryReactionPublicRepost = 3486322451,
    StoriesStoryReactionsList = 2858383516,
    SavedDialog = 3179793260,
    MessagesSavedDialogs = 4164608545,
    MessagesSavedDialogsSlice = 1153080793,
    MessagesSavedDialogsNotModified = 3223285736,
    SavedReactionTag = 3413112872,
    MessagesSavedReactionTagsNotModified = 2291882479,
    MessagesSavedReactionTags = 844731658,
    OutboxReadDate = 1001931436,
    SmsjobsEligibleToJoin = 3700114639,
    SmsjobsStatus = 720277905,
    SmsJob = 3869372088,
    BusinessWeeklyOpen = 302717625,
    BusinessWorkHours = 2358423704,
    BusinessLocation = 2891717367,
    InputBusinessRecipients = 1871393450,
    BusinessRecipients = 554733559,
    BusinessAwayMessageScheduleAlways = 3384402617,
    BusinessAwayMessageScheduleOutsideWorkHours = 3287479553,
    BusinessAwayMessageScheduleCustom = 3427638988,
    InputBusinessGreetingMessage = 26528571,
    BusinessGreetingMessage = 3843664811,
    InputBusinessAwayMessage = 2200008160,
    BusinessAwayMessage = 4011158108,
    Timezone = 4287793653,
    HelpTimezonesListNotModified = 2533820620,
    HelpTimezonesList = 2071260529,
    QuickReply = 110563371,
    InputQuickReplyShortcut = 609840449,
    InputQuickReplyShortcutId = 18418929,
    MessagesQuickReplies = 3331155605,
    MessagesQuickRepliesNotModified = 1603398491,
    ConnectedBot = 3171321345,
    AccountConnectedBots = 400029819,
    MessagesDialogFilters = 718878489,
    Birthday = 1821253126,
    BotBusinessConnection = 2305045428,
    InputBusinessIntro = 163867085,
    BusinessIntro = 1510606445,
    MessagesMyStickers = 4211040925,
    InputCollectibleUsername = 3818152105,
    InputCollectiblePhone = 2732725412,
    FragmentCollectibleInfo = 1857945489,
    InputBusinessBotRecipients = 3303379486,
    BusinessBotRecipients = 3096245107,
    ContactBirthday = 496600883,
    ContactsContactBirthdays = 290452237,
    MissingInvitee = 1653379620,
    MessagesInvitedUsers = 2136862630,
    InputBusinessChatLink = 292003751,
    BusinessChatLink = 3031328367,
    AccountBusinessChatLinks = 3963855569,
    AccountResolvedBusinessChatLinks = 2586029857,
    RequestedPeerUser = 3593466986,
    RequestedPeerChat = 1929860175,
    RequestedPeerChannel = 2342781924,
    SponsoredMessageReportOption = 1124938064,
    ChannelsSponsoredMessageReportResultChooseOption = 2221907522,
    ChannelsSponsoredMessageReportResultAdsHidden = 1044107055,
    ChannelsSponsoredMessageReportResultReported = 2910423113,
    StatsBroadcastRevenueStats = 1409802903,
    StatsBroadcastRevenueWithdrawalUrl = 3966080823,
    BroadcastRevenueTransactionProceeds = 1434332356,
    BroadcastRevenueTransactionWithdrawal = 1515784568,
    BroadcastRevenueTransactionRefund = 1121127726,
    StatsBroadcastRevenueTransactions = 2266334310,
    ReactionNotificationsFromContacts = 3133384218,
    ReactionNotificationsFromAll = 1268654752,
    ReactionsNotifySettings = 1457736048,
    BroadcastRevenueBalances = 3288297959,
    AvailableEffect = 2479088254,
    MessagesAvailableEffectsNotModified = 3522009691,
    MessagesAvailableEffects = 3185271150,
    FactCheck = 3097230543,
    StarsTransactionPeerUnsupported = 2515714020,
    StarsTransactionPeerAppStore = 3025646453,
    StarsTransactionPeerPlayMarket = 2069236235,
    StarsTransactionPeerPremiumBot = 621656824,
    StarsTransactionPeerFragment = 3912227074,
    StarsTransactionPeer = 3624771933,
    StarsTransactionPeerAds = 1617438738,
    StarsTopupOption = 198776256,
    StarsTransaction = 178185410,
    PaymentsStarsStatus = 3153736044,
    FoundStory = 3900361664,
    StoriesFoundStories = 3806230327,
    GeoPointAddress = 3729546643,
    StarsRevenueStatus = 2033461574,
    PaymentsStarsRevenueStats = 3375085371,
    PaymentsStarsRevenueWithdrawalUrl = 497778871,
    PaymentsStarsRevenueAdsAccountUrl = 961445665,
    InputStarsTransaction = 543876817,
    StarsGiftOption = 1577421297,
    BotsPopularAppBots = 428978491,
    BotPreviewMedia = 602479523,
    BotsPreviewInfo = 212278628,
    StarsSubscriptionPricing = 88173912,
    StarsSubscription = 1401868056,
    MessageReactor = 1269016922,
    StarsGiveawayOption = 2496562474,
    StarsGiveawayWinnersOption = 1411605001,
    StarGift = 2929816814,
    PaymentsStarGiftsNotModified = 2743640936,
    PaymentsStarGifts = 2417396202,
    UserStarGift = 4003764846,
    PaymentsUserStarGifts = 1801827607,
    MessageReportOption = 2030298073,
    ReportResultChooseOption = 4041531574,
    ReportResultAddComment = 1862904881,
    ReportResultReported = 2377333835,
    InvokeAfterMsgs = 1036301552,
    InitConnection = 3251461801,
    InvokeWithLayer = 3667594509,
    InvokeWithoutUpdates = 3214170551,
    InvokeWithMessagesRange = 911373810,
    InvokeWithTakeout = 2896821550,
    InvokeWithBusinessConnection = 3710427022,
    InvokeWithGooglePlayIntegrity = 502868356,
    InvokeWithApnsSecret = 229528824,
    AuthSendCode = 2792825935,
    AuthSignUp = 2865215255,
    AuthSignIn = 2371004753,
    AuthLogOut = 1047706137,
    AuthResetAuthorizations = 2678787354,
    AuthExportAuthorization = 3854565325,
    AuthImportAuthorization = 2776268205,
    AuthBindTempAuthKey = 3453233669,
    AuthImportBotAuthorization = 1738800940,
    AuthCheckPassword = 3515567382,
    AuthRequestPasswordRecovery = 3633822822,
    AuthRecoverPassword = 923364464,
    AuthResendCode = 3403969827,
    AuthCancelCode = 520357240,
    AuthDropTempAuthKeys = 2387124616,
    AuthExportLoginToken = 3084944894,
    AuthImportLoginToken = 2511101156,
    AuthAcceptLoginToken = 3902057805,
    AuthCheckRecoveryPassword = 221691769,
    AuthImportWebTokenAuthorization = 767062953,
    AuthRequestFirebaseSms = 2386109982,
    AuthResetLoginEmail = 2123760019,
    AuthReportMissingCode = 3416125430,
    AccountRegisterDevice = 3968205178,
    AccountUnregisterDevice = 1779249670,
    AccountUpdateNotifySettings = 2227067795,
    AccountGetNotifySettings = 313765169,
    AccountResetNotifySettings = 3682473799,
    AccountUpdateProfile = 2018596725,
    AccountUpdateStatus = 1713919532,
    AccountGetWallPapers = 127302966,
    AccountReportPeer = 3317316998,
    AccountCheckUsername = 655677548,
    AccountUpdateUsername = 1040964988,
    AccountGetPrivacy = 3671837008,
    AccountSetPrivacy = 3388480744,
    AccountDeleteAccount = 2730545012,
    AccountGetAccountTTL = 150761757,
    AccountSetAccountTTL = 608323678,
    AccountSendChangePhoneCode = 2186758885,
    AccountChangePhone = 1891839707,
    AccountUpdateDeviceLocked = 954152242,
    AccountGetAuthorizations = 3810574680,
    AccountResetAuthorization = 3749180348,
    AccountGetPassword = 1418342645,
    AccountGetPasswordSettings = 2631199481,
    AccountUpdatePasswordSettings = 2778402863,
    AccountSendConfirmPhoneCode = 457157256,
    AccountConfirmPhone = 1596029123,
    AccountGetTmpPassword = 1151208273,
    AccountGetWebAuthorizations = 405695855,
    AccountResetWebAuthorization = 755087855,
    AccountResetWebAuthorizations = 1747789204,
    AccountGetAllSecureValues = 2995305597,
    AccountGetSecureValue = 1936088002,
    AccountSaveSecureValue = 2308956957,
    AccountDeleteSecureValue = 3095444555,
    AccountGetAuthorizationForm = 2838059386,
    AccountAcceptAuthorization = 4092415091,
    AccountSendVerifyPhoneCode = 2778945273,
    AccountVerifyPhone = 1305716726,
    AccountSendVerifyEmailCode = 2564831163,
    AccountVerifyEmail = 53322959,
    AccountInitTakeoutSession = 2398350000,
    AccountFinishTakeoutSession = 489050862,
    AccountConfirmPasswordEmail = 2413762848,
    AccountResendPasswordEmail = 2055154197,
    AccountCancelPasswordEmail = 3251361206,
    AccountGetContactSignUpNotification = 2668087080,
    AccountSetContactSignUpNotification = 3488890721,
    AccountGetNotifyExceptions = 1398240377,
    AccountGetWallPaper = 4237155306,
    AccountUploadWallPaper = 3818557187,
    AccountSaveWallPaper = 1817860919,
    AccountInstallWallPaper = 4276967273,
    AccountResetWallPapers = 3141244932,
    AccountGetAutoDownloadSettings = 1457130303,
    AccountSaveAutoDownloadSettings = 1995661875,
    AccountUploadTheme = 473805619,
    AccountCreateTheme = 1697530880,
    AccountUpdateTheme = 737414348,
    AccountSaveTheme = 4065792108,
    AccountInstallTheme = 3341269819,
    AccountGetTheme = 978872812,
    AccountGetThemes = 1913054296,
    AccountSetContentSettings = 3044323691,
    AccountGetContentSettings = 2342210990,
    AccountGetMultiWallPapers = 1705865692,
    AccountGetGlobalPrivacySettings = 3945483510,
    AccountSetGlobalPrivacySettings = 517647042,
    AccountReportProfilePhoto = 4203529973,
    AccountResetPassword = 2466827803,
    AccountDeclinePasswordReset = 1284770294,
    AccountGetChatThemes = 3594051209,
    AccountSetAuthorizationTTL = 3213466272,
    AccountChangeAuthorizationSettings = 1089766498,
    AccountGetSavedRingtones = 3784319624,
    AccountSaveRingtone = 1038768899,
    AccountUploadRingtone = 2199552930,
    AccountUpdateEmojiStatus = 4224966251,
    AccountGetDefaultEmojiStatuses = 3598005126,
    AccountGetRecentEmojiStatuses = 257392901,
    AccountClearRecentEmojiStatuses = 404757166,
    AccountReorderUsernames = 4015001259,
    AccountToggleUsername = 1490465654,
    AccountGetDefaultProfilePhotoEmojis = 3799319336,
    AccountGetDefaultGroupPhotoEmojis = 2438488238,
    AccountGetAutoSaveSettings = 2915810522,
    AccountSaveAutoSaveSettings = 3600515937,
    AccountDeleteAutoSaveExceptions = 1404829728,
    AccountInvalidateSignInCodes = 3398101178,
    AccountUpdateColor = 2096079197,
    AccountGetDefaultBackgroundEmojis = 2785720782,
    AccountGetChannelDefaultEmojiStatuses = 1999087573,
    AccountGetChannelRestrictedStatusEmojis = 900325589,
    AccountUpdateBusinessWorkHours = 1258348646,
    AccountUpdateBusinessLocation = 2657817370,
    AccountUpdateBusinessGreetingMessage = 1724755908,
    AccountUpdateBusinessAwayMessage = 2724888485,
    AccountUpdateConnectedBot = 1138250269,
    AccountGetConnectedBots = 1319421967,
    AccountGetBotBusinessConnection = 1990746736,
    AccountUpdateBusinessIntro = 2786381876,
    AccountToggleConnectedBotPaused = 1684934807,
    AccountDisablePeerConnectedBot = 1581481689,
    AccountUpdateBirthday = 3429764113,
    AccountCreateBusinessChatLink = 2287068814,
    AccountEditBusinessChatLink = 2352222383,
    AccountDeleteBusinessChatLink = 1611085428,
    AccountGetBusinessChatLinks = 1869667809,
    AccountResolveBusinessChatLink = 1418913262,
    AccountUpdatePersonalChannel = 3645048288,
    AccountToggleSponsoredMessages = 3118048141,
    AccountGetReactionsNotifySettings = 115172684,
    AccountSetReactionsNotifySettings = 829220168,
    UsersGetUsers = 227648840,
    UsersGetFullUser = 3054459160,
    UsersSetSecureValueErrors = 2429064373,
    UsersGetIsPremiumRequiredToContact = 2787289616,
    ContactsGetContactIDs = 2061264541,
    ContactsGetStatuses = 3299038190,
    ContactsGetContacts = 1574346258,
    ContactsImportContacts = 746589157,
    ContactsDeleteContacts = 157945344,
    ContactsDeleteByPhones = 269745566,
    ContactsBlock = 774801204,
    ContactsUnblock = 3041973032,
    ContactsGetBlocked = 2592509824,
    ContactsSearch = 301470424,
    ContactsResolveUsername = 4181511075,
    ContactsGetTopPeers = 2536798390,
    ContactsResetTopPeerRating = 451113900,
    ContactsResetSaved = 2274703345,
    ContactsGetSaved = 2196890527,
    ContactsToggleTopPeers = 2232729050,
    ContactsAddContact = 3908330448,
    ContactsAcceptContact = 4164002319,
    ContactsGetLocated = 3544759364,
    ContactsBlockFromReplies = 698914348,
    ContactsResolvePhone = 2331591492,
    ContactsExportContactToken = 4167385127,
    ContactsImportContactToken = 318789512,
    ContactsEditCloseFriends = 3127313904,
    ContactsSetBlocked = 2496027766,
    ContactsGetBirthdays = 3673008228,
    MessagesGetMessages = 1673946374,
    MessagesGetDialogs = 2700397391,
    MessagesGetHistory = 1143203525,
    MessagesSearch = 703497338,
    MessagesReadHistory = 238054714,
    MessagesDeleteHistory = 2962199082,
    MessagesDeleteMessages = 3851326930,
    MessagesReceivedMessages = 94983360,
    MessagesSetTyping = 1486110434,
    MessagesSendMessage = 2554304325,
    MessagesSendMedia = 2018673486,
    MessagesForwardMessages = 3573781000,
    MessagesReportSpam = 3474297563,
    MessagesGetPeerSettings = 4024018594,
    MessagesReport = 4235767707,
    MessagesGetChats = 1240027791,
    MessagesGetFullChat = 2930772788,
    MessagesEditChatTitle = 1937260541,
    MessagesEditChatPhoto = 903730804,
    MessagesAddChatUser = 3418804487,
    MessagesDeleteChatUser = 2719505579,
    MessagesCreateChat = 2463030740,
    MessagesGetDhConfig = 651135312,
    MessagesRequestEncryption = 4132286275,
    MessagesAcceptEncryption = 1035731989,
    MessagesDiscardEncryption = 4086541984,
    MessagesSetEncryptedTyping = 2031374829,
    MessagesReadEncryptedHistory = 2135648522,
    MessagesSendEncrypted = 1157265941,
    MessagesSendEncryptedFile = 1431914525,
    MessagesSendEncryptedService = 852769188,
    MessagesReceivedQueue = 1436924774,
    MessagesReportEncryptedSpam = 1259113487,
    MessagesReadMessageContents = 916930423,
    MessagesGetStickers = 3584414625,
    MessagesGetAllStickers = 3097534888,
    MessagesGetWebPagePreview = 2338894028,
    MessagesExportChatInvite = 2757090960,
    MessagesCheckChatInvite = 1051570619,
    MessagesImportChatInvite = 1817183516,
    MessagesGetStickerSet = 3365989492,
    MessagesInstallStickerSet = 3348096096,
    MessagesUninstallStickerSet = 4184757726,
    MessagesStartBot = 3873403768,
    MessagesGetMessagesViews = 1468322785,
    MessagesEditChatAdmin = 2824589762,
    MessagesMigrateChat = 2726777625,
    MessagesSearchGlobal = 1271290010,
    MessagesReorderStickerSets = 2016638777,
    MessagesGetDocumentByHash = 2985428511,
    MessagesGetSavedGifs = 1559270965,
    MessagesSaveGif = 846868683,
    MessagesGetInlineBotResults = 1364105629,
    MessagesSetInlineBotResults = 3138561049,
    MessagesSendInlineBotResult = 1052698730,
    MessagesGetMessageEditData = 4255550774,
    MessagesEditMessage = 3755032581,
    MessagesEditInlineBotMessage = 2203418042,
    MessagesGetBotCallbackAnswer = 2470627847,
    MessagesSetBotCallbackAnswer = 3582923530,
    MessagesGetPeerDialogs = 3832593661,
    MessagesSaveDraft = 3547514318,
    MessagesGetAllDrafts = 1782549861,
    MessagesGetFeaturedStickers = 1685588756,
    MessagesReadFeaturedStickers = 1527873830,
    MessagesGetRecentStickers = 2645114939,
    MessagesSaveRecentSticker = 958863608,
    MessagesClearRecentStickers = 2308530221,
    MessagesGetArchivedStickers = 1475442322,
    MessagesGetMaskStickers = 1678738104,
    MessagesGetAttachedStickers = 3428542412,
    MessagesSetGameScore = 2398678208,
    MessagesSetInlineGameScore = 363700068,
    MessagesGetGameHighScores = 3894568093,
    MessagesGetInlineGameHighScores = 258170395,
    MessagesGetCommonChats = 3826032900,
    MessagesGetWebPage = 2375455395,
    MessagesToggleDialogPin = 2805064279,
    MessagesReorderPinnedDialogs = 991616823,
    MessagesGetPinnedDialogs = 3602468338,
    MessagesSetBotShippingResults = 3858133754,
    MessagesSetBotPrecheckoutResults = 163765653,
    MessagesUploadMedia = 345405816,
    MessagesSendScreenshotNotification = 2705348631,
    MessagesGetFavedStickers = 82946729,
    MessagesFaveSticker = 3120547163,
    MessagesGetUnreadMentions = 4043827088,
    MessagesReadMentions = 921026381,
    MessagesGetRecentLocations = 1881817312,
    MessagesSendMultiMedia = 934757205,
    MessagesUploadEncryptedFile = 1347929239,
    MessagesSearchStickerSets = 896555914,
    MessagesGetSplitRanges = 486505992,
    MessagesMarkDialogUnread = 3263617423,
    MessagesGetDialogUnreadMarks = 585256482,
    MessagesClearAllDrafts = 2119757468,
    MessagesUpdatePinnedMessage = 3534419948,
    MessagesSendVote = 283795844,
    MessagesGetPollResults = 1941660731,
    MessagesGetOnlines = 1848369232,
    MessagesEditChatAbout = 3740665751,
    MessagesEditChatDefaultBannedRights = 2777049921,
    MessagesGetEmojiKeywords = 899735650,
    MessagesGetEmojiKeywordsDifference = 352892591,
    MessagesGetEmojiKeywordsLanguages = 1318675378,
    MessagesGetEmojiURL = 3585149990,
    MessagesGetSearchCounters = 465367808,
    MessagesRequestUrlAuth = 428848198,
    MessagesAcceptUrlAuth = 2972479781,
    MessagesHidePeerSettingsBar = 1336717624,
    MessagesGetScheduledHistory = 4111889931,
    MessagesGetScheduledMessages = 3183150180,
    MessagesSendScheduledMessages = 3174597898,
    MessagesDeleteScheduledMessages = 1504586518,
    MessagesGetPollVotes = 3094231054,
    MessagesToggleStickerSets = 3037016042,
    MessagesGetDialogFilters = 4023684233,
    MessagesGetSuggestedDialogFilters = 2728186924,
    MessagesUpdateDialogFilter = 450142282,
    MessagesUpdateDialogFiltersOrder = 3311649252,
    MessagesGetOldFeaturedStickers = 2127598753,
    MessagesGetReplies = 584962828,
    MessagesGetDiscussionMessage = 1147761405,
    MessagesReadDiscussion = 4147227124,
    MessagesUnpinAllMessages = 3995253160,
    MessagesDeleteChat = 1540419152,
    MessagesDeletePhoneCallHistory = 4190888969,
    MessagesCheckHistoryImport = 1140726259,
    MessagesInitHistoryImport = 873008187,
    MessagesUploadImportedMedia = 713433234,
    MessagesStartHistoryImport = 3023958852,
    MessagesGetExportedChatInvites = 2729812982,
    MessagesGetExportedChatInvite = 1937010524,
    MessagesEditExportedChatInvite = 3184144245,
    MessagesDeleteRevokedExportedChatInvites = 1452833749,
    MessagesDeleteExportedChatInvite = 3563365419,
    MessagesGetAdminsWithInvites = 958457583,
    MessagesGetChatInviteImporters = 3741637966,
    MessagesSetHistoryTTL = 3087949796,
    MessagesCheckHistoryImportPeer = 1573261059,
    MessagesSetChatTheme = 3862683967,
    MessagesGetMessageReadParticipants = 834782287,
    MessagesGetSearchResultsCalendar = 1789130429,
    MessagesGetSearchResultsPositions = 2625580816,
    MessagesHideChatJoinRequest = 2145904661,
    MessagesHideAllChatJoinRequests = 3766875370,
    MessagesToggleNoForwards = 2971578274,
    MessagesSaveDefaultSendAs = 3439189910,
    MessagesSendReaction = 3540875476,
    MessagesGetMessagesReactions = 2344259814,
    MessagesGetMessageReactionsList = 1176190792,
    MessagesSetChatAvailableReactions = 2253071745,
    MessagesGetAvailableReactions = 417243308,
    MessagesSetDefaultReaction = 1330094102,
    MessagesTranslateText = 1662529584,
    MessagesGetUnreadReactions = 841173339,
    MessagesReadReactions = 1420459918,
    MessagesSearchSentMedia = 276705696,
    MessagesGetAttachMenuBots = 385663691,
    MessagesGetAttachMenuBot = 1998676370,
    MessagesToggleBotInAttachMenu = 1777704297,
    MessagesRequestWebView = 647873217,
    MessagesProlongWebView = 2966952579,
    MessagesRequestSimpleWebView = 1094336115,
    MessagesSendWebViewResultMessage = 172168437,
    MessagesSendWebViewData = 3691135688,
    MessagesTranscribeAudio = 647928393,
    MessagesRateTranscribedAudio = 2132608815,
    MessagesGetCustomEmojiDocuments = 3651866452,
    MessagesGetEmojiStickers = 4227637647,
    MessagesGetFeaturedEmojiStickers = 248473398,
    MessagesReportReaction = 1063567478,
    MessagesGetTopReactions = 3145803194,
    MessagesGetRecentReactions = 960896434,
    MessagesClearRecentReactions = 2650730420,
    MessagesGetExtendedMedia = 2230847508,
    MessagesSetDefaultHistoryTTL = 2662667333,
    MessagesGetDefaultHistoryTTL = 1703637384,
    MessagesSendBotRequestedPeer = 2444415072,
    MessagesGetEmojiGroups = 1955122779,
    MessagesGetEmojiStatusGroups = 785209037,
    MessagesGetEmojiProfilePhotoGroups = 564480243,
    MessagesSearchCustomEmoji = 739360983,
    MessagesTogglePeerTranslations = 3833378169,
    MessagesGetBotApp = 889046467,
    MessagesRequestAppWebView = 1398901710,
    MessagesSetChatWallPaper = 2415577825,
    MessagesSearchEmojiStickerSets = 2461288780,
    MessagesGetSavedDialogs = 1401016858,
    MessagesGetSavedHistory = 1033519437,
    MessagesDeleteSavedHistory = 1855459371,
    MessagesGetPinnedSavedDialogs = 3594360032,
    MessagesToggleSavedDialogPin = 2894183390,
    MessagesReorderPinnedSavedDialogs = 2339464583,
    MessagesGetSavedReactionTags = 909631579,
    MessagesUpdateSavedReactionTag = 1613331948,
    MessagesGetDefaultTagReactions = 3187225640,
    MessagesGetOutboxReadDate = 2353790557,
    MessagesGetQuickReplies = 3565417128,
    MessagesReorderQuickReplies = 1613961479,
    MessagesCheckQuickReplyShortcut = 4057005011,
    MessagesEditQuickReplyShortcut = 1543519471,
    MessagesDeleteQuickReplyShortcut = 1019234112,
    MessagesGetQuickReplyMessages = 2493814211,
    MessagesSendQuickReplyMessages = 1819610593,
    MessagesDeleteQuickReplyMessages = 3775260944,
    MessagesToggleDialogFilterTags = 4247640649,
    MessagesGetMyStickers = 3501580796,
    MessagesGetEmojiStickerGroups = 500711669,
    MessagesGetAvailableEffects = 3735161401,
    MessagesEditFactCheck = 92925557,
    MessagesDeleteFactCheck = 3520762892,
    MessagesGetFactCheck = 3117270510,
    MessagesRequestMainWebView = 3386908283,
    MessagesSendPaidReaction = 2648090235,
    MessagesTogglePaidReactionPrivacy = 2224739223,
    MessagesGetPaidReactionPrivacy = 1193563562,
    UpdatesGetState = 3990128682,
    UpdatesGetDifference = 432207715,
    UpdatesGetChannelDifference = 51854712,
    PhotosUpdateProfilePhoto = 166207545,
    PhotosUploadProfilePhoto = 59286453,
    PhotosDeletePhotos = 2278522671,
    PhotosGetUserPhotos = 2446144168,
    PhotosUploadContactProfilePhoto = 3779873393,
    UploadSaveFilePart = 3003426337,
    UploadGetFile = 3193124286,
    UploadSaveBigFilePart = 3732629309,
    UploadGetWebFile = 619086221,
    UploadGetCdnFile = 962554330,
    UploadReuploadCdnFile = 2603046056,
    UploadGetCdnFileHashes = 2447130417,
    UploadGetFileHashes = 2438371370,
    HelpGetConfig = 3304659051,
    HelpGetNearestDc = 531836966,
    HelpGetAppUpdate = 1378703997,
    HelpGetInviteText = 1295590211,
    HelpGetSupport = 2631862477,
    HelpSetBotUpdatesStatus = 3961704397,
    HelpGetCdnConfig = 1375900482,
    HelpGetRecentMeUrls = 1036054804,
    HelpGetTermsOfServiceUpdate = 749019089,
    HelpAcceptTermsOfService = 4000511898,
    HelpGetDeepLinkInfo = 1072547679,
    HelpGetAppConfig = 1642330196,
    HelpSaveAppLog = 1862465352,
    HelpGetPassportConfig = 3328290056,
    HelpGetSupportName = 3546343212,
    HelpGetUserInfo = 59377875,
    HelpEditUserInfo = 1723407216,
    HelpGetPromoData = 3231151137,
    HelpHidePromoData = 505748629,
    HelpDismissSuggestion = 4111317665,
    HelpGetCountriesList = 1935116200,
    HelpGetPremiumPromo = 3088815060,
    HelpGetPeerColors = 3665884207,
    HelpGetPeerProfileColors = 2882513405,
    HelpGetTimezonesList = 1236468288,
    ChannelsReadHistory = 3423619383,
    ChannelsDeleteMessages = 2227305806,
    ChannelsReportSpam = 4098523925,
    ChannelsGetMessages = 2911672867,
    ChannelsGetParticipants = 2010044880,
    ChannelsGetParticipant = 2695589062,
    ChannelsGetChannels = 176122811,
    ChannelsGetFullChannel = 141781513,
    ChannelsCreateChannel = 2432722695,
    ChannelsEditAdmin = 3543959810,
    ChannelsEditTitle = 1450044624,
    ChannelsEditPhoto = 4046346185,
    ChannelsCheckUsername = 283557164,
    ChannelsUpdateUsername = 890549214,
    ChannelsJoinChannel = 615851205,
    ChannelsLeaveChannel = 4164332181,
    ChannelsInviteToChannel = 3387112788,
    ChannelsDeleteChannel = 3222347747,
    ChannelsExportMessageLink = 3862932971,
    ChannelsToggleSignatures = 1099781276,
    ChannelsGetAdminedPublicChannels = 4172297903,
    ChannelsEditBanned = 2531708289,
    ChannelsGetAdminLog = 870184064,
    ChannelsSetStickers = 3935085817,
    ChannelsReadMessageContents = 3937786936,
    ChannelsDeleteHistory = 2611648071,
    ChannelsTogglePreHistoryHidden = 3938171212,
    ChannelsGetLeftChannels = 2202135744,
    ChannelsGetGroupsForDiscussion = 4124758904,
    ChannelsSetDiscussionGroup = 1079520178,
    ChannelsEditCreator = 2402864415,
    ChannelsEditLocation = 1491484525,
    ChannelsToggleSlowMode = 3990134512,
    ChannelsGetInactiveChannels = 300429806,
    ChannelsConvertToGigagroup = 187239529,
    ChannelsViewSponsoredMessage = 3199130516,
    ChannelsGetSponsoredMessages = 3961589695,
    ChannelsGetSendAs = 231174382,
    ChannelsDeleteParticipantHistory = 913655003,
    ChannelsToggleJoinToSend = 3838547328,
    ChannelsToggleJoinRequest = 1277789622,
    ChannelsReorderUsernames = 3025988893,
    ChannelsToggleUsername = 1358053637,
    ChannelsDeactivateAllUsernames = 170155475,
    ChannelsToggleForum = 2754186025,
    ChannelsCreateForumTopic = 4094427684,
    ChannelsGetForumTopics = 233136337,
    ChannelsGetForumTopicsByID = 2961383097,
    ChannelsEditForumTopic = 4108296581,
    ChannelsUpdatePinnedForumTopic = 1814925350,
    ChannelsDeleteTopicHistory = 876830509,
    ChannelsReorderPinnedForumTopics = 693150095,
    ChannelsToggleAntiSpam = 1760814315,
    ChannelsReportAntiSpamFalsePositive = 2823857811,
    ChannelsToggleParticipantsHidden = 1785624660,
    ChannelsClickSponsoredMessage = 21257589,
    ChannelsUpdateColor = 3635033713,
    ChannelsToggleViewForumAsMessages = 2537077525,
    ChannelsGetChannelRecommendations = 631707458,
    ChannelsUpdateEmojiStatus = 4040418984,
    ChannelsSetBoostsToUnblockRestrictions = 2906234094,
    ChannelsSetEmojiStickers = 1020866743,
    ChannelsReportSponsoredMessage = 2945447609,
    ChannelsRestrictSponsoredMessages = 2598966553,
    ChannelsSearchPosts = 3516897403,
    BotsSendCustomRequest = 2854709741,
    BotsAnswerWebhookJSONQuery = 3860938573,
    BotsSetBotCommands = 85399130,
    BotsResetBotCommands = 1032708345,
    BotsGetBotCommands = 3813412310,
    BotsSetBotMenuButton = 1157944655,
    BotsGetBotMenuButton = 2623597352,
    BotsSetBotBroadcastDefaultAdminRights = 2021942497,
    BotsSetBotGroupDefaultAdminRights = 2455685610,
    BotsSetBotInfo = 282013987,
    BotsGetBotInfo = 3705214205,
    BotsReorderUsernames = 2533994946,
    BotsToggleUsername = 87861619,
    BotsCanSendMessage = 324662502,
    BotsAllowSendMessage = 4046644207,
    BotsInvokeWebViewCustomMethod = 142591463,
    BotsGetPopularAppBots = 3260088722,
    BotsAddPreviewMedia = 397326170,
    BotsEditPreviewMedia = 2233819247,
    BotsDeletePreviewMedia = 755054003,
    BotsReorderPreviewMedias = 3056071594,
    BotsGetPreviewInfo = 1111143341,
    BotsGetPreviewMedias = 2728745293,
    PaymentsGetPaymentForm = 924093883,
    PaymentsGetPaymentReceipt = 611897804,
    PaymentsValidateRequestedInfo = 3066622251,
    PaymentsSendPaymentForm = 755192367,
    PaymentsGetSavedInfo = 578650699,
    PaymentsClearSavedInfo = 3627905217,
    PaymentsGetBankCardData = 779736953,
    PaymentsExportInvoice = 261206117,
    PaymentsAssignAppStoreTransaction = 2163045501,
    PaymentsAssignPlayMarketTransaction = 3757920467,
    PaymentsCanPurchasePremium = 2680266422,
    PaymentsGetPremiumGiftCodeOptions = 660060756,
    PaymentsCheckGiftCode = 2387719361,
    PaymentsApplyGiftCode = 4142032980,
    PaymentsGetGiveawayInfo = 4095972389,
    PaymentsLaunchPrepaidGiveaway = 1609928480,
    PaymentsGetStarsTopupOptions = 3222194131,
    PaymentsGetStarsStatus = 273665959,
    PaymentsGetStarsTransactions = 1775912279,
    PaymentsSendStarsForm = 2040056084,
    PaymentsRefundStarsCharge = 632196938,
    PaymentsGetStarsRevenueStats = 3642751702,
    PaymentsGetStarsRevenueWithdrawalUrl = 331081907,
    PaymentsGetStarsRevenueAdsAccountUrl = 3520589765,
    PaymentsGetStarsTransactionsByID = 662973742,
    PaymentsGetStarsGiftOptions = 3553192904,
    PaymentsGetStarsSubscriptions = 52761285,
    PaymentsChangeStarsSubscription = 3346466936,
    PaymentsFulfillStarsSubscription = 3428576179,
    PaymentsGetStarsGiveawayOptions = 3172924734,
    PaymentsGetStarGifts = 3293984144,
    PaymentsGetUserStarGifts = 1584580577,
    PaymentsSaveStarGift = 2276257934,
    PaymentsConvertStarGift = 69328935,
    StickersCreateStickerSet = 2418125671,
    StickersRemoveStickerFromSet = 4151709521,
    StickersChangeStickerPosition = 4290172106,
    StickersAddStickerToSet = 2253651646,
    StickersSetStickerSetThumb = 2808763282,
    StickersCheckShortName = 676017721,
    StickersSuggestShortName = 1303364867,
    StickersChangeSticker = 4115889852,
    StickersRenameStickerSet = 306912256,
    StickersDeleteStickerSet = 2272281492,
    StickersReplaceSticker = 1184253338,
    PhoneGetCallConfig = 1430593449,
    PhoneRequestCall = 1124046573,
    PhoneAcceptCall = 1003664544,
    PhoneConfirmCall = 788404002,
    PhoneReceivedCall = 399855457,
    PhoneDiscardCall = 2999697856,
    PhoneSetCallRating = 1508562471,
    PhoneSaveCallDebug = 662363518,
    PhoneSendSignalingData = 4286223235,
    PhoneCreateGroupCall = 1221445336,
    PhoneJoinGroupCall = 2972909435,
    PhoneLeaveGroupCall = 1342404601,
    PhoneInviteToGroupCall = 2067345760,
    PhoneDiscardGroupCall = 2054648117,
    PhoneToggleGroupCallSettings = 1958458429,
    PhoneGetGroupCall = 68699611,
    PhoneGetGroupParticipants = 3310934187,
    PhoneCheckGroupCall = 3046963575,
    PhoneToggleGroupCallRecord = 4045981448,
    PhoneEditGroupCallParticipant = 2770811583,
    PhoneEditGroupCallTitle = 480685066,
    PhoneGetGroupCallJoinAs = 4017889594,
    PhoneExportGroupCallInvite = 3869926527,
    PhoneToggleGroupCallStartSubscription = 563885286,
    PhoneStartScheduledGroupCall = 1451287362,
    PhoneSaveDefaultGroupCallJoinAs = 1465786252,
    PhoneJoinGroupCallPresentation = 3421137860,
    PhoneLeaveGroupCallPresentation = 475058500,
    PhoneGetGroupCallStreamChannels = 447879488,
    PhoneGetGroupCallStreamRtmpUrl = 3736316863,
    PhoneSaveCallLog = 1092913030,
    LangpackGetLangPack = 4075959050,
    LangpackGetStrings = 4025104387,
    LangpackGetDifference = 3449309861,
    LangpackGetLanguages = 1120311183,
    LangpackGetLanguage = 1784243458,
    FoldersEditPeerFolders = 1749536939,
    StatsGetBroadcastStats = 2873246746,
    StatsLoadAsyncGraph = 1646092192,
    StatsGetMegagroupStats = 3705636359,
    StatsGetMessagePublicForwards = 1595212100,
    StatsGetMessageStats = 3068175349,
    StatsGetStoryStats = 927985472,
    StatsGetStoryPublicForwards = 2789441270,
    StatsGetBroadcastRevenueStats = 1977595505,
    StatsGetBroadcastRevenueWithdrawalUrl = 711323507,
    StatsGetBroadcastRevenueTransactions = 6891535,
    ChatlistsExportChatlistInvite = 2222081934,
    ChatlistsDeleteExportedInvite = 1906072670,
    ChatlistsEditExportedInvite = 1698543165,
    ChatlistsGetExportedInvites = 3456359043,
    ChatlistsCheckChatlistInvite = 1103171583,
    ChatlistsJoinChatlistInvite = 2796675994,
    ChatlistsGetChatlistUpdates = 2302776609,
    ChatlistsJoinChatlistUpdates = 3767138549,
    ChatlistsHideChatlistUpdates = 1726252795,
    ChatlistsGetLeaveChatlistSuggestions = 4257011476,
    ChatlistsLeaveChatlist = 1962598714,
    StoriesCanSendStory = 3353337821,
    StoriesSendStory = 3840305483,
    StoriesEditStory = 3045308998,
    StoriesDeleteStories = 2925124447,
    StoriesTogglePinned = 2591400431,
    StoriesGetAllStories = 4004566565,
    StoriesGetPinnedStories = 1478600156,
    StoriesGetStoriesArchive = 3023380502,
    StoriesGetStoriesByID = 1467271796,
    StoriesToggleAllStoriesHidden = 2082822084,
    StoriesReadStories = 2773932744,
    StoriesIncrementStoryViews = 2986511099,
    StoriesGetStoryViewsList = 2127707223,
    StoriesGetStoriesViews = 685862088,
    StoriesExportStoryLink = 2072899360,
    StoriesReport = 433646405,
    StoriesActivateStealthMode = 1471926630,
    StoriesSendReaction = 2144810674,
    StoriesGetPeerStories = 743103056,
    StoriesGetAllReadPeerStories = 2606426105,
    StoriesGetPeerMaxIDs = 1398375363,
    StoriesGetChatsToSend = 2775223136,
    StoriesTogglePeerStoriesHidden = 3171161540,
    StoriesGetStoryReactionsList = 3115485215,
    StoriesTogglePinnedToTop = 187268763,
    StoriesSearchPosts = 1827279210,
    PremiumGetBoostsList = 1626764896,
    PremiumGetMyBoosts = 199719754,
    PremiumApplyBoost = 1803396934,
    PremiumGetBoostsStatus = 70197089,
    PremiumGetUserBoosts = 965037343,
    SmsjobsIsEligibleToJoin = 249313744,
    SmsjobsJoin = 2806959661,
    SmsjobsLeave = 2560142707,
    SmsjobsUpdateSettings = 155164863,
    SmsjobsGetStatus = 279353576,
    SmsjobsGetSmsJob = 2005766191,
    SmsjobsFinishJob = 1327415076,
    FragmentGetCollectibleInfo = 3189671354,
};
const TL = union(TLID) {
    ProtoResPQ: struct {
        nonce: i128,
        server_nonce: i128,
        pq: []const u8,
        server_public_key_fingerprints: []const i64,
    },
    ProtoPQInnerDataDc: struct {
        pq: []const u8,
        p: []const u8,
        q: []const u8,
        nonce: i128,
        server_nonce: i128,
        new_nonce: i256,
        dc: i32,
    },
    ProtoPQInnerDataTempDc: struct {
        pq: []const u8,
        p: []const u8,
        q: []const u8,
        nonce: i128,
        server_nonce: i128,
        new_nonce: i256,
        dc: i32,
        expires_in: i32,
    },
    ProtoServerDHParamsOk: struct {
        nonce: i128,
        server_nonce: i128,
        encrypted_answer: []const u8,
    },
    ProtoServerDHInnerData: struct {
        nonce: i128,
        server_nonce: i128,
        g: i32,
        dh_prime: []const u8,
        g_a: []const u8,
        server_time: i32,
    },
    ProtoClientDHInnerData: struct {
        nonce: i128,
        server_nonce: i128,
        retry_id: i64,
        g_b: []const u8,
    },
    ProtoDhGenOk: struct {
        nonce: i128,
        server_nonce: i128,
        new_nonce_hash1: i128,
    },
    ProtoDhGenRetry: struct {
        nonce: i128,
        server_nonce: i128,
        new_nonce_hash2: i128,
    },
    ProtoDhGenFail: struct {
        nonce: i128,
        server_nonce: i128,
        new_nonce_hash3: i128,
    },
    ProtoBindAuthKeyInner: struct {
        nonce: i64,
        temp_auth_key_id: i64,
        perm_auth_key_id: i64,
        temp_session_id: i64,
        expires_at: i32,
    },
    ProtoRpcResult: struct {
        req_msg_id: i64,
        result: ProtoObject,
    },
    ProtoRpcError: struct {
        error_code: i32,
        error_message: []const u8,
    },
    ProtoRpcAnswerUnknown: struct {
    },
    ProtoRpcAnswerDroppedRunning: struct {
    },
    ProtoRpcAnswerDropped: struct {
        msg_id: i64,
        seq_no: i32,
        bytes: i32,
    },
    ProtoFutureSalt: struct {
        valid_since: i32,
        valid_until: i32,
        salt: i64,
    },
    ProtoPong: struct {
        msg_id: i64,
        ping_id: i64,
    },
    ProtoDestroySessionOk: struct {
        session_id: i64,
    },
    ProtoDestroySessionNone: struct {
        session_id: i64,
    },
    ProtoNewSessionCreated: struct {
        first_msg_id: i64,
        unique_id: i64,
        server_salt: i64,
    },
    ProtoMessage: struct {
        msg_id: i64,
        seqno: i32,
        bytes: i32,
        body: ProtoObject,
    },
    ProtoGzipPacked: struct {
        packed_data: []const u8,
    },
    ProtoMsgsAck: struct {
        msg_ids: []const i64,
    },
    ProtoBadMsgNotification: struct {
        bad_msg_id: i64,
        bad_msg_seqno: i32,
        error_code: i32,
    },
    ProtoBadServerSalt: struct {
        bad_msg_id: i64,
        bad_msg_seqno: i32,
        error_code: i32,
        new_server_salt: i64,
    },
    ProtoMsgResendReq: struct {
        msg_ids: []const i64,
    },
    ProtoMsgsStateReq: struct {
        msg_ids: []const i64,
    },
    ProtoMsgsStateInfo: struct {
        req_msg_id: i64,
        info: []const u8,
    },
    ProtoMsgsAllInfo: struct {
        msg_ids: []const i64,
        info: []const u8,
    },
    ProtoMsgDetailedInfo: struct {
        msg_id: i64,
        answer_msg_id: i64,
        bytes: i32,
        status: i32,
    },
    ProtoMsgNewDetailedInfo: struct {
        answer_msg_id: i64,
        bytes: i32,
        status: i32,
    },
    ProtoDestroyAuthKeyOk: struct {
    },
    ProtoDestroyAuthKeyNone: struct {
    },
    ProtoDestroyAuthKeyFail: struct {
    },
    ProtoHttpWait: struct {
        max_delay: i32,
        wait_after: i32,
        max_wait: i32,
    },
    ProtoReqDHParams: struct {
        nonce: i128,
        server_nonce: i128,
        p: []const u8,
        q: []const u8,
        public_key_fingerprint: i64,
        encrypted_data: []const u8,
    },
    ProtoSetClientDHParams: struct {
        nonce: i128,
        server_nonce: i128,
        encrypted_data: []const u8,
    },
    ProtoRpcDropAnswer: struct {
        req_msg_id: i64,
    },
    ProtoGetFutureSalts: struct {
        num: i32,
    },
    ProtoPing: struct {
        ping_id: i64,
    },
    ProtoPingDelayDisconnect: struct {
        ping_id: i64,
        disconnect_delay: i32,
    },
    ProtoDestroySession: struct {
        session_id: i64,
    },
    ProtoDestroyAuthKey: struct {
    },
    InputPeerEmpty: struct {
    },
    InputPeerSelf: struct {
    },
    InputPeerChat: struct {
        chat_id: i64,
    },
    InputPeerUser: struct {
        user_id: i64,
        access_hash: i64,
    },
    InputPeerChannel: struct {
        channel_id: i64,
        access_hash: i64,
    },
    InputPeerUserFromMessage: struct {
        peer: InputPeer,
        msg_id: i32,
        user_id: i64,
    },
    InputPeerChannelFromMessage: struct {
        peer: InputPeer,
        msg_id: i32,
        channel_id: i64,
    },
    InputUserEmpty: struct {
    },
    InputUserSelf: struct {
    },
    InputUser: struct {
        user_id: i64,
        access_hash: i64,
    },
    InputUserFromMessage: struct {
        peer: InputPeer,
        msg_id: i32,
        user_id: i64,
    },
    InputPhoneContact: struct {
        client_id: i64,
        phone: []const u8,
        first_name: []const u8,
        last_name: []const u8,
    },
    InputFile: struct {
        id: i64,
        parts: i32,
        name: []const u8,
        md5_checksum: []const u8,
    },
    InputFileBig: struct {
        id: i64,
        parts: i32,
        name: []const u8,
    },
    InputFileStoryDocument: struct {
        id: InputDocument,
    },
    InputMediaEmpty: struct {
    },
    InputMediaUploadedPhoto: struct {
        flags: usize,
        spoiler: ?bool,
        file: InputFile,
        stickers: ?[]const InputDocument,
        ttl_seconds: ?i32,
    },
    InputMediaPhoto: struct {
        flags: usize,
        spoiler: ?bool,
        id: InputPhoto,
        ttl_seconds: ?i32,
    },
    InputMediaGeoPoint: struct {
        geo_point: InputGeoPoint,
    },
    InputMediaContact: struct {
        phone_number: []const u8,
        first_name: []const u8,
        last_name: []const u8,
        vcard: []const u8,
    },
    InputMediaUploadedDocument: struct {
        flags: usize,
        nosound_video: ?bool,
        force_file: ?bool,
        spoiler: ?bool,
        file: InputFile,
        thumb: ?InputFile,
        mime_type: []const u8,
        attributes: []const DocumentAttribute,
        stickers: ?[]const InputDocument,
        ttl_seconds: ?i32,
    },
    InputMediaDocument: struct {
        flags: usize,
        spoiler: ?bool,
        id: InputDocument,
        ttl_seconds: ?i32,
        query: ?[]const u8,
    },
    InputMediaVenue: struct {
        geo_point: InputGeoPoint,
        title: []const u8,
        address: []const u8,
        provider: []const u8,
        venue_id: []const u8,
        venue_type: []const u8,
    },
    InputMediaPhotoExternal: struct {
        flags: usize,
        spoiler: ?bool,
        url: []const u8,
        ttl_seconds: ?i32,
    },
    InputMediaDocumentExternal: struct {
        flags: usize,
        spoiler: ?bool,
        url: []const u8,
        ttl_seconds: ?i32,
    },
    InputMediaGame: struct {
        id: InputGame,
    },
    InputMediaInvoice: struct {
        flags: usize,
        title: []const u8,
        description: []const u8,
        photo: ?InputWebDocument,
        invoice: Invoice,
        payload: []const u8,
        provider: ?[]const u8,
        provider_data: DataJSON,
        start_param: ?[]const u8,
        extended_media: ?InputMedia,
    },
    InputMediaGeoLive: struct {
        flags: usize,
        stopped: ?bool,
        geo_point: InputGeoPoint,
        heading: ?i32,
        period: ?i32,
        proximity_notification_radius: ?i32,
    },
    InputMediaPoll: struct {
        flags: usize,
        poll: Poll,
        correct_answers: ?[]const []const u8,
        solution: ?[]const u8,
        solution_entities: ?[]const MessageEntity,
    },
    InputMediaDice: struct {
        emoticon: []const u8,
    },
    InputMediaStory: struct {
        peer: InputPeer,
        id: i32,
    },
    InputMediaWebPage: struct {
        flags: usize,
        force_large_media: ?bool,
        force_small_media: ?bool,
        optional: ?bool,
        url: []const u8,
    },
    InputMediaPaidMedia: struct {
        flags: usize,
        stars_amount: i64,
        extended_media: []const InputMedia,
        payload: ?[]const u8,
    },
    InputChatPhotoEmpty: struct {
    },
    InputChatUploadedPhoto: struct {
        flags: usize,
        file: ?InputFile,
        video: ?InputFile,
        video_start_ts: ?f64,
        video_emoji_markup: ?VideoSize,
    },
    InputChatPhoto: struct {
        id: InputPhoto,
    },
    InputGeoPointEmpty: struct {
    },
    InputGeoPoint: struct {
        flags: usize,
        lat: f64,
        long: f64,
        accuracy_radius: ?i32,
    },
    InputPhotoEmpty: struct {
    },
    InputPhoto: struct {
        id: i64,
        access_hash: i64,
        file_reference: []const u8,
    },
    InputFileLocation: struct {
        volume_id: i64,
        local_id: i32,
        secret: i64,
        file_reference: []const u8,
    },
    InputEncryptedFileLocation: struct {
        id: i64,
        access_hash: i64,
    },
    InputDocumentFileLocation: struct {
        id: i64,
        access_hash: i64,
        file_reference: []const u8,
        thumb_size: []const u8,
    },
    InputSecureFileLocation: struct {
        id: i64,
        access_hash: i64,
    },
    InputTakeoutFileLocation: struct {
    },
    InputPhotoFileLocation: struct {
        id: i64,
        access_hash: i64,
        file_reference: []const u8,
        thumb_size: []const u8,
    },
    InputPhotoLegacyFileLocation: struct {
        id: i64,
        access_hash: i64,
        file_reference: []const u8,
        volume_id: i64,
        local_id: i32,
        secret: i64,
    },
    InputPeerPhotoFileLocation: struct {
        flags: usize,
        big: ?bool,
        peer: InputPeer,
        photo_id: i64,
    },
    InputStickerSetThumb: struct {
        stickerset: InputStickerSet,
        thumb_version: i32,
    },
    InputGroupCallStream: struct {
        flags: usize,
        call: InputGroupCall,
        time_ms: i64,
        scale: i32,
        video_channel: ?i32,
        video_quality: ?i32,
    },
    PeerUser: struct {
        user_id: i64,
    },
    PeerChat: struct {
        chat_id: i64,
    },
    PeerChannel: struct {
        channel_id: i64,
    },
    StorageFileUnknown: struct {
    },
    StorageFilePartial: struct {
    },
    StorageFileJpeg: struct {
    },
    StorageFileGif: struct {
    },
    StorageFilePng: struct {
    },
    StorageFilePdf: struct {
    },
    StorageFileMp3: struct {
    },
    StorageFileMov: struct {
    },
    StorageFileMp4: struct {
    },
    StorageFileWebp: struct {
    },
    UserEmpty: struct {
        id: i64,
    },
    User: struct {
        flags: usize,
        self: ?bool,
        contact: ?bool,
        mutual_contact: ?bool,
        deleted: ?bool,
        bot: ?bool,
        bot_chat_history: ?bool,
        bot_nochats: ?bool,
        verified: ?bool,
        restricted: ?bool,
        min: ?bool,
        bot_inline_geo: ?bool,
        support: ?bool,
        scam: ?bool,
        apply_min_photo: ?bool,
        fake: ?bool,
        bot_attach_menu: ?bool,
        premium: ?bool,
        attach_menu_enabled: ?bool,
        flags2: usize,
        bot_can_edit: ?bool,
        close_friend: ?bool,
        stories_hidden: ?bool,
        stories_unavailable: ?bool,
        contact_require_premium: ?bool,
        bot_business: ?bool,
        bot_has_main_app: ?bool,
        id: i64,
        access_hash: ?i64,
        first_name: ?[]const u8,
        last_name: ?[]const u8,
        username: ?[]const u8,
        phone: ?[]const u8,
        photo: ?UserProfilePhoto,
        status: ?UserStatus,
        bot_info_version: ?i32,
        restriction_reason: ?[]const RestrictionReason,
        bot_inline_placeholder: ?[]const u8,
        lang_code: ?[]const u8,
        emoji_status: ?EmojiStatus,
        usernames: ?[]const Username,
        stories_max_id: ?i32,
        color: ?PeerColor,
        profile_color: ?PeerColor,
        bot_active_users: ?i32,
    },
    UserProfilePhotoEmpty: struct {
    },
    UserProfilePhoto: struct {
        flags: usize,
        has_video: ?bool,
        personal: ?bool,
        photo_id: i64,
        stripped_thumb: ?[]const u8,
        dc_id: i32,
    },
    UserStatusEmpty: struct {
    },
    UserStatusOnline: struct {
        expires: i32,
    },
    UserStatusOffline: struct {
        was_online: i32,
    },
    UserStatusRecently: struct {
        flags: usize,
        by_me: ?bool,
    },
    UserStatusLastWeek: struct {
        flags: usize,
        by_me: ?bool,
    },
    UserStatusLastMonth: struct {
        flags: usize,
        by_me: ?bool,
    },
    ChatEmpty: struct {
        id: i64,
    },
    Chat: struct {
        flags: usize,
        creator: ?bool,
        left: ?bool,
        deactivated: ?bool,
        call_active: ?bool,
        call_not_empty: ?bool,
        noforwards: ?bool,
        id: i64,
        title: []const u8,
        photo: ChatPhoto,
        participants_count: i32,
        date: i32,
        version: i32,
        migrated_to: ?InputChannel,
        admin_rights: ?ChatAdminRights,
        default_banned_rights: ?ChatBannedRights,
    },
    ChatForbidden: struct {
        id: i64,
        title: []const u8,
    },
    Channel: struct {
        flags: usize,
        creator: ?bool,
        left: ?bool,
        broadcast: ?bool,
        verified: ?bool,
        megagroup: ?bool,
        restricted: ?bool,
        signatures: ?bool,
        min: ?bool,
        scam: ?bool,
        has_link: ?bool,
        has_geo: ?bool,
        slowmode_enabled: ?bool,
        call_active: ?bool,
        call_not_empty: ?bool,
        fake: ?bool,
        gigagroup: ?bool,
        noforwards: ?bool,
        join_to_send: ?bool,
        join_request: ?bool,
        forum: ?bool,
        flags2: usize,
        stories_hidden: ?bool,
        stories_hidden_min: ?bool,
        stories_unavailable: ?bool,
        signature_profiles: ?bool,
        id: i64,
        access_hash: ?i64,
        title: []const u8,
        username: ?[]const u8,
        photo: ChatPhoto,
        date: i32,
        restriction_reason: ?[]const RestrictionReason,
        admin_rights: ?ChatAdminRights,
        banned_rights: ?ChatBannedRights,
        default_banned_rights: ?ChatBannedRights,
        participants_count: ?i32,
        usernames: ?[]const Username,
        stories_max_id: ?i32,
        color: ?PeerColor,
        profile_color: ?PeerColor,
        emoji_status: ?EmojiStatus,
        level: ?i32,
        subscription_until_date: ?i32,
    },
    ChannelForbidden: struct {
        flags: usize,
        broadcast: ?bool,
        megagroup: ?bool,
        id: i64,
        access_hash: i64,
        title: []const u8,
        until_date: ?i32,
    },
    ChatFull: struct {
        flags: usize,
        can_set_username: ?bool,
        has_scheduled: ?bool,
        translations_disabled: ?bool,
        id: i64,
        about: []const u8,
        participants: ChatParticipants,
        chat_photo: ?Photo,
        notify_settings: PeerNotifySettings,
        exported_invite: ?ExportedChatInvite,
        bot_info: ?[]const BotInfo,
        pinned_msg_id: ?i32,
        folder_id: ?i32,
        call: ?InputGroupCall,
        ttl_period: ?i32,
        groupcall_default_join_as: ?Peer,
        theme_emoticon: ?[]const u8,
        requests_pending: ?i32,
        recent_requesters: ?[]const i64,
        available_reactions: ?ChatReactions,
        reactions_limit: ?i32,
    },
    ChannelFull: struct {
        flags: usize,
        can_view_participants: ?bool,
        can_set_username: ?bool,
        can_set_stickers: ?bool,
        hidden_prehistory: ?bool,
        can_set_location: ?bool,
        has_scheduled: ?bool,
        can_view_stats: ?bool,
        blocked: ?bool,
        flags2: usize,
        can_delete_channel: ?bool,
        antispam: ?bool,
        participants_hidden: ?bool,
        translations_disabled: ?bool,
        stories_pinned_available: ?bool,
        view_forum_as_messages: ?bool,
        restricted_sponsored: ?bool,
        can_view_revenue: ?bool,
        paid_media_allowed: ?bool,
        can_view_stars_revenue: ?bool,
        paid_reactions_available: ?bool,
        id: i64,
        about: []const u8,
        participants_count: ?i32,
        admins_count: ?i32,
        kicked_count: ?i32,
        banned_count: ?i32,
        online_count: ?i32,
        read_inbox_max_id: i32,
        read_outbox_max_id: i32,
        unread_count: i32,
        chat_photo: Photo,
        notify_settings: PeerNotifySettings,
        exported_invite: ?ExportedChatInvite,
        bot_info: []const BotInfo,
        migrated_from_chat_id: ?i64,
        migrated_from_max_id: ?i32,
        pinned_msg_id: ?i32,
        stickerset: ?StickerSet,
        available_min_id: ?i32,
        folder_id: ?i32,
        linked_chat_id: ?i64,
        location: ?ChannelLocation,
        slowmode_seconds: ?i32,
        slowmode_next_send_date: ?i32,
        stats_dc: ?i32,
        pts: i32,
        call: ?InputGroupCall,
        ttl_period: ?i32,
        pending_suggestions: ?[]const []const u8,
        groupcall_default_join_as: ?Peer,
        theme_emoticon: ?[]const u8,
        requests_pending: ?i32,
        recent_requesters: ?[]const i64,
        default_send_as: ?Peer,
        available_reactions: ?ChatReactions,
        reactions_limit: ?i32,
        stories: ?PeerStories,
        wallpaper: ?WallPaper,
        boosts_applied: ?i32,
        boosts_unrestrict: ?i32,
        emojiset: ?StickerSet,
    },
    ChatParticipant: struct {
        user_id: i64,
        inviter_id: i64,
        date: i32,
    },
    ChatParticipantCreator: struct {
        user_id: i64,
    },
    ChatParticipantAdmin: struct {
        user_id: i64,
        inviter_id: i64,
        date: i32,
    },
    ChatParticipantsForbidden: struct {
        flags: usize,
        chat_id: i64,
        self_participant: ?ChatParticipant,
    },
    ChatParticipants: struct {
        chat_id: i64,
        participants: []const ChatParticipant,
        version: i32,
    },
    ChatPhotoEmpty: struct {
    },
    ChatPhoto: struct {
        flags: usize,
        has_video: ?bool,
        photo_id: i64,
        stripped_thumb: ?[]const u8,
        dc_id: i32,
    },
    MessageEmpty: struct {
        flags: usize,
        id: i32,
        peer_id: ?Peer,
    },
    Message: struct {
        flags: usize,
        out: ?bool,
        mentioned: ?bool,
        media_unread: ?bool,
        silent: ?bool,
        post: ?bool,
        from_scheduled: ?bool,
        legacy: ?bool,
        edit_hide: ?bool,
        pinned: ?bool,
        noforwards: ?bool,
        invert_media: ?bool,
        flags2: usize,
        offline: ?bool,
        id: i32,
        from_id: ?Peer,
        from_boosts_applied: ?i32,
        peer_id: Peer,
        saved_peer_id: ?Peer,
        fwd_from: ?MessageFwdHeader,
        via_bot_id: ?i64,
        via_business_bot_id: ?i64,
        reply_to: ?MessageReplyHeader,
        date: i32,
        message: []const u8,
        media: ?MessageMedia,
        reply_markup: ?ReplyMarkup,
        entities: ?[]const MessageEntity,
        views: ?i32,
        forwards: ?i32,
        replies: ?MessageReplies,
        edit_date: ?i32,
        post_author: ?[]const u8,
        grouped_id: ?i64,
        reactions: ?MessageReactions,
        restriction_reason: ?[]const RestrictionReason,
        ttl_period: ?i32,
        quick_reply_shortcut_id: ?i32,
        effect: ?i64,
        factcheck: ?FactCheck,
    },
    MessageService: struct {
        flags: usize,
        out: ?bool,
        mentioned: ?bool,
        media_unread: ?bool,
        silent: ?bool,
        post: ?bool,
        legacy: ?bool,
        id: i32,
        from_id: ?Peer,
        peer_id: Peer,
        reply_to: ?MessageReplyHeader,
        date: i32,
        action: MessageAction,
        ttl_period: ?i32,
    },
    MessageMediaEmpty: struct {
    },
    MessageMediaPhoto: struct {
        flags: usize,
        spoiler: ?bool,
        photo: ?Photo,
        ttl_seconds: ?i32,
    },
    MessageMediaGeo: struct {
        geo: GeoPoint,
    },
    MessageMediaContact: struct {
        phone_number: []const u8,
        first_name: []const u8,
        last_name: []const u8,
        vcard: []const u8,
        user_id: i64,
    },
    MessageMediaUnsupported: struct {
    },
    MessageMediaDocument: struct {
        flags: usize,
        nopremium: ?bool,
        spoiler: ?bool,
        video: ?bool,
        round: ?bool,
        voice: ?bool,
        document: ?Document,
        alt_documents: ?[]const Document,
        ttl_seconds: ?i32,
    },
    MessageMediaWebPage: struct {
        flags: usize,
        force_large_media: ?bool,
        force_small_media: ?bool,
        manual: ?bool,
        safe: ?bool,
        webpage: WebPage,
    },
    MessageMediaVenue: struct {
        geo: GeoPoint,
        title: []const u8,
        address: []const u8,
        provider: []const u8,
        venue_id: []const u8,
        venue_type: []const u8,
    },
    MessageMediaGame: struct {
        game: Game,
    },
    MessageMediaInvoice: struct {
        flags: usize,
        shipping_address_requested: ?bool,
        Test: ?bool,
        title: []const u8,
        description: []const u8,
        photo: ?WebDocument,
        receipt_msg_id: ?i32,
        currency: []const u8,
        total_amount: i64,
        start_param: []const u8,
        extended_media: ?MessageExtendedMedia,
    },
    MessageMediaGeoLive: struct {
        flags: usize,
        geo: GeoPoint,
        heading: ?i32,
        period: i32,
        proximity_notification_radius: ?i32,
    },
    MessageMediaPoll: struct {
        poll: Poll,
        results: PollResults,
    },
    MessageMediaDice: struct {
        value: i32,
        emoticon: []const u8,
    },
    MessageMediaStory: struct {
        flags: usize,
        via_mention: ?bool,
        peer: Peer,
        id: i32,
        story: ?StoryItem,
    },
    MessageMediaGiveaway: struct {
        flags: usize,
        only_new_subscribers: ?bool,
        winners_are_visible: ?bool,
        channels: []const i64,
        countries_iso2: ?[]const []const u8,
        prize_description: ?[]const u8,
        quantity: i32,
        months: ?i32,
        stars: ?i64,
        until_date: i32,
    },
    MessageMediaGiveawayResults: struct {
        flags: usize,
        only_new_subscribers: ?bool,
        refunded: ?bool,
        channel_id: i64,
        additional_peers_count: ?i32,
        launch_msg_id: i32,
        winners_count: i32,
        unclaimed_count: i32,
        winners: []const i64,
        months: ?i32,
        stars: ?i64,
        prize_description: ?[]const u8,
        until_date: i32,
    },
    MessageMediaPaidMedia: struct {
        stars_amount: i64,
        extended_media: []const MessageExtendedMedia,
    },
    MessageActionEmpty: struct {
    },
    MessageActionChatCreate: struct {
        title: []const u8,
        users: []const i64,
    },
    MessageActionChatEditTitle: struct {
        title: []const u8,
    },
    MessageActionChatEditPhoto: struct {
        photo: Photo,
    },
    MessageActionChatDeletePhoto: struct {
    },
    MessageActionChatAddUser: struct {
        users: []const i64,
    },
    MessageActionChatDeleteUser: struct {
        user_id: i64,
    },
    MessageActionChatJoinedByLink: struct {
        inviter_id: i64,
    },
    MessageActionChannelCreate: struct {
        title: []const u8,
    },
    MessageActionChatMigrateTo: struct {
        channel_id: i64,
    },
    MessageActionChannelMigrateFrom: struct {
        title: []const u8,
        chat_id: i64,
    },
    MessageActionPinMessage: struct {
    },
    MessageActionHistoryClear: struct {
    },
    MessageActionGameScore: struct {
        game_id: i64,
        score: i32,
    },
    MessageActionPaymentSentMe: struct {
        flags: usize,
        recurring_init: ?bool,
        recurring_used: ?bool,
        currency: []const u8,
        total_amount: i64,
        payload: []const u8,
        info: ?PaymentRequestedInfo,
        shipping_option_id: ?[]const u8,
        charge: PaymentCharge,
    },
    MessageActionPaymentSent: struct {
        flags: usize,
        recurring_init: ?bool,
        recurring_used: ?bool,
        currency: []const u8,
        total_amount: i64,
        invoice_slug: ?[]const u8,
    },
    MessageActionPhoneCall: struct {
        flags: usize,
        video: ?bool,
        call_id: i64,
        reason: ?PhoneCallDiscardReason,
        duration: ?i32,
    },
    MessageActionScreenshotTaken: struct {
    },
    MessageActionCustomAction: struct {
        message: []const u8,
    },
    MessageActionBotAllowed: struct {
        flags: usize,
        attach_menu: ?bool,
        from_request: ?bool,
        domain: ?[]const u8,
        app: ?BotApp,
    },
    MessageActionSecureValuesSentMe: struct {
        values: []const SecureValue,
        credentials: SecureCredentialsEncrypted,
    },
    MessageActionSecureValuesSent: struct {
        types: []const SecureValueType,
    },
    MessageActionContactSignUp: struct {
    },
    MessageActionGeoProximityReached: struct {
        from_id: Peer,
        to_id: Peer,
        distance: i32,
    },
    MessageActionGroupCall: struct {
        flags: usize,
        call: InputGroupCall,
        duration: ?i32,
    },
    MessageActionInviteToGroupCall: struct {
        call: InputGroupCall,
        users: []const i64,
    },
    MessageActionSetMessagesTTL: struct {
        flags: usize,
        period: i32,
        auto_setting_from: ?i64,
    },
    MessageActionGroupCallScheduled: struct {
        call: InputGroupCall,
        schedule_date: i32,
    },
    MessageActionSetChatTheme: struct {
        emoticon: []const u8,
    },
    MessageActionChatJoinedByRequest: struct {
    },
    MessageActionWebViewDataSentMe: struct {
        text: []const u8,
        data: []const u8,
    },
    MessageActionWebViewDataSent: struct {
        text: []const u8,
    },
    MessageActionGiftPremium: struct {
        flags: usize,
        currency: []const u8,
        amount: i64,
        months: i32,
        crypto_currency: ?[]const u8,
        crypto_amount: ?i64,
    },
    MessageActionTopicCreate: struct {
        flags: usize,
        title: []const u8,
        icon_color: i32,
        icon_emoji_id: ?i64,
    },
    MessageActionTopicEdit: struct {
        flags: usize,
        title: ?[]const u8,
        icon_emoji_id: ?i64,
        closed: ?bool,
        hidden: ?bool,
    },
    MessageActionSuggestProfilePhoto: struct {
        photo: Photo,
    },
    MessageActionRequestedPeer: struct {
        button_id: i32,
        peers: []const Peer,
    },
    MessageActionSetChatWallPaper: struct {
        flags: usize,
        same: ?bool,
        for_both: ?bool,
        wallpaper: WallPaper,
    },
    MessageActionGiftCode: struct {
        flags: usize,
        via_giveaway: ?bool,
        unclaimed: ?bool,
        boost_peer: ?Peer,
        months: i32,
        slug: []const u8,
        currency: ?[]const u8,
        amount: ?i64,
        crypto_currency: ?[]const u8,
        crypto_amount: ?i64,
    },
    MessageActionGiveawayLaunch: struct {
        flags: usize,
        stars: ?i64,
    },
    MessageActionGiveawayResults: struct {
        flags: usize,
        stars: ?bool,
        winners_count: i32,
        unclaimed_count: i32,
    },
    MessageActionBoostApply: struct {
        boosts: i32,
    },
    MessageActionRequestedPeerSentMe: struct {
        button_id: i32,
        peers: []const RequestedPeer,
    },
    MessageActionPaymentRefunded: struct {
        flags: usize,
        peer: Peer,
        currency: []const u8,
        total_amount: i64,
        payload: ?[]const u8,
        charge: PaymentCharge,
    },
    MessageActionGiftStars: struct {
        flags: usize,
        currency: []const u8,
        amount: i64,
        stars: i64,
        crypto_currency: ?[]const u8,
        crypto_amount: ?i64,
        transaction_id: ?[]const u8,
    },
    MessageActionPrizeStars: struct {
        flags: usize,
        unclaimed: ?bool,
        stars: i64,
        transaction_id: []const u8,
        boost_peer: Peer,
        giveaway_msg_id: i32,
    },
    MessageActionStarGift: struct {
        flags: usize,
        name_hidden: ?bool,
        saved: ?bool,
        converted: ?bool,
        gift: StarGift,
        message: ?TextWithEntities,
        convert_stars: i64,
    },
    Dialog: struct {
        flags: usize,
        pinned: ?bool,
        unread_mark: ?bool,
        view_forum_as_messages: ?bool,
        peer: Peer,
        top_message: i32,
        read_inbox_max_id: i32,
        read_outbox_max_id: i32,
        unread_count: i32,
        unread_mentions_count: i32,
        unread_reactions_count: i32,
        notify_settings: PeerNotifySettings,
        pts: ?i32,
        draft: ?DraftMessage,
        folder_id: ?i32,
        ttl_period: ?i32,
    },
    DialogFolder: struct {
        flags: usize,
        pinned: ?bool,
        folder: Folder,
        peer: Peer,
        top_message: i32,
        unread_muted_peers_count: i32,
        unread_unmuted_peers_count: i32,
        unread_muted_messages_count: i32,
        unread_unmuted_messages_count: i32,
    },
    PhotoEmpty: struct {
        id: i64,
    },
    Photo: struct {
        flags: usize,
        has_stickers: ?bool,
        id: i64,
        access_hash: i64,
        file_reference: []const u8,
        date: i32,
        sizes: []const PhotoSize,
        video_sizes: ?[]const VideoSize,
        dc_id: i32,
    },
    PhotoSizeEmpty: struct {
        type: []const u8,
    },
    PhotoSize: struct {
        type: []const u8,
        w: i32,
        h: i32,
        size: i32,
    },
    PhotoCachedSize: struct {
        type: []const u8,
        w: i32,
        h: i32,
        bytes: []const u8,
    },
    PhotoStrippedSize: struct {
        type: []const u8,
        bytes: []const u8,
    },
    PhotoSizeProgressive: struct {
        type: []const u8,
        w: i32,
        h: i32,
        sizes: []const i32,
    },
    PhotoPathSize: struct {
        type: []const u8,
        bytes: []const u8,
    },
    GeoPointEmpty: struct {
    },
    GeoPoint: struct {
        flags: usize,
        long: f64,
        lat: f64,
        access_hash: i64,
        accuracy_radius: ?i32,
    },
    AuthSentCode: struct {
        flags: usize,
        type: AuthSentCodeType,
        phone_code_hash: []const u8,
        next_type: ?AuthCodeType,
        timeout: ?i32,
    },
    AuthSentCodeSuccess: struct {
        authorization: AuthAuthorization,
    },
    AuthAuthorization: struct {
        flags: usize,
        setup_password_required: ?bool,
        otherwise_relogin_days: ?i32,
        tmp_sessions: ?i32,
        future_auth_token: ?[]const u8,
        user: User,
    },
    AuthAuthorizationSignUpRequired: struct {
        flags: usize,
        terms_of_service: ?HelpTermsOfService,
    },
    AuthExportedAuthorization: struct {
        id: i64,
        bytes: []const u8,
    },
    InputNotifyPeer: struct {
        peer: InputPeer,
    },
    InputNotifyUsers: struct {
    },
    InputNotifyChats: struct {
    },
    InputNotifyBroadcasts: struct {
    },
    InputNotifyForumTopic: struct {
        peer: InputPeer,
        top_msg_id: i32,
    },
    InputPeerNotifySettings: struct {
        flags: usize,
        show_previews: ?bool,
        silent: ?bool,
        mute_until: ?i32,
        sound: ?NotificationSound,
        stories_muted: ?bool,
        stories_hide_sender: ?bool,
        stories_sound: ?NotificationSound,
    },
    PeerNotifySettings: struct {
        flags: usize,
        show_previews: ?bool,
        silent: ?bool,
        mute_until: ?i32,
        ios_sound: ?NotificationSound,
        android_sound: ?NotificationSound,
        other_sound: ?NotificationSound,
        stories_muted: ?bool,
        stories_hide_sender: ?bool,
        stories_ios_sound: ?NotificationSound,
        stories_android_sound: ?NotificationSound,
        stories_other_sound: ?NotificationSound,
    },
    PeerSettings: struct {
        flags: usize,
        report_spam: ?bool,
        add_contact: ?bool,
        block_contact: ?bool,
        share_contact: ?bool,
        need_contacts_exception: ?bool,
        report_geo: ?bool,
        autoarchived: ?bool,
        invite_members: ?bool,
        request_chat_broadcast: ?bool,
        business_bot_paused: ?bool,
        business_bot_can_reply: ?bool,
        geo_distance: ?i32,
        request_chat_title: ?[]const u8,
        request_chat_date: ?i32,
        business_bot_id: ?i64,
        business_bot_manage_url: ?[]const u8,
    },
    WallPaper: struct {
        id: i64,
        flags: usize,
        creator: ?bool,
        default: ?bool,
        pattern: ?bool,
        dark: ?bool,
        access_hash: i64,
        slug: []const u8,
        document: Document,
        settings: ?WallPaperSettings,
    },
    WallPaperNoFile: struct {
        id: i64,
        flags: usize,
        default: ?bool,
        dark: ?bool,
        settings: ?WallPaperSettings,
    },
    InputReportReasonSpam: struct {
    },
    InputReportReasonViolence: struct {
    },
    InputReportReasonPornography: struct {
    },
    InputReportReasonChildAbuse: struct {
    },
    InputReportReasonOther: struct {
    },
    InputReportReasonCopyright: struct {
    },
    InputReportReasonGeoIrrelevant: struct {
    },
    InputReportReasonFake: struct {
    },
    InputReportReasonIllegalDrugs: struct {
    },
    InputReportReasonPersonalDetails: struct {
    },
    UserFull: struct {
        flags: usize,
        blocked: ?bool,
        phone_calls_available: ?bool,
        phone_calls_private: ?bool,
        can_pin_message: ?bool,
        has_scheduled: ?bool,
        video_calls_available: ?bool,
        voice_messages_forbidden: ?bool,
        translations_disabled: ?bool,
        stories_pinned_available: ?bool,
        blocked_my_stories_from: ?bool,
        wallpaper_overridden: ?bool,
        contact_require_premium: ?bool,
        read_dates_private: ?bool,
        flags2: usize,
        sponsored_enabled: ?bool,
        id: i64,
        about: ?[]const u8,
        settings: PeerSettings,
        personal_photo: ?Photo,
        profile_photo: ?Photo,
        fallback_photo: ?Photo,
        notify_settings: PeerNotifySettings,
        bot_info: ?BotInfo,
        pinned_msg_id: ?i32,
        common_chats_count: i32,
        folder_id: ?i32,
        ttl_period: ?i32,
        theme_emoticon: ?[]const u8,
        private_forward_name: ?[]const u8,
        bot_group_admin_rights: ?ChatAdminRights,
        bot_broadcast_admin_rights: ?ChatAdminRights,
        premium_gifts: ?[]const PremiumGiftOption,
        wallpaper: ?WallPaper,
        stories: ?PeerStories,
        business_work_hours: ?BusinessWorkHours,
        business_location: ?BusinessLocation,
        business_greeting_message: ?BusinessGreetingMessage,
        business_away_message: ?BusinessAwayMessage,
        business_intro: ?BusinessIntro,
        birthday: ?Birthday,
        personal_channel_id: ?i64,
        personal_channel_message: ?i32,
        stargifts_count: ?i32,
    },
    Contact: struct {
        user_id: i64,
        mutual: bool,
    },
    ImportedContact: struct {
        user_id: i64,
        client_id: i64,
    },
    ContactStatus: struct {
        user_id: i64,
        status: UserStatus,
    },
    ContactsContactsNotModified: struct {
    },
    ContactsContacts: struct {
        contacts: []const Contact,
        saved_count: i32,
        users: []const User,
    },
    ContactsImportedContacts: struct {
        imported: []const ImportedContact,
        popular_invites: []const PopularContact,
        retry_contacts: []const i64,
        users: []const User,
    },
    ContactsBlocked: struct {
        blocked: []const PeerBlocked,
        chats: []const Chat,
        users: []const User,
    },
    ContactsBlockedSlice: struct {
        count: i32,
        blocked: []const PeerBlocked,
        chats: []const Chat,
        users: []const User,
    },
    MessagesDialogs: struct {
        dialogs: []const Dialog,
        messages: []const Message,
        chats: []const Chat,
        users: []const User,
    },
    MessagesDialogsSlice: struct {
        count: i32,
        dialogs: []const Dialog,
        messages: []const Message,
        chats: []const Chat,
        users: []const User,
    },
    MessagesDialogsNotModified: struct {
        count: i32,
    },
    MessagesMessages: struct {
        messages: []const Message,
        chats: []const Chat,
        users: []const User,
    },
    MessagesMessagesSlice: struct {
        flags: usize,
        inexact: ?bool,
        count: i32,
        next_rate: ?i32,
        offset_id_offset: ?i32,
        messages: []const Message,
        chats: []const Chat,
        users: []const User,
    },
    MessagesChannelMessages: struct {
        flags: usize,
        inexact: ?bool,
        pts: i32,
        count: i32,
        offset_id_offset: ?i32,
        messages: []const Message,
        topics: []const ForumTopic,
        chats: []const Chat,
        users: []const User,
    },
    MessagesMessagesNotModified: struct {
        count: i32,
    },
    MessagesChats: struct {
        chats: []const Chat,
    },
    MessagesChatsSlice: struct {
        count: i32,
        chats: []const Chat,
    },
    MessagesChatFull: struct {
        full_chat: ChatFull,
        chats: []const Chat,
        users: []const User,
    },
    MessagesAffectedHistory: struct {
        pts: i32,
        pts_count: i32,
        offset: i32,
    },
    InputMessagesFilterEmpty: struct {
    },
    InputMessagesFilterPhotos: struct {
    },
    InputMessagesFilterVideo: struct {
    },
    InputMessagesFilterPhotoVideo: struct {
    },
    InputMessagesFilterDocument: struct {
    },
    InputMessagesFilterUrl: struct {
    },
    InputMessagesFilterGif: struct {
    },
    InputMessagesFilterVoice: struct {
    },
    InputMessagesFilterMusic: struct {
    },
    InputMessagesFilterChatPhotos: struct {
    },
    InputMessagesFilterPhoneCalls: struct {
        flags: usize,
        missed: ?bool,
    },
    InputMessagesFilterRoundVoice: struct {
    },
    InputMessagesFilterRoundVideo: struct {
    },
    InputMessagesFilterMyMentions: struct {
    },
    InputMessagesFilterGeo: struct {
    },
    InputMessagesFilterContacts: struct {
    },
    InputMessagesFilterPinned: struct {
    },
    UpdateNewMessage: struct {
        message: Message,
        pts: i32,
        pts_count: i32,
    },
    UpdateMessageID: struct {
        id: i32,
        random_id: i64,
    },
    UpdateDeleteMessages: struct {
        messages: []const i32,
        pts: i32,
        pts_count: i32,
    },
    UpdateUserTyping: struct {
        user_id: i64,
        action: SendMessageAction,
    },
    UpdateChatUserTyping: struct {
        chat_id: i64,
        from_id: Peer,
        action: SendMessageAction,
    },
    UpdateChatParticipants: struct {
        participants: ChatParticipants,
    },
    UpdateUserStatus: struct {
        user_id: i64,
        status: UserStatus,
    },
    UpdateUserName: struct {
        user_id: i64,
        first_name: []const u8,
        last_name: []const u8,
        usernames: []const Username,
    },
    UpdateNewAuthorization: struct {
        flags: usize,
        unconfirmed: ?bool,
        hash: i64,
        date: ?i32,
        device: ?[]const u8,
        location: ?[]const u8,
    },
    UpdateNewEncryptedMessage: struct {
        message: EncryptedMessage,
        qts: i32,
    },
    UpdateEncryptedChatTyping: struct {
        chat_id: i32,
    },
    UpdateEncryption: struct {
        chat: EncryptedChat,
        date: i32,
    },
    UpdateEncryptedMessagesRead: struct {
        chat_id: i32,
        max_date: i32,
        date: i32,
    },
    UpdateChatParticipantAdd: struct {
        chat_id: i64,
        user_id: i64,
        inviter_id: i64,
        date: i32,
        version: i32,
    },
    UpdateChatParticipantDelete: struct {
        chat_id: i64,
        user_id: i64,
        version: i32,
    },
    UpdateDcOptions: struct {
        dc_options: []const DcOption,
    },
    UpdateNotifySettings: struct {
        peer: NotifyPeer,
        notify_settings: PeerNotifySettings,
    },
    UpdateServiceNotification: struct {
        flags: usize,
        popup: ?bool,
        invert_media: ?bool,
        inbox_date: ?i32,
        type: []const u8,
        message: []const u8,
        media: MessageMedia,
        entities: []const MessageEntity,
    },
    UpdatePrivacy: struct {
        key: PrivacyKey,
        rules: []const PrivacyRule,
    },
    UpdateUserPhone: struct {
        user_id: i64,
        phone: []const u8,
    },
    UpdateReadHistoryInbox: struct {
        flags: usize,
        folder_id: ?i32,
        peer: Peer,
        max_id: i32,
        still_unread_count: i32,
        pts: i32,
        pts_count: i32,
    },
    UpdateReadHistoryOutbox: struct {
        peer: Peer,
        max_id: i32,
        pts: i32,
        pts_count: i32,
    },
    UpdateWebPage: struct {
        webpage: WebPage,
        pts: i32,
        pts_count: i32,
    },
    UpdateReadMessagesContents: struct {
        flags: usize,
        messages: []const i32,
        pts: i32,
        pts_count: i32,
        date: ?i32,
    },
    UpdateChannelTooLong: struct {
        flags: usize,
        channel_id: i64,
        pts: ?i32,
    },
    UpdateChannel: struct {
        channel_id: i64,
    },
    UpdateNewChannelMessage: struct {
        message: Message,
        pts: i32,
        pts_count: i32,
    },
    UpdateReadChannelInbox: struct {
        flags: usize,
        folder_id: ?i32,
        channel_id: i64,
        max_id: i32,
        still_unread_count: i32,
        pts: i32,
    },
    UpdateDeleteChannelMessages: struct {
        channel_id: i64,
        messages: []const i32,
        pts: i32,
        pts_count: i32,
    },
    UpdateChannelMessageViews: struct {
        channel_id: i64,
        id: i32,
        views: i32,
    },
    UpdateChatParticipantAdmin: struct {
        chat_id: i64,
        user_id: i64,
        is_admin: bool,
        version: i32,
    },
    UpdateNewStickerSet: struct {
        stickerset: MessagesStickerSet,
    },
    UpdateStickerSetsOrder: struct {
        flags: usize,
        masks: ?bool,
        emojis: ?bool,
        order: []const i64,
    },
    UpdateStickerSets: struct {
        flags: usize,
        masks: ?bool,
        emojis: ?bool,
    },
    UpdateSavedGifs: struct {
    },
    UpdateBotInlineQuery: struct {
        flags: usize,
        query_id: i64,
        user_id: i64,
        query: []const u8,
        geo: ?GeoPoint,
        peer_type: ?InlineQueryPeerType,
        offset: []const u8,
    },
    UpdateBotInlineSend: struct {
        flags: usize,
        user_id: i64,
        query: []const u8,
        geo: ?GeoPoint,
        id: []const u8,
        msg_id: ?InputBotInlineMessageID,
    },
    UpdateEditChannelMessage: struct {
        message: Message,
        pts: i32,
        pts_count: i32,
    },
    UpdateBotCallbackQuery: struct {
        flags: usize,
        query_id: i64,
        user_id: i64,
        peer: Peer,
        msg_id: i32,
        chat_instance: i64,
        data: ?[]const u8,
        game_short_name: ?[]const u8,
    },
    UpdateEditMessage: struct {
        message: Message,
        pts: i32,
        pts_count: i32,
    },
    UpdateInlineBotCallbackQuery: struct {
        flags: usize,
        query_id: i64,
        user_id: i64,
        msg_id: InputBotInlineMessageID,
        chat_instance: i64,
        data: ?[]const u8,
        game_short_name: ?[]const u8,
    },
    UpdateReadChannelOutbox: struct {
        channel_id: i64,
        max_id: i32,
    },
    UpdateDraftMessage: struct {
        flags: usize,
        peer: Peer,
        top_msg_id: ?i32,
        draft: DraftMessage,
    },
    UpdateReadFeaturedStickers: struct {
    },
    UpdateRecentStickers: struct {
    },
    UpdateConfig: struct {
    },
    UpdatePtsChanged: struct {
    },
    UpdateChannelWebPage: struct {
        channel_id: i64,
        webpage: WebPage,
        pts: i32,
        pts_count: i32,
    },
    UpdateDialogPinned: struct {
        flags: usize,
        pinned: ?bool,
        folder_id: ?i32,
        peer: DialogPeer,
    },
    UpdatePinnedDialogs: struct {
        flags: usize,
        folder_id: ?i32,
        order: ?[]const DialogPeer,
    },
    UpdateBotWebhookJSON: struct {
        data: DataJSON,
    },
    UpdateBotWebhookJSONQuery: struct {
        query_id: i64,
        data: DataJSON,
        timeout: i32,
    },
    UpdateBotShippingQuery: struct {
        query_id: i64,
        user_id: i64,
        payload: []const u8,
        shipping_address: PostAddress,
    },
    UpdateBotPrecheckoutQuery: struct {
        flags: usize,
        query_id: i64,
        user_id: i64,
        payload: []const u8,
        info: ?PaymentRequestedInfo,
        shipping_option_id: ?[]const u8,
        currency: []const u8,
        total_amount: i64,
    },
    UpdatePhoneCall: struct {
        phone_call: PhoneCall,
    },
    UpdateLangPackTooLong: struct {
        lang_code: []const u8,
    },
    UpdateLangPack: struct {
        difference: LangPackDifference,
    },
    UpdateFavedStickers: struct {
    },
    UpdateChannelReadMessagesContents: struct {
        flags: usize,
        channel_id: i64,
        top_msg_id: ?i32,
        messages: []const i32,
    },
    UpdateContactsReset: struct {
    },
    UpdateChannelAvailableMessages: struct {
        channel_id: i64,
        available_min_id: i32,
    },
    UpdateDialogUnreadMark: struct {
        flags: usize,
        unread: ?bool,
        peer: DialogPeer,
    },
    UpdateMessagePoll: struct {
        flags: usize,
        poll_id: i64,
        poll: ?Poll,
        results: PollResults,
    },
    UpdateChatDefaultBannedRights: struct {
        peer: Peer,
        default_banned_rights: ChatBannedRights,
        version: i32,
    },
    UpdateFolderPeers: struct {
        folder_peers: []const FolderPeer,
        pts: i32,
        pts_count: i32,
    },
    UpdatePeerSettings: struct {
        peer: Peer,
        settings: PeerSettings,
    },
    UpdatePeerLocated: struct {
        peers: []const PeerLocated,
    },
    UpdateNewScheduledMessage: struct {
        message: Message,
    },
    UpdateDeleteScheduledMessages: struct {
        peer: Peer,
        messages: []const i32,
    },
    UpdateTheme: struct {
        theme: Theme,
    },
    UpdateGeoLiveViewed: struct {
        peer: Peer,
        msg_id: i32,
    },
    UpdateLoginToken: struct {
    },
    UpdateMessagePollVote: struct {
        poll_id: i64,
        peer: Peer,
        options: []const []const u8,
        qts: i32,
    },
    UpdateDialogFilter: struct {
        flags: usize,
        id: i32,
        filter: ?DialogFilter,
    },
    UpdateDialogFilterOrder: struct {
        order: []const i32,
    },
    UpdateDialogFilters: struct {
    },
    UpdatePhoneCallSignalingData: struct {
        phone_call_id: i64,
        data: []const u8,
    },
    UpdateChannelMessageForwards: struct {
        channel_id: i64,
        id: i32,
        forwards: i32,
    },
    UpdateReadChannelDiscussionInbox: struct {
        flags: usize,
        channel_id: i64,
        top_msg_id: i32,
        read_max_id: i32,
        broadcast_id: ?i64,
        broadcast_post: ?i32,
    },
    UpdateReadChannelDiscussionOutbox: struct {
        channel_id: i64,
        top_msg_id: i32,
        read_max_id: i32,
    },
    UpdatePeerBlocked: struct {
        flags: usize,
        blocked: ?bool,
        blocked_my_stories_from: ?bool,
        peer_id: Peer,
    },
    UpdateChannelUserTyping: struct {
        flags: usize,
        channel_id: i64,
        top_msg_id: ?i32,
        from_id: Peer,
        action: SendMessageAction,
    },
    UpdatePinnedMessages: struct {
        flags: usize,
        pinned: ?bool,
        peer: Peer,
        messages: []const i32,
        pts: i32,
        pts_count: i32,
    },
    UpdatePinnedChannelMessages: struct {
        flags: usize,
        pinned: ?bool,
        channel_id: i64,
        messages: []const i32,
        pts: i32,
        pts_count: i32,
    },
    UpdateChat: struct {
        chat_id: i64,
    },
    UpdateGroupCallParticipants: struct {
        call: InputGroupCall,
        participants: []const GroupCallParticipant,
        version: i32,
    },
    UpdateGroupCall: struct {
        chat_id: i64,
        call: GroupCall,
    },
    UpdatePeerHistoryTTL: struct {
        flags: usize,
        peer: Peer,
        ttl_period: ?i32,
    },
    UpdateChatParticipant: struct {
        flags: usize,
        chat_id: i64,
        date: i32,
        actor_id: i64,
        user_id: i64,
        prev_participant: ?ChatParticipant,
        new_participant: ?ChatParticipant,
        invite: ?ExportedChatInvite,
        qts: i32,
    },
    UpdateChannelParticipant: struct {
        flags: usize,
        via_chatlist: ?bool,
        channel_id: i64,
        date: i32,
        actor_id: i64,
        user_id: i64,
        prev_participant: ?ChannelParticipant,
        new_participant: ?ChannelParticipant,
        invite: ?ExportedChatInvite,
        qts: i32,
    },
    UpdateBotStopped: struct {
        user_id: i64,
        date: i32,
        stopped: bool,
        qts: i32,
    },
    UpdateGroupCallConnection: struct {
        flags: usize,
        presentation: ?bool,
        params: DataJSON,
    },
    UpdateBotCommands: struct {
        peer: Peer,
        bot_id: i64,
        commands: []const BotCommand,
    },
    UpdatePendingJoinRequests: struct {
        peer: Peer,
        requests_pending: i32,
        recent_requesters: []const i64,
    },
    UpdateBotChatInviteRequester: struct {
        peer: Peer,
        date: i32,
        user_id: i64,
        about: []const u8,
        invite: ExportedChatInvite,
        qts: i32,
    },
    UpdateMessageReactions: struct {
        flags: usize,
        peer: Peer,
        msg_id: i32,
        top_msg_id: ?i32,
        reactions: MessageReactions,
    },
    UpdateAttachMenuBots: struct {
    },
    UpdateWebViewResultSent: struct {
        query_id: i64,
    },
    UpdateBotMenuButton: struct {
        bot_id: i64,
        button: BotMenuButton,
    },
    UpdateSavedRingtones: struct {
    },
    UpdateTranscribedAudio: struct {
        flags: usize,
        pending: ?bool,
        peer: Peer,
        msg_id: i32,
        transcription_id: i64,
        text: []const u8,
    },
    UpdateReadFeaturedEmojiStickers: struct {
    },
    UpdateUserEmojiStatus: struct {
        user_id: i64,
        emoji_status: EmojiStatus,
    },
    UpdateRecentEmojiStatuses: struct {
    },
    UpdateRecentReactions: struct {
    },
    UpdateMoveStickerSetToTop: struct {
        flags: usize,
        masks: ?bool,
        emojis: ?bool,
        stickerset: i64,
    },
    UpdateMessageExtendedMedia: struct {
        peer: Peer,
        msg_id: i32,
        extended_media: []const MessageExtendedMedia,
    },
    UpdateChannelPinnedTopic: struct {
        flags: usize,
        pinned: ?bool,
        channel_id: i64,
        topic_id: i32,
    },
    UpdateChannelPinnedTopics: struct {
        flags: usize,
        channel_id: i64,
        order: ?[]const i32,
    },
    UpdateUser: struct {
        user_id: i64,
    },
    UpdateAutoSaveSettings: struct {
    },
    UpdateStory: struct {
        peer: Peer,
        story: StoryItem,
    },
    UpdateReadStories: struct {
        peer: Peer,
        max_id: i32,
    },
    UpdateStoryID: struct {
        id: i32,
        random_id: i64,
    },
    UpdateStoriesStealthMode: struct {
        stealth_mode: StoriesStealthMode,
    },
    UpdateSentStoryReaction: struct {
        peer: Peer,
        story_id: i32,
        reaction: Reaction,
    },
    UpdateBotChatBoost: struct {
        peer: Peer,
        boost: Boost,
        qts: i32,
    },
    UpdateChannelViewForumAsMessages: struct {
        channel_id: i64,
        enabled: bool,
    },
    UpdatePeerWallpaper: struct {
        flags: usize,
        wallpaper_overridden: ?bool,
        peer: Peer,
        wallpaper: ?WallPaper,
    },
    UpdateBotMessageReaction: struct {
        peer: Peer,
        msg_id: i32,
        date: i32,
        actor: Peer,
        old_reactions: []const Reaction,
        new_reactions: []const Reaction,
        qts: i32,
    },
    UpdateBotMessageReactions: struct {
        peer: Peer,
        msg_id: i32,
        date: i32,
        reactions: []const ReactionCount,
        qts: i32,
    },
    UpdateSavedDialogPinned: struct {
        flags: usize,
        pinned: ?bool,
        peer: DialogPeer,
    },
    UpdatePinnedSavedDialogs: struct {
        flags: usize,
        order: ?[]const DialogPeer,
    },
    UpdateSavedReactionTags: struct {
    },
    UpdateSmsJob: struct {
        job_id: []const u8,
    },
    UpdateQuickReplies: struct {
        quick_replies: []const QuickReply,
    },
    UpdateNewQuickReply: struct {
        quick_reply: QuickReply,
    },
    UpdateDeleteQuickReply: struct {
        shortcut_id: i32,
    },
    UpdateQuickReplyMessage: struct {
        message: Message,
    },
    UpdateDeleteQuickReplyMessages: struct {
        shortcut_id: i32,
        messages: []const i32,
    },
    UpdateBotBusinessConnect: struct {
        connection: BotBusinessConnection,
        qts: i32,
    },
    UpdateBotNewBusinessMessage: struct {
        flags: usize,
        connection_id: []const u8,
        message: Message,
        reply_to_message: ?Message,
        qts: i32,
    },
    UpdateBotEditBusinessMessage: struct {
        flags: usize,
        connection_id: []const u8,
        message: Message,
        reply_to_message: ?Message,
        qts: i32,
    },
    UpdateBotDeleteBusinessMessage: struct {
        connection_id: []const u8,
        peer: Peer,
        messages: []const i32,
        qts: i32,
    },
    UpdateNewStoryReaction: struct {
        story_id: i32,
        peer: Peer,
        reaction: Reaction,
    },
    UpdateBroadcastRevenueTransactions: struct {
        peer: Peer,
        balances: BroadcastRevenueBalances,
    },
    UpdateStarsBalance: struct {
        balance: i64,
    },
    UpdateBusinessBotCallbackQuery: struct {
        flags: usize,
        query_id: i64,
        user_id: i64,
        connection_id: []const u8,
        message: Message,
        reply_to_message: ?Message,
        chat_instance: i64,
        data: ?[]const u8,
    },
    UpdateStarsRevenueStatus: struct {
        peer: Peer,
        status: StarsRevenueStatus,
    },
    UpdateBotPurchasedPaidMedia: struct {
        user_id: i64,
        payload: []const u8,
        qts: i32,
    },
    UpdatePaidReactionPrivacy: struct {
        private: bool,
    },
    UpdatesState: struct {
        pts: i32,
        qts: i32,
        date: i32,
        seq: i32,
        unread_count: i32,
    },
    UpdatesDifferenceEmpty: struct {
        date: i32,
        seq: i32,
    },
    UpdatesDifference: struct {
        new_messages: []const Message,
        new_encrypted_messages: []const EncryptedMessage,
        other_updates: []const Update,
        chats: []const Chat,
        users: []const User,
        state: UpdatesState,
    },
    UpdatesDifferenceSlice: struct {
        new_messages: []const Message,
        new_encrypted_messages: []const EncryptedMessage,
        other_updates: []const Update,
        chats: []const Chat,
        users: []const User,
        intermediate_state: UpdatesState,
    },
    UpdatesDifferenceTooLong: struct {
        pts: i32,
    },
    UpdatesTooLong: struct {
    },
    UpdateShortMessage: struct {
        flags: usize,
        out: ?bool,
        mentioned: ?bool,
        media_unread: ?bool,
        silent: ?bool,
        id: i32,
        user_id: i64,
        message: []const u8,
        pts: i32,
        pts_count: i32,
        date: i32,
        fwd_from: ?MessageFwdHeader,
        via_bot_id: ?i64,
        reply_to: ?MessageReplyHeader,
        entities: ?[]const MessageEntity,
        ttl_period: ?i32,
    },
    UpdateShortChatMessage: struct {
        flags: usize,
        out: ?bool,
        mentioned: ?bool,
        media_unread: ?bool,
        silent: ?bool,
        id: i32,
        from_id: i64,
        chat_id: i64,
        message: []const u8,
        pts: i32,
        pts_count: i32,
        date: i32,
        fwd_from: ?MessageFwdHeader,
        via_bot_id: ?i64,
        reply_to: ?MessageReplyHeader,
        entities: ?[]const MessageEntity,
        ttl_period: ?i32,
    },
    UpdateShort: struct {
        update: Update,
        date: i32,
    },
    UpdatesCombined: struct {
        updates: []const Update,
        users: []const User,
        chats: []const Chat,
        date: i32,
        seq_start: i32,
        seq: i32,
    },
    Updates: struct {
        updates: []const Update,
        users: []const User,
        chats: []const Chat,
        date: i32,
        seq: i32,
    },
    UpdateShortSentMessage: struct {
        flags: usize,
        out: ?bool,
        id: i32,
        pts: i32,
        pts_count: i32,
        date: i32,
        media: ?MessageMedia,
        entities: ?[]const MessageEntity,
        ttl_period: ?i32,
    },
    PhotosPhotos: struct {
        photos: []const Photo,
        users: []const User,
    },
    PhotosPhotosSlice: struct {
        count: i32,
        photos: []const Photo,
        users: []const User,
    },
    PhotosPhoto: struct {
        photo: Photo,
        users: []const User,
    },
    UploadFile: struct {
        type: StorageFileType,
        mtime: i32,
        bytes: []const u8,
    },
    UploadFileCdnRedirect: struct {
        dc_id: i32,
        file_token: []const u8,
        encryption_key: []const u8,
        encryption_iv: []const u8,
        file_hashes: []const FileHash,
    },
    DcOption: struct {
        flags: usize,
        ipv6: ?bool,
        media_only: ?bool,
        tcpo_only: ?bool,
        cdn: ?bool,
        static: ?bool,
        this_port_only: ?bool,
        id: i32,
        ip_address: []const u8,
        port: i32,
        secret: ?[]const u8,
    },
    Config: struct {
        flags: usize,
        default_p2p_contacts: ?bool,
        preload_featured_stickers: ?bool,
        revoke_pm_inbox: ?bool,
        blocked_mode: ?bool,
        force_try_ipv6: ?bool,
        date: i32,
        expires: i32,
        test_mode: bool,
        this_dc: i32,
        dc_options: []const DcOption,
        dc_txt_domain_name: []const u8,
        chat_size_max: i32,
        megagroup_size_max: i32,
        forwarded_count_max: i32,
        online_update_period_ms: i32,
        offline_blur_timeout_ms: i32,
        offline_idle_timeout_ms: i32,
        online_cloud_timeout_ms: i32,
        notify_cloud_delay_ms: i32,
        notify_default_delay_ms: i32,
        push_chat_period_ms: i32,
        push_chat_limit: i32,
        edit_time_limit: i32,
        revoke_time_limit: i32,
        revoke_pm_time_limit: i32,
        rating_e_decay: i32,
        stickers_recent_limit: i32,
        channels_read_media_period: i32,
        tmp_sessions: ?i32,
        call_receive_timeout_ms: i32,
        call_ring_timeout_ms: i32,
        call_connect_timeout_ms: i32,
        call_packet_timeout_ms: i32,
        me_url_prefix: []const u8,
        autoupdate_url_prefix: ?[]const u8,
        gif_search_username: ?[]const u8,
        venue_search_username: ?[]const u8,
        img_search_username: ?[]const u8,
        static_maps_provider: ?[]const u8,
        caption_length_max: i32,
        message_length_max: i32,
        webfile_dc_id: i32,
        suggested_lang_code: ?[]const u8,
        lang_pack_version: ?i32,
        base_lang_pack_version: ?i32,
        reactions_default: ?Reaction,
        autologin_token: ?[]const u8,
    },
    NearestDc: struct {
        country: []const u8,
        this_dc: i32,
        nearest_dc: i32,
    },
    HelpAppUpdate: struct {
        flags: usize,
        can_not_skip: ?bool,
        id: i32,
        version: []const u8,
        text: []const u8,
        entities: []const MessageEntity,
        document: ?Document,
        url: ?[]const u8,
        sticker: ?Document,
    },
    HelpNoAppUpdate: struct {
    },
    HelpInviteText: struct {
        message: []const u8,
    },
    EncryptedChatEmpty: struct {
        id: i32,
    },
    EncryptedChatWaiting: struct {
        id: i32,
        access_hash: i64,
        date: i32,
        admin_id: i64,
        participant_id: i64,
    },
    EncryptedChatRequested: struct {
        flags: usize,
        folder_id: ?i32,
        id: i32,
        access_hash: i64,
        date: i32,
        admin_id: i64,
        participant_id: i64,
        g_a: []const u8,
    },
    EncryptedChat: struct {
        id: i32,
        access_hash: i64,
        date: i32,
        admin_id: i64,
        participant_id: i64,
        g_a_or_b: []const u8,
        key_fingerprint: i64,
    },
    EncryptedChatDiscarded: struct {
        flags: usize,
        history_deleted: ?bool,
        id: i32,
    },
    InputEncryptedChat: struct {
        chat_id: i32,
        access_hash: i64,
    },
    EncryptedFileEmpty: struct {
    },
    EncryptedFile: struct {
        id: i64,
        access_hash: i64,
        size: i64,
        dc_id: i32,
        key_fingerprint: i32,
    },
    InputEncryptedFileEmpty: struct {
    },
    InputEncryptedFileUploaded: struct {
        id: i64,
        parts: i32,
        md5_checksum: []const u8,
        key_fingerprint: i32,
    },
    InputEncryptedFile: struct {
        id: i64,
        access_hash: i64,
    },
    InputEncryptedFileBigUploaded: struct {
        id: i64,
        parts: i32,
        key_fingerprint: i32,
    },
    EncryptedMessage: struct {
        random_id: i64,
        chat_id: i32,
        date: i32,
        bytes: []const u8,
        file: EncryptedFile,
    },
    EncryptedMessageService: struct {
        random_id: i64,
        chat_id: i32,
        date: i32,
        bytes: []const u8,
    },
    MessagesDhConfigNotModified: struct {
        random: []const u8,
    },
    MessagesDhConfig: struct {
        g: i32,
        p: []const u8,
        version: i32,
        random: []const u8,
    },
    MessagesSentEncryptedMessage: struct {
        date: i32,
    },
    MessagesSentEncryptedFile: struct {
        date: i32,
        file: EncryptedFile,
    },
    InputDocumentEmpty: struct {
    },
    InputDocument: struct {
        id: i64,
        access_hash: i64,
        file_reference: []const u8,
    },
    DocumentEmpty: struct {
        id: i64,
    },
    Document: struct {
        flags: usize,
        id: i64,
        access_hash: i64,
        file_reference: []const u8,
        date: i32,
        mime_type: []const u8,
        size: i64,
        thumbs: ?[]const PhotoSize,
        video_thumbs: ?[]const VideoSize,
        dc_id: i32,
        attributes: []const DocumentAttribute,
    },
    HelpSupport: struct {
        phone_number: []const u8,
        user: User,
    },
    NotifyPeer: struct {
        peer: Peer,
    },
    NotifyUsers: struct {
    },
    NotifyChats: struct {
    },
    NotifyBroadcasts: struct {
    },
    NotifyForumTopic: struct {
        peer: Peer,
        top_msg_id: i32,
    },
    SendMessageTypingAction: struct {
    },
    SendMessageCancelAction: struct {
    },
    SendMessageRecordVideoAction: struct {
    },
    SendMessageUploadVideoAction: struct {
        progress: i32,
    },
    SendMessageRecordAudioAction: struct {
    },
    SendMessageUploadAudioAction: struct {
        progress: i32,
    },
    SendMessageUploadPhotoAction: struct {
        progress: i32,
    },
    SendMessageUploadDocumentAction: struct {
        progress: i32,
    },
    SendMessageGeoLocationAction: struct {
    },
    SendMessageChooseContactAction: struct {
    },
    SendMessageGamePlayAction: struct {
    },
    SendMessageRecordRoundAction: struct {
    },
    SendMessageUploadRoundAction: struct {
        progress: i32,
    },
    SpeakingInGroupCallAction: struct {
    },
    SendMessageHistoryImportAction: struct {
        progress: i32,
    },
    SendMessageChooseStickerAction: struct {
    },
    SendMessageEmojiInteraction: struct {
        emoticon: []const u8,
        msg_id: i32,
        interaction: DataJSON,
    },
    SendMessageEmojiInteractionSeen: struct {
        emoticon: []const u8,
    },
    ContactsFound: struct {
        my_results: []const Peer,
        results: []const Peer,
        chats: []const Chat,
        users: []const User,
    },
    InputPrivacyKeyStatusTimestamp: struct {
    },
    InputPrivacyKeyChatInvite: struct {
    },
    InputPrivacyKeyPhoneCall: struct {
    },
    InputPrivacyKeyPhoneP2P: struct {
    },
    InputPrivacyKeyForwards: struct {
    },
    InputPrivacyKeyProfilePhoto: struct {
    },
    InputPrivacyKeyPhoneNumber: struct {
    },
    InputPrivacyKeyAddedByPhone: struct {
    },
    InputPrivacyKeyVoiceMessages: struct {
    },
    InputPrivacyKeyAbout: struct {
    },
    InputPrivacyKeyBirthday: struct {
    },
    PrivacyKeyStatusTimestamp: struct {
    },
    PrivacyKeyChatInvite: struct {
    },
    PrivacyKeyPhoneCall: struct {
    },
    PrivacyKeyPhoneP2P: struct {
    },
    PrivacyKeyForwards: struct {
    },
    PrivacyKeyProfilePhoto: struct {
    },
    PrivacyKeyPhoneNumber: struct {
    },
    PrivacyKeyAddedByPhone: struct {
    },
    PrivacyKeyVoiceMessages: struct {
    },
    PrivacyKeyAbout: struct {
    },
    PrivacyKeyBirthday: struct {
    },
    InputPrivacyValueAllowContacts: struct {
    },
    InputPrivacyValueAllowAll: struct {
    },
    InputPrivacyValueAllowUsers: struct {
        users: []const InputUser,
    },
    InputPrivacyValueDisallowContacts: struct {
    },
    InputPrivacyValueDisallowAll: struct {
    },
    InputPrivacyValueDisallowUsers: struct {
        users: []const InputUser,
    },
    InputPrivacyValueAllowChatParticipants: struct {
        chats: []const i64,
    },
    InputPrivacyValueDisallowChatParticipants: struct {
        chats: []const i64,
    },
    InputPrivacyValueAllowCloseFriends: struct {
    },
    InputPrivacyValueAllowPremium: struct {
    },
    PrivacyValueAllowContacts: struct {
    },
    PrivacyValueAllowAll: struct {
    },
    PrivacyValueAllowUsers: struct {
        users: []const i64,
    },
    PrivacyValueDisallowContacts: struct {
    },
    PrivacyValueDisallowAll: struct {
    },
    PrivacyValueDisallowUsers: struct {
        users: []const i64,
    },
    PrivacyValueAllowChatParticipants: struct {
        chats: []const i64,
    },
    PrivacyValueDisallowChatParticipants: struct {
        chats: []const i64,
    },
    PrivacyValueAllowCloseFriends: struct {
    },
    PrivacyValueAllowPremium: struct {
    },
    AccountPrivacyRules: struct {
        rules: []const PrivacyRule,
        chats: []const Chat,
        users: []const User,
    },
    AccountDaysTTL: struct {
        days: i32,
    },
    DocumentAttributeImageSize: struct {
        w: i32,
        h: i32,
    },
    DocumentAttributeAnimated: struct {
    },
    DocumentAttributeSticker: struct {
        flags: usize,
        mask: ?bool,
        alt: []const u8,
        stickerset: InputStickerSet,
        mask_coords: ?MaskCoords,
    },
    DocumentAttributeVideo: struct {
        flags: usize,
        round_message: ?bool,
        supports_streaming: ?bool,
        nosound: ?bool,
        duration: f64,
        w: i32,
        h: i32,
        preload_prefix_size: ?i32,
        video_start_ts: ?f64,
        video_codec: ?[]const u8,
    },
    DocumentAttributeAudio: struct {
        flags: usize,
        voice: ?bool,
        duration: i32,
        title: ?[]const u8,
        performer: ?[]const u8,
        waveform: ?[]const u8,
    },
    DocumentAttributeFilename: struct {
        file_name: []const u8,
    },
    DocumentAttributeHasStickers: struct {
    },
    DocumentAttributeCustomEmoji: struct {
        flags: usize,
        free: ?bool,
        text_color: ?bool,
        alt: []const u8,
        stickerset: InputStickerSet,
    },
    MessagesStickersNotModified: struct {
    },
    MessagesStickers: struct {
        hash: i64,
        stickers: []const Document,
    },
    StickerPack: struct {
        emoticon: []const u8,
        documents: []const i64,
    },
    MessagesAllStickersNotModified: struct {
    },
    MessagesAllStickers: struct {
        hash: i64,
        sets: []const StickerSet,
    },
    MessagesAffectedMessages: struct {
        pts: i32,
        pts_count: i32,
    },
    WebPageEmpty: struct {
        flags: usize,
        id: i64,
        url: ?[]const u8,
    },
    WebPagePending: struct {
        flags: usize,
        id: i64,
        url: ?[]const u8,
        date: i32,
    },
    WebPage: struct {
        flags: usize,
        has_large_media: ?bool,
        id: i64,
        url: []const u8,
        display_url: []const u8,
        hash: i32,
        type: ?[]const u8,
        site_name: ?[]const u8,
        title: ?[]const u8,
        description: ?[]const u8,
        photo: ?Photo,
        embed_url: ?[]const u8,
        embed_type: ?[]const u8,
        embed_width: ?i32,
        embed_height: ?i32,
        duration: ?i32,
        author: ?[]const u8,
        document: ?Document,
        cached_page: ?Page,
        attributes: ?[]const WebPageAttribute,
    },
    WebPageNotModified: struct {
        flags: usize,
        cached_page_views: ?i32,
    },
    Authorization: struct {
        flags: usize,
        current: ?bool,
        official_app: ?bool,
        password_pending: ?bool,
        encrypted_requests_disabled: ?bool,
        call_requests_disabled: ?bool,
        unconfirmed: ?bool,
        hash: i64,
        device_model: []const u8,
        platform: []const u8,
        system_version: []const u8,
        api_id: i32,
        app_name: []const u8,
        app_version: []const u8,
        date_created: i32,
        date_active: i32,
        ip: []const u8,
        country: []const u8,
        region: []const u8,
    },
    AccountAuthorizations: struct {
        authorization_ttl_days: i32,
        authorizations: []const Authorization,
    },
    AccountPassword: struct {
        flags: usize,
        has_recovery: ?bool,
        has_secure_values: ?bool,
        has_password: ?bool,
        current_algo: ?PasswordKdfAlgo,
        srp_B: ?[]const u8,
        srp_id: ?i64,
        hint: ?[]const u8,
        email_unconfirmed_pattern: ?[]const u8,
        new_algo: PasswordKdfAlgo,
        new_secure_algo: SecurePasswordKdfAlgo,
        secure_random: []const u8,
        pending_reset_date: ?i32,
        login_email_pattern: ?[]const u8,
    },
    AccountPasswordSettings: struct {
        flags: usize,
        email: ?[]const u8,
        secure_settings: ?SecureSecretSettings,
    },
    AccountPasswordInputSettings: struct {
        flags: usize,
        new_algo: ?PasswordKdfAlgo,
        new_password_hash: ?[]const u8,
        hint: ?[]const u8,
        email: ?[]const u8,
        new_secure_settings: ?SecureSecretSettings,
    },
    AuthPasswordRecovery: struct {
        email_pattern: []const u8,
    },
    ReceivedNotifyMessage: struct {
        id: i32,
        flags: i32,
    },
    ChatInviteExported: struct {
        flags: usize,
        revoked: ?bool,
        permanent: ?bool,
        request_needed: ?bool,
        link: []const u8,
        admin_id: i64,
        date: i32,
        start_date: ?i32,
        expire_date: ?i32,
        usage_limit: ?i32,
        usage: ?i32,
        requested: ?i32,
        subscription_expired: ?i32,
        title: ?[]const u8,
        subscription_pricing: ?StarsSubscriptionPricing,
    },
    ChatInvitePublicJoinRequests: struct {
    },
    ChatInviteAlready: struct {
        chat: Chat,
    },
    ChatInvite: struct {
        flags: usize,
        channel: ?bool,
        broadcast: ?bool,
        public: ?bool,
        megagroup: ?bool,
        request_needed: ?bool,
        verified: ?bool,
        scam: ?bool,
        fake: ?bool,
        can_refulfill_subscription: ?bool,
        title: []const u8,
        about: ?[]const u8,
        photo: Photo,
        participants_count: i32,
        participants: ?[]const User,
        color: i32,
        subscription_pricing: ?StarsSubscriptionPricing,
        subscription_form_id: ?i64,
    },
    ChatInvitePeek: struct {
        chat: Chat,
        expires: i32,
    },
    InputStickerSetEmpty: struct {
    },
    InputStickerSetID: struct {
        id: i64,
        access_hash: i64,
    },
    InputStickerSetShortName: struct {
        short_name: []const u8,
    },
    InputStickerSetAnimatedEmoji: struct {
    },
    InputStickerSetDice: struct {
        emoticon: []const u8,
    },
    InputStickerSetAnimatedEmojiAnimations: struct {
    },
    InputStickerSetPremiumGifts: struct {
    },
    InputStickerSetEmojiGenericAnimations: struct {
    },
    InputStickerSetEmojiDefaultStatuses: struct {
    },
    InputStickerSetEmojiDefaultTopicIcons: struct {
    },
    InputStickerSetEmojiChannelDefaultStatuses: struct {
    },
    StickerSet: struct {
        flags: usize,
        archived: ?bool,
        official: ?bool,
        masks: ?bool,
        emojis: ?bool,
        text_color: ?bool,
        channel_emoji_status: ?bool,
        creator: ?bool,
        installed_date: ?i32,
        id: i64,
        access_hash: i64,
        title: []const u8,
        short_name: []const u8,
        thumbs: ?[]const PhotoSize,
        thumb_dc_id: ?i32,
        thumb_version: ?i32,
        thumb_document_id: ?i64,
        count: i32,
        hash: i32,
    },
    MessagesStickerSet: struct {
        set: StickerSet,
        packs: []const StickerPack,
        keywords: []const StickerKeyword,
        documents: []const Document,
    },
    MessagesStickerSetNotModified: struct {
    },
    BotCommand: struct {
        command: []const u8,
        description: []const u8,
    },
    BotInfo: struct {
        flags: usize,
        has_preview_medias: ?bool,
        user_id: ?i64,
        description: ?[]const u8,
        description_photo: ?Photo,
        description_document: ?Document,
        commands: ?[]const BotCommand,
        menu_button: ?BotMenuButton,
        privacy_policy_url: ?[]const u8,
    },
    KeyboardButton: struct {
        text: []const u8,
    },
    KeyboardButtonUrl: struct {
        text: []const u8,
        url: []const u8,
    },
    KeyboardButtonCallback: struct {
        flags: usize,
        requires_password: ?bool,
        text: []const u8,
        data: []const u8,
    },
    KeyboardButtonRequestPhone: struct {
        text: []const u8,
    },
    KeyboardButtonRequestGeoLocation: struct {
        text: []const u8,
    },
    KeyboardButtonSwitchInline: struct {
        flags: usize,
        same_peer: ?bool,
        text: []const u8,
        query: []const u8,
        peer_types: ?[]const InlineQueryPeerType,
    },
    KeyboardButtonGame: struct {
        text: []const u8,
    },
    KeyboardButtonBuy: struct {
        text: []const u8,
    },
    KeyboardButtonUrlAuth: struct {
        flags: usize,
        text: []const u8,
        fwd_text: ?[]const u8,
        url: []const u8,
        button_id: i32,
    },
    InputKeyboardButtonUrlAuth: struct {
        flags: usize,
        request_write_access: ?bool,
        text: []const u8,
        fwd_text: ?[]const u8,
        url: []const u8,
        bot: InputUser,
    },
    KeyboardButtonRequestPoll: struct {
        flags: usize,
        quiz: ?bool,
        text: []const u8,
    },
    InputKeyboardButtonUserProfile: struct {
        text: []const u8,
        user_id: InputUser,
    },
    KeyboardButtonUserProfile: struct {
        text: []const u8,
        user_id: i64,
    },
    KeyboardButtonWebView: struct {
        text: []const u8,
        url: []const u8,
    },
    KeyboardButtonSimpleWebView: struct {
        text: []const u8,
        url: []const u8,
    },
    KeyboardButtonRequestPeer: struct {
        text: []const u8,
        button_id: i32,
        peer_type: RequestPeerType,
        max_quantity: i32,
    },
    InputKeyboardButtonRequestPeer: struct {
        flags: usize,
        name_requested: ?bool,
        username_requested: ?bool,
        photo_requested: ?bool,
        text: []const u8,
        button_id: i32,
        peer_type: RequestPeerType,
        max_quantity: i32,
    },
    KeyboardButtonCopy: struct {
        text: []const u8,
        copy_text: []const u8,
    },
    KeyboardButtonRow: struct {
        buttons: []const KeyboardButton,
    },
    ReplyKeyboardHide: struct {
        flags: usize,
        selective: ?bool,
    },
    ReplyKeyboardForceReply: struct {
        flags: usize,
        single_use: ?bool,
        selective: ?bool,
        placeholder: ?[]const u8,
    },
    ReplyKeyboardMarkup: struct {
        flags: usize,
        resize: ?bool,
        single_use: ?bool,
        selective: ?bool,
        persistent: ?bool,
        rows: []const KeyboardButtonRow,
        placeholder: ?[]const u8,
    },
    ReplyInlineMarkup: struct {
        rows: []const KeyboardButtonRow,
    },
    MessageEntityUnknown: struct {
        offset: i32,
        length: i32,
    },
    MessageEntityMention: struct {
        offset: i32,
        length: i32,
    },
    MessageEntityHashtag: struct {
        offset: i32,
        length: i32,
    },
    MessageEntityBotCommand: struct {
        offset: i32,
        length: i32,
    },
    MessageEntityUrl: struct {
        offset: i32,
        length: i32,
    },
    MessageEntityEmail: struct {
        offset: i32,
        length: i32,
    },
    MessageEntityBold: struct {
        offset: i32,
        length: i32,
    },
    MessageEntityItalic: struct {
        offset: i32,
        length: i32,
    },
    MessageEntityCode: struct {
        offset: i32,
        length: i32,
    },
    MessageEntityPre: struct {
        offset: i32,
        length: i32,
        language: []const u8,
    },
    MessageEntityTextUrl: struct {
        offset: i32,
        length: i32,
        url: []const u8,
    },
    MessageEntityMentionName: struct {
        offset: i32,
        length: i32,
        user_id: i64,
    },
    InputMessageEntityMentionName: struct {
        offset: i32,
        length: i32,
        user_id: InputUser,
    },
    MessageEntityPhone: struct {
        offset: i32,
        length: i32,
    },
    MessageEntityCashtag: struct {
        offset: i32,
        length: i32,
    },
    MessageEntityUnderline: struct {
        offset: i32,
        length: i32,
    },
    MessageEntityStrike: struct {
        offset: i32,
        length: i32,
    },
    MessageEntityBankCard: struct {
        offset: i32,
        length: i32,
    },
    MessageEntitySpoiler: struct {
        offset: i32,
        length: i32,
    },
    MessageEntityCustomEmoji: struct {
        offset: i32,
        length: i32,
        document_id: i64,
    },
    MessageEntityBlockquote: struct {
        flags: usize,
        collapsed: ?bool,
        offset: i32,
        length: i32,
    },
    InputChannelEmpty: struct {
    },
    InputChannel: struct {
        channel_id: i64,
        access_hash: i64,
    },
    InputChannelFromMessage: struct {
        peer: InputPeer,
        msg_id: i32,
        channel_id: i64,
    },
    ContactsResolvedPeer: struct {
        peer: Peer,
        chats: []const Chat,
        users: []const User,
    },
    MessageRange: struct {
        min_id: i32,
        max_id: i32,
    },
    UpdatesChannelDifferenceEmpty: struct {
        flags: usize,
        final: ?bool,
        pts: i32,
        timeout: ?i32,
    },
    UpdatesChannelDifferenceTooLong: struct {
        flags: usize,
        final: ?bool,
        timeout: ?i32,
        dialog: Dialog,
        messages: []const Message,
        chats: []const Chat,
        users: []const User,
    },
    UpdatesChannelDifference: struct {
        flags: usize,
        final: ?bool,
        pts: i32,
        timeout: ?i32,
        new_messages: []const Message,
        other_updates: []const Update,
        chats: []const Chat,
        users: []const User,
    },
    ChannelMessagesFilterEmpty: struct {
    },
    ChannelMessagesFilter: struct {
        flags: usize,
        exclude_new_messages: ?bool,
        ranges: []const MessageRange,
    },
    ChannelParticipant: struct {
        flags: usize,
        user_id: i64,
        date: i32,
        subscription_until_date: ?i32,
    },
    ChannelParticipantSelf: struct {
        flags: usize,
        via_request: ?bool,
        user_id: i64,
        inviter_id: i64,
        date: i32,
        subscription_until_date: ?i32,
    },
    ChannelParticipantCreator: struct {
        flags: usize,
        user_id: i64,
        admin_rights: ChatAdminRights,
        rank: ?[]const u8,
    },
    ChannelParticipantAdmin: struct {
        flags: usize,
        can_edit: ?bool,
        self: ?bool,
        user_id: i64,
        inviter_id: ?i64,
        promoted_by: i64,
        date: i32,
        admin_rights: ChatAdminRights,
        rank: ?[]const u8,
    },
    ChannelParticipantBanned: struct {
        flags: usize,
        left: ?bool,
        peer: Peer,
        kicked_by: i64,
        date: i32,
        banned_rights: ChatBannedRights,
    },
    ChannelParticipantLeft: struct {
        peer: Peer,
    },
    ChannelParticipantsRecent: struct {
    },
    ChannelParticipantsAdmins: struct {
    },
    ChannelParticipantsKicked: struct {
        q: []const u8,
    },
    ChannelParticipantsBots: struct {
    },
    ChannelParticipantsBanned: struct {
        q: []const u8,
    },
    ChannelParticipantsSearch: struct {
        q: []const u8,
    },
    ChannelParticipantsContacts: struct {
        q: []const u8,
    },
    ChannelParticipantsMentions: struct {
        flags: usize,
        q: ?[]const u8,
        top_msg_id: ?i32,
    },
    ChannelsChannelParticipants: struct {
        count: i32,
        participants: []const ChannelParticipant,
        chats: []const Chat,
        users: []const User,
    },
    ChannelsChannelParticipantsNotModified: struct {
    },
    ChannelsChannelParticipant: struct {
        participant: ChannelParticipant,
        chats: []const Chat,
        users: []const User,
    },
    HelpTermsOfService: struct {
        flags: usize,
        popup: ?bool,
        id: DataJSON,
        text: []const u8,
        entities: []const MessageEntity,
        min_age_confirm: ?i32,
    },
    MessagesSavedGifsNotModified: struct {
    },
    MessagesSavedGifs: struct {
        hash: i64,
        gifs: []const Document,
    },
    InputBotInlineMessageMediaAuto: struct {
        flags: usize,
        invert_media: ?bool,
        message: []const u8,
        entities: ?[]const MessageEntity,
        reply_markup: ?ReplyMarkup,
    },
    InputBotInlineMessageText: struct {
        flags: usize,
        no_webpage: ?bool,
        invert_media: ?bool,
        message: []const u8,
        entities: ?[]const MessageEntity,
        reply_markup: ?ReplyMarkup,
    },
    InputBotInlineMessageMediaGeo: struct {
        flags: usize,
        geo_point: InputGeoPoint,
        heading: ?i32,
        period: ?i32,
        proximity_notification_radius: ?i32,
        reply_markup: ?ReplyMarkup,
    },
    InputBotInlineMessageMediaVenue: struct {
        flags: usize,
        geo_point: InputGeoPoint,
        title: []const u8,
        address: []const u8,
        provider: []const u8,
        venue_id: []const u8,
        venue_type: []const u8,
        reply_markup: ?ReplyMarkup,
    },
    InputBotInlineMessageMediaContact: struct {
        flags: usize,
        phone_number: []const u8,
        first_name: []const u8,
        last_name: []const u8,
        vcard: []const u8,
        reply_markup: ?ReplyMarkup,
    },
    InputBotInlineMessageGame: struct {
        flags: usize,
        reply_markup: ?ReplyMarkup,
    },
    InputBotInlineMessageMediaInvoice: struct {
        flags: usize,
        title: []const u8,
        description: []const u8,
        photo: ?InputWebDocument,
        invoice: Invoice,
        payload: []const u8,
        provider: []const u8,
        provider_data: DataJSON,
        reply_markup: ?ReplyMarkup,
    },
    InputBotInlineMessageMediaWebPage: struct {
        flags: usize,
        invert_media: ?bool,
        force_large_media: ?bool,
        force_small_media: ?bool,
        optional: ?bool,
        message: []const u8,
        entities: ?[]const MessageEntity,
        url: []const u8,
        reply_markup: ?ReplyMarkup,
    },
    InputBotInlineResult: struct {
        flags: usize,
        id: []const u8,
        type: []const u8,
        title: ?[]const u8,
        description: ?[]const u8,
        url: ?[]const u8,
        thumb: ?InputWebDocument,
        content: ?InputWebDocument,
        send_message: InputBotInlineMessage,
    },
    InputBotInlineResultPhoto: struct {
        id: []const u8,
        type: []const u8,
        photo: InputPhoto,
        send_message: InputBotInlineMessage,
    },
    InputBotInlineResultDocument: struct {
        flags: usize,
        id: []const u8,
        type: []const u8,
        title: ?[]const u8,
        description: ?[]const u8,
        document: InputDocument,
        send_message: InputBotInlineMessage,
    },
    InputBotInlineResultGame: struct {
        id: []const u8,
        short_name: []const u8,
        send_message: InputBotInlineMessage,
    },
    BotInlineMessageMediaAuto: struct {
        flags: usize,
        invert_media: ?bool,
        message: []const u8,
        entities: ?[]const MessageEntity,
        reply_markup: ?ReplyMarkup,
    },
    BotInlineMessageText: struct {
        flags: usize,
        no_webpage: ?bool,
        invert_media: ?bool,
        message: []const u8,
        entities: ?[]const MessageEntity,
        reply_markup: ?ReplyMarkup,
    },
    BotInlineMessageMediaGeo: struct {
        flags: usize,
        geo: GeoPoint,
        heading: ?i32,
        period: ?i32,
        proximity_notification_radius: ?i32,
        reply_markup: ?ReplyMarkup,
    },
    BotInlineMessageMediaVenue: struct {
        flags: usize,
        geo: GeoPoint,
        title: []const u8,
        address: []const u8,
        provider: []const u8,
        venue_id: []const u8,
        venue_type: []const u8,
        reply_markup: ?ReplyMarkup,
    },
    BotInlineMessageMediaContact: struct {
        flags: usize,
        phone_number: []const u8,
        first_name: []const u8,
        last_name: []const u8,
        vcard: []const u8,
        reply_markup: ?ReplyMarkup,
    },
    BotInlineMessageMediaInvoice: struct {
        flags: usize,
        shipping_address_requested: ?bool,
        Test: ?bool,
        title: []const u8,
        description: []const u8,
        photo: ?WebDocument,
        currency: []const u8,
        total_amount: i64,
        reply_markup: ?ReplyMarkup,
    },
    BotInlineMessageMediaWebPage: struct {
        flags: usize,
        invert_media: ?bool,
        force_large_media: ?bool,
        force_small_media: ?bool,
        manual: ?bool,
        safe: ?bool,
        message: []const u8,
        entities: ?[]const MessageEntity,
        url: []const u8,
        reply_markup: ?ReplyMarkup,
    },
    BotInlineResult: struct {
        flags: usize,
        id: []const u8,
        type: []const u8,
        title: ?[]const u8,
        description: ?[]const u8,
        url: ?[]const u8,
        thumb: ?WebDocument,
        content: ?WebDocument,
        send_message: BotInlineMessage,
    },
    BotInlineMediaResult: struct {
        flags: usize,
        id: []const u8,
        type: []const u8,
        photo: ?Photo,
        document: ?Document,
        title: ?[]const u8,
        description: ?[]const u8,
        send_message: BotInlineMessage,
    },
    MessagesBotResults: struct {
        flags: usize,
        gallery: ?bool,
        query_id: i64,
        next_offset: ?[]const u8,
        switch_pm: ?InlineBotSwitchPM,
        switch_webview: ?InlineBotWebView,
        results: []const BotInlineResult,
        cache_time: i32,
        users: []const User,
    },
    ExportedMessageLink: struct {
        link: []const u8,
        html: []const u8,
    },
    MessageFwdHeader: struct {
        flags: usize,
        imported: ?bool,
        saved_out: ?bool,
        from_id: ?Peer,
        from_name: ?[]const u8,
        date: i32,
        channel_post: ?i32,
        post_author: ?[]const u8,
        saved_from_peer: ?Peer,
        saved_from_msg_id: ?i32,
        saved_from_id: ?Peer,
        saved_from_name: ?[]const u8,
        saved_date: ?i32,
        psa_type: ?[]const u8,
    },
    AuthCodeTypeSms: struct {
    },
    AuthCodeTypeCall: struct {
    },
    AuthCodeTypeFlashCall: struct {
    },
    AuthCodeTypeMissedCall: struct {
    },
    AuthCodeTypeFragmentSms: struct {
    },
    AuthSentCodeTypeApp: struct {
        length: i32,
    },
    AuthSentCodeTypeSms: struct {
        length: i32,
    },
    AuthSentCodeTypeCall: struct {
        length: i32,
    },
    AuthSentCodeTypeFlashCall: struct {
        pattern: []const u8,
    },
    AuthSentCodeTypeMissedCall: struct {
        prefix: []const u8,
        length: i32,
    },
    AuthSentCodeTypeEmailCode: struct {
        flags: usize,
        apple_signin_allowed: ?bool,
        google_signin_allowed: ?bool,
        email_pattern: []const u8,
        length: i32,
        reset_available_period: ?i32,
        reset_pending_date: ?i32,
    },
    AuthSentCodeTypeSetUpEmailRequired: struct {
        flags: usize,
        apple_signin_allowed: ?bool,
        google_signin_allowed: ?bool,
    },
    AuthSentCodeTypeFragmentSms: struct {
        url: []const u8,
        length: i32,
    },
    AuthSentCodeTypeFirebaseSms: struct {
        flags: usize,
        nonce: ?[]const u8,
        play_integrity_project_id: ?i64,
        play_integrity_nonce: ?[]const u8,
        receipt: ?[]const u8,
        push_timeout: ?i32,
        length: i32,
    },
    AuthSentCodeTypeSmsWord: struct {
        flags: usize,
        beginning: ?[]const u8,
    },
    AuthSentCodeTypeSmsPhrase: struct {
        flags: usize,
        beginning: ?[]const u8,
    },
    MessagesBotCallbackAnswer: struct {
        flags: usize,
        alert: ?bool,
        has_url: ?bool,
        native_ui: ?bool,
        message: ?[]const u8,
        url: ?[]const u8,
        cache_time: i32,
    },
    MessagesMessageEditData: struct {
        flags: usize,
        caption: ?bool,
    },
    InputBotInlineMessageID: struct {
        dc_id: i32,
        id: i64,
        access_hash: i64,
    },
    InputBotInlineMessageID64: struct {
        dc_id: i32,
        owner_id: i64,
        id: i32,
        access_hash: i64,
    },
    InlineBotSwitchPM: struct {
        text: []const u8,
        start_param: []const u8,
    },
    MessagesPeerDialogs: struct {
        dialogs: []const Dialog,
        messages: []const Message,
        chats: []const Chat,
        users: []const User,
        state: UpdatesState,
    },
    TopPeer: struct {
        peer: Peer,
        rating: f64,
    },
    TopPeerCategoryBotsPM: struct {
    },
    TopPeerCategoryBotsInline: struct {
    },
    TopPeerCategoryCorrespondents: struct {
    },
    TopPeerCategoryGroups: struct {
    },
    TopPeerCategoryChannels: struct {
    },
    TopPeerCategoryPhoneCalls: struct {
    },
    TopPeerCategoryForwardUsers: struct {
    },
    TopPeerCategoryForwardChats: struct {
    },
    TopPeerCategoryBotsApp: struct {
    },
    TopPeerCategoryPeers: struct {
        category: TopPeerCategory,
        count: i32,
        peers: []const TopPeer,
    },
    ContactsTopPeersNotModified: struct {
    },
    ContactsTopPeers: struct {
        categories: []const TopPeerCategoryPeers,
        chats: []const Chat,
        users: []const User,
    },
    ContactsTopPeersDisabled: struct {
    },
    DraftMessageEmpty: struct {
        flags: usize,
        date: ?i32,
    },
    DraftMessage: struct {
        flags: usize,
        no_webpage: ?bool,
        invert_media: ?bool,
        reply_to: ?InputReplyTo,
        message: []const u8,
        entities: ?[]const MessageEntity,
        media: ?InputMedia,
        date: i32,
        effect: ?i64,
    },
    MessagesFeaturedStickersNotModified: struct {
        count: i32,
    },
    MessagesFeaturedStickers: struct {
        flags: usize,
        premium: ?bool,
        hash: i64,
        count: i32,
        sets: []const StickerSetCovered,
        unread: []const i64,
    },
    MessagesRecentStickersNotModified: struct {
    },
    MessagesRecentStickers: struct {
        hash: i64,
        packs: []const StickerPack,
        stickers: []const Document,
        dates: []const i32,
    },
    MessagesArchivedStickers: struct {
        count: i32,
        sets: []const StickerSetCovered,
    },
    MessagesStickerSetInstallResultSuccess: struct {
    },
    MessagesStickerSetInstallResultArchive: struct {
        sets: []const StickerSetCovered,
    },
    StickerSetCovered: struct {
        set: StickerSet,
        cover: Document,
    },
    StickerSetMultiCovered: struct {
        set: StickerSet,
        covers: []const Document,
    },
    StickerSetFullCovered: struct {
        set: StickerSet,
        packs: []const StickerPack,
        keywords: []const StickerKeyword,
        documents: []const Document,
    },
    StickerSetNoCovered: struct {
        set: StickerSet,
    },
    MaskCoords: struct {
        n: i32,
        x: f64,
        y: f64,
        zoom: f64,
    },
    InputStickeredMediaPhoto: struct {
        id: InputPhoto,
    },
    InputStickeredMediaDocument: struct {
        id: InputDocument,
    },
    Game: struct {
        flags: usize,
        id: i64,
        access_hash: i64,
        short_name: []const u8,
        title: []const u8,
        description: []const u8,
        photo: Photo,
        document: ?Document,
    },
    InputGameID: struct {
        id: i64,
        access_hash: i64,
    },
    InputGameShortName: struct {
        bot_id: InputUser,
        short_name: []const u8,
    },
    HighScore: struct {
        pos: i32,
        user_id: i64,
        score: i32,
    },
    MessagesHighScores: struct {
        scores: []const HighScore,
        users: []const User,
    },
    TextEmpty: struct {
    },
    TextPlain: struct {
        text: []const u8,
    },
    TextBold: struct {
        text: RichText,
    },
    TextItalic: struct {
        text: RichText,
    },
    TextUnderline: struct {
        text: RichText,
    },
    TextStrike: struct {
        text: RichText,
    },
    TextFixed: struct {
        text: RichText,
    },
    TextUrl: struct {
        text: RichText,
        url: []const u8,
        webpage_id: i64,
    },
    TextEmail: struct {
        text: RichText,
        email: []const u8,
    },
    TextConcat: struct {
        texts: []const RichText,
    },
    TextSubscript: struct {
        text: RichText,
    },
    TextSuperscript: struct {
        text: RichText,
    },
    TextMarked: struct {
        text: RichText,
    },
    TextPhone: struct {
        text: RichText,
        phone: []const u8,
    },
    TextImage: struct {
        document_id: i64,
        w: i32,
        h: i32,
    },
    TextAnchor: struct {
        text: RichText,
        name: []const u8,
    },
    PageBlockUnsupported: struct {
    },
    PageBlockTitle: struct {
        text: RichText,
    },
    PageBlockSubtitle: struct {
        text: RichText,
    },
    PageBlockAuthorDate: struct {
        author: RichText,
        published_date: i32,
    },
    PageBlockHeader: struct {
        text: RichText,
    },
    PageBlockSubheader: struct {
        text: RichText,
    },
    PageBlockParagraph: struct {
        text: RichText,
    },
    PageBlockPreformatted: struct {
        text: RichText,
        language: []const u8,
    },
    PageBlockFooter: struct {
        text: RichText,
    },
    PageBlockDivider: struct {
    },
    PageBlockAnchor: struct {
        name: []const u8,
    },
    PageBlockList: struct {
        items: []const PageListItem,
    },
    PageBlockBlockquote: struct {
        text: RichText,
        caption: RichText,
    },
    PageBlockPullquote: struct {
        text: RichText,
        caption: RichText,
    },
    PageBlockPhoto: struct {
        flags: usize,
        photo_id: i64,
        caption: PageCaption,
        url: ?[]const u8,
        webpage_id: ?i64,
    },
    PageBlockVideo: struct {
        flags: usize,
        autoplay: ?bool,
        loop: ?bool,
        video_id: i64,
        caption: PageCaption,
    },
    PageBlockCover: struct {
        cover: PageBlock,
    },
    PageBlockEmbed: struct {
        flags: usize,
        full_width: ?bool,
        allow_scrolling: ?bool,
        url: ?[]const u8,
        html: ?[]const u8,
        poster_photo_id: ?i64,
        w: ?i32,
        h: ?i32,
        caption: PageCaption,
    },
    PageBlockEmbedPost: struct {
        url: []const u8,
        webpage_id: i64,
        author_photo_id: i64,
        author: []const u8,
        date: i32,
        blocks: []const PageBlock,
        caption: PageCaption,
    },
    PageBlockCollage: struct {
        items: []const PageBlock,
        caption: PageCaption,
    },
    PageBlockSlideshow: struct {
        items: []const PageBlock,
        caption: PageCaption,
    },
    PageBlockChannel: struct {
        channel: Chat,
    },
    PageBlockAudio: struct {
        audio_id: i64,
        caption: PageCaption,
    },
    PageBlockKicker: struct {
        text: RichText,
    },
    PageBlockTable: struct {
        flags: usize,
        bordered: ?bool,
        striped: ?bool,
        title: RichText,
        rows: []const PageTableRow,
    },
    PageBlockOrderedList: struct {
        items: []const PageListOrderedItem,
    },
    PageBlockDetails: struct {
        flags: usize,
        open: ?bool,
        blocks: []const PageBlock,
        title: RichText,
    },
    PageBlockRelatedArticles: struct {
        title: RichText,
        articles: []const PageRelatedArticle,
    },
    PageBlockMap: struct {
        geo: GeoPoint,
        zoom: i32,
        w: i32,
        h: i32,
        caption: PageCaption,
    },
    PhoneCallDiscardReasonMissed: struct {
    },
    PhoneCallDiscardReasonDisconnect: struct {
    },
    PhoneCallDiscardReasonHangup: struct {
    },
    PhoneCallDiscardReasonBusy: struct {
    },
    DataJSON: struct {
        data: []const u8,
    },
    LabeledPrice: struct {
        label: []const u8,
        amount: i64,
    },
    Invoice: struct {
        flags: usize,
        Test: ?bool,
        name_requested: ?bool,
        phone_requested: ?bool,
        email_requested: ?bool,
        shipping_address_requested: ?bool,
        flexible: ?bool,
        phone_to_provider: ?bool,
        email_to_provider: ?bool,
        recurring: ?bool,
        currency: []const u8,
        prices: []const LabeledPrice,
        max_tip_amount: ?i64,
        suggested_tip_amounts: ?[]const i64,
        terms_url: ?[]const u8,
    },
    PaymentCharge: struct {
        id: []const u8,
        provider_charge_id: []const u8,
    },
    PostAddress: struct {
        street_line1: []const u8,
        street_line2: []const u8,
        city: []const u8,
        state: []const u8,
        country_iso2: []const u8,
        post_code: []const u8,
    },
    PaymentRequestedInfo: struct {
        flags: usize,
        name: ?[]const u8,
        phone: ?[]const u8,
        email: ?[]const u8,
        shipping_address: ?PostAddress,
    },
    PaymentSavedCredentialsCard: struct {
        id: []const u8,
        title: []const u8,
    },
    WebDocument: struct {
        url: []const u8,
        access_hash: i64,
        size: i32,
        mime_type: []const u8,
        attributes: []const DocumentAttribute,
    },
    WebDocumentNoProxy: struct {
        url: []const u8,
        size: i32,
        mime_type: []const u8,
        attributes: []const DocumentAttribute,
    },
    InputWebDocument: struct {
        url: []const u8,
        size: i32,
        mime_type: []const u8,
        attributes: []const DocumentAttribute,
    },
    InputWebFileLocation: struct {
        url: []const u8,
        access_hash: i64,
    },
    InputWebFileGeoPointLocation: struct {
        geo_point: InputGeoPoint,
        access_hash: i64,
        w: i32,
        h: i32,
        zoom: i32,
        scale: i32,
    },
    InputWebFileAudioAlbumThumbLocation: struct {
        flags: usize,
        small: ?bool,
        document: ?InputDocument,
        title: ?[]const u8,
        performer: ?[]const u8,
    },
    UploadWebFile: struct {
        size: i32,
        mime_type: []const u8,
        file_type: StorageFileType,
        mtime: i32,
        bytes: []const u8,
    },
    PaymentsPaymentForm: struct {
        flags: usize,
        can_save_credentials: ?bool,
        password_missing: ?bool,
        form_id: i64,
        bot_id: i64,
        title: []const u8,
        description: []const u8,
        photo: ?WebDocument,
        invoice: Invoice,
        provider_id: i64,
        url: []const u8,
        native_provider: ?[]const u8,
        native_params: ?DataJSON,
        additional_methods: ?[]const PaymentFormMethod,
        saved_info: ?PaymentRequestedInfo,
        saved_credentials: ?[]const PaymentSavedCredentials,
        users: []const User,
    },
    PaymentsPaymentFormStars: struct {
        flags: usize,
        form_id: i64,
        bot_id: i64,
        title: []const u8,
        description: []const u8,
        photo: ?WebDocument,
        invoice: Invoice,
        users: []const User,
    },
    PaymentsPaymentFormStarGift: struct {
        form_id: i64,
        invoice: Invoice,
    },
    PaymentsValidatedRequestedInfo: struct {
        flags: usize,
        id: ?[]const u8,
        shipping_options: ?[]const ShippingOption,
    },
    PaymentsPaymentResult: struct {
        updates: Updates,
    },
    PaymentsPaymentVerificationNeeded: struct {
        url: []const u8,
    },
    PaymentsPaymentReceipt: struct {
        flags: usize,
        date: i32,
        bot_id: i64,
        provider_id: i64,
        title: []const u8,
        description: []const u8,
        photo: ?WebDocument,
        invoice: Invoice,
        info: ?PaymentRequestedInfo,
        shipping: ?ShippingOption,
        tip_amount: ?i64,
        currency: []const u8,
        total_amount: i64,
        credentials_title: []const u8,
        users: []const User,
    },
    PaymentsPaymentReceiptStars: struct {
        flags: usize,
        date: i32,
        bot_id: i64,
        title: []const u8,
        description: []const u8,
        photo: ?WebDocument,
        invoice: Invoice,
        currency: []const u8,
        total_amount: i64,
        transaction_id: []const u8,
        users: []const User,
    },
    PaymentsSavedInfo: struct {
        flags: usize,
        has_saved_credentials: ?bool,
        saved_info: ?PaymentRequestedInfo,
    },
    InputPaymentCredentialsSaved: struct {
        id: []const u8,
        tmp_password: []const u8,
    },
    InputPaymentCredentials: struct {
        flags: usize,
        save: ?bool,
        data: DataJSON,
    },
    InputPaymentCredentialsApplePay: struct {
        payment_data: DataJSON,
    },
    InputPaymentCredentialsGooglePay: struct {
        payment_token: DataJSON,
    },
    AccountTmpPassword: struct {
        tmp_password: []const u8,
        valid_until: i32,
    },
    ShippingOption: struct {
        id: []const u8,
        title: []const u8,
        prices: []const LabeledPrice,
    },
    InputStickerSetItem: struct {
        flags: usize,
        document: InputDocument,
        emoji: []const u8,
        mask_coords: ?MaskCoords,
        keywords: ?[]const u8,
    },
    InputPhoneCall: struct {
        id: i64,
        access_hash: i64,
    },
    PhoneCallEmpty: struct {
        id: i64,
    },
    PhoneCallWaiting: struct {
        flags: usize,
        video: ?bool,
        id: i64,
        access_hash: i64,
        date: i32,
        admin_id: i64,
        participant_id: i64,
        protocol: PhoneCallProtocol,
        receive_date: ?i32,
    },
    PhoneCallRequested: struct {
        flags: usize,
        video: ?bool,
        id: i64,
        access_hash: i64,
        date: i32,
        admin_id: i64,
        participant_id: i64,
        g_a_hash: []const u8,
        protocol: PhoneCallProtocol,
    },
    PhoneCallAccepted: struct {
        flags: usize,
        video: ?bool,
        id: i64,
        access_hash: i64,
        date: i32,
        admin_id: i64,
        participant_id: i64,
        g_b: []const u8,
        protocol: PhoneCallProtocol,
    },
    PhoneCall: struct {
        flags: usize,
        p2p_allowed: ?bool,
        video: ?bool,
        id: i64,
        access_hash: i64,
        date: i32,
        admin_id: i64,
        participant_id: i64,
        g_a_or_b: []const u8,
        key_fingerprint: i64,
        protocol: PhoneCallProtocol,
        connections: []const PhoneConnection,
        start_date: i32,
        custom_parameters: ?DataJSON,
    },
    PhoneCallDiscarded: struct {
        flags: usize,
        need_rating: ?bool,
        need_debug: ?bool,
        video: ?bool,
        id: i64,
        reason: ?PhoneCallDiscardReason,
        duration: ?i32,
    },
    PhoneConnection: struct {
        flags: usize,
        tcp: ?bool,
        id: i64,
        ip: []const u8,
        ipv6: []const u8,
        port: i32,
        peer_tag: []const u8,
    },
    PhoneConnectionWebrtc: struct {
        flags: usize,
        turn: ?bool,
        stun: ?bool,
        id: i64,
        ip: []const u8,
        ipv6: []const u8,
        port: i32,
        username: []const u8,
        password: []const u8,
    },
    PhoneCallProtocol: struct {
        flags: usize,
        udp_p2p: ?bool,
        udp_reflector: ?bool,
        min_layer: i32,
        max_layer: i32,
        library_versions: []const []const u8,
    },
    PhonePhoneCall: struct {
        phone_call: PhoneCall,
        users: []const User,
    },
    UploadCdnFileReuploadNeeded: struct {
        request_token: []const u8,
    },
    UploadCdnFile: struct {
        bytes: []const u8,
    },
    CdnPublicKey: struct {
        dc_id: i32,
        public_key: []const u8,
    },
    CdnConfig: struct {
        public_keys: []const CdnPublicKey,
    },
    LangPackString: struct {
        key: []const u8,
        value: []const u8,
    },
    LangPackStringPluralized: struct {
        flags: usize,
        key: []const u8,
        zero_value: ?[]const u8,
        one_value: ?[]const u8,
        two_value: ?[]const u8,
        few_value: ?[]const u8,
        many_value: ?[]const u8,
        other_value: []const u8,
    },
    LangPackStringDeleted: struct {
        key: []const u8,
    },
    LangPackDifference: struct {
        lang_code: []const u8,
        from_version: i32,
        version: i32,
        strings: []const LangPackString,
    },
    LangPackLanguage: struct {
        flags: usize,
        official: ?bool,
        rtl: ?bool,
        beta: ?bool,
        name: []const u8,
        native_name: []const u8,
        lang_code: []const u8,
        base_lang_code: ?[]const u8,
        plural_code: []const u8,
        strings_count: i32,
        translated_count: i32,
        translations_url: []const u8,
    },
    ChannelAdminLogEventActionChangeTitle: struct {
        prev_value: []const u8,
        new_value: []const u8,
    },
    ChannelAdminLogEventActionChangeAbout: struct {
        prev_value: []const u8,
        new_value: []const u8,
    },
    ChannelAdminLogEventActionChangeUsername: struct {
        prev_value: []const u8,
        new_value: []const u8,
    },
    ChannelAdminLogEventActionChangePhoto: struct {
        prev_photo: Photo,
        new_photo: Photo,
    },
    ChannelAdminLogEventActionToggleInvites: struct {
        new_value: bool,
    },
    ChannelAdminLogEventActionToggleSignatures: struct {
        new_value: bool,
    },
    ChannelAdminLogEventActionUpdatePinned: struct {
        message: Message,
    },
    ChannelAdminLogEventActionEditMessage: struct {
        prev_message: Message,
        new_message: Message,
    },
    ChannelAdminLogEventActionDeleteMessage: struct {
        message: Message,
    },
    ChannelAdminLogEventActionParticipantJoin: struct {
    },
    ChannelAdminLogEventActionParticipantLeave: struct {
    },
    ChannelAdminLogEventActionParticipantInvite: struct {
        participant: ChannelParticipant,
    },
    ChannelAdminLogEventActionParticipantToggleBan: struct {
        prev_participant: ChannelParticipant,
        new_participant: ChannelParticipant,
    },
    ChannelAdminLogEventActionParticipantToggleAdmin: struct {
        prev_participant: ChannelParticipant,
        new_participant: ChannelParticipant,
    },
    ChannelAdminLogEventActionChangeStickerSet: struct {
        prev_stickerset: InputStickerSet,
        new_stickerset: InputStickerSet,
    },
    ChannelAdminLogEventActionTogglePreHistoryHidden: struct {
        new_value: bool,
    },
    ChannelAdminLogEventActionDefaultBannedRights: struct {
        prev_banned_rights: ChatBannedRights,
        new_banned_rights: ChatBannedRights,
    },
    ChannelAdminLogEventActionStopPoll: struct {
        message: Message,
    },
    ChannelAdminLogEventActionChangeLinkedChat: struct {
        prev_value: i64,
        new_value: i64,
    },
    ChannelAdminLogEventActionChangeLocation: struct {
        prev_value: ChannelLocation,
        new_value: ChannelLocation,
    },
    ChannelAdminLogEventActionToggleSlowMode: struct {
        prev_value: i32,
        new_value: i32,
    },
    ChannelAdminLogEventActionStartGroupCall: struct {
        call: InputGroupCall,
    },
    ChannelAdminLogEventActionDiscardGroupCall: struct {
        call: InputGroupCall,
    },
    ChannelAdminLogEventActionParticipantMute: struct {
        participant: GroupCallParticipant,
    },
    ChannelAdminLogEventActionParticipantUnmute: struct {
        participant: GroupCallParticipant,
    },
    ChannelAdminLogEventActionToggleGroupCallSetting: struct {
        join_muted: bool,
    },
    ChannelAdminLogEventActionParticipantJoinByInvite: struct {
        flags: usize,
        via_chatlist: ?bool,
        invite: ExportedChatInvite,
    },
    ChannelAdminLogEventActionExportedInviteDelete: struct {
        invite: ExportedChatInvite,
    },
    ChannelAdminLogEventActionExportedInviteRevoke: struct {
        invite: ExportedChatInvite,
    },
    ChannelAdminLogEventActionExportedInviteEdit: struct {
        prev_invite: ExportedChatInvite,
        new_invite: ExportedChatInvite,
    },
    ChannelAdminLogEventActionParticipantVolume: struct {
        participant: GroupCallParticipant,
    },
    ChannelAdminLogEventActionChangeHistoryTTL: struct {
        prev_value: i32,
        new_value: i32,
    },
    ChannelAdminLogEventActionParticipantJoinByRequest: struct {
        invite: ExportedChatInvite,
        approved_by: i64,
    },
    ChannelAdminLogEventActionToggleNoForwards: struct {
        new_value: bool,
    },
    ChannelAdminLogEventActionSendMessage: struct {
        message: Message,
    },
    ChannelAdminLogEventActionChangeAvailableReactions: struct {
        prev_value: ChatReactions,
        new_value: ChatReactions,
    },
    ChannelAdminLogEventActionChangeUsernames: struct {
        prev_value: []const []const u8,
        new_value: []const []const u8,
    },
    ChannelAdminLogEventActionToggleForum: struct {
        new_value: bool,
    },
    ChannelAdminLogEventActionCreateTopic: struct {
        topic: ForumTopic,
    },
    ChannelAdminLogEventActionEditTopic: struct {
        prev_topic: ForumTopic,
        new_topic: ForumTopic,
    },
    ChannelAdminLogEventActionDeleteTopic: struct {
        topic: ForumTopic,
    },
    ChannelAdminLogEventActionPinTopic: struct {
        flags: usize,
        prev_topic: ?ForumTopic,
        new_topic: ?ForumTopic,
    },
    ChannelAdminLogEventActionToggleAntiSpam: struct {
        new_value: bool,
    },
    ChannelAdminLogEventActionChangePeerColor: struct {
        prev_value: PeerColor,
        new_value: PeerColor,
    },
    ChannelAdminLogEventActionChangeProfilePeerColor: struct {
        prev_value: PeerColor,
        new_value: PeerColor,
    },
    ChannelAdminLogEventActionChangeWallpaper: struct {
        prev_value: WallPaper,
        new_value: WallPaper,
    },
    ChannelAdminLogEventActionChangeEmojiStatus: struct {
        prev_value: EmojiStatus,
        new_value: EmojiStatus,
    },
    ChannelAdminLogEventActionChangeEmojiStickerSet: struct {
        prev_stickerset: InputStickerSet,
        new_stickerset: InputStickerSet,
    },
    ChannelAdminLogEventActionToggleSignatureProfiles: struct {
        new_value: bool,
    },
    ChannelAdminLogEventActionParticipantSubExtend: struct {
        prev_participant: ChannelParticipant,
        new_participant: ChannelParticipant,
    },
    ChannelAdminLogEvent: struct {
        id: i64,
        date: i32,
        user_id: i64,
        action: ChannelAdminLogEventAction,
    },
    ChannelsAdminLogResults: struct {
        events: []const ChannelAdminLogEvent,
        chats: []const Chat,
        users: []const User,
    },
    ChannelAdminLogEventsFilter: struct {
        flags: usize,
        join: ?bool,
        leave: ?bool,
        invite: ?bool,
        ban: ?bool,
        unban: ?bool,
        kick: ?bool,
        unkick: ?bool,
        promote: ?bool,
        demote: ?bool,
        info: ?bool,
        settings: ?bool,
        pinned: ?bool,
        edit: ?bool,
        delete: ?bool,
        group_call: ?bool,
        invites: ?bool,
        send: ?bool,
        forums: ?bool,
        sub_extend: ?bool,
    },
    PopularContact: struct {
        client_id: i64,
        importers: i32,
    },
    MessagesFavedStickersNotModified: struct {
    },
    MessagesFavedStickers: struct {
        hash: i64,
        packs: []const StickerPack,
        stickers: []const Document,
    },
    RecentMeUrlUnknown: struct {
        url: []const u8,
    },
    RecentMeUrlUser: struct {
        url: []const u8,
        user_id: i64,
    },
    RecentMeUrlChat: struct {
        url: []const u8,
        chat_id: i64,
    },
    RecentMeUrlChatInvite: struct {
        url: []const u8,
        chat_invite: ChatInvite,
    },
    RecentMeUrlStickerSet: struct {
        url: []const u8,
        set: StickerSetCovered,
    },
    HelpRecentMeUrls: struct {
        urls: []const RecentMeUrl,
        chats: []const Chat,
        users: []const User,
    },
    InputSingleMedia: struct {
        flags: usize,
        media: InputMedia,
        random_id: i64,
        message: []const u8,
        entities: ?[]const MessageEntity,
    },
    WebAuthorization: struct {
        hash: i64,
        bot_id: i64,
        domain: []const u8,
        browser: []const u8,
        platform: []const u8,
        date_created: i32,
        date_active: i32,
        ip: []const u8,
        region: []const u8,
    },
    AccountWebAuthorizations: struct {
        authorizations: []const WebAuthorization,
        users: []const User,
    },
    InputMessageID: struct {
        id: i32,
    },
    InputMessageReplyTo: struct {
        id: i32,
    },
    InputMessagePinned: struct {
    },
    InputMessageCallbackQuery: struct {
        id: i32,
        query_id: i64,
    },
    InputDialogPeer: struct {
        peer: InputPeer,
    },
    InputDialogPeerFolder: struct {
        folder_id: i32,
    },
    DialogPeer: struct {
        peer: Peer,
    },
    DialogPeerFolder: struct {
        folder_id: i32,
    },
    MessagesFoundStickerSetsNotModified: struct {
    },
    MessagesFoundStickerSets: struct {
        hash: i64,
        sets: []const StickerSetCovered,
    },
    FileHash: struct {
        offset: i64,
        limit: i32,
        hash: []const u8,
    },
    InputClientProxy: struct {
        address: []const u8,
        port: i32,
    },
    HelpTermsOfServiceUpdateEmpty: struct {
        expires: i32,
    },
    HelpTermsOfServiceUpdate: struct {
        expires: i32,
        terms_of_service: HelpTermsOfService,
    },
    InputSecureFileUploaded: struct {
        id: i64,
        parts: i32,
        md5_checksum: []const u8,
        file_hash: []const u8,
        secret: []const u8,
    },
    InputSecureFile: struct {
        id: i64,
        access_hash: i64,
    },
    SecureFileEmpty: struct {
    },
    SecureFile: struct {
        id: i64,
        access_hash: i64,
        size: i64,
        dc_id: i32,
        date: i32,
        file_hash: []const u8,
        secret: []const u8,
    },
    SecureData: struct {
        data: []const u8,
        data_hash: []const u8,
        secret: []const u8,
    },
    SecurePlainPhone: struct {
        phone: []const u8,
    },
    SecurePlainEmail: struct {
        email: []const u8,
    },
    SecureValueTypePersonalDetails: struct {
    },
    SecureValueTypePassport: struct {
    },
    SecureValueTypeDriverLicense: struct {
    },
    SecureValueTypeIdentityCard: struct {
    },
    SecureValueTypeInternalPassport: struct {
    },
    SecureValueTypeAddress: struct {
    },
    SecureValueTypeUtilityBill: struct {
    },
    SecureValueTypeBankStatement: struct {
    },
    SecureValueTypeRentalAgreement: struct {
    },
    SecureValueTypePassportRegistration: struct {
    },
    SecureValueTypeTemporaryRegistration: struct {
    },
    SecureValueTypePhone: struct {
    },
    SecureValueTypeEmail: struct {
    },
    SecureValue: struct {
        flags: usize,
        type: SecureValueType,
        data: ?SecureData,
        front_side: ?SecureFile,
        reverse_side: ?SecureFile,
        selfie: ?SecureFile,
        translation: ?[]const SecureFile,
        files: ?[]const SecureFile,
        plain_data: ?SecurePlainData,
        hash: []const u8,
    },
    InputSecureValue: struct {
        flags: usize,
        type: SecureValueType,
        data: ?SecureData,
        front_side: ?InputSecureFile,
        reverse_side: ?InputSecureFile,
        selfie: ?InputSecureFile,
        translation: ?[]const InputSecureFile,
        files: ?[]const InputSecureFile,
        plain_data: ?SecurePlainData,
    },
    SecureValueHash: struct {
        type: SecureValueType,
        hash: []const u8,
    },
    SecureValueErrorData: struct {
        type: SecureValueType,
        data_hash: []const u8,
        field: []const u8,
        text: []const u8,
    },
    SecureValueErrorFrontSide: struct {
        type: SecureValueType,
        file_hash: []const u8,
        text: []const u8,
    },
    SecureValueErrorReverseSide: struct {
        type: SecureValueType,
        file_hash: []const u8,
        text: []const u8,
    },
    SecureValueErrorSelfie: struct {
        type: SecureValueType,
        file_hash: []const u8,
        text: []const u8,
    },
    SecureValueErrorFile: struct {
        type: SecureValueType,
        file_hash: []const u8,
        text: []const u8,
    },
    SecureValueErrorFiles: struct {
        type: SecureValueType,
        file_hash: []const []const u8,
        text: []const u8,
    },
    SecureValueError: struct {
        type: SecureValueType,
        hash: []const u8,
        text: []const u8,
    },
    SecureValueErrorTranslationFile: struct {
        type: SecureValueType,
        file_hash: []const u8,
        text: []const u8,
    },
    SecureValueErrorTranslationFiles: struct {
        type: SecureValueType,
        file_hash: []const []const u8,
        text: []const u8,
    },
    SecureCredentialsEncrypted: struct {
        data: []const u8,
        hash: []const u8,
        secret: []const u8,
    },
    AccountAuthorizationForm: struct {
        flags: usize,
        required_types: []const SecureRequiredType,
        values: []const SecureValue,
        errors: []const SecureValueError,
        users: []const User,
        privacy_policy_url: ?[]const u8,
    },
    AccountSentEmailCode: struct {
        email_pattern: []const u8,
        length: i32,
    },
    HelpDeepLinkInfoEmpty: struct {
    },
    HelpDeepLinkInfo: struct {
        flags: usize,
        update_app: ?bool,
        message: []const u8,
        entities: ?[]const MessageEntity,
    },
    SavedPhoneContact: struct {
        phone: []const u8,
        first_name: []const u8,
        last_name: []const u8,
        date: i32,
    },
    AccountTakeout: struct {
        id: i64,
    },
    PasswordKdfAlgoUnknown: struct {
    },
    PasswordKdfAlgoSHA256SHA256PBKDF2HMACSHA512iter100000SHA256ModPow: struct {
        salt1: []const u8,
        salt2: []const u8,
        g: i32,
        p: []const u8,
    },
    SecurePasswordKdfAlgoUnknown: struct {
    },
    SecurePasswordKdfAlgoPBKDF2HMACSHA512iter100000: struct {
        salt: []const u8,
    },
    SecurePasswordKdfAlgoSHA512: struct {
        salt: []const u8,
    },
    SecureSecretSettings: struct {
        secure_algo: SecurePasswordKdfAlgo,
        secure_secret: []const u8,
        secure_secret_id: i64,
    },
    InputCheckPasswordEmpty: struct {
    },
    InputCheckPasswordSRP: struct {
        srp_id: i64,
        A: []const u8,
        M1: []const u8,
    },
    SecureRequiredType: struct {
        flags: usize,
        native_names: ?bool,
        selfie_required: ?bool,
        translation_required: ?bool,
        type: SecureValueType,
    },
    SecureRequiredTypeOneOf: struct {
        types: []const SecureRequiredType,
    },
    HelpPassportConfigNotModified: struct {
    },
    HelpPassportConfig: struct {
        hash: i32,
        countries_langs: DataJSON,
    },
    InputAppEvent: struct {
        time: f64,
        type: []const u8,
        peer: i64,
        data: JSONValue,
    },
    JsonObjectValue: struct {
        key: []const u8,
        value: JSONValue,
    },
    JsonNull: struct {
    },
    JsonBool: struct {
        value: bool,
    },
    JsonNumber: struct {
        value: f64,
    },
    JsonString: struct {
        value: []const u8,
    },
    JsonArray: struct {
        value: []const JSONValue,
    },
    JsonObject: struct {
        value: []const JSONObjectValue,
    },
    PageTableCell: struct {
        flags: usize,
        header: ?bool,
        align_center: ?bool,
        align_right: ?bool,
        valign_middle: ?bool,
        valign_bottom: ?bool,
        text: ?RichText,
        colspan: ?i32,
        rowspan: ?i32,
    },
    PageTableRow: struct {
        cells: []const PageTableCell,
    },
    PageCaption: struct {
        text: RichText,
        credit: RichText,
    },
    PageListItemText: struct {
        text: RichText,
    },
    PageListItemBlocks: struct {
        blocks: []const PageBlock,
    },
    PageListOrderedItemText: struct {
        num: []const u8,
        text: RichText,
    },
    PageListOrderedItemBlocks: struct {
        num: []const u8,
        blocks: []const PageBlock,
    },
    PageRelatedArticle: struct {
        flags: usize,
        url: []const u8,
        webpage_id: i64,
        title: ?[]const u8,
        description: ?[]const u8,
        photo_id: ?i64,
        author: ?[]const u8,
        published_date: ?i32,
    },
    Page: struct {
        flags: usize,
        part: ?bool,
        rtl: ?bool,
        v2: ?bool,
        url: []const u8,
        blocks: []const PageBlock,
        photos: []const Photo,
        documents: []const Document,
        views: ?i32,
    },
    HelpSupportName: struct {
        name: []const u8,
    },
    HelpUserInfoEmpty: struct {
    },
    HelpUserInfo: struct {
        message: []const u8,
        entities: []const MessageEntity,
        author: []const u8,
        date: i32,
    },
    PollAnswer: struct {
        text: TextWithEntities,
        option: []const u8,
    },
    Poll: struct {
        id: i64,
        flags: usize,
        closed: ?bool,
        public_voters: ?bool,
        multiple_choice: ?bool,
        quiz: ?bool,
        question: TextWithEntities,
        answers: []const PollAnswer,
        close_period: ?i32,
        close_date: ?i32,
    },
    PollAnswerVoters: struct {
        flags: usize,
        chosen: ?bool,
        correct: ?bool,
        option: []const u8,
        voters: i32,
    },
    PollResults: struct {
        flags: usize,
        min: ?bool,
        results: ?[]const PollAnswerVoters,
        total_voters: ?i32,
        recent_voters: ?[]const Peer,
        solution: ?[]const u8,
        solution_entities: ?[]const MessageEntity,
    },
    ChatOnlines: struct {
        onlines: i32,
    },
    StatsURL: struct {
        url: []const u8,
    },
    ChatAdminRights: struct {
        flags: usize,
        change_info: ?bool,
        post_messages: ?bool,
        edit_messages: ?bool,
        delete_messages: ?bool,
        ban_users: ?bool,
        invite_users: ?bool,
        pin_messages: ?bool,
        add_admins: ?bool,
        anonymous: ?bool,
        manage_call: ?bool,
        other: ?bool,
        manage_topics: ?bool,
        post_stories: ?bool,
        edit_stories: ?bool,
        delete_stories: ?bool,
    },
    ChatBannedRights: struct {
        flags: usize,
        view_messages: ?bool,
        send_messages: ?bool,
        send_media: ?bool,
        send_stickers: ?bool,
        send_gifs: ?bool,
        send_games: ?bool,
        send_inline: ?bool,
        embed_links: ?bool,
        send_polls: ?bool,
        change_info: ?bool,
        invite_users: ?bool,
        pin_messages: ?bool,
        manage_topics: ?bool,
        send_photos: ?bool,
        send_videos: ?bool,
        send_roundvideos: ?bool,
        send_audios: ?bool,
        send_voices: ?bool,
        send_docs: ?bool,
        send_plain: ?bool,
        until_date: i32,
    },
    InputWallPaper: struct {
        id: i64,
        access_hash: i64,
    },
    InputWallPaperSlug: struct {
        slug: []const u8,
    },
    InputWallPaperNoFile: struct {
        id: i64,
    },
    AccountWallPapersNotModified: struct {
    },
    AccountWallPapers: struct {
        hash: i64,
        wallpapers: []const WallPaper,
    },
    CodeSettings: struct {
        flags: usize,
        allow_flashcall: ?bool,
        current_number: ?bool,
        allow_app_hash: ?bool,
        allow_missed_call: ?bool,
        allow_firebase: ?bool,
        unknown_number: ?bool,
        logout_tokens: ?[]const []const u8,
        token: ?[]const u8,
        app_sandbox: ?bool,
    },
    WallPaperSettings: struct {
        flags: usize,
        blur: ?bool,
        motion: ?bool,
        background_color: ?i32,
        second_background_color: ?i32,
        third_background_color: ?i32,
        fourth_background_color: ?i32,
        intensity: ?i32,
        rotation: ?i32,
        emoticon: ?[]const u8,
    },
    AutoDownloadSettings: struct {
        flags: usize,
        disabled: ?bool,
        video_preload_large: ?bool,
        audio_preload_next: ?bool,
        phonecalls_less_data: ?bool,
        stories_preload: ?bool,
        photo_size_max: i32,
        video_size_max: i64,
        file_size_max: i64,
        video_upload_maxbitrate: i32,
        small_queue_active_operations_max: i32,
        large_queue_active_operations_max: i32,
    },
    AccountAutoDownloadSettings: struct {
        low: AutoDownloadSettings,
        medium: AutoDownloadSettings,
        high: AutoDownloadSettings,
    },
    EmojiKeyword: struct {
        keyword: []const u8,
        emoticons: []const []const u8,
    },
    EmojiKeywordDeleted: struct {
        keyword: []const u8,
        emoticons: []const []const u8,
    },
    EmojiKeywordsDifference: struct {
        lang_code: []const u8,
        from_version: i32,
        version: i32,
        keywords: []const EmojiKeyword,
    },
    EmojiURL: struct {
        url: []const u8,
    },
    EmojiLanguage: struct {
        lang_code: []const u8,
    },
    Folder: struct {
        flags: usize,
        autofill_new_broadcasts: ?bool,
        autofill_public_groups: ?bool,
        autofill_new_correspondents: ?bool,
        id: i32,
        title: []const u8,
        photo: ?ChatPhoto,
    },
    InputFolderPeer: struct {
        peer: InputPeer,
        folder_id: i32,
    },
    FolderPeer: struct {
        peer: Peer,
        folder_id: i32,
    },
    MessagesSearchCounter: struct {
        flags: usize,
        inexact: ?bool,
        filter: MessagesFilter,
        count: i32,
    },
    UrlAuthResultRequest: struct {
        flags: usize,
        request_write_access: ?bool,
        bot: User,
        domain: []const u8,
    },
    UrlAuthResultAccepted: struct {
        url: []const u8,
    },
    UrlAuthResultDefault: struct {
    },
    ChannelLocationEmpty: struct {
    },
    ChannelLocation: struct {
        geo_point: GeoPoint,
        address: []const u8,
    },
    PeerLocated: struct {
        peer: Peer,
        expires: i32,
        distance: i32,
    },
    PeerSelfLocated: struct {
        expires: i32,
    },
    RestrictionReason: struct {
        platform: []const u8,
        reason: []const u8,
        text: []const u8,
    },
    InputTheme: struct {
        id: i64,
        access_hash: i64,
    },
    InputThemeSlug: struct {
        slug: []const u8,
    },
    Theme: struct {
        flags: usize,
        creator: ?bool,
        default: ?bool,
        for_chat: ?bool,
        id: i64,
        access_hash: i64,
        slug: []const u8,
        title: []const u8,
        document: ?Document,
        settings: ?[]const ThemeSettings,
        emoticon: ?[]const u8,
        installs_count: ?i32,
    },
    AccountThemesNotModified: struct {
    },
    AccountThemes: struct {
        hash: i64,
        themes: []const Theme,
    },
    AuthLoginToken: struct {
        expires: i32,
        token: []const u8,
    },
    AuthLoginTokenMigrateTo: struct {
        dc_id: i32,
        token: []const u8,
    },
    AuthLoginTokenSuccess: struct {
        authorization: AuthAuthorization,
    },
    AccountContentSettings: struct {
        flags: usize,
        sensitive_enabled: ?bool,
        sensitive_can_change: ?bool,
    },
    MessagesInactiveChats: struct {
        dates: []const i32,
        chats: []const Chat,
        users: []const User,
    },
    BaseThemeClassic: struct {
    },
    BaseThemeDay: struct {
    },
    BaseThemeNight: struct {
    },
    BaseThemeTinted: struct {
    },
    BaseThemeArctic: struct {
    },
    InputThemeSettings: struct {
        flags: usize,
        message_colors_animated: ?bool,
        base_theme: BaseTheme,
        accent_color: i32,
        outbox_accent_color: ?i32,
        message_colors: ?[]const i32,
        wallpaper: ?InputWallPaper,
        wallpaper_settings: ?WallPaperSettings,
    },
    ThemeSettings: struct {
        flags: usize,
        message_colors_animated: ?bool,
        base_theme: BaseTheme,
        accent_color: i32,
        outbox_accent_color: ?i32,
        message_colors: ?[]const i32,
        wallpaper: ?WallPaper,
    },
    WebPageAttributeTheme: struct {
        flags: usize,
        documents: ?[]const Document,
        settings: ?ThemeSettings,
    },
    WebPageAttributeStory: struct {
        flags: usize,
        peer: Peer,
        id: i32,
        story: ?StoryItem,
    },
    WebPageAttributeStickerSet: struct {
        flags: usize,
        emojis: ?bool,
        text_color: ?bool,
        stickers: []const Document,
    },
    MessagesVotesList: struct {
        flags: usize,
        count: i32,
        votes: []const MessagePeerVote,
        chats: []const Chat,
        users: []const User,
        next_offset: ?[]const u8,
    },
    BankCardOpenUrl: struct {
        url: []const u8,
        name: []const u8,
    },
    PaymentsBankCardData: struct {
        title: []const u8,
        open_urls: []const BankCardOpenUrl,
    },
    DialogFilter: struct {
        flags: usize,
        contacts: ?bool,
        non_contacts: ?bool,
        groups: ?bool,
        broadcasts: ?bool,
        bots: ?bool,
        exclude_muted: ?bool,
        exclude_read: ?bool,
        exclude_archived: ?bool,
        id: i32,
        title: []const u8,
        emoticon: ?[]const u8,
        color: ?i32,
        pinned_peers: []const InputPeer,
        include_peers: []const InputPeer,
        exclude_peers: []const InputPeer,
    },
    DialogFilterDefault: struct {
    },
    DialogFilterChatlist: struct {
        flags: usize,
        has_my_invites: ?bool,
        id: i32,
        title: []const u8,
        emoticon: ?[]const u8,
        color: ?i32,
        pinned_peers: []const InputPeer,
        include_peers: []const InputPeer,
    },
    DialogFilterSuggested: struct {
        filter: DialogFilter,
        description: []const u8,
    },
    StatsDateRangeDays: struct {
        min_date: i32,
        max_date: i32,
    },
    StatsAbsValueAndPrev: struct {
        current: f64,
        previous: f64,
    },
    StatsPercentValue: struct {
        part: f64,
        total: f64,
    },
    StatsGraphAsync: struct {
        token: []const u8,
    },
    StatsGraphError: struct {
        Error: []const u8,
    },
    StatsGraph: struct {
        flags: usize,
        json: DataJSON,
        zoom_token: ?[]const u8,
    },
    StatsBroadcastStats: struct {
        period: StatsDateRangeDays,
        followers: StatsAbsValueAndPrev,
        views_per_post: StatsAbsValueAndPrev,
        shares_per_post: StatsAbsValueAndPrev,
        reactions_per_post: StatsAbsValueAndPrev,
        views_per_story: StatsAbsValueAndPrev,
        shares_per_story: StatsAbsValueAndPrev,
        reactions_per_story: StatsAbsValueAndPrev,
        enabled_notifications: StatsPercentValue,
        growth_graph: StatsGraph,
        followers_graph: StatsGraph,
        mute_graph: StatsGraph,
        top_hours_graph: StatsGraph,
        interactions_graph: StatsGraph,
        iv_interactions_graph: StatsGraph,
        views_by_source_graph: StatsGraph,
        new_followers_by_source_graph: StatsGraph,
        languages_graph: StatsGraph,
        reactions_by_emotion_graph: StatsGraph,
        story_interactions_graph: StatsGraph,
        story_reactions_by_emotion_graph: StatsGraph,
        recent_posts_interactions: []const PostInteractionCounters,
    },
    HelpPromoDataEmpty: struct {
        expires: i32,
    },
    HelpPromoData: struct {
        flags: usize,
        proxy: ?bool,
        expires: i32,
        peer: Peer,
        chats: []const Chat,
        users: []const User,
        psa_type: ?[]const u8,
        psa_message: ?[]const u8,
    },
    VideoSize: struct {
        flags: usize,
        type: []const u8,
        w: i32,
        h: i32,
        size: i32,
        video_start_ts: ?f64,
    },
    VideoSizeEmojiMarkup: struct {
        emoji_id: i64,
        background_colors: []const i32,
    },
    VideoSizeStickerMarkup: struct {
        stickerset: InputStickerSet,
        sticker_id: i64,
        background_colors: []const i32,
    },
    StatsGroupTopPoster: struct {
        user_id: i64,
        messages: i32,
        avg_chars: i32,
    },
    StatsGroupTopAdmin: struct {
        user_id: i64,
        deleted: i32,
        kicked: i32,
        banned: i32,
    },
    StatsGroupTopInviter: struct {
        user_id: i64,
        invitations: i32,
    },
    StatsMegagroupStats: struct {
        period: StatsDateRangeDays,
        members: StatsAbsValueAndPrev,
        messages: StatsAbsValueAndPrev,
        viewers: StatsAbsValueAndPrev,
        posters: StatsAbsValueAndPrev,
        growth_graph: StatsGraph,
        members_graph: StatsGraph,
        new_members_by_source_graph: StatsGraph,
        languages_graph: StatsGraph,
        messages_graph: StatsGraph,
        actions_graph: StatsGraph,
        top_hours_graph: StatsGraph,
        weekdays_graph: StatsGraph,
        top_posters: []const StatsGroupTopPoster,
        top_admins: []const StatsGroupTopAdmin,
        top_inviters: []const StatsGroupTopInviter,
        users: []const User,
    },
    GlobalPrivacySettings: struct {
        flags: usize,
        archive_and_mute_new_noncontact_peers: ?bool,
        keep_archived_unmuted: ?bool,
        keep_archived_folders: ?bool,
        hide_read_marks: ?bool,
        new_noncontact_peers_require_premium: ?bool,
    },
    HelpCountryCode: struct {
        flags: usize,
        country_code: []const u8,
        prefixes: ?[]const []const u8,
        patterns: ?[]const []const u8,
    },
    HelpCountry: struct {
        flags: usize,
        hidden: ?bool,
        iso2: []const u8,
        default_name: []const u8,
        name: ?[]const u8,
        country_codes: []const HelpCountryCode,
    },
    HelpCountriesListNotModified: struct {
    },
    HelpCountriesList: struct {
        countries: []const HelpCountry,
        hash: i32,
    },
    MessageViews: struct {
        flags: usize,
        views: ?i32,
        forwards: ?i32,
        replies: ?MessageReplies,
    },
    MessagesMessageViews: struct {
        views: []const MessageViews,
        chats: []const Chat,
        users: []const User,
    },
    MessagesDiscussionMessage: struct {
        flags: usize,
        messages: []const Message,
        max_id: ?i32,
        read_inbox_max_id: ?i32,
        read_outbox_max_id: ?i32,
        unread_count: i32,
        chats: []const Chat,
        users: []const User,
    },
    MessageReplyHeader: struct {
        flags: usize,
        reply_to_scheduled: ?bool,
        forum_topic: ?bool,
        quote: ?bool,
        reply_to_msg_id: ?i32,
        reply_to_peer_id: ?Peer,
        reply_from: ?MessageFwdHeader,
        reply_media: ?MessageMedia,
        reply_to_top_id: ?i32,
        quote_text: ?[]const u8,
        quote_entities: ?[]const MessageEntity,
        quote_offset: ?i32,
    },
    MessageReplyStoryHeader: struct {
        peer: Peer,
        story_id: i32,
    },
    MessageReplies: struct {
        flags: usize,
        comments: ?bool,
        replies: i32,
        replies_pts: i32,
        recent_repliers: ?[]const Peer,
        channel_id: ?i64,
        max_id: ?i32,
        read_max_id: ?i32,
    },
    PeerBlocked: struct {
        peer_id: Peer,
        date: i32,
    },
    StatsMessageStats: struct {
        views_graph: StatsGraph,
        reactions_by_emotion_graph: StatsGraph,
    },
    GroupCallDiscarded: struct {
        id: i64,
        access_hash: i64,
        duration: i32,
    },
    GroupCall: struct {
        flags: usize,
        join_muted: ?bool,
        can_change_join_muted: ?bool,
        join_date_asc: ?bool,
        schedule_start_subscribed: ?bool,
        can_start_video: ?bool,
        record_video_active: ?bool,
        rtmp_stream: ?bool,
        listeners_hidden: ?bool,
        id: i64,
        access_hash: i64,
        participants_count: i32,
        title: ?[]const u8,
        stream_dc_id: ?i32,
        record_start_date: ?i32,
        schedule_date: ?i32,
        unmuted_video_count: ?i32,
        unmuted_video_limit: i32,
        version: i32,
    },
    InputGroupCall: struct {
        id: i64,
        access_hash: i64,
    },
    GroupCallParticipant: struct {
        flags: usize,
        muted: ?bool,
        left: ?bool,
        can_self_unmute: ?bool,
        just_joined: ?bool,
        versioned: ?bool,
        min: ?bool,
        muted_by_you: ?bool,
        volume_by_admin: ?bool,
        self: ?bool,
        video_joined: ?bool,
        peer: Peer,
        date: i32,
        active_date: ?i32,
        source: i32,
        volume: ?i32,
        about: ?[]const u8,
        raise_hand_rating: ?i64,
        video: ?GroupCallParticipantVideo,
        presentation: ?GroupCallParticipantVideo,
    },
    PhoneGroupCall: struct {
        call: GroupCall,
        participants: []const GroupCallParticipant,
        participants_next_offset: []const u8,
        chats: []const Chat,
        users: []const User,
    },
    PhoneGroupParticipants: struct {
        count: i32,
        participants: []const GroupCallParticipant,
        next_offset: []const u8,
        chats: []const Chat,
        users: []const User,
        version: i32,
    },
    InlineQueryPeerTypeSameBotPM: struct {
    },
    InlineQueryPeerTypePM: struct {
    },
    InlineQueryPeerTypeChat: struct {
    },
    InlineQueryPeerTypeMegagroup: struct {
    },
    InlineQueryPeerTypeBroadcast: struct {
    },
    InlineQueryPeerTypeBotPM: struct {
    },
    MessagesHistoryImport: struct {
        id: i64,
    },
    MessagesHistoryImportParsed: struct {
        flags: usize,
        pm: ?bool,
        group: ?bool,
        title: ?[]const u8,
    },
    MessagesAffectedFoundMessages: struct {
        pts: i32,
        pts_count: i32,
        offset: i32,
        messages: []const i32,
    },
    ChatInviteImporter: struct {
        flags: usize,
        requested: ?bool,
        via_chatlist: ?bool,
        user_id: i64,
        date: i32,
        about: ?[]const u8,
        approved_by: ?i64,
    },
    MessagesExportedChatInvites: struct {
        count: i32,
        invites: []const ExportedChatInvite,
        users: []const User,
    },
    MessagesExportedChatInvite: struct {
        invite: ExportedChatInvite,
        users: []const User,
    },
    MessagesExportedChatInviteReplaced: struct {
        invite: ExportedChatInvite,
        new_invite: ExportedChatInvite,
        users: []const User,
    },
    MessagesChatInviteImporters: struct {
        count: i32,
        importers: []const ChatInviteImporter,
        users: []const User,
    },
    ChatAdminWithInvites: struct {
        admin_id: i64,
        invites_count: i32,
        revoked_invites_count: i32,
    },
    MessagesChatAdminsWithInvites: struct {
        admins: []const ChatAdminWithInvites,
        users: []const User,
    },
    MessagesCheckedHistoryImportPeer: struct {
        confirm_text: []const u8,
    },
    PhoneJoinAsPeers: struct {
        peers: []const Peer,
        chats: []const Chat,
        users: []const User,
    },
    PhoneExportedGroupCallInvite: struct {
        link: []const u8,
    },
    GroupCallParticipantVideoSourceGroup: struct {
        semantics: []const u8,
        sources: []const i32,
    },
    GroupCallParticipantVideo: struct {
        flags: usize,
        paused: ?bool,
        endpoint: []const u8,
        source_groups: []const GroupCallParticipantVideoSourceGroup,
        audio_source: ?i32,
    },
    StickersSuggestedShortName: struct {
        short_name: []const u8,
    },
    BotCommandScopeDefault: struct {
    },
    BotCommandScopeUsers: struct {
    },
    BotCommandScopeChats: struct {
    },
    BotCommandScopeChatAdmins: struct {
    },
    BotCommandScopePeer: struct {
        peer: InputPeer,
    },
    BotCommandScopePeerAdmins: struct {
        peer: InputPeer,
    },
    BotCommandScopePeerUser: struct {
        peer: InputPeer,
        user_id: InputUser,
    },
    AccountResetPasswordFailedWait: struct {
        retry_date: i32,
    },
    AccountResetPasswordRequestedWait: struct {
        until_date: i32,
    },
    AccountResetPasswordOk: struct {
    },
    SponsoredMessage: struct {
        flags: usize,
        recommended: ?bool,
        can_report: ?bool,
        random_id: []const u8,
        url: []const u8,
        title: []const u8,
        message: []const u8,
        entities: ?[]const MessageEntity,
        photo: ?Photo,
        media: ?MessageMedia,
        color: ?PeerColor,
        button_text: []const u8,
        sponsor_info: ?[]const u8,
        additional_info: ?[]const u8,
    },
    MessagesSponsoredMessages: struct {
        flags: usize,
        posts_between: ?i32,
        messages: []const SponsoredMessage,
        chats: []const Chat,
        users: []const User,
    },
    MessagesSponsoredMessagesEmpty: struct {
    },
    SearchResultsCalendarPeriod: struct {
        date: i32,
        min_msg_id: i32,
        max_msg_id: i32,
        count: i32,
    },
    MessagesSearchResultsCalendar: struct {
        flags: usize,
        inexact: ?bool,
        count: i32,
        min_date: i32,
        min_msg_id: i32,
        offset_id_offset: ?i32,
        periods: []const SearchResultsCalendarPeriod,
        messages: []const Message,
        chats: []const Chat,
        users: []const User,
    },
    SearchResultPosition: struct {
        msg_id: i32,
        date: i32,
        offset: i32,
    },
    MessagesSearchResultsPositions: struct {
        count: i32,
        positions: []const SearchResultsPosition,
    },
    ChannelsSendAsPeers: struct {
        peers: []const SendAsPeer,
        chats: []const Chat,
        users: []const User,
    },
    UsersUserFull: struct {
        full_user: UserFull,
        chats: []const Chat,
        users: []const User,
    },
    MessagesPeerSettings: struct {
        settings: PeerSettings,
        chats: []const Chat,
        users: []const User,
    },
    AuthLoggedOut: struct {
        flags: usize,
        future_auth_token: ?[]const u8,
    },
    ReactionCount: struct {
        flags: usize,
        chosen_order: ?i32,
        reaction: Reaction,
        count: i32,
    },
    MessageReactions: struct {
        flags: usize,
        min: ?bool,
        can_see_list: ?bool,
        reactions_as_tags: ?bool,
        results: []const ReactionCount,
        recent_reactions: ?[]const MessagePeerReaction,
        top_reactors: ?[]const MessageReactor,
    },
    MessagesMessageReactionsList: struct {
        flags: usize,
        count: i32,
        reactions: []const MessagePeerReaction,
        chats: []const Chat,
        users: []const User,
        next_offset: ?[]const u8,
    },
    AvailableReaction: struct {
        flags: usize,
        inactive: ?bool,
        premium: ?bool,
        reaction: []const u8,
        title: []const u8,
        static_icon: Document,
        appear_animation: Document,
        select_animation: Document,
        activate_animation: Document,
        effect_animation: Document,
        around_animation: ?Document,
        center_icon: ?Document,
    },
    MessagesAvailableReactionsNotModified: struct {
    },
    MessagesAvailableReactions: struct {
        hash: i32,
        reactions: []const AvailableReaction,
    },
    MessagePeerReaction: struct {
        flags: usize,
        big: ?bool,
        unread: ?bool,
        my: ?bool,
        peer_id: Peer,
        date: i32,
        reaction: Reaction,
    },
    GroupCallStreamChannel: struct {
        channel: i32,
        scale: i32,
        last_timestamp_ms: i64,
    },
    PhoneGroupCallStreamChannels: struct {
        channels: []const GroupCallStreamChannel,
    },
    PhoneGroupCallStreamRtmpUrl: struct {
        url: []const u8,
        key: []const u8,
    },
    AttachMenuBotIconColor: struct {
        name: []const u8,
        color: i32,
    },
    AttachMenuBotIcon: struct {
        flags: usize,
        name: []const u8,
        icon: Document,
        colors: ?[]const AttachMenuBotIconColor,
    },
    AttachMenuBot: struct {
        flags: usize,
        inactive: ?bool,
        has_settings: ?bool,
        request_write_access: ?bool,
        show_in_attach_menu: ?bool,
        show_in_side_menu: ?bool,
        side_menu_disclaimer_needed: ?bool,
        bot_id: i64,
        short_name: []const u8,
        peer_types: ?[]const AttachMenuPeerType,
        icons: []const AttachMenuBotIcon,
    },
    AttachMenuBotsNotModified: struct {
    },
    AttachMenuBots: struct {
        hash: i64,
        bots: []const AttachMenuBot,
        users: []const User,
    },
    AttachMenuBotsBot: struct {
        bot: AttachMenuBot,
        users: []const User,
    },
    WebViewResultUrl: struct {
        flags: usize,
        fullsize: ?bool,
        query_id: ?i64,
        url: []const u8,
    },
    WebViewMessageSent: struct {
        flags: usize,
        msg_id: ?InputBotInlineMessageID,
    },
    BotMenuButtonDefault: struct {
    },
    BotMenuButtonCommands: struct {
    },
    BotMenuButton: struct {
        text: []const u8,
        url: []const u8,
    },
    AccountSavedRingtonesNotModified: struct {
    },
    AccountSavedRingtones: struct {
        hash: i64,
        ringtones: []const Document,
    },
    NotificationSoundDefault: struct {
    },
    NotificationSoundNone: struct {
    },
    NotificationSoundLocal: struct {
        title: []const u8,
        data: []const u8,
    },
    NotificationSoundRingtone: struct {
        id: i64,
    },
    AccountSavedRingtone: struct {
    },
    AccountSavedRingtoneConverted: struct {
        document: Document,
    },
    AttachMenuPeerTypeSameBotPM: struct {
    },
    AttachMenuPeerTypeBotPM: struct {
    },
    AttachMenuPeerTypePM: struct {
    },
    AttachMenuPeerTypeChat: struct {
    },
    AttachMenuPeerTypeBroadcast: struct {
    },
    InputInvoiceMessage: struct {
        peer: InputPeer,
        msg_id: i32,
    },
    InputInvoiceSlug: struct {
        slug: []const u8,
    },
    InputInvoicePremiumGiftCode: struct {
        purpose: InputStorePaymentPurpose,
        option: PremiumGiftCodeOption,
    },
    InputInvoiceStars: struct {
        purpose: InputStorePaymentPurpose,
    },
    InputInvoiceChatInviteSubscription: struct {
        hash: []const u8,
    },
    InputInvoiceStarGift: struct {
        flags: usize,
        hide_name: ?bool,
        user_id: InputUser,
        gift_id: i64,
        message: ?TextWithEntities,
    },
    PaymentsExportedInvoice: struct {
        url: []const u8,
    },
    MessagesTranscribedAudio: struct {
        flags: usize,
        pending: ?bool,
        transcription_id: i64,
        text: []const u8,
        trial_remains_num: ?i32,
        trial_remains_until_date: ?i32,
    },
    HelpPremiumPromo: struct {
        status_text: []const u8,
        status_entities: []const MessageEntity,
        video_sections: []const []const u8,
        videos: []const Document,
        period_options: []const PremiumSubscriptionOption,
        users: []const User,
    },
    InputStorePaymentPremiumSubscription: struct {
        flags: usize,
        restore: ?bool,
        upgrade: ?bool,
    },
    InputStorePaymentGiftPremium: struct {
        user_id: InputUser,
        currency: []const u8,
        amount: i64,
    },
    InputStorePaymentPremiumGiftCode: struct {
        flags: usize,
        users: []const InputUser,
        boost_peer: ?InputPeer,
        currency: []const u8,
        amount: i64,
    },
    InputStorePaymentPremiumGiveaway: struct {
        flags: usize,
        only_new_subscribers: ?bool,
        winners_are_visible: ?bool,
        boost_peer: InputPeer,
        additional_peers: ?[]const InputPeer,
        countries_iso2: ?[]const []const u8,
        prize_description: ?[]const u8,
        random_id: i64,
        until_date: i32,
        currency: []const u8,
        amount: i64,
    },
    InputStorePaymentStarsTopup: struct {
        stars: i64,
        currency: []const u8,
        amount: i64,
    },
    InputStorePaymentStarsGift: struct {
        user_id: InputUser,
        stars: i64,
        currency: []const u8,
        amount: i64,
    },
    InputStorePaymentStarsGiveaway: struct {
        flags: usize,
        only_new_subscribers: ?bool,
        winners_are_visible: ?bool,
        stars: i64,
        boost_peer: InputPeer,
        additional_peers: ?[]const InputPeer,
        countries_iso2: ?[]const []const u8,
        prize_description: ?[]const u8,
        random_id: i64,
        until_date: i32,
        currency: []const u8,
        amount: i64,
        users: i32,
    },
    PremiumGiftOption: struct {
        flags: usize,
        months: i32,
        currency: []const u8,
        amount: i64,
        bot_url: []const u8,
        store_product: ?[]const u8,
    },
    PaymentFormMethod: struct {
        url: []const u8,
        title: []const u8,
    },
    EmojiStatusEmpty: struct {
    },
    EmojiStatus: struct {
        document_id: i64,
    },
    EmojiStatusUntil: struct {
        document_id: i64,
        until: i32,
    },
    AccountEmojiStatusesNotModified: struct {
    },
    AccountEmojiStatuses: struct {
        hash: i64,
        statuses: []const EmojiStatus,
    },
    ReactionEmpty: struct {
    },
    ReactionEmoji: struct {
        emoticon: []const u8,
    },
    ReactionCustomEmoji: struct {
        document_id: i64,
    },
    ReactionPaid: struct {
    },
    ChatReactionsNone: struct {
    },
    ChatReactionsAll: struct {
        flags: usize,
        allow_custom: ?bool,
    },
    ChatReactionsSome: struct {
        reactions: []const Reaction,
    },
    MessagesReactionsNotModified: struct {
    },
    MessagesReactions: struct {
        hash: i64,
        reactions: []const Reaction,
    },
    EmailVerifyPurposeLoginSetup: struct {
        phone_number: []const u8,
        phone_code_hash: []const u8,
    },
    EmailVerifyPurposeLoginChange: struct {
    },
    EmailVerifyPurposePassport: struct {
    },
    EmailVerificationCode: struct {
        code: []const u8,
    },
    EmailVerificationGoogle: struct {
        token: []const u8,
    },
    EmailVerificationApple: struct {
        token: []const u8,
    },
    AccountEmailVerified: struct {
        email: []const u8,
    },
    AccountEmailVerifiedLogin: struct {
        email: []const u8,
        sent_code: AuthSentCode,
    },
    PremiumSubscriptionOption: struct {
        flags: usize,
        current: ?bool,
        can_purchase_upgrade: ?bool,
        transaction: ?[]const u8,
        months: i32,
        currency: []const u8,
        amount: i64,
        bot_url: []const u8,
        store_product: ?[]const u8,
    },
    SendAsPeer: struct {
        flags: usize,
        premium_required: ?bool,
        peer: Peer,
    },
    MessageExtendedMediaPreview: struct {
        flags: usize,
        w: ?i32,
        h: ?i32,
        thumb: ?PhotoSize,
        video_duration: ?i32,
    },
    MessageExtendedMedia: struct {
        media: MessageMedia,
    },
    StickerKeyword: struct {
        document_id: i64,
        keyword: []const []const u8,
    },
    Username: struct {
        flags: usize,
        editable: ?bool,
        active: ?bool,
        username: []const u8,
    },
    ForumTopicDeleted: struct {
        id: i32,
    },
    ForumTopic: struct {
        flags: usize,
        my: ?bool,
        closed: ?bool,
        pinned: ?bool,
        short: ?bool,
        hidden: ?bool,
        id: i32,
        date: i32,
        title: []const u8,
        icon_color: i32,
        icon_emoji_id: ?i64,
        top_message: i32,
        read_inbox_max_id: i32,
        read_outbox_max_id: i32,
        unread_count: i32,
        unread_mentions_count: i32,
        unread_reactions_count: i32,
        from_id: Peer,
        notify_settings: PeerNotifySettings,
        draft: ?DraftMessage,
    },
    MessagesForumTopics: struct {
        flags: usize,
        order_by_create_date: ?bool,
        count: i32,
        topics: []const ForumTopic,
        messages: []const Message,
        chats: []const Chat,
        users: []const User,
        pts: i32,
    },
    DefaultHistoryTTL: struct {
        period: i32,
    },
    ExportedContactToken: struct {
        url: []const u8,
        expires: i32,
    },
    RequestPeerTypeUser: struct {
        flags: usize,
        bot: ?bool,
        premium: ?bool,
    },
    RequestPeerTypeChat: struct {
        flags: usize,
        creator: ?bool,
        bot_participant: ?bool,
        has_username: ?bool,
        forum: ?bool,
        user_admin_rights: ?ChatAdminRights,
        bot_admin_rights: ?ChatAdminRights,
    },
    RequestPeerTypeBroadcast: struct {
        flags: usize,
        creator: ?bool,
        has_username: ?bool,
        user_admin_rights: ?ChatAdminRights,
        bot_admin_rights: ?ChatAdminRights,
    },
    EmojiListNotModified: struct {
    },
    EmojiList: struct {
        hash: i64,
        document_id: []const i64,
    },
    EmojiGroup: struct {
        title: []const u8,
        icon_emoji_id: i64,
        emoticons: []const []const u8,
    },
    EmojiGroupGreeting: struct {
        title: []const u8,
        icon_emoji_id: i64,
        emoticons: []const []const u8,
    },
    EmojiGroupPremium: struct {
        title: []const u8,
        icon_emoji_id: i64,
    },
    MessagesEmojiGroupsNotModified: struct {
    },
    MessagesEmojiGroups: struct {
        hash: i32,
        groups: []const EmojiGroup,
    },
    TextWithEntities: struct {
        text: []const u8,
        entities: []const MessageEntity,
    },
    MessagesTranslateResult: struct {
        result: []const TextWithEntities,
    },
    AutoSaveSettings: struct {
        flags: usize,
        photos: ?bool,
        videos: ?bool,
        video_max_size: ?i64,
    },
    AutoSaveException: struct {
        peer: Peer,
        settings: AutoSaveSettings,
    },
    AccountAutoSaveSettings: struct {
        users_settings: AutoSaveSettings,
        chats_settings: AutoSaveSettings,
        broadcasts_settings: AutoSaveSettings,
        exceptions: []const AutoSaveException,
        chats: []const Chat,
        users: []const User,
    },
    HelpAppConfigNotModified: struct {
    },
    HelpAppConfig: struct {
        hash: i32,
        config: JSONValue,
    },
    InputBotAppID: struct {
        id: i64,
        access_hash: i64,
    },
    InputBotAppShortName: struct {
        bot_id: InputUser,
        short_name: []const u8,
    },
    BotAppNotModified: struct {
    },
    BotApp: struct {
        flags: usize,
        id: i64,
        access_hash: i64,
        short_name: []const u8,
        title: []const u8,
        description: []const u8,
        photo: Photo,
        document: ?Document,
        hash: i64,
    },
    MessagesBotApp: struct {
        flags: usize,
        inactive: ?bool,
        request_write_access: ?bool,
        has_settings: ?bool,
        app: BotApp,
    },
    InlineBotWebView: struct {
        text: []const u8,
        url: []const u8,
    },
    ReadParticipantDate: struct {
        user_id: i64,
        date: i32,
    },
    InputChatlistDialogFilter: struct {
        filter_id: i32,
    },
    ExportedChatlistInvite: struct {
        flags: usize,
        title: []const u8,
        url: []const u8,
        peers: []const Peer,
    },
    ChatlistsExportedChatlistInvite: struct {
        filter: DialogFilter,
        invite: ExportedChatlistInvite,
    },
    ChatlistsExportedInvites: struct {
        invites: []const ExportedChatlistInvite,
        chats: []const Chat,
        users: []const User,
    },
    ChatlistsChatlistInviteAlready: struct {
        filter_id: i32,
        missing_peers: []const Peer,
        already_peers: []const Peer,
        chats: []const Chat,
        users: []const User,
    },
    ChatlistsChatlistInvite: struct {
        flags: usize,
        title: []const u8,
        emoticon: ?[]const u8,
        peers: []const Peer,
        chats: []const Chat,
        users: []const User,
    },
    ChatlistsChatlistUpdates: struct {
        missing_peers: []const Peer,
        chats: []const Chat,
        users: []const User,
    },
    BotsBotInfo: struct {
        name: []const u8,
        about: []const u8,
        description: []const u8,
    },
    MessagePeerVote: struct {
        peer: Peer,
        option: []const u8,
        date: i32,
    },
    MessagePeerVoteInputOption: struct {
        peer: Peer,
        date: i32,
    },
    MessagePeerVoteMultiple: struct {
        peer: Peer,
        options: []const []const u8,
        date: i32,
    },
    StoryViews: struct {
        flags: usize,
        has_viewers: ?bool,
        views_count: i32,
        forwards_count: ?i32,
        reactions: ?[]const ReactionCount,
        reactions_count: ?i32,
        recent_viewers: ?[]const i64,
    },
    StoryItemDeleted: struct {
        id: i32,
    },
    StoryItemSkipped: struct {
        flags: usize,
        close_friends: ?bool,
        id: i32,
        date: i32,
        expire_date: i32,
    },
    StoryItem: struct {
        flags: usize,
        pinned: ?bool,
        public: ?bool,
        close_friends: ?bool,
        min: ?bool,
        noforwards: ?bool,
        edited: ?bool,
        contacts: ?bool,
        selected_contacts: ?bool,
        out: ?bool,
        id: i32,
        date: i32,
        from_id: ?Peer,
        fwd_from: ?StoryFwdHeader,
        expire_date: i32,
        caption: ?[]const u8,
        entities: ?[]const MessageEntity,
        media: MessageMedia,
        media_areas: ?[]const MediaArea,
        privacy: ?[]const PrivacyRule,
        views: ?StoryViews,
        sent_reaction: ?Reaction,
    },
    StoriesAllStoriesNotModified: struct {
        flags: usize,
        state: []const u8,
        stealth_mode: StoriesStealthMode,
    },
    StoriesAllStories: struct {
        flags: usize,
        has_more: ?bool,
        count: i32,
        state: []const u8,
        peer_stories: []const PeerStories,
        chats: []const Chat,
        users: []const User,
        stealth_mode: StoriesStealthMode,
    },
    StoriesStories: struct {
        flags: usize,
        count: i32,
        stories: []const StoryItem,
        pinned_to_top: ?[]const i32,
        chats: []const Chat,
        users: []const User,
    },
    StoryView: struct {
        flags: usize,
        blocked: ?bool,
        blocked_my_stories_from: ?bool,
        user_id: i64,
        date: i32,
        reaction: ?Reaction,
    },
    StoryViewPublicForward: struct {
        flags: usize,
        blocked: ?bool,
        blocked_my_stories_from: ?bool,
        message: Message,
    },
    StoryViewPublicRepost: struct {
        flags: usize,
        blocked: ?bool,
        blocked_my_stories_from: ?bool,
        peer_id: Peer,
        story: StoryItem,
    },
    StoriesStoryViewsList: struct {
        flags: usize,
        count: i32,
        views_count: i32,
        forwards_count: i32,
        reactions_count: i32,
        views: []const StoryView,
        chats: []const Chat,
        users: []const User,
        next_offset: ?[]const u8,
    },
    StoriesStoryViews: struct {
        views: []const StoryViews,
        users: []const User,
    },
    InputReplyToMessage: struct {
        flags: usize,
        reply_to_msg_id: i32,
        top_msg_id: ?i32,
        reply_to_peer_id: ?InputPeer,
        quote_text: ?[]const u8,
        quote_entities: ?[]const MessageEntity,
        quote_offset: ?i32,
    },
    InputReplyToStory: struct {
        peer: InputPeer,
        story_id: i32,
    },
    ExportedStoryLink: struct {
        link: []const u8,
    },
    StoriesStealthMode: struct {
        flags: usize,
        active_until_date: ?i32,
        cooldown_until_date: ?i32,
    },
    MediaAreaCoordinates: struct {
        flags: usize,
        x: f64,
        y: f64,
        w: f64,
        h: f64,
        rotation: f64,
        radius: ?f64,
    },
    MediaAreaVenue: struct {
        coordinates: MediaAreaCoordinates,
        geo: GeoPoint,
        title: []const u8,
        address: []const u8,
        provider: []const u8,
        venue_id: []const u8,
        venue_type: []const u8,
    },
    InputMediaAreaVenue: struct {
        coordinates: MediaAreaCoordinates,
        query_id: i64,
        result_id: []const u8,
    },
    MediaAreaGeoPoint: struct {
        flags: usize,
        coordinates: MediaAreaCoordinates,
        geo: GeoPoint,
        address: ?GeoPointAddress,
    },
    MediaAreaSuggestedReaction: struct {
        flags: usize,
        dark: ?bool,
        flipped: ?bool,
        coordinates: MediaAreaCoordinates,
        reaction: Reaction,
    },
    MediaAreaChannelPost: struct {
        coordinates: MediaAreaCoordinates,
        channel_id: i64,
        msg_id: i32,
    },
    InputMediaAreaChannelPost: struct {
        coordinates: MediaAreaCoordinates,
        channel: InputChannel,
        msg_id: i32,
    },
    MediaAreaUrl: struct {
        coordinates: MediaAreaCoordinates,
        url: []const u8,
    },
    MediaAreaWeather: struct {
        coordinates: MediaAreaCoordinates,
        emoji: []const u8,
        temperature_c: f64,
        color: i32,
    },
    PeerStories: struct {
        flags: usize,
        peer: Peer,
        max_read_id: ?i32,
        stories: []const StoryItem,
    },
    StoriesPeerStories: struct {
        stories: PeerStories,
        chats: []const Chat,
        users: []const User,
    },
    MessagesWebPage: struct {
        webpage: WebPage,
        chats: []const Chat,
        users: []const User,
    },
    PremiumGiftCodeOption: struct {
        flags: usize,
        users: i32,
        months: i32,
        store_product: ?[]const u8,
        store_quantity: ?i32,
        currency: []const u8,
        amount: i64,
    },
    PaymentsCheckedGiftCode: struct {
        flags: usize,
        via_giveaway: ?bool,
        from_id: ?Peer,
        giveaway_msg_id: ?i32,
        to_id: ?i64,
        date: i32,
        months: i32,
        used_date: ?i32,
        chats: []const Chat,
        users: []const User,
    },
    PaymentsGiveawayInfo: struct {
        flags: usize,
        participating: ?bool,
        preparing_results: ?bool,
        start_date: i32,
        joined_too_early_date: ?i32,
        admin_disallowed_chat_id: ?i64,
        disallowed_country: ?[]const u8,
    },
    PaymentsGiveawayInfoResults: struct {
        flags: usize,
        winner: ?bool,
        refunded: ?bool,
        start_date: i32,
        gift_code_slug: ?[]const u8,
        stars_prize: ?i64,
        finish_date: i32,
        winners_count: i32,
        activated_count: ?i32,
    },
    PrepaidGiveaway: struct {
        id: i64,
        months: i32,
        quantity: i32,
        date: i32,
    },
    PrepaidStarsGiveaway: struct {
        id: i64,
        stars: i64,
        quantity: i32,
        boosts: i32,
        date: i32,
    },
    Boost: struct {
        flags: usize,
        gift: ?bool,
        giveaway: ?bool,
        unclaimed: ?bool,
        id: []const u8,
        user_id: ?i64,
        giveaway_msg_id: ?i32,
        date: i32,
        expires: i32,
        used_gift_slug: ?[]const u8,
        multiplier: ?i32,
        stars: ?i64,
    },
    PremiumBoostsList: struct {
        flags: usize,
        count: i32,
        boosts: []const Boost,
        next_offset: ?[]const u8,
        users: []const User,
    },
    MyBoost: struct {
        flags: usize,
        slot: i32,
        peer: ?Peer,
        date: i32,
        expires: i32,
        cooldown_until_date: ?i32,
    },
    PremiumMyBoosts: struct {
        my_boosts: []const MyBoost,
        chats: []const Chat,
        users: []const User,
    },
    PremiumBoostsStatus: struct {
        flags: usize,
        my_boost: ?bool,
        level: i32,
        current_level_boosts: i32,
        boosts: i32,
        gift_boosts: ?i32,
        next_level_boosts: ?i32,
        premium_audience: ?StatsPercentValue,
        boost_url: []const u8,
        prepaid_giveaways: ?[]const PrepaidGiveaway,
        my_boost_slots: ?[]const i32,
    },
    StoryFwdHeader: struct {
        flags: usize,
        modified: ?bool,
        from: ?Peer,
        from_name: ?[]const u8,
        story_id: ?i32,
    },
    PostInteractionCountersMessage: struct {
        msg_id: i32,
        views: i32,
        forwards: i32,
        reactions: i32,
    },
    PostInteractionCountersStory: struct {
        story_id: i32,
        views: i32,
        forwards: i32,
        reactions: i32,
    },
    StatsStoryStats: struct {
        views_graph: StatsGraph,
        reactions_by_emotion_graph: StatsGraph,
    },
    PublicForwardMessage: struct {
        message: Message,
    },
    PublicForwardStory: struct {
        peer: Peer,
        story: StoryItem,
    },
    StatsPublicForwards: struct {
        flags: usize,
        count: i32,
        forwards: []const PublicForward,
        next_offset: ?[]const u8,
        chats: []const Chat,
        users: []const User,
    },
    PeerColor: struct {
        flags: usize,
        color: ?i32,
        background_emoji_id: ?i64,
    },
    HelpPeerColorSet: struct {
        colors: []const i32,
    },
    HelpPeerColorProfileSet: struct {
        palette_colors: []const i32,
        bg_colors: []const i32,
        story_colors: []const i32,
    },
    HelpPeerColorOption: struct {
        flags: usize,
        hidden: ?bool,
        color_id: i32,
        colors: ?HelpPeerColorSet,
        dark_colors: ?HelpPeerColorSet,
        channel_min_level: ?i32,
        group_min_level: ?i32,
    },
    HelpPeerColorsNotModified: struct {
    },
    HelpPeerColors: struct {
        hash: i32,
        colors: []const HelpPeerColorOption,
    },
    StoryReaction: struct {
        peer_id: Peer,
        date: i32,
        reaction: Reaction,
    },
    StoryReactionPublicForward: struct {
        message: Message,
    },
    StoryReactionPublicRepost: struct {
        peer_id: Peer,
        story: StoryItem,
    },
    StoriesStoryReactionsList: struct {
        flags: usize,
        count: i32,
        reactions: []const StoryReaction,
        chats: []const Chat,
        users: []const User,
        next_offset: ?[]const u8,
    },
    SavedDialog: struct {
        flags: usize,
        pinned: ?bool,
        peer: Peer,
        top_message: i32,
    },
    MessagesSavedDialogs: struct {
        dialogs: []const SavedDialog,
        messages: []const Message,
        chats: []const Chat,
        users: []const User,
    },
    MessagesSavedDialogsSlice: struct {
        count: i32,
        dialogs: []const SavedDialog,
        messages: []const Message,
        chats: []const Chat,
        users: []const User,
    },
    MessagesSavedDialogsNotModified: struct {
        count: i32,
    },
    SavedReactionTag: struct {
        flags: usize,
        reaction: Reaction,
        title: ?[]const u8,
        count: i32,
    },
    MessagesSavedReactionTagsNotModified: struct {
    },
    MessagesSavedReactionTags: struct {
        tags: []const SavedReactionTag,
        hash: i64,
    },
    OutboxReadDate: struct {
        date: i32,
    },
    SmsjobsEligibleToJoin: struct {
        terms_url: []const u8,
        monthly_sent_sms: i32,
    },
    SmsjobsStatus: struct {
        flags: usize,
        allow_international: ?bool,
        recent_sent: i32,
        recent_since: i32,
        recent_remains: i32,
        total_sent: i32,
        total_since: i32,
        last_gift_slug: ?[]const u8,
        terms_url: []const u8,
    },
    SmsJob: struct {
        job_id: []const u8,
        phone_number: []const u8,
        text: []const u8,
    },
    BusinessWeeklyOpen: struct {
        start_minute: i32,
        end_minute: i32,
    },
    BusinessWorkHours: struct {
        flags: usize,
        open_now: ?bool,
        timezone_id: []const u8,
        weekly_open: []const BusinessWeeklyOpen,
    },
    BusinessLocation: struct {
        flags: usize,
        geo_point: ?GeoPoint,
        address: []const u8,
    },
    InputBusinessRecipients: struct {
        flags: usize,
        existing_chats: ?bool,
        new_chats: ?bool,
        contacts: ?bool,
        non_contacts: ?bool,
        exclude_selected: ?bool,
        users: ?[]const InputUser,
    },
    BusinessRecipients: struct {
        flags: usize,
        existing_chats: ?bool,
        new_chats: ?bool,
        contacts: ?bool,
        non_contacts: ?bool,
        exclude_selected: ?bool,
        users: ?[]const i64,
    },
    BusinessAwayMessageScheduleAlways: struct {
    },
    BusinessAwayMessageScheduleOutsideWorkHours: struct {
    },
    BusinessAwayMessageScheduleCustom: struct {
        start_date: i32,
        end_date: i32,
    },
    InputBusinessGreetingMessage: struct {
        shortcut_id: i32,
        recipients: InputBusinessRecipients,
        no_activity_days: i32,
    },
    BusinessGreetingMessage: struct {
        shortcut_id: i32,
        recipients: BusinessRecipients,
        no_activity_days: i32,
    },
    InputBusinessAwayMessage: struct {
        flags: usize,
        offline_only: ?bool,
        shortcut_id: i32,
        schedule: BusinessAwayMessageSchedule,
        recipients: InputBusinessRecipients,
    },
    BusinessAwayMessage: struct {
        flags: usize,
        offline_only: ?bool,
        shortcut_id: i32,
        schedule: BusinessAwayMessageSchedule,
        recipients: BusinessRecipients,
    },
    Timezone: struct {
        id: []const u8,
        name: []const u8,
        utc_offset: i32,
    },
    HelpTimezonesListNotModified: struct {
    },
    HelpTimezonesList: struct {
        timezones: []const Timezone,
        hash: i32,
    },
    QuickReply: struct {
        shortcut_id: i32,
        shortcut: []const u8,
        top_message: i32,
        count: i32,
    },
    InputQuickReplyShortcut: struct {
        shortcut: []const u8,
    },
    InputQuickReplyShortcutId: struct {
        shortcut_id: i32,
    },
    MessagesQuickReplies: struct {
        quick_replies: []const QuickReply,
        messages: []const Message,
        chats: []const Chat,
        users: []const User,
    },
    MessagesQuickRepliesNotModified: struct {
    },
    ConnectedBot: struct {
        flags: usize,
        can_reply: ?bool,
        bot_id: i64,
        recipients: BusinessBotRecipients,
    },
    AccountConnectedBots: struct {
        connected_bots: []const ConnectedBot,
        users: []const User,
    },
    MessagesDialogFilters: struct {
        flags: usize,
        tags_enabled: ?bool,
        filters: []const DialogFilter,
    },
    Birthday: struct {
        flags: usize,
        day: i32,
        month: i32,
        year: ?i32,
    },
    BotBusinessConnection: struct {
        flags: usize,
        can_reply: ?bool,
        disabled: ?bool,
        connection_id: []const u8,
        user_id: i64,
        dc_id: i32,
        date: i32,
    },
    InputBusinessIntro: struct {
        flags: usize,
        title: []const u8,
        description: []const u8,
        sticker: ?InputDocument,
    },
    BusinessIntro: struct {
        flags: usize,
        title: []const u8,
        description: []const u8,
        sticker: ?Document,
    },
    MessagesMyStickers: struct {
        count: i32,
        sets: []const StickerSetCovered,
    },
    InputCollectibleUsername: struct {
        username: []const u8,
    },
    InputCollectiblePhone: struct {
        phone: []const u8,
    },
    FragmentCollectibleInfo: struct {
        purchase_date: i32,
        currency: []const u8,
        amount: i64,
        crypto_currency: []const u8,
        crypto_amount: i64,
        url: []const u8,
    },
    InputBusinessBotRecipients: struct {
        flags: usize,
        existing_chats: ?bool,
        new_chats: ?bool,
        contacts: ?bool,
        non_contacts: ?bool,
        exclude_selected: ?bool,
        users: ?[]const InputUser,
        exclude_users: ?[]const InputUser,
    },
    BusinessBotRecipients: struct {
        flags: usize,
        existing_chats: ?bool,
        new_chats: ?bool,
        contacts: ?bool,
        non_contacts: ?bool,
        exclude_selected: ?bool,
        users: ?[]const i64,
        exclude_users: ?[]const i64,
    },
    ContactBirthday: struct {
        contact_id: i64,
        birthday: Birthday,
    },
    ContactsContactBirthdays: struct {
        contacts: []const ContactBirthday,
        users: []const User,
    },
    MissingInvitee: struct {
        flags: usize,
        premium_would_allow_invite: ?bool,
        premium_required_for_pm: ?bool,
        user_id: i64,
    },
    MessagesInvitedUsers: struct {
        updates: Updates,
        missing_invitees: []const MissingInvitee,
    },
    InputBusinessChatLink: struct {
        flags: usize,
        message: []const u8,
        entities: ?[]const MessageEntity,
        title: ?[]const u8,
    },
    BusinessChatLink: struct {
        flags: usize,
        link: []const u8,
        message: []const u8,
        entities: ?[]const MessageEntity,
        title: ?[]const u8,
        views: i32,
    },
    AccountBusinessChatLinks: struct {
        links: []const BusinessChatLink,
        chats: []const Chat,
        users: []const User,
    },
    AccountResolvedBusinessChatLinks: struct {
        flags: usize,
        peer: Peer,
        message: []const u8,
        entities: ?[]const MessageEntity,
        chats: []const Chat,
        users: []const User,
    },
    RequestedPeerUser: struct {
        flags: usize,
        user_id: i64,
        first_name: ?[]const u8,
        last_name: ?[]const u8,
        username: ?[]const u8,
        photo: ?Photo,
    },
    RequestedPeerChat: struct {
        flags: usize,
        chat_id: i64,
        title: ?[]const u8,
        photo: ?Photo,
    },
    RequestedPeerChannel: struct {
        flags: usize,
        channel_id: i64,
        title: ?[]const u8,
        username: ?[]const u8,
        photo: ?Photo,
    },
    SponsoredMessageReportOption: struct {
        text: []const u8,
        option: []const u8,
    },
    ChannelsSponsoredMessageReportResultChooseOption: struct {
        title: []const u8,
        options: []const SponsoredMessageReportOption,
    },
    ChannelsSponsoredMessageReportResultAdsHidden: struct {
    },
    ChannelsSponsoredMessageReportResultReported: struct {
    },
    StatsBroadcastRevenueStats: struct {
        top_hours_graph: StatsGraph,
        revenue_graph: StatsGraph,
        balances: BroadcastRevenueBalances,
        usd_rate: f64,
    },
    StatsBroadcastRevenueWithdrawalUrl: struct {
        url: []const u8,
    },
    BroadcastRevenueTransactionProceeds: struct {
        amount: i64,
        from_date: i32,
        to_date: i32,
    },
    BroadcastRevenueTransactionWithdrawal: struct {
        flags: usize,
        pending: ?bool,
        failed: ?bool,
        amount: i64,
        date: i32,
        provider: []const u8,
        transaction_date: ?i32,
        transaction_url: ?[]const u8,
    },
    BroadcastRevenueTransactionRefund: struct {
        amount: i64,
        date: i32,
        provider: []const u8,
    },
    StatsBroadcastRevenueTransactions: struct {
        count: i32,
        transactions: []const BroadcastRevenueTransaction,
    },
    ReactionNotificationsFromContacts: struct {
    },
    ReactionNotificationsFromAll: struct {
    },
    ReactionsNotifySettings: struct {
        flags: usize,
        messages_notify_from: ?ReactionNotificationsFrom,
        stories_notify_from: ?ReactionNotificationsFrom,
        sound: NotificationSound,
        show_previews: bool,
    },
    BroadcastRevenueBalances: struct {
        flags: usize,
        withdrawal_enabled: ?bool,
        current_balance: i64,
        available_balance: i64,
        overall_revenue: i64,
    },
    AvailableEffect: struct {
        flags: usize,
        premium_required: ?bool,
        id: i64,
        emoticon: []const u8,
        static_icon_id: ?i64,
        effect_sticker_id: i64,
        effect_animation_id: ?i64,
    },
    MessagesAvailableEffectsNotModified: struct {
    },
    MessagesAvailableEffects: struct {
        hash: i32,
        effects: []const AvailableEffect,
        documents: []const Document,
    },
    FactCheck: struct {
        flags: usize,
        need_check: ?bool,
        country: ?[]const u8,
        text: ?TextWithEntities,
        hash: i64,
    },
    StarsTransactionPeerUnsupported: struct {
    },
    StarsTransactionPeerAppStore: struct {
    },
    StarsTransactionPeerPlayMarket: struct {
    },
    StarsTransactionPeerPremiumBot: struct {
    },
    StarsTransactionPeerFragment: struct {
    },
    StarsTransactionPeer: struct {
        peer: Peer,
    },
    StarsTransactionPeerAds: struct {
    },
    StarsTopupOption: struct {
        flags: usize,
        extended: ?bool,
        stars: i64,
        store_product: ?[]const u8,
        currency: []const u8,
        amount: i64,
    },
    StarsTransaction: struct {
        flags: usize,
        refund: ?bool,
        pending: ?bool,
        failed: ?bool,
        gift: ?bool,
        reaction: ?bool,
        id: []const u8,
        stars: i64,
        date: i32,
        peer: StarsTransactionPeer,
        title: ?[]const u8,
        description: ?[]const u8,
        photo: ?WebDocument,
        transaction_date: ?i32,
        transaction_url: ?[]const u8,
        bot_payload: ?[]const u8,
        msg_id: ?i32,
        extended_media: ?[]const MessageMedia,
        subscription_period: ?i32,
        giveaway_post_id: ?i32,
        stargift: ?StarGift,
    },
    PaymentsStarsStatus: struct {
        flags: usize,
        balance: i64,
        subscriptions: ?[]const StarsSubscription,
        subscriptions_next_offset: ?[]const u8,
        subscriptions_missing_balance: ?i64,
        history: ?[]const StarsTransaction,
        next_offset: ?[]const u8,
        chats: []const Chat,
        users: []const User,
    },
    FoundStory: struct {
        peer: Peer,
        story: StoryItem,
    },
    StoriesFoundStories: struct {
        flags: usize,
        count: i32,
        stories: []const FoundStory,
        next_offset: ?[]const u8,
        chats: []const Chat,
        users: []const User,
    },
    GeoPointAddress: struct {
        flags: usize,
        country_iso2: []const u8,
        state: ?[]const u8,
        city: ?[]const u8,
        street: ?[]const u8,
    },
    StarsRevenueStatus: struct {
        flags: usize,
        withdrawal_enabled: ?bool,
        current_balance: i64,
        available_balance: i64,
        overall_revenue: i64,
        next_withdrawal_at: ?i32,
    },
    PaymentsStarsRevenueStats: struct {
        revenue_graph: StatsGraph,
        status: StarsRevenueStatus,
        usd_rate: f64,
    },
    PaymentsStarsRevenueWithdrawalUrl: struct {
        url: []const u8,
    },
    PaymentsStarsRevenueAdsAccountUrl: struct {
        url: []const u8,
    },
    InputStarsTransaction: struct {
        flags: usize,
        refund: ?bool,
        id: []const u8,
    },
    StarsGiftOption: struct {
        flags: usize,
        extended: ?bool,
        stars: i64,
        store_product: ?[]const u8,
        currency: []const u8,
        amount: i64,
    },
    BotsPopularAppBots: struct {
        flags: usize,
        next_offset: ?[]const u8,
        users: []const User,
    },
    BotPreviewMedia: struct {
        date: i32,
        media: MessageMedia,
    },
    BotsPreviewInfo: struct {
        media: []const BotPreviewMedia,
        lang_codes: []const []const u8,
    },
    StarsSubscriptionPricing: struct {
        period: i32,
        amount: i64,
    },
    StarsSubscription: struct {
        flags: usize,
        canceled: ?bool,
        can_refulfill: ?bool,
        missing_balance: ?bool,
        id: []const u8,
        peer: Peer,
        until_date: i32,
        pricing: StarsSubscriptionPricing,
        chat_invite_hash: ?[]const u8,
    },
    MessageReactor: struct {
        flags: usize,
        top: ?bool,
        my: ?bool,
        anonymous: ?bool,
        peer_id: ?Peer,
        count: i32,
    },
    StarsGiveawayOption: struct {
        flags: usize,
        extended: ?bool,
        default: ?bool,
        stars: i64,
        yearly_boosts: i32,
        store_product: ?[]const u8,
        currency: []const u8,
        amount: i64,
        winners: []const StarsGiveawayWinnersOption,
    },
    StarsGiveawayWinnersOption: struct {
        flags: usize,
        default: ?bool,
        users: i32,
        per_user_stars: i64,
    },
    StarGift: struct {
        flags: usize,
        limited: ?bool,
        id: i64,
        sticker: Document,
        stars: i64,
        availability_remains: ?i32,
        availability_total: ?i32,
        convert_stars: i64,
    },
    PaymentsStarGiftsNotModified: struct {
    },
    PaymentsStarGifts: struct {
        hash: i32,
        gifts: []const StarGift,
    },
    UserStarGift: struct {
        flags: usize,
        name_hidden: ?bool,
        unsaved: ?bool,
        from_id: ?i64,
        date: i32,
        gift: StarGift,
        message: ?TextWithEntities,
        msg_id: ?i32,
        convert_stars: ?i64,
    },
    PaymentsUserStarGifts: struct {
        flags: usize,
        count: i32,
        gifts: []const UserStarGift,
        next_offset: ?[]const u8,
        users: []const User,
    },
    MessageReportOption: struct {
        text: []const u8,
        option: []const u8,
    },
    ReportResultChooseOption: struct {
        title: []const u8,
        options: []const MessageReportOption,
    },
    ReportResultAddComment: struct {
        flags: usize,
        optional: ?bool,
        option: []const u8,
    },
    ReportResultReported: struct {
    },
    InvokeAfterMsgs: struct {
        msg_ids: []const i64,
        query: *const TL,
    },
    InitConnection: struct {
        flags: usize,
        api_id: i32,
        device_model: []const u8,
        system_version: []const u8,
        app_version: []const u8,
        system_lang_code: []const u8,
        lang_pack: []const u8,
        lang_code: []const u8,
        proxy: ?InputClientProxy,
        params: ?JSONValue,
        query: *const TL,
    },
    InvokeWithLayer: struct {
        layer: i32,
        query: *const TL,
    },
    InvokeWithoutUpdates: struct {
        query: *const TL,
    },
    InvokeWithMessagesRange: struct {
        range: MessageRange,
        query: *const TL,
    },
    InvokeWithTakeout: struct {
        takeout_id: i64,
        query: *const TL,
    },
    InvokeWithBusinessConnection: struct {
        connection_id: []const u8,
        query: *const TL,
    },
    InvokeWithGooglePlayIntegrity: struct {
        nonce: []const u8,
        token: []const u8,
        query: *const TL,
    },
    InvokeWithApnsSecret: struct {
        nonce: []const u8,
        secret: []const u8,
        query: *const TL,
    },
    AuthSendCode: struct {
        phone_number: []const u8,
        api_id: i32,
        api_hash: []const u8,
        settings: CodeSettings,
    },
    AuthSignUp: struct {
        flags: usize,
        no_joined_notifications: ?bool,
        phone_number: []const u8,
        phone_code_hash: []const u8,
        first_name: []const u8,
        last_name: []const u8,
    },
    AuthSignIn: struct {
        flags: usize,
        phone_number: []const u8,
        phone_code_hash: []const u8,
        phone_code: ?[]const u8,
        email_verification: ?EmailVerification,
    },
    AuthLogOut: struct {
    },
    AuthResetAuthorizations: struct {
    },
    AuthExportAuthorization: struct {
        dc_id: i32,
    },
    AuthImportAuthorization: struct {
        id: i64,
        bytes: []const u8,
    },
    AuthBindTempAuthKey: struct {
        perm_auth_key_id: i64,
        nonce: i64,
        expires_at: i32,
        encrypted_message: []const u8,
    },
    AuthImportBotAuthorization: struct {
        flags: i32,
        api_id: i32,
        api_hash: []const u8,
        bot_auth_token: []const u8,
    },
    AuthCheckPassword: struct {
        password: InputCheckPasswordSRP,
    },
    AuthRequestPasswordRecovery: struct {
    },
    AuthRecoverPassword: struct {
        flags: usize,
        code: []const u8,
        new_settings: ?AccountPasswordInputSettings,
    },
    AuthResendCode: struct {
        flags: usize,
        phone_number: []const u8,
        phone_code_hash: []const u8,
        reason: ?[]const u8,
    },
    AuthCancelCode: struct {
        phone_number: []const u8,
        phone_code_hash: []const u8,
    },
    AuthDropTempAuthKeys: struct {
        except_auth_keys: []const i64,
    },
    AuthExportLoginToken: struct {
        api_id: i32,
        api_hash: []const u8,
        except_ids: []const i64,
    },
    AuthImportLoginToken: struct {
        token: []const u8,
    },
    AuthAcceptLoginToken: struct {
        token: []const u8,
    },
    AuthCheckRecoveryPassword: struct {
        code: []const u8,
    },
    AuthImportWebTokenAuthorization: struct {
        api_id: i32,
        api_hash: []const u8,
        web_auth_token: []const u8,
    },
    AuthRequestFirebaseSms: struct {
        flags: usize,
        phone_number: []const u8,
        phone_code_hash: []const u8,
        safety_net_token: ?[]const u8,
        play_integrity_token: ?[]const u8,
        ios_push_secret: ?[]const u8,
    },
    AuthResetLoginEmail: struct {
        phone_number: []const u8,
        phone_code_hash: []const u8,
    },
    AuthReportMissingCode: struct {
        phone_number: []const u8,
        phone_code_hash: []const u8,
        mnc: []const u8,
    },
    AccountRegisterDevice: struct {
        flags: usize,
        no_muted: ?bool,
        token_type: i32,
        token: []const u8,
        app_sandbox: bool,
        secret: []const u8,
        other_uids: []const i64,
    },
    AccountUnregisterDevice: struct {
        token_type: i32,
        token: []const u8,
        other_uids: []const i64,
    },
    AccountUpdateNotifySettings: struct {
        peer: InputNotifyPeer,
        settings: InputPeerNotifySettings,
    },
    AccountGetNotifySettings: struct {
        peer: InputNotifyPeer,
    },
    AccountResetNotifySettings: struct {
    },
    AccountUpdateProfile: struct {
        flags: usize,
        first_name: ?[]const u8,
        last_name: ?[]const u8,
        about: ?[]const u8,
    },
    AccountUpdateStatus: struct {
        offline: bool,
    },
    AccountGetWallPapers: struct {
        hash: i64,
    },
    AccountReportPeer: struct {
        peer: InputPeer,
        reason: ReportReason,
        message: []const u8,
    },
    AccountCheckUsername: struct {
        username: []const u8,
    },
    AccountUpdateUsername: struct {
        username: []const u8,
    },
    AccountGetPrivacy: struct {
        key: InputPrivacyKey,
    },
    AccountSetPrivacy: struct {
        key: InputPrivacyKey,
        rules: []const InputPrivacyRule,
    },
    AccountDeleteAccount: struct {
        flags: usize,
        reason: []const u8,
        password: ?InputCheckPasswordSRP,
    },
    AccountGetAccountTTL: struct {
    },
    AccountSetAccountTTL: struct {
        ttl: AccountDaysTTL,
    },
    AccountSendChangePhoneCode: struct {
        phone_number: []const u8,
        settings: CodeSettings,
    },
    AccountChangePhone: struct {
        phone_number: []const u8,
        phone_code_hash: []const u8,
        phone_code: []const u8,
    },
    AccountUpdateDeviceLocked: struct {
        period: i32,
    },
    AccountGetAuthorizations: struct {
    },
    AccountResetAuthorization: struct {
        hash: i64,
    },
    AccountGetPassword: struct {
    },
    AccountGetPasswordSettings: struct {
        password: InputCheckPasswordSRP,
    },
    AccountUpdatePasswordSettings: struct {
        password: InputCheckPasswordSRP,
        new_settings: AccountPasswordInputSettings,
    },
    AccountSendConfirmPhoneCode: struct {
        hash: []const u8,
        settings: CodeSettings,
    },
    AccountConfirmPhone: struct {
        phone_code_hash: []const u8,
        phone_code: []const u8,
    },
    AccountGetTmpPassword: struct {
        password: InputCheckPasswordSRP,
        period: i32,
    },
    AccountGetWebAuthorizations: struct {
    },
    AccountResetWebAuthorization: struct {
        hash: i64,
    },
    AccountResetWebAuthorizations: struct {
    },
    AccountGetAllSecureValues: struct {
    },
    AccountGetSecureValue: struct {
        types: []const SecureValueType,
    },
    AccountSaveSecureValue: struct {
        value: InputSecureValue,
        secure_secret_id: i64,
    },
    AccountDeleteSecureValue: struct {
        types: []const SecureValueType,
    },
    AccountGetAuthorizationForm: struct {
        bot_id: i64,
        scope: []const u8,
        public_key: []const u8,
    },
    AccountAcceptAuthorization: struct {
        bot_id: i64,
        scope: []const u8,
        public_key: []const u8,
        value_hashes: []const SecureValueHash,
        credentials: SecureCredentialsEncrypted,
    },
    AccountSendVerifyPhoneCode: struct {
        phone_number: []const u8,
        settings: CodeSettings,
    },
    AccountVerifyPhone: struct {
        phone_number: []const u8,
        phone_code_hash: []const u8,
        phone_code: []const u8,
    },
    AccountSendVerifyEmailCode: struct {
        purpose: EmailVerifyPurpose,
        email: []const u8,
    },
    AccountVerifyEmail: struct {
        purpose: EmailVerifyPurpose,
        verification: EmailVerification,
    },
    AccountInitTakeoutSession: struct {
        flags: usize,
        contacts: ?bool,
        message_users: ?bool,
        message_chats: ?bool,
        message_megagroups: ?bool,
        message_channels: ?bool,
        files: ?bool,
        file_max_size: ?i64,
    },
    AccountFinishTakeoutSession: struct {
        flags: usize,
        success: ?bool,
    },
    AccountConfirmPasswordEmail: struct {
        code: []const u8,
    },
    AccountResendPasswordEmail: struct {
    },
    AccountCancelPasswordEmail: struct {
    },
    AccountGetContactSignUpNotification: struct {
    },
    AccountSetContactSignUpNotification: struct {
        silent: bool,
    },
    AccountGetNotifyExceptions: struct {
        flags: usize,
        compare_sound: ?bool,
        compare_stories: ?bool,
        peer: ?InputNotifyPeer,
    },
    AccountGetWallPaper: struct {
        wallpaper: InputWallPaper,
    },
    AccountUploadWallPaper: struct {
        flags: usize,
        for_chat: ?bool,
        file: InputFile,
        mime_type: []const u8,
        settings: WallPaperSettings,
    },
    AccountSaveWallPaper: struct {
        wallpaper: InputWallPaper,
        unsave: bool,
        settings: WallPaperSettings,
    },
    AccountInstallWallPaper: struct {
        wallpaper: InputWallPaper,
        settings: WallPaperSettings,
    },
    AccountResetWallPapers: struct {
    },
    AccountGetAutoDownloadSettings: struct {
    },
    AccountSaveAutoDownloadSettings: struct {
        flags: usize,
        low: ?bool,
        high: ?bool,
        settings: AutoDownloadSettings,
    },
    AccountUploadTheme: struct {
        flags: usize,
        file: InputFile,
        thumb: ?InputFile,
        file_name: []const u8,
        mime_type: []const u8,
    },
    AccountCreateTheme: struct {
        flags: usize,
        slug: []const u8,
        title: []const u8,
        document: ?InputDocument,
        settings: ?[]const InputThemeSettings,
    },
    AccountUpdateTheme: struct {
        flags: usize,
        format: []const u8,
        theme: InputTheme,
        slug: ?[]const u8,
        title: ?[]const u8,
        document: ?InputDocument,
        settings: ?[]const InputThemeSettings,
    },
    AccountSaveTheme: struct {
        theme: InputTheme,
        unsave: bool,
    },
    AccountInstallTheme: struct {
        flags: usize,
        dark: ?bool,
        theme: ?InputTheme,
        format: ?[]const u8,
        base_theme: ?BaseTheme,
    },
    AccountGetTheme: struct {
        format: []const u8,
        theme: InputTheme,
    },
    AccountGetThemes: struct {
        format: []const u8,
        hash: i64,
    },
    AccountSetContentSettings: struct {
        flags: usize,
        sensitive_enabled: ?bool,
    },
    AccountGetContentSettings: struct {
    },
    AccountGetMultiWallPapers: struct {
        wallpapers: []const InputWallPaper,
    },
    AccountGetGlobalPrivacySettings: struct {
    },
    AccountSetGlobalPrivacySettings: struct {
        settings: GlobalPrivacySettings,
    },
    AccountReportProfilePhoto: struct {
        peer: InputPeer,
        photo_id: InputPhoto,
        reason: ReportReason,
        message: []const u8,
    },
    AccountResetPassword: struct {
    },
    AccountDeclinePasswordReset: struct {
    },
    AccountGetChatThemes: struct {
        hash: i64,
    },
    AccountSetAuthorizationTTL: struct {
        authorization_ttl_days: i32,
    },
    AccountChangeAuthorizationSettings: struct {
        flags: usize,
        confirmed: ?bool,
        hash: i64,
        encrypted_requests_disabled: ?bool,
        call_requests_disabled: ?bool,
    },
    AccountGetSavedRingtones: struct {
        hash: i64,
    },
    AccountSaveRingtone: struct {
        id: InputDocument,
        unsave: bool,
    },
    AccountUploadRingtone: struct {
        file: InputFile,
        file_name: []const u8,
        mime_type: []const u8,
    },
    AccountUpdateEmojiStatus: struct {
        emoji_status: EmojiStatus,
    },
    AccountGetDefaultEmojiStatuses: struct {
        hash: i64,
    },
    AccountGetRecentEmojiStatuses: struct {
        hash: i64,
    },
    AccountClearRecentEmojiStatuses: struct {
    },
    AccountReorderUsernames: struct {
        order: []const []const u8,
    },
    AccountToggleUsername: struct {
        username: []const u8,
        active: bool,
    },
    AccountGetDefaultProfilePhotoEmojis: struct {
        hash: i64,
    },
    AccountGetDefaultGroupPhotoEmojis: struct {
        hash: i64,
    },
    AccountGetAutoSaveSettings: struct {
    },
    AccountSaveAutoSaveSettings: struct {
        flags: usize,
        users: ?bool,
        chats: ?bool,
        broadcasts: ?bool,
        peer: ?InputPeer,
        settings: AutoSaveSettings,
    },
    AccountDeleteAutoSaveExceptions: struct {
    },
    AccountInvalidateSignInCodes: struct {
        codes: []const []const u8,
    },
    AccountUpdateColor: struct {
        flags: usize,
        for_profile: ?bool,
        color: ?i32,
        background_emoji_id: ?i64,
    },
    AccountGetDefaultBackgroundEmojis: struct {
        hash: i64,
    },
    AccountGetChannelDefaultEmojiStatuses: struct {
        hash: i64,
    },
    AccountGetChannelRestrictedStatusEmojis: struct {
        hash: i64,
    },
    AccountUpdateBusinessWorkHours: struct {
        flags: usize,
        business_work_hours: ?BusinessWorkHours,
    },
    AccountUpdateBusinessLocation: struct {
        flags: usize,
        geo_point: ?InputGeoPoint,
        address: ?[]const u8,
    },
    AccountUpdateBusinessGreetingMessage: struct {
        flags: usize,
        message: ?InputBusinessGreetingMessage,
    },
    AccountUpdateBusinessAwayMessage: struct {
        flags: usize,
        message: ?InputBusinessAwayMessage,
    },
    AccountUpdateConnectedBot: struct {
        flags: usize,
        can_reply: ?bool,
        deleted: ?bool,
        bot: InputUser,
        recipients: InputBusinessBotRecipients,
    },
    AccountGetConnectedBots: struct {
    },
    AccountGetBotBusinessConnection: struct {
        connection_id: []const u8,
    },
    AccountUpdateBusinessIntro: struct {
        flags: usize,
        intro: ?InputBusinessIntro,
    },
    AccountToggleConnectedBotPaused: struct {
        peer: InputPeer,
        paused: bool,
    },
    AccountDisablePeerConnectedBot: struct {
        peer: InputPeer,
    },
    AccountUpdateBirthday: struct {
        flags: usize,
        birthday: ?Birthday,
    },
    AccountCreateBusinessChatLink: struct {
        link: InputBusinessChatLink,
    },
    AccountEditBusinessChatLink: struct {
        slug: []const u8,
        link: InputBusinessChatLink,
    },
    AccountDeleteBusinessChatLink: struct {
        slug: []const u8,
    },
    AccountGetBusinessChatLinks: struct {
    },
    AccountResolveBusinessChatLink: struct {
        slug: []const u8,
    },
    AccountUpdatePersonalChannel: struct {
        channel: InputChannel,
    },
    AccountToggleSponsoredMessages: struct {
        enabled: bool,
    },
    AccountGetReactionsNotifySettings: struct {
    },
    AccountSetReactionsNotifySettings: struct {
        settings: ReactionsNotifySettings,
    },
    UsersGetUsers: struct {
        id: []const InputUser,
    },
    UsersGetFullUser: struct {
        id: InputUser,
    },
    UsersSetSecureValueErrors: struct {
        id: InputUser,
        errors: []const SecureValueError,
    },
    UsersGetIsPremiumRequiredToContact: struct {
        id: []const InputUser,
    },
    ContactsGetContactIDs: struct {
        hash: i64,
    },
    ContactsGetStatuses: struct {
    },
    ContactsGetContacts: struct {
        hash: i64,
    },
    ContactsImportContacts: struct {
        contacts: []const InputContact,
    },
    ContactsDeleteContacts: struct {
        id: []const InputUser,
    },
    ContactsDeleteByPhones: struct {
        phones: []const []const u8,
    },
    ContactsBlock: struct {
        flags: usize,
        my_stories_from: ?bool,
        id: InputPeer,
    },
    ContactsUnblock: struct {
        flags: usize,
        my_stories_from: ?bool,
        id: InputPeer,
    },
    ContactsGetBlocked: struct {
        flags: usize,
        my_stories_from: ?bool,
        offset: i32,
        limit: i32,
    },
    ContactsSearch: struct {
        q: []const u8,
        limit: i32,
    },
    ContactsResolveUsername: struct {
        username: []const u8,
    },
    ContactsGetTopPeers: struct {
        flags: usize,
        correspondents: ?bool,
        bots_pm: ?bool,
        bots_inline: ?bool,
        phone_calls: ?bool,
        forward_users: ?bool,
        forward_chats: ?bool,
        groups: ?bool,
        channels: ?bool,
        bots_app: ?bool,
        offset: i32,
        limit: i32,
        hash: i64,
    },
    ContactsResetTopPeerRating: struct {
        category: TopPeerCategory,
        peer: InputPeer,
    },
    ContactsResetSaved: struct {
    },
    ContactsGetSaved: struct {
    },
    ContactsToggleTopPeers: struct {
        enabled: bool,
    },
    ContactsAddContact: struct {
        flags: usize,
        add_phone_privacy_exception: ?bool,
        id: InputUser,
        first_name: []const u8,
        last_name: []const u8,
        phone: []const u8,
    },
    ContactsAcceptContact: struct {
        id: InputUser,
    },
    ContactsGetLocated: struct {
        flags: usize,
        background: ?bool,
        geo_point: InputGeoPoint,
        self_expires: ?i32,
    },
    ContactsBlockFromReplies: struct {
        flags: usize,
        delete_message: ?bool,
        delete_history: ?bool,
        report_spam: ?bool,
        msg_id: i32,
    },
    ContactsResolvePhone: struct {
        phone: []const u8,
    },
    ContactsExportContactToken: struct {
    },
    ContactsImportContactToken: struct {
        token: []const u8,
    },
    ContactsEditCloseFriends: struct {
        id: []const i64,
    },
    ContactsSetBlocked: struct {
        flags: usize,
        my_stories_from: ?bool,
        id: []const InputPeer,
        limit: i32,
    },
    ContactsGetBirthdays: struct {
    },
    MessagesGetMessages: struct {
        id: []const InputMessage,
    },
    MessagesGetDialogs: struct {
        flags: usize,
        exclude_pinned: ?bool,
        folder_id: ?i32,
        offset_date: i32,
        offset_id: i32,
        offset_peer: InputPeer,
        limit: i32,
        hash: i64,
    },
    MessagesGetHistory: struct {
        peer: InputPeer,
        offset_id: i32,
        offset_date: i32,
        add_offset: i32,
        limit: i32,
        max_id: i32,
        min_id: i32,
        hash: i64,
    },
    MessagesSearch: struct {
        flags: usize,
        peer: InputPeer,
        q: []const u8,
        from_id: ?InputPeer,
        saved_peer_id: ?InputPeer,
        saved_reaction: ?[]const Reaction,
        top_msg_id: ?i32,
        filter: MessagesFilter,
        min_date: i32,
        max_date: i32,
        offset_id: i32,
        add_offset: i32,
        limit: i32,
        max_id: i32,
        min_id: i32,
        hash: i64,
    },
    MessagesReadHistory: struct {
        peer: InputPeer,
        max_id: i32,
    },
    MessagesDeleteHistory: struct {
        flags: usize,
        just_clear: ?bool,
        revoke: ?bool,
        peer: InputPeer,
        max_id: i32,
        min_date: ?i32,
        max_date: ?i32,
    },
    MessagesDeleteMessages: struct {
        flags: usize,
        revoke: ?bool,
        id: []const i32,
    },
    MessagesReceivedMessages: struct {
        max_id: i32,
    },
    MessagesSetTyping: struct {
        flags: usize,
        peer: InputPeer,
        top_msg_id: ?i32,
        action: SendMessageAction,
    },
    MessagesSendMessage: struct {
        flags: usize,
        no_webpage: ?bool,
        silent: ?bool,
        background: ?bool,
        clear_draft: ?bool,
        noforwards: ?bool,
        update_stickersets_order: ?bool,
        invert_media: ?bool,
        peer: InputPeer,
        reply_to: ?InputReplyTo,
        message: []const u8,
        random_id: i64,
        reply_markup: ?ReplyMarkup,
        entities: ?[]const MessageEntity,
        schedule_date: ?i32,
        send_as: ?InputPeer,
        quick_reply_shortcut: ?InputQuickReplyShortcut,
        effect: ?i64,
    },
    MessagesSendMedia: struct {
        flags: usize,
        silent: ?bool,
        background: ?bool,
        clear_draft: ?bool,
        noforwards: ?bool,
        update_stickersets_order: ?bool,
        invert_media: ?bool,
        peer: InputPeer,
        reply_to: ?InputReplyTo,
        media: InputMedia,
        message: []const u8,
        random_id: i64,
        reply_markup: ?ReplyMarkup,
        entities: ?[]const MessageEntity,
        schedule_date: ?i32,
        send_as: ?InputPeer,
        quick_reply_shortcut: ?InputQuickReplyShortcut,
        effect: ?i64,
    },
    MessagesForwardMessages: struct {
        flags: usize,
        silent: ?bool,
        background: ?bool,
        with_my_score: ?bool,
        drop_author: ?bool,
        drop_media_captions: ?bool,
        noforwards: ?bool,
        from_peer: InputPeer,
        id: []const i32,
        random_id: []const i64,
        to_peer: InputPeer,
        top_msg_id: ?i32,
        schedule_date: ?i32,
        send_as: ?InputPeer,
        quick_reply_shortcut: ?InputQuickReplyShortcut,
    },
    MessagesReportSpam: struct {
        peer: InputPeer,
    },
    MessagesGetPeerSettings: struct {
        peer: InputPeer,
    },
    MessagesReport: struct {
        peer: InputPeer,
        id: []const i32,
        option: []const u8,
        message: []const u8,
    },
    MessagesGetChats: struct {
        id: []const i64,
    },
    MessagesGetFullChat: struct {
        chat_id: i64,
    },
    MessagesEditChatTitle: struct {
        chat_id: i64,
        title: []const u8,
    },
    MessagesEditChatPhoto: struct {
        chat_id: i64,
        photo: InputChatPhoto,
    },
    MessagesAddChatUser: struct {
        chat_id: i64,
        user_id: InputUser,
        fwd_limit: i32,
    },
    MessagesDeleteChatUser: struct {
        flags: usize,
        revoke_history: ?bool,
        chat_id: i64,
        user_id: InputUser,
    },
    MessagesCreateChat: struct {
        flags: usize,
        users: []const InputUser,
        title: []const u8,
        ttl_period: ?i32,
    },
    MessagesGetDhConfig: struct {
        version: i32,
        random_length: i32,
    },
    MessagesRequestEncryption: struct {
        user_id: InputUser,
        random_id: i32,
        g_a: []const u8,
    },
    MessagesAcceptEncryption: struct {
        peer: InputEncryptedChat,
        g_b: []const u8,
        key_fingerprint: i64,
    },
    MessagesDiscardEncryption: struct {
        flags: usize,
        delete_history: ?bool,
        chat_id: i32,
    },
    MessagesSetEncryptedTyping: struct {
        peer: InputEncryptedChat,
        typing: bool,
    },
    MessagesReadEncryptedHistory: struct {
        peer: InputEncryptedChat,
        max_date: i32,
    },
    MessagesSendEncrypted: struct {
        flags: usize,
        silent: ?bool,
        peer: InputEncryptedChat,
        random_id: i64,
        data: []const u8,
    },
    MessagesSendEncryptedFile: struct {
        flags: usize,
        silent: ?bool,
        peer: InputEncryptedChat,
        random_id: i64,
        data: []const u8,
        file: InputEncryptedFile,
    },
    MessagesSendEncryptedService: struct {
        peer: InputEncryptedChat,
        random_id: i64,
        data: []const u8,
    },
    MessagesReceivedQueue: struct {
        max_qts: i32,
    },
    MessagesReportEncryptedSpam: struct {
        peer: InputEncryptedChat,
    },
    MessagesReadMessageContents: struct {
        id: []const i32,
    },
    MessagesGetStickers: struct {
        emoticon: []const u8,
        hash: i64,
    },
    MessagesGetAllStickers: struct {
        hash: i64,
    },
    MessagesGetWebPagePreview: struct {
        flags: usize,
        message: []const u8,
        entities: ?[]const MessageEntity,
    },
    MessagesExportChatInvite: struct {
        flags: usize,
        legacy_revoke_permanent: ?bool,
        request_needed: ?bool,
        peer: InputPeer,
        expire_date: ?i32,
        usage_limit: ?i32,
        title: ?[]const u8,
        subscription_pricing: ?StarsSubscriptionPricing,
    },
    MessagesCheckChatInvite: struct {
        hash: []const u8,
    },
    MessagesImportChatInvite: struct {
        hash: []const u8,
    },
    MessagesGetStickerSet: struct {
        stickerset: InputStickerSet,
        hash: i32,
    },
    MessagesInstallStickerSet: struct {
        stickerset: InputStickerSet,
        archived: bool,
    },
    MessagesUninstallStickerSet: struct {
        stickerset: InputStickerSet,
    },
    MessagesStartBot: struct {
        bot: InputUser,
        peer: InputPeer,
        random_id: i64,
        start_param: []const u8,
    },
    MessagesGetMessagesViews: struct {
        peer: InputPeer,
        id: []const i32,
        increment: bool,
    },
    MessagesEditChatAdmin: struct {
        chat_id: i64,
        user_id: InputUser,
        is_admin: bool,
    },
    MessagesMigrateChat: struct {
        chat_id: i64,
    },
    MessagesSearchGlobal: struct {
        flags: usize,
        broadcasts_only: ?bool,
        folder_id: ?i32,
        q: []const u8,
        filter: MessagesFilter,
        min_date: i32,
        max_date: i32,
        offset_rate: i32,
        offset_peer: InputPeer,
        offset_id: i32,
        limit: i32,
    },
    MessagesReorderStickerSets: struct {
        flags: usize,
        masks: ?bool,
        emojis: ?bool,
        order: []const i64,
    },
    MessagesGetDocumentByHash: struct {
        sha256: []const u8,
        size: i64,
        mime_type: []const u8,
    },
    MessagesGetSavedGifs: struct {
        hash: i64,
    },
    MessagesSaveGif: struct {
        id: InputDocument,
        unsave: bool,
    },
    MessagesGetInlineBotResults: struct {
        flags: usize,
        bot: InputUser,
        peer: InputPeer,
        geo_point: ?InputGeoPoint,
        query: []const u8,
        offset: []const u8,
    },
    MessagesSetInlineBotResults: struct {
        flags: usize,
        gallery: ?bool,
        private: ?bool,
        query_id: i64,
        results: []const InputBotInlineResult,
        cache_time: i32,
        next_offset: ?[]const u8,
        switch_pm: ?InlineBotSwitchPM,
        switch_webview: ?InlineBotWebView,
    },
    MessagesSendInlineBotResult: struct {
        flags: usize,
        silent: ?bool,
        background: ?bool,
        clear_draft: ?bool,
        hide_via: ?bool,
        peer: InputPeer,
        reply_to: ?InputReplyTo,
        random_id: i64,
        query_id: i64,
        id: []const u8,
        schedule_date: ?i32,
        send_as: ?InputPeer,
        quick_reply_shortcut: ?InputQuickReplyShortcut,
    },
    MessagesGetMessageEditData: struct {
        peer: InputPeer,
        id: i32,
    },
    MessagesEditMessage: struct {
        flags: usize,
        no_webpage: ?bool,
        invert_media: ?bool,
        peer: InputPeer,
        id: i32,
        message: ?[]const u8,
        media: ?InputMedia,
        reply_markup: ?ReplyMarkup,
        entities: ?[]const MessageEntity,
        schedule_date: ?i32,
        quick_reply_shortcut_id: ?i32,
    },
    MessagesEditInlineBotMessage: struct {
        flags: usize,
        no_webpage: ?bool,
        invert_media: ?bool,
        id: InputBotInlineMessageID,
        message: ?[]const u8,
        media: ?InputMedia,
        reply_markup: ?ReplyMarkup,
        entities: ?[]const MessageEntity,
    },
    MessagesGetBotCallbackAnswer: struct {
        flags: usize,
        game: ?bool,
        peer: InputPeer,
        msg_id: i32,
        data: ?[]const u8,
        password: ?InputCheckPasswordSRP,
    },
    MessagesSetBotCallbackAnswer: struct {
        flags: usize,
        alert: ?bool,
        query_id: i64,
        message: ?[]const u8,
        url: ?[]const u8,
        cache_time: i32,
    },
    MessagesGetPeerDialogs: struct {
        peers: []const InputDialogPeer,
    },
    MessagesSaveDraft: struct {
        flags: usize,
        no_webpage: ?bool,
        invert_media: ?bool,
        reply_to: ?InputReplyTo,
        peer: InputPeer,
        message: []const u8,
        entities: ?[]const MessageEntity,
        media: ?InputMedia,
        effect: ?i64,
    },
    MessagesGetAllDrafts: struct {
    },
    MessagesGetFeaturedStickers: struct {
        hash: i64,
    },
    MessagesReadFeaturedStickers: struct {
        id: []const i64,
    },
    MessagesGetRecentStickers: struct {
        flags: usize,
        attached: ?bool,
        hash: i64,
    },
    MessagesSaveRecentSticker: struct {
        flags: usize,
        attached: ?bool,
        id: InputDocument,
        unsave: bool,
    },
    MessagesClearRecentStickers: struct {
        flags: usize,
        attached: ?bool,
    },
    MessagesGetArchivedStickers: struct {
        flags: usize,
        masks: ?bool,
        emojis: ?bool,
        offset_id: i64,
        limit: i32,
    },
    MessagesGetMaskStickers: struct {
        hash: i64,
    },
    MessagesGetAttachedStickers: struct {
        media: InputStickeredMedia,
    },
    MessagesSetGameScore: struct {
        flags: usize,
        edit_message: ?bool,
        force: ?bool,
        peer: InputPeer,
        id: i32,
        user_id: InputUser,
        score: i32,
    },
    MessagesSetInlineGameScore: struct {
        flags: usize,
        edit_message: ?bool,
        force: ?bool,
        id: InputBotInlineMessageID,
        user_id: InputUser,
        score: i32,
    },
    MessagesGetGameHighScores: struct {
        peer: InputPeer,
        id: i32,
        user_id: InputUser,
    },
    MessagesGetInlineGameHighScores: struct {
        id: InputBotInlineMessageID,
        user_id: InputUser,
    },
    MessagesGetCommonChats: struct {
        user_id: InputUser,
        max_id: i64,
        limit: i32,
    },
    MessagesGetWebPage: struct {
        url: []const u8,
        hash: i32,
    },
    MessagesToggleDialogPin: struct {
        flags: usize,
        pinned: ?bool,
        peer: InputDialogPeer,
    },
    MessagesReorderPinnedDialogs: struct {
        flags: usize,
        force: ?bool,
        folder_id: i32,
        order: []const InputDialogPeer,
    },
    MessagesGetPinnedDialogs: struct {
        folder_id: i32,
    },
    MessagesSetBotShippingResults: struct {
        flags: usize,
        query_id: i64,
        Error: ?[]const u8,
        shipping_options: ?[]const ShippingOption,
    },
    MessagesSetBotPrecheckoutResults: struct {
        flags: usize,
        success: ?bool,
        query_id: i64,
        Error: ?[]const u8,
    },
    MessagesUploadMedia: struct {
        flags: usize,
        business_connection_id: ?[]const u8,
        peer: InputPeer,
        media: InputMedia,
    },
    MessagesSendScreenshotNotification: struct {
        peer: InputPeer,
        reply_to: InputReplyTo,
        random_id: i64,
    },
    MessagesGetFavedStickers: struct {
        hash: i64,
    },
    MessagesFaveSticker: struct {
        id: InputDocument,
        unfave: bool,
    },
    MessagesGetUnreadMentions: struct {
        flags: usize,
        peer: InputPeer,
        top_msg_id: ?i32,
        offset_id: i32,
        add_offset: i32,
        limit: i32,
        max_id: i32,
        min_id: i32,
    },
    MessagesReadMentions: struct {
        flags: usize,
        peer: InputPeer,
        top_msg_id: ?i32,
    },
    MessagesGetRecentLocations: struct {
        peer: InputPeer,
        limit: i32,
        hash: i64,
    },
    MessagesSendMultiMedia: struct {
        flags: usize,
        silent: ?bool,
        background: ?bool,
        clear_draft: ?bool,
        noforwards: ?bool,
        update_stickersets_order: ?bool,
        invert_media: ?bool,
        peer: InputPeer,
        reply_to: ?InputReplyTo,
        multi_media: []const InputSingleMedia,
        schedule_date: ?i32,
        send_as: ?InputPeer,
        quick_reply_shortcut: ?InputQuickReplyShortcut,
        effect: ?i64,
    },
    MessagesUploadEncryptedFile: struct {
        peer: InputEncryptedChat,
        file: InputEncryptedFile,
    },
    MessagesSearchStickerSets: struct {
        flags: usize,
        exclude_featured: ?bool,
        q: []const u8,
        hash: i64,
    },
    MessagesGetSplitRanges: struct {
    },
    MessagesMarkDialogUnread: struct {
        flags: usize,
        unread: ?bool,
        peer: InputDialogPeer,
    },
    MessagesGetDialogUnreadMarks: struct {
    },
    MessagesClearAllDrafts: struct {
    },
    MessagesUpdatePinnedMessage: struct {
        flags: usize,
        silent: ?bool,
        unpin: ?bool,
        pm_oneside: ?bool,
        peer: InputPeer,
        id: i32,
    },
    MessagesSendVote: struct {
        peer: InputPeer,
        msg_id: i32,
        options: []const []const u8,
    },
    MessagesGetPollResults: struct {
        peer: InputPeer,
        msg_id: i32,
    },
    MessagesGetOnlines: struct {
        peer: InputPeer,
    },
    MessagesEditChatAbout: struct {
        peer: InputPeer,
        about: []const u8,
    },
    MessagesEditChatDefaultBannedRights: struct {
        peer: InputPeer,
        banned_rights: ChatBannedRights,
    },
    MessagesGetEmojiKeywords: struct {
        lang_code: []const u8,
    },
    MessagesGetEmojiKeywordsDifference: struct {
        lang_code: []const u8,
        from_version: i32,
    },
    MessagesGetEmojiKeywordsLanguages: struct {
        lang_codes: []const []const u8,
    },
    MessagesGetEmojiURL: struct {
        lang_code: []const u8,
    },
    MessagesGetSearchCounters: struct {
        flags: usize,
        peer: InputPeer,
        saved_peer_id: ?InputPeer,
        top_msg_id: ?i32,
        filters: []const MessagesFilter,
    },
    MessagesRequestUrlAuth: struct {
        flags: usize,
        peer: ?InputPeer,
        msg_id: ?i32,
        button_id: ?i32,
        url: ?[]const u8,
    },
    MessagesAcceptUrlAuth: struct {
        flags: usize,
        write_allowed: ?bool,
        peer: ?InputPeer,
        msg_id: ?i32,
        button_id: ?i32,
        url: ?[]const u8,
    },
    MessagesHidePeerSettingsBar: struct {
        peer: InputPeer,
    },
    MessagesGetScheduledHistory: struct {
        peer: InputPeer,
        hash: i64,
    },
    MessagesGetScheduledMessages: struct {
        peer: InputPeer,
        id: []const i32,
    },
    MessagesSendScheduledMessages: struct {
        peer: InputPeer,
        id: []const i32,
    },
    MessagesDeleteScheduledMessages: struct {
        peer: InputPeer,
        id: []const i32,
    },
    MessagesGetPollVotes: struct {
        flags: usize,
        peer: InputPeer,
        id: i32,
        option: ?[]const u8,
        offset: ?[]const u8,
        limit: i32,
    },
    MessagesToggleStickerSets: struct {
        flags: usize,
        uninstall: ?bool,
        archive: ?bool,
        unarchive: ?bool,
        stickersets: []const InputStickerSet,
    },
    MessagesGetDialogFilters: struct {
    },
    MessagesGetSuggestedDialogFilters: struct {
    },
    MessagesUpdateDialogFilter: struct {
        flags: usize,
        id: i32,
        filter: ?DialogFilter,
    },
    MessagesUpdateDialogFiltersOrder: struct {
        order: []const i32,
    },
    MessagesGetOldFeaturedStickers: struct {
        offset: i32,
        limit: i32,
        hash: i64,
    },
    MessagesGetReplies: struct {
        peer: InputPeer,
        msg_id: i32,
        offset_id: i32,
        offset_date: i32,
        add_offset: i32,
        limit: i32,
        max_id: i32,
        min_id: i32,
        hash: i64,
    },
    MessagesGetDiscussionMessage: struct {
        peer: InputPeer,
        msg_id: i32,
    },
    MessagesReadDiscussion: struct {
        peer: InputPeer,
        msg_id: i32,
        read_max_id: i32,
    },
    MessagesUnpinAllMessages: struct {
        flags: usize,
        peer: InputPeer,
        top_msg_id: ?i32,
    },
    MessagesDeleteChat: struct {
        chat_id: i64,
    },
    MessagesDeletePhoneCallHistory: struct {
        flags: usize,
        revoke: ?bool,
    },
    MessagesCheckHistoryImport: struct {
        import_head: []const u8,
    },
    MessagesInitHistoryImport: struct {
        peer: InputPeer,
        file: InputFile,
        media_count: i32,
    },
    MessagesUploadImportedMedia: struct {
        peer: InputPeer,
        import_id: i64,
        file_name: []const u8,
        media: InputMedia,
    },
    MessagesStartHistoryImport: struct {
        peer: InputPeer,
        import_id: i64,
    },
    MessagesGetExportedChatInvites: struct {
        flags: usize,
        revoked: ?bool,
        peer: InputPeer,
        admin_id: InputUser,
        offset_date: ?i32,
        offset_link: ?[]const u8,
        limit: i32,
    },
    MessagesGetExportedChatInvite: struct {
        peer: InputPeer,
        link: []const u8,
    },
    MessagesEditExportedChatInvite: struct {
        flags: usize,
        revoked: ?bool,
        peer: InputPeer,
        link: []const u8,
        expire_date: ?i32,
        usage_limit: ?i32,
        request_needed: ?bool,
        title: ?[]const u8,
    },
    MessagesDeleteRevokedExportedChatInvites: struct {
        peer: InputPeer,
        admin_id: InputUser,
    },
    MessagesDeleteExportedChatInvite: struct {
        peer: InputPeer,
        link: []const u8,
    },
    MessagesGetAdminsWithInvites: struct {
        peer: InputPeer,
    },
    MessagesGetChatInviteImporters: struct {
        flags: usize,
        requested: ?bool,
        subscription_expired: ?bool,
        peer: InputPeer,
        link: ?[]const u8,
        q: ?[]const u8,
        offset_date: i32,
        offset_user: InputUser,
        limit: i32,
    },
    MessagesSetHistoryTTL: struct {
        peer: InputPeer,
        period: i32,
    },
    MessagesCheckHistoryImportPeer: struct {
        peer: InputPeer,
    },
    MessagesSetChatTheme: struct {
        peer: InputPeer,
        emoticon: []const u8,
    },
    MessagesGetMessageReadParticipants: struct {
        peer: InputPeer,
        msg_id: i32,
    },
    MessagesGetSearchResultsCalendar: struct {
        flags: usize,
        peer: InputPeer,
        saved_peer_id: ?InputPeer,
        filter: MessagesFilter,
        offset_id: i32,
        offset_date: i32,
    },
    MessagesGetSearchResultsPositions: struct {
        flags: usize,
        peer: InputPeer,
        saved_peer_id: ?InputPeer,
        filter: MessagesFilter,
        offset_id: i32,
        limit: i32,
    },
    MessagesHideChatJoinRequest: struct {
        flags: usize,
        approved: ?bool,
        peer: InputPeer,
        user_id: InputUser,
    },
    MessagesHideAllChatJoinRequests: struct {
        flags: usize,
        approved: ?bool,
        peer: InputPeer,
        link: ?[]const u8,
    },
    MessagesToggleNoForwards: struct {
        peer: InputPeer,
        enabled: bool,
    },
    MessagesSaveDefaultSendAs: struct {
        peer: InputPeer,
        send_as: InputPeer,
    },
    MessagesSendReaction: struct {
        flags: usize,
        big: ?bool,
        add_to_recent: ?bool,
        peer: InputPeer,
        msg_id: i32,
        reaction: ?[]const Reaction,
    },
    MessagesGetMessagesReactions: struct {
        peer: InputPeer,
        id: []const i32,
    },
    MessagesGetMessageReactionsList: struct {
        flags: usize,
        peer: InputPeer,
        id: i32,
        reaction: ?Reaction,
        offset: ?[]const u8,
        limit: i32,
    },
    MessagesSetChatAvailableReactions: struct {
        flags: usize,
        peer: InputPeer,
        available_reactions: ChatReactions,
        reactions_limit: ?i32,
        paid_enabled: ?bool,
    },
    MessagesGetAvailableReactions: struct {
        hash: i32,
    },
    MessagesSetDefaultReaction: struct {
        reaction: Reaction,
    },
    MessagesTranslateText: struct {
        flags: usize,
        peer: ?InputPeer,
        id: ?[]const i32,
        text: ?[]const TextWithEntities,
        to_lang: []const u8,
    },
    MessagesGetUnreadReactions: struct {
        flags: usize,
        peer: InputPeer,
        top_msg_id: ?i32,
        offset_id: i32,
        add_offset: i32,
        limit: i32,
        max_id: i32,
        min_id: i32,
    },
    MessagesReadReactions: struct {
        flags: usize,
        peer: InputPeer,
        top_msg_id: ?i32,
    },
    MessagesSearchSentMedia: struct {
        q: []const u8,
        filter: MessagesFilter,
        limit: i32,
    },
    MessagesGetAttachMenuBots: struct {
        hash: i64,
    },
    MessagesGetAttachMenuBot: struct {
        bot: InputUser,
    },
    MessagesToggleBotInAttachMenu: struct {
        flags: usize,
        write_allowed: ?bool,
        bot: InputUser,
        enabled: bool,
    },
    MessagesRequestWebView: struct {
        flags: usize,
        from_bot_menu: ?bool,
        silent: ?bool,
        compact: ?bool,
        peer: InputPeer,
        bot: InputUser,
        url: ?[]const u8,
        start_param: ?[]const u8,
        theme_params: ?DataJSON,
        platform: []const u8,
        reply_to: ?InputReplyTo,
        send_as: ?InputPeer,
    },
    MessagesProlongWebView: struct {
        flags: usize,
        silent: ?bool,
        peer: InputPeer,
        bot: InputUser,
        query_id: i64,
        reply_to: ?InputReplyTo,
        send_as: ?InputPeer,
    },
    MessagesRequestSimpleWebView: struct {
        flags: usize,
        from_switch_webview: ?bool,
        from_side_menu: ?bool,
        compact: ?bool,
        bot: InputUser,
        url: ?[]const u8,
        start_param: ?[]const u8,
        theme_params: ?DataJSON,
        platform: []const u8,
    },
    MessagesSendWebViewResultMessage: struct {
        bot_query_id: []const u8,
        result: InputBotInlineResult,
    },
    MessagesSendWebViewData: struct {
        bot: InputUser,
        random_id: i64,
        button_text: []const u8,
        data: []const u8,
    },
    MessagesTranscribeAudio: struct {
        peer: InputPeer,
        msg_id: i32,
    },
    MessagesRateTranscribedAudio: struct {
        peer: InputPeer,
        msg_id: i32,
        transcription_id: i64,
        good: bool,
    },
    MessagesGetCustomEmojiDocuments: struct {
        document_id: []const i64,
    },
    MessagesGetEmojiStickers: struct {
        hash: i64,
    },
    MessagesGetFeaturedEmojiStickers: struct {
        hash: i64,
    },
    MessagesReportReaction: struct {
        peer: InputPeer,
        id: i32,
        reaction_peer: InputPeer,
    },
    MessagesGetTopReactions: struct {
        limit: i32,
        hash: i64,
    },
    MessagesGetRecentReactions: struct {
        limit: i32,
        hash: i64,
    },
    MessagesClearRecentReactions: struct {
    },
    MessagesGetExtendedMedia: struct {
        peer: InputPeer,
        id: []const i32,
    },
    MessagesSetDefaultHistoryTTL: struct {
        period: i32,
    },
    MessagesGetDefaultHistoryTTL: struct {
    },
    MessagesSendBotRequestedPeer: struct {
        peer: InputPeer,
        msg_id: i32,
        button_id: i32,
        requested_peers: []const InputPeer,
    },
    MessagesGetEmojiGroups: struct {
        hash: i32,
    },
    MessagesGetEmojiStatusGroups: struct {
        hash: i32,
    },
    MessagesGetEmojiProfilePhotoGroups: struct {
        hash: i32,
    },
    MessagesSearchCustomEmoji: struct {
        emoticon: []const u8,
        hash: i64,
    },
    MessagesTogglePeerTranslations: struct {
        flags: usize,
        disabled: ?bool,
        peer: InputPeer,
    },
    MessagesGetBotApp: struct {
        app: InputBotApp,
        hash: i64,
    },
    MessagesRequestAppWebView: struct {
        flags: usize,
        write_allowed: ?bool,
        compact: ?bool,
        peer: InputPeer,
        app: InputBotApp,
        start_param: ?[]const u8,
        theme_params: ?DataJSON,
        platform: []const u8,
    },
    MessagesSetChatWallPaper: struct {
        flags: usize,
        for_both: ?bool,
        revert: ?bool,
        peer: InputPeer,
        wallpaper: ?InputWallPaper,
        settings: ?WallPaperSettings,
        id: ?i32,
    },
    MessagesSearchEmojiStickerSets: struct {
        flags: usize,
        exclude_featured: ?bool,
        q: []const u8,
        hash: i64,
    },
    MessagesGetSavedDialogs: struct {
        flags: usize,
        exclude_pinned: ?bool,
        offset_date: i32,
        offset_id: i32,
        offset_peer: InputPeer,
        limit: i32,
        hash: i64,
    },
    MessagesGetSavedHistory: struct {
        peer: InputPeer,
        offset_id: i32,
        offset_date: i32,
        add_offset: i32,
        limit: i32,
        max_id: i32,
        min_id: i32,
        hash: i64,
    },
    MessagesDeleteSavedHistory: struct {
        flags: usize,
        peer: InputPeer,
        max_id: i32,
        min_date: ?i32,
        max_date: ?i32,
    },
    MessagesGetPinnedSavedDialogs: struct {
    },
    MessagesToggleSavedDialogPin: struct {
        flags: usize,
        pinned: ?bool,
        peer: InputDialogPeer,
    },
    MessagesReorderPinnedSavedDialogs: struct {
        flags: usize,
        force: ?bool,
        order: []const InputDialogPeer,
    },
    MessagesGetSavedReactionTags: struct {
        flags: usize,
        peer: ?InputPeer,
        hash: i64,
    },
    MessagesUpdateSavedReactionTag: struct {
        flags: usize,
        reaction: Reaction,
        title: ?[]const u8,
    },
    MessagesGetDefaultTagReactions: struct {
        hash: i64,
    },
    MessagesGetOutboxReadDate: struct {
        peer: InputPeer,
        msg_id: i32,
    },
    MessagesGetQuickReplies: struct {
        hash: i64,
    },
    MessagesReorderQuickReplies: struct {
        order: []const i32,
    },
    MessagesCheckQuickReplyShortcut: struct {
        shortcut: []const u8,
    },
    MessagesEditQuickReplyShortcut: struct {
        shortcut_id: i32,
        shortcut: []const u8,
    },
    MessagesDeleteQuickReplyShortcut: struct {
        shortcut_id: i32,
    },
    MessagesGetQuickReplyMessages: struct {
        flags: usize,
        shortcut_id: i32,
        id: ?[]const i32,
        hash: i64,
    },
    MessagesSendQuickReplyMessages: struct {
        peer: InputPeer,
        shortcut_id: i32,
        id: []const i32,
        random_id: []const i64,
    },
    MessagesDeleteQuickReplyMessages: struct {
        shortcut_id: i32,
        id: []const i32,
    },
    MessagesToggleDialogFilterTags: struct {
        enabled: bool,
    },
    MessagesGetMyStickers: struct {
        offset_id: i64,
        limit: i32,
    },
    MessagesGetEmojiStickerGroups: struct {
        hash: i32,
    },
    MessagesGetAvailableEffects: struct {
        hash: i32,
    },
    MessagesEditFactCheck: struct {
        peer: InputPeer,
        msg_id: i32,
        text: TextWithEntities,
    },
    MessagesDeleteFactCheck: struct {
        peer: InputPeer,
        msg_id: i32,
    },
    MessagesGetFactCheck: struct {
        peer: InputPeer,
        msg_id: []const i32,
    },
    MessagesRequestMainWebView: struct {
        flags: usize,
        compact: ?bool,
        peer: InputPeer,
        bot: InputUser,
        start_param: ?[]const u8,
        theme_params: ?DataJSON,
        platform: []const u8,
    },
    MessagesSendPaidReaction: struct {
        flags: usize,
        peer: InputPeer,
        msg_id: i32,
        count: i32,
        random_id: i64,
        private: ?bool,
    },
    MessagesTogglePaidReactionPrivacy: struct {
        peer: InputPeer,
        msg_id: i32,
        private: bool,
    },
    MessagesGetPaidReactionPrivacy: struct {
    },
    UpdatesGetState: struct {
    },
    UpdatesGetDifference: struct {
        flags: usize,
        pts: i32,
        pts_limit: ?i32,
        pts_total_limit: ?i32,
        date: i32,
        qts: i32,
        qts_limit: ?i32,
    },
    UpdatesGetChannelDifference: struct {
        flags: usize,
        force: ?bool,
        channel: InputChannel,
        filter: ChannelMessagesFilter,
        pts: i32,
        limit: i32,
    },
    PhotosUpdateProfilePhoto: struct {
        flags: usize,
        fallback: ?bool,
        bot: ?InputUser,
        id: InputPhoto,
    },
    PhotosUploadProfilePhoto: struct {
        flags: usize,
        fallback: ?bool,
        bot: ?InputUser,
        file: ?InputFile,
        video: ?InputFile,
        video_start_ts: ?f64,
        video_emoji_markup: ?VideoSize,
    },
    PhotosDeletePhotos: struct {
        id: []const InputPhoto,
    },
    PhotosGetUserPhotos: struct {
        user_id: InputUser,
        offset: i32,
        max_id: i64,
        limit: i32,
    },
    PhotosUploadContactProfilePhoto: struct {
        flags: usize,
        suggest: ?bool,
        save: ?bool,
        user_id: InputUser,
        file: ?InputFile,
        video: ?InputFile,
        video_start_ts: ?f64,
        video_emoji_markup: ?VideoSize,
    },
    UploadSaveFilePart: struct {
        file_id: i64,
        file_part: i32,
        bytes: []const u8,
    },
    UploadGetFile: struct {
        flags: usize,
        precise: ?bool,
        cdn_supported: ?bool,
        location: InputFileLocation,
        offset: i64,
        limit: i32,
    },
    UploadSaveBigFilePart: struct {
        file_id: i64,
        file_part: i32,
        file_total_parts: i32,
        bytes: []const u8,
    },
    UploadGetWebFile: struct {
        location: InputWebFileLocation,
        offset: i32,
        limit: i32,
    },
    UploadGetCdnFile: struct {
        file_token: []const u8,
        offset: i64,
        limit: i32,
    },
    UploadReuploadCdnFile: struct {
        file_token: []const u8,
        request_token: []const u8,
    },
    UploadGetCdnFileHashes: struct {
        file_token: []const u8,
        offset: i64,
    },
    UploadGetFileHashes: struct {
        location: InputFileLocation,
        offset: i64,
    },
    HelpGetConfig: struct {
    },
    HelpGetNearestDc: struct {
    },
    HelpGetAppUpdate: struct {
        source: []const u8,
    },
    HelpGetInviteText: struct {
    },
    HelpGetSupport: struct {
    },
    HelpSetBotUpdatesStatus: struct {
        pending_updates_count: i32,
        message: []const u8,
    },
    HelpGetCdnConfig: struct {
    },
    HelpGetRecentMeUrls: struct {
        referer: []const u8,
    },
    HelpGetTermsOfServiceUpdate: struct {
    },
    HelpAcceptTermsOfService: struct {
        id: DataJSON,
    },
    HelpGetDeepLinkInfo: struct {
        path: []const u8,
    },
    HelpGetAppConfig: struct {
        hash: i32,
    },
    HelpSaveAppLog: struct {
        events: []const InputAppEvent,
    },
    HelpGetPassportConfig: struct {
        hash: i32,
    },
    HelpGetSupportName: struct {
    },
    HelpGetUserInfo: struct {
        user_id: InputUser,
    },
    HelpEditUserInfo: struct {
        user_id: InputUser,
        message: []const u8,
        entities: []const MessageEntity,
    },
    HelpGetPromoData: struct {
    },
    HelpHidePromoData: struct {
        peer: InputPeer,
    },
    HelpDismissSuggestion: struct {
        peer: InputPeer,
        suggestion: []const u8,
    },
    HelpGetCountriesList: struct {
        lang_code: []const u8,
        hash: i32,
    },
    HelpGetPremiumPromo: struct {
    },
    HelpGetPeerColors: struct {
        hash: i32,
    },
    HelpGetPeerProfileColors: struct {
        hash: i32,
    },
    HelpGetTimezonesList: struct {
        hash: i32,
    },
    ChannelsReadHistory: struct {
        channel: InputChannel,
        max_id: i32,
    },
    ChannelsDeleteMessages: struct {
        channel: InputChannel,
        id: []const i32,
    },
    ChannelsReportSpam: struct {
        channel: InputChannel,
        participant: InputPeer,
        id: []const i32,
    },
    ChannelsGetMessages: struct {
        channel: InputChannel,
        id: []const InputMessage,
    },
    ChannelsGetParticipants: struct {
        channel: InputChannel,
        filter: ChannelParticipantsFilter,
        offset: i32,
        limit: i32,
        hash: i64,
    },
    ChannelsGetParticipant: struct {
        channel: InputChannel,
        participant: InputPeer,
    },
    ChannelsGetChannels: struct {
        id: []const InputChannel,
    },
    ChannelsGetFullChannel: struct {
        channel: InputChannel,
    },
    ChannelsCreateChannel: struct {
        flags: usize,
        broadcast: ?bool,
        megagroup: ?bool,
        for_import: ?bool,
        forum: ?bool,
        title: []const u8,
        about: []const u8,
        geo_point: ?InputGeoPoint,
        address: ?[]const u8,
        ttl_period: ?i32,
    },
    ChannelsEditAdmin: struct {
        channel: InputChannel,
        user_id: InputUser,
        admin_rights: ChatAdminRights,
        rank: []const u8,
    },
    ChannelsEditTitle: struct {
        channel: InputChannel,
        title: []const u8,
    },
    ChannelsEditPhoto: struct {
        channel: InputChannel,
        photo: InputChatPhoto,
    },
    ChannelsCheckUsername: struct {
        channel: InputChannel,
        username: []const u8,
    },
    ChannelsUpdateUsername: struct {
        channel: InputChannel,
        username: []const u8,
    },
    ChannelsJoinChannel: struct {
        channel: InputChannel,
    },
    ChannelsLeaveChannel: struct {
        channel: InputChannel,
    },
    ChannelsInviteToChannel: struct {
        channel: InputChannel,
        users: []const InputUser,
    },
    ChannelsDeleteChannel: struct {
        channel: InputChannel,
    },
    ChannelsExportMessageLink: struct {
        flags: usize,
        grouped: ?bool,
        thread: ?bool,
        channel: InputChannel,
        id: i32,
    },
    ChannelsToggleSignatures: struct {
        flags: usize,
        signatures_enabled: ?bool,
        profiles_enabled: ?bool,
        channel: InputChannel,
    },
    ChannelsGetAdminedPublicChannels: struct {
        flags: usize,
        by_location: ?bool,
        check_limit: ?bool,
        for_personal: ?bool,
    },
    ChannelsEditBanned: struct {
        channel: InputChannel,
        participant: InputPeer,
        banned_rights: ChatBannedRights,
    },
    ChannelsGetAdminLog: struct {
        flags: usize,
        channel: InputChannel,
        q: []const u8,
        events_filter: ?ChannelAdminLogEventsFilter,
        admins: ?[]const InputUser,
        max_id: i64,
        min_id: i64,
        limit: i32,
    },
    ChannelsSetStickers: struct {
        channel: InputChannel,
        stickerset: InputStickerSet,
    },
    ChannelsReadMessageContents: struct {
        channel: InputChannel,
        id: []const i32,
    },
    ChannelsDeleteHistory: struct {
        flags: usize,
        for_everyone: ?bool,
        channel: InputChannel,
        max_id: i32,
    },
    ChannelsTogglePreHistoryHidden: struct {
        channel: InputChannel,
        enabled: bool,
    },
    ChannelsGetLeftChannels: struct {
        offset: i32,
    },
    ChannelsGetGroupsForDiscussion: struct {
    },
    ChannelsSetDiscussionGroup: struct {
        broadcast: InputChannel,
        group: InputChannel,
    },
    ChannelsEditCreator: struct {
        channel: InputChannel,
        user_id: InputUser,
        password: InputCheckPasswordSRP,
    },
    ChannelsEditLocation: struct {
        channel: InputChannel,
        geo_point: InputGeoPoint,
        address: []const u8,
    },
    ChannelsToggleSlowMode: struct {
        channel: InputChannel,
        seconds: i32,
    },
    ChannelsGetInactiveChannels: struct {
    },
    ChannelsConvertToGigagroup: struct {
        channel: InputChannel,
    },
    ChannelsViewSponsoredMessage: struct {
        channel: InputChannel,
        random_id: []const u8,
    },
    ChannelsGetSponsoredMessages: struct {
        channel: InputChannel,
    },
    ChannelsGetSendAs: struct {
        peer: InputPeer,
    },
    ChannelsDeleteParticipantHistory: struct {
        channel: InputChannel,
        participant: InputPeer,
    },
    ChannelsToggleJoinToSend: struct {
        channel: InputChannel,
        enabled: bool,
    },
    ChannelsToggleJoinRequest: struct {
        channel: InputChannel,
        enabled: bool,
    },
    ChannelsReorderUsernames: struct {
        channel: InputChannel,
        order: []const []const u8,
    },
    ChannelsToggleUsername: struct {
        channel: InputChannel,
        username: []const u8,
        active: bool,
    },
    ChannelsDeactivateAllUsernames: struct {
        channel: InputChannel,
    },
    ChannelsToggleForum: struct {
        channel: InputChannel,
        enabled: bool,
    },
    ChannelsCreateForumTopic: struct {
        flags: usize,
        channel: InputChannel,
        title: []const u8,
        icon_color: ?i32,
        icon_emoji_id: ?i64,
        random_id: i64,
        send_as: ?InputPeer,
    },
    ChannelsGetForumTopics: struct {
        flags: usize,
        channel: InputChannel,
        q: ?[]const u8,
        offset_date: i32,
        offset_id: i32,
        offset_topic: i32,
        limit: i32,
    },
    ChannelsGetForumTopicsByID: struct {
        channel: InputChannel,
        topics: []const i32,
    },
    ChannelsEditForumTopic: struct {
        flags: usize,
        channel: InputChannel,
        topic_id: i32,
        title: ?[]const u8,
        icon_emoji_id: ?i64,
        closed: ?bool,
        hidden: ?bool,
    },
    ChannelsUpdatePinnedForumTopic: struct {
        channel: InputChannel,
        topic_id: i32,
        pinned: bool,
    },
    ChannelsDeleteTopicHistory: struct {
        channel: InputChannel,
        top_msg_id: i32,
    },
    ChannelsReorderPinnedForumTopics: struct {
        flags: usize,
        force: ?bool,
        channel: InputChannel,
        order: []const i32,
    },
    ChannelsToggleAntiSpam: struct {
        channel: InputChannel,
        enabled: bool,
    },
    ChannelsReportAntiSpamFalsePositive: struct {
        channel: InputChannel,
        msg_id: i32,
    },
    ChannelsToggleParticipantsHidden: struct {
        channel: InputChannel,
        enabled: bool,
    },
    ChannelsClickSponsoredMessage: struct {
        flags: usize,
        media: ?bool,
        fullscreen: ?bool,
        channel: InputChannel,
        random_id: []const u8,
    },
    ChannelsUpdateColor: struct {
        flags: usize,
        for_profile: ?bool,
        channel: InputChannel,
        color: ?i32,
        background_emoji_id: ?i64,
    },
    ChannelsToggleViewForumAsMessages: struct {
        channel: InputChannel,
        enabled: bool,
    },
    ChannelsGetChannelRecommendations: struct {
        flags: usize,
        channel: ?InputChannel,
    },
    ChannelsUpdateEmojiStatus: struct {
        channel: InputChannel,
        emoji_status: EmojiStatus,
    },
    ChannelsSetBoostsToUnblockRestrictions: struct {
        channel: InputChannel,
        boosts: i32,
    },
    ChannelsSetEmojiStickers: struct {
        channel: InputChannel,
        stickerset: InputStickerSet,
    },
    ChannelsReportSponsoredMessage: struct {
        channel: InputChannel,
        random_id: []const u8,
        option: []const u8,
    },
    ChannelsRestrictSponsoredMessages: struct {
        channel: InputChannel,
        restricted: bool,
    },
    ChannelsSearchPosts: struct {
        hashtag: []const u8,
        offset_rate: i32,
        offset_peer: InputPeer,
        offset_id: i32,
        limit: i32,
    },
    BotsSendCustomRequest: struct {
        custom_method: []const u8,
        params: DataJSON,
    },
    BotsAnswerWebhookJSONQuery: struct {
        query_id: i64,
        data: DataJSON,
    },
    BotsSetBotCommands: struct {
        scope: BotCommandScope,
        lang_code: []const u8,
        commands: []const BotCommand,
    },
    BotsResetBotCommands: struct {
        scope: BotCommandScope,
        lang_code: []const u8,
    },
    BotsGetBotCommands: struct {
        scope: BotCommandScope,
        lang_code: []const u8,
    },
    BotsSetBotMenuButton: struct {
        user_id: InputUser,
        button: BotMenuButton,
    },
    BotsGetBotMenuButton: struct {
        user_id: InputUser,
    },
    BotsSetBotBroadcastDefaultAdminRights: struct {
        admin_rights: ChatAdminRights,
    },
    BotsSetBotGroupDefaultAdminRights: struct {
        admin_rights: ChatAdminRights,
    },
    BotsSetBotInfo: struct {
        flags: usize,
        bot: ?InputUser,
        lang_code: []const u8,
        name: ?[]const u8,
        about: ?[]const u8,
        description: ?[]const u8,
    },
    BotsGetBotInfo: struct {
        flags: usize,
        bot: ?InputUser,
        lang_code: []const u8,
    },
    BotsReorderUsernames: struct {
        bot: InputUser,
        order: []const []const u8,
    },
    BotsToggleUsername: struct {
        bot: InputUser,
        username: []const u8,
        active: bool,
    },
    BotsCanSendMessage: struct {
        bot: InputUser,
    },
    BotsAllowSendMessage: struct {
        bot: InputUser,
    },
    BotsInvokeWebViewCustomMethod: struct {
        bot: InputUser,
        custom_method: []const u8,
        params: DataJSON,
    },
    BotsGetPopularAppBots: struct {
        offset: []const u8,
        limit: i32,
    },
    BotsAddPreviewMedia: struct {
        bot: InputUser,
        lang_code: []const u8,
        media: InputMedia,
    },
    BotsEditPreviewMedia: struct {
        bot: InputUser,
        lang_code: []const u8,
        media: InputMedia,
        new_media: InputMedia,
    },
    BotsDeletePreviewMedia: struct {
        bot: InputUser,
        lang_code: []const u8,
        media: []const InputMedia,
    },
    BotsReorderPreviewMedias: struct {
        bot: InputUser,
        lang_code: []const u8,
        order: []const InputMedia,
    },
    BotsGetPreviewInfo: struct {
        bot: InputUser,
        lang_code: []const u8,
    },
    BotsGetPreviewMedias: struct {
        bot: InputUser,
    },
    PaymentsGetPaymentForm: struct {
        flags: usize,
        invoice: InputInvoice,
        theme_params: ?DataJSON,
    },
    PaymentsGetPaymentReceipt: struct {
        peer: InputPeer,
        msg_id: i32,
    },
    PaymentsValidateRequestedInfo: struct {
        flags: usize,
        save: ?bool,
        invoice: InputInvoice,
        info: PaymentRequestedInfo,
    },
    PaymentsSendPaymentForm: struct {
        flags: usize,
        form_id: i64,
        invoice: InputInvoice,
        requested_info_id: ?[]const u8,
        shipping_option_id: ?[]const u8,
        credentials: InputPaymentCredentials,
        tip_amount: ?i64,
    },
    PaymentsGetSavedInfo: struct {
    },
    PaymentsClearSavedInfo: struct {
        flags: usize,
        credentials: ?bool,
        info: ?bool,
    },
    PaymentsGetBankCardData: struct {
        number: []const u8,
    },
    PaymentsExportInvoice: struct {
        invoice_media: InputMedia,
    },
    PaymentsAssignAppStoreTransaction: struct {
        receipt: []const u8,
        purpose: InputStorePaymentPurpose,
    },
    PaymentsAssignPlayMarketTransaction: struct {
        receipt: DataJSON,
        purpose: InputStorePaymentPurpose,
    },
    PaymentsCanPurchasePremium: struct {
        purpose: InputStorePaymentPurpose,
    },
    PaymentsGetPremiumGiftCodeOptions: struct {
        flags: usize,
        boost_peer: ?InputPeer,
    },
    PaymentsCheckGiftCode: struct {
        slug: []const u8,
    },
    PaymentsApplyGiftCode: struct {
        slug: []const u8,
    },
    PaymentsGetGiveawayInfo: struct {
        peer: InputPeer,
        msg_id: i32,
    },
    PaymentsLaunchPrepaidGiveaway: struct {
        peer: InputPeer,
        giveaway_id: i64,
        purpose: InputStorePaymentPurpose,
    },
    PaymentsGetStarsTopupOptions: struct {
    },
    PaymentsGetStarsStatus: struct {
        peer: InputPeer,
    },
    PaymentsGetStarsTransactions: struct {
        flags: usize,
        inbound: ?bool,
        outbound: ?bool,
        ascending: ?bool,
        subscription_id: ?[]const u8,
        peer: InputPeer,
        offset: []const u8,
        limit: i32,
    },
    PaymentsSendStarsForm: struct {
        form_id: i64,
        invoice: InputInvoice,
    },
    PaymentsRefundStarsCharge: struct {
        user_id: InputUser,
        charge_id: []const u8,
    },
    PaymentsGetStarsRevenueStats: struct {
        flags: usize,
        dark: ?bool,
        peer: InputPeer,
    },
    PaymentsGetStarsRevenueWithdrawalUrl: struct {
        peer: InputPeer,
        stars: i64,
        password: InputCheckPasswordSRP,
    },
    PaymentsGetStarsRevenueAdsAccountUrl: struct {
        peer: InputPeer,
    },
    PaymentsGetStarsTransactionsByID: struct {
        peer: InputPeer,
        id: []const InputStarsTransaction,
    },
    PaymentsGetStarsGiftOptions: struct {
        flags: usize,
        user_id: ?InputUser,
    },
    PaymentsGetStarsSubscriptions: struct {
        flags: usize,
        missing_balance: ?bool,
        peer: InputPeer,
        offset: []const u8,
    },
    PaymentsChangeStarsSubscription: struct {
        flags: usize,
        peer: InputPeer,
        subscription_id: []const u8,
        canceled: ?bool,
    },
    PaymentsFulfillStarsSubscription: struct {
        peer: InputPeer,
        subscription_id: []const u8,
    },
    PaymentsGetStarsGiveawayOptions: struct {
    },
    PaymentsGetStarGifts: struct {
        hash: i32,
    },
    PaymentsGetUserStarGifts: struct {
        user_id: InputUser,
        offset: []const u8,
        limit: i32,
    },
    PaymentsSaveStarGift: struct {
        flags: usize,
        unsave: ?bool,
        user_id: InputUser,
        msg_id: i32,
    },
    PaymentsConvertStarGift: struct {
        user_id: InputUser,
        msg_id: i32,
    },
    StickersCreateStickerSet: struct {
        flags: usize,
        masks: ?bool,
        emojis: ?bool,
        text_color: ?bool,
        user_id: InputUser,
        title: []const u8,
        short_name: []const u8,
        thumb: ?InputDocument,
        stickers: []const InputStickerSetItem,
        software: ?[]const u8,
    },
    StickersRemoveStickerFromSet: struct {
        sticker: InputDocument,
    },
    StickersChangeStickerPosition: struct {
        sticker: InputDocument,
        position: i32,
    },
    StickersAddStickerToSet: struct {
        stickerset: InputStickerSet,
        sticker: InputStickerSetItem,
    },
    StickersSetStickerSetThumb: struct {
        flags: usize,
        stickerset: InputStickerSet,
        thumb: ?InputDocument,
        thumb_document_id: ?i64,
    },
    StickersCheckShortName: struct {
        short_name: []const u8,
    },
    StickersSuggestShortName: struct {
        title: []const u8,
    },
    StickersChangeSticker: struct {
        flags: usize,
        sticker: InputDocument,
        emoji: ?[]const u8,
        mask_coords: ?MaskCoords,
        keywords: ?[]const u8,
    },
    StickersRenameStickerSet: struct {
        stickerset: InputStickerSet,
        title: []const u8,
    },
    StickersDeleteStickerSet: struct {
        stickerset: InputStickerSet,
    },
    StickersReplaceSticker: struct {
        sticker: InputDocument,
        new_sticker: InputStickerSetItem,
    },
    PhoneGetCallConfig: struct {
    },
    PhoneRequestCall: struct {
        flags: usize,
        video: ?bool,
        user_id: InputUser,
        random_id: i32,
        g_a_hash: []const u8,
        protocol: PhoneCallProtocol,
    },
    PhoneAcceptCall: struct {
        peer: InputPhoneCall,
        g_b: []const u8,
        protocol: PhoneCallProtocol,
    },
    PhoneConfirmCall: struct {
        peer: InputPhoneCall,
        g_a: []const u8,
        key_fingerprint: i64,
        protocol: PhoneCallProtocol,
    },
    PhoneReceivedCall: struct {
        peer: InputPhoneCall,
    },
    PhoneDiscardCall: struct {
        flags: usize,
        video: ?bool,
        peer: InputPhoneCall,
        duration: i32,
        reason: PhoneCallDiscardReason,
        connection_id: i64,
    },
    PhoneSetCallRating: struct {
        flags: usize,
        user_initiative: ?bool,
        peer: InputPhoneCall,
        rating: i32,
        comment: []const u8,
    },
    PhoneSaveCallDebug: struct {
        peer: InputPhoneCall,
        debug: DataJSON,
    },
    PhoneSendSignalingData: struct {
        peer: InputPhoneCall,
        data: []const u8,
    },
    PhoneCreateGroupCall: struct {
        flags: usize,
        rtmp_stream: ?bool,
        peer: InputPeer,
        random_id: i32,
        title: ?[]const u8,
        schedule_date: ?i32,
    },
    PhoneJoinGroupCall: struct {
        flags: usize,
        muted: ?bool,
        video_stopped: ?bool,
        call: InputGroupCall,
        join_as: InputPeer,
        invite_hash: ?[]const u8,
        params: DataJSON,
    },
    PhoneLeaveGroupCall: struct {
        call: InputGroupCall,
        source: i32,
    },
    PhoneInviteToGroupCall: struct {
        call: InputGroupCall,
        users: []const InputUser,
    },
    PhoneDiscardGroupCall: struct {
        call: InputGroupCall,
    },
    PhoneToggleGroupCallSettings: struct {
        flags: usize,
        reset_invite_hash: ?bool,
        call: InputGroupCall,
        join_muted: ?bool,
    },
    PhoneGetGroupCall: struct {
        call: InputGroupCall,
        limit: i32,
    },
    PhoneGetGroupParticipants: struct {
        call: InputGroupCall,
        ids: []const InputPeer,
        sources: []const i32,
        offset: []const u8,
        limit: i32,
    },
    PhoneCheckGroupCall: struct {
        call: InputGroupCall,
        sources: []const i32,
    },
    PhoneToggleGroupCallRecord: struct {
        flags: usize,
        start: ?bool,
        video: ?bool,
        call: InputGroupCall,
        title: ?[]const u8,
        video_portrait: ?bool,
    },
    PhoneEditGroupCallParticipant: struct {
        flags: usize,
        call: InputGroupCall,
        participant: InputPeer,
        muted: ?bool,
        volume: ?i32,
        raise_hand: ?bool,
        video_stopped: ?bool,
        video_paused: ?bool,
        presentation_paused: ?bool,
    },
    PhoneEditGroupCallTitle: struct {
        call: InputGroupCall,
        title: []const u8,
    },
    PhoneGetGroupCallJoinAs: struct {
        peer: InputPeer,
    },
    PhoneExportGroupCallInvite: struct {
        flags: usize,
        can_self_unmute: ?bool,
        call: InputGroupCall,
    },
    PhoneToggleGroupCallStartSubscription: struct {
        call: InputGroupCall,
        subscribed: bool,
    },
    PhoneStartScheduledGroupCall: struct {
        call: InputGroupCall,
    },
    PhoneSaveDefaultGroupCallJoinAs: struct {
        peer: InputPeer,
        join_as: InputPeer,
    },
    PhoneJoinGroupCallPresentation: struct {
        call: InputGroupCall,
        params: DataJSON,
    },
    PhoneLeaveGroupCallPresentation: struct {
        call: InputGroupCall,
    },
    PhoneGetGroupCallStreamChannels: struct {
        call: InputGroupCall,
    },
    PhoneGetGroupCallStreamRtmpUrl: struct {
        peer: InputPeer,
        revoke: bool,
    },
    PhoneSaveCallLog: struct {
        peer: InputPhoneCall,
        file: InputFile,
    },
    LangpackGetLangPack: struct {
        lang_pack: []const u8,
        lang_code: []const u8,
    },
    LangpackGetStrings: struct {
        lang_pack: []const u8,
        lang_code: []const u8,
        keys: []const []const u8,
    },
    LangpackGetDifference: struct {
        lang_pack: []const u8,
        lang_code: []const u8,
        from_version: i32,
    },
    LangpackGetLanguages: struct {
        lang_pack: []const u8,
    },
    LangpackGetLanguage: struct {
        lang_pack: []const u8,
        lang_code: []const u8,
    },
    FoldersEditPeerFolders: struct {
        folder_peers: []const InputFolderPeer,
    },
    StatsGetBroadcastStats: struct {
        flags: usize,
        dark: ?bool,
        channel: InputChannel,
    },
    StatsLoadAsyncGraph: struct {
        flags: usize,
        token: []const u8,
        x: ?i64,
    },
    StatsGetMegagroupStats: struct {
        flags: usize,
        dark: ?bool,
        channel: InputChannel,
    },
    StatsGetMessagePublicForwards: struct {
        channel: InputChannel,
        msg_id: i32,
        offset: []const u8,
        limit: i32,
    },
    StatsGetMessageStats: struct {
        flags: usize,
        dark: ?bool,
        channel: InputChannel,
        msg_id: i32,
    },
    StatsGetStoryStats: struct {
        flags: usize,
        dark: ?bool,
        peer: InputPeer,
        id: i32,
    },
    StatsGetStoryPublicForwards: struct {
        peer: InputPeer,
        id: i32,
        offset: []const u8,
        limit: i32,
    },
    StatsGetBroadcastRevenueStats: struct {
        flags: usize,
        dark: ?bool,
        channel: InputChannel,
    },
    StatsGetBroadcastRevenueWithdrawalUrl: struct {
        channel: InputChannel,
        password: InputCheckPasswordSRP,
    },
    StatsGetBroadcastRevenueTransactions: struct {
        channel: InputChannel,
        offset: i32,
        limit: i32,
    },
    ChatlistsExportChatlistInvite: struct {
        chatlist: InputChatlist,
        title: []const u8,
        peers: []const InputPeer,
    },
    ChatlistsDeleteExportedInvite: struct {
        chatlist: InputChatlist,
        slug: []const u8,
    },
    ChatlistsEditExportedInvite: struct {
        flags: usize,
        chatlist: InputChatlist,
        slug: []const u8,
        title: ?[]const u8,
        peers: ?[]const InputPeer,
    },
    ChatlistsGetExportedInvites: struct {
        chatlist: InputChatlist,
    },
    ChatlistsCheckChatlistInvite: struct {
        slug: []const u8,
    },
    ChatlistsJoinChatlistInvite: struct {
        slug: []const u8,
        peers: []const InputPeer,
    },
    ChatlistsGetChatlistUpdates: struct {
        chatlist: InputChatlist,
    },
    ChatlistsJoinChatlistUpdates: struct {
        chatlist: InputChatlist,
        peers: []const InputPeer,
    },
    ChatlistsHideChatlistUpdates: struct {
        chatlist: InputChatlist,
    },
    ChatlistsGetLeaveChatlistSuggestions: struct {
        chatlist: InputChatlist,
    },
    ChatlistsLeaveChatlist: struct {
        chatlist: InputChatlist,
        peers: []const InputPeer,
    },
    StoriesCanSendStory: struct {
        peer: InputPeer,
    },
    StoriesSendStory: struct {
        flags: usize,
        pinned: ?bool,
        noforwards: ?bool,
        fwd_modified: ?bool,
        peer: InputPeer,
        media: InputMedia,
        media_areas: ?[]const MediaArea,
        caption: ?[]const u8,
        entities: ?[]const MessageEntity,
        privacy_rules: []const InputPrivacyRule,
        random_id: i64,
        period: ?i32,
        fwd_from_id: ?InputPeer,
        fwd_from_story: ?i32,
    },
    StoriesEditStory: struct {
        flags: usize,
        peer: InputPeer,
        id: i32,
        media: ?InputMedia,
        media_areas: ?[]const MediaArea,
        caption: ?[]const u8,
        entities: ?[]const MessageEntity,
        privacy_rules: ?[]const InputPrivacyRule,
    },
    StoriesDeleteStories: struct {
        peer: InputPeer,
        id: []const i32,
    },
    StoriesTogglePinned: struct {
        peer: InputPeer,
        id: []const i32,
        pinned: bool,
    },
    StoriesGetAllStories: struct {
        flags: usize,
        next: ?bool,
        hidden: ?bool,
        state: ?[]const u8,
    },
    StoriesGetPinnedStories: struct {
        peer: InputPeer,
        offset_id: i32,
        limit: i32,
    },
    StoriesGetStoriesArchive: struct {
        peer: InputPeer,
        offset_id: i32,
        limit: i32,
    },
    StoriesGetStoriesByID: struct {
        peer: InputPeer,
        id: []const i32,
    },
    StoriesToggleAllStoriesHidden: struct {
        hidden: bool,
    },
    StoriesReadStories: struct {
        peer: InputPeer,
        max_id: i32,
    },
    StoriesIncrementStoryViews: struct {
        peer: InputPeer,
        id: []const i32,
    },
    StoriesGetStoryViewsList: struct {
        flags: usize,
        just_contacts: ?bool,
        reactions_first: ?bool,
        forwards_first: ?bool,
        peer: InputPeer,
        q: ?[]const u8,
        id: i32,
        offset: []const u8,
        limit: i32,
    },
    StoriesGetStoriesViews: struct {
        peer: InputPeer,
        id: []const i32,
    },
    StoriesExportStoryLink: struct {
        peer: InputPeer,
        id: i32,
    },
    StoriesReport: struct {
        peer: InputPeer,
        id: []const i32,
        option: []const u8,
        message: []const u8,
    },
    StoriesActivateStealthMode: struct {
        flags: usize,
        past: ?bool,
        future: ?bool,
    },
    StoriesSendReaction: struct {
        flags: usize,
        add_to_recent: ?bool,
        peer: InputPeer,
        story_id: i32,
        reaction: Reaction,
    },
    StoriesGetPeerStories: struct {
        peer: InputPeer,
    },
    StoriesGetAllReadPeerStories: struct {
    },
    StoriesGetPeerMaxIDs: struct {
        id: []const InputPeer,
    },
    StoriesGetChatsToSend: struct {
    },
    StoriesTogglePeerStoriesHidden: struct {
        peer: InputPeer,
        hidden: bool,
    },
    StoriesGetStoryReactionsList: struct {
        flags: usize,
        forwards_first: ?bool,
        peer: InputPeer,
        id: i32,
        reaction: ?Reaction,
        offset: ?[]const u8,
        limit: i32,
    },
    StoriesTogglePinnedToTop: struct {
        peer: InputPeer,
        id: []const i32,
    },
    StoriesSearchPosts: struct {
        flags: usize,
        hashtag: ?[]const u8,
        area: ?MediaArea,
        offset: []const u8,
        limit: i32,
    },
    PremiumGetBoostsList: struct {
        flags: usize,
        gifts: ?bool,
        peer: InputPeer,
        offset: []const u8,
        limit: i32,
    },
    PremiumGetMyBoosts: struct {
    },
    PremiumApplyBoost: struct {
        flags: usize,
        slots: ?[]const i32,
        peer: InputPeer,
    },
    PremiumGetBoostsStatus: struct {
        peer: InputPeer,
    },
    PremiumGetUserBoosts: struct {
        peer: InputPeer,
        user_id: InputUser,
    },
    SmsjobsIsEligibleToJoin: struct {
    },
    SmsjobsJoin: struct {
    },
    SmsjobsLeave: struct {
    },
    SmsjobsUpdateSettings: struct {
        flags: usize,
        allow_international: ?bool,
    },
    SmsjobsGetStatus: struct {
    },
    SmsjobsGetSmsJob: struct {
        job_id: []const u8,
    },
    SmsjobsFinishJob: struct {
        flags: usize,
        job_id: []const u8,
        Error: ?[]const u8,
    },
    FragmentGetCollectibleInfo: struct {
        collectible: InputCollectible,
    },
};
const InputPeer = union(TLID) {
    InputPeerEmpty: TL.InputPeerEmpty,
    InputPeerSelf: TL.InputPeerSelf,
    InputPeerChat: TL.InputPeerChat,
    InputPeerUser: TL.InputPeerUser,
    InputPeerChannel: TL.InputPeerChannel,
    InputPeerUserFromMessage: TL.InputPeerUserFromMessage,
    InputPeerChannelFromMessage: TL.InputPeerChannelFromMessage,
};
const InputUser = union(TLID) {
    InputUserEmpty: TL.InputUserEmpty,
    InputUserSelf: TL.InputUserSelf,
    InputUser: TL.InputUser,
    InputUserFromMessage: TL.InputUserFromMessage,
};
const InputContact = union(TLID) {
    InputPhoneContact: TL.InputPhoneContact,
};
const InputFile = union(TLID) {
    InputFile: TL.InputFile,
    InputFileBig: TL.InputFileBig,
    InputFileStoryDocument: TL.InputFileStoryDocument,
};
const InputMedia = union(TLID) {
    InputMediaEmpty: TL.InputMediaEmpty,
    InputMediaUploadedPhoto: TL.InputMediaUploadedPhoto,
    InputMediaPhoto: TL.InputMediaPhoto,
    InputMediaGeoPoint: TL.InputMediaGeoPoint,
    InputMediaContact: TL.InputMediaContact,
    InputMediaUploadedDocument: TL.InputMediaUploadedDocument,
    InputMediaDocument: TL.InputMediaDocument,
    InputMediaVenue: TL.InputMediaVenue,
    InputMediaPhotoExternal: TL.InputMediaPhotoExternal,
    InputMediaDocumentExternal: TL.InputMediaDocumentExternal,
    InputMediaGame: TL.InputMediaGame,
    InputMediaInvoice: TL.InputMediaInvoice,
    InputMediaGeoLive: TL.InputMediaGeoLive,
    InputMediaPoll: TL.InputMediaPoll,
    InputMediaDice: TL.InputMediaDice,
    InputMediaStory: TL.InputMediaStory,
    InputMediaWebPage: TL.InputMediaWebPage,
    InputMediaPaidMedia: TL.InputMediaPaidMedia,
};
const InputChatPhoto = union(TLID) {
    InputChatPhotoEmpty: TL.InputChatPhotoEmpty,
    InputChatUploadedPhoto: TL.InputChatUploadedPhoto,
    InputChatPhoto: TL.InputChatPhoto,
};
const InputGeoPoint = union(TLID) {
    InputGeoPointEmpty: TL.InputGeoPointEmpty,
    InputGeoPoint: TL.InputGeoPoint,
};
const InputPhoto = union(TLID) {
    InputPhotoEmpty: TL.InputPhotoEmpty,
    InputPhoto: TL.InputPhoto,
};
const InputFileLocation = union(TLID) {
    InputFileLocation: TL.InputFileLocation,
    InputEncryptedFileLocation: TL.InputEncryptedFileLocation,
    InputDocumentFileLocation: TL.InputDocumentFileLocation,
    InputSecureFileLocation: TL.InputSecureFileLocation,
    InputTakeoutFileLocation: TL.InputTakeoutFileLocation,
    InputPhotoFileLocation: TL.InputPhotoFileLocation,
    InputPhotoLegacyFileLocation: TL.InputPhotoLegacyFileLocation,
    InputPeerPhotoFileLocation: TL.InputPeerPhotoFileLocation,
    InputStickerSetThumb: TL.InputStickerSetThumb,
    InputGroupCallStream: TL.InputGroupCallStream,
};
const Peer = union(TLID) {
    PeerUser: TL.PeerUser,
    PeerChat: TL.PeerChat,
    PeerChannel: TL.PeerChannel,
};
const StorageFileType = union(TLID) {
    StorageFileUnknown: TL.StorageFileUnknown,
    StorageFilePartial: TL.StorageFilePartial,
    StorageFileJpeg: TL.StorageFileJpeg,
    StorageFileGif: TL.StorageFileGif,
    StorageFilePng: TL.StorageFilePng,
    StorageFilePdf: TL.StorageFilePdf,
    StorageFileMp3: TL.StorageFileMp3,
    StorageFileMov: TL.StorageFileMov,
    StorageFileMp4: TL.StorageFileMp4,
    StorageFileWebp: TL.StorageFileWebp,
};
const User = union(TLID) {
    UserEmpty: TL.UserEmpty,
    User: TL.User,
};
const UserProfilePhoto = union(TLID) {
    UserProfilePhotoEmpty: TL.UserProfilePhotoEmpty,
    UserProfilePhoto: TL.UserProfilePhoto,
};
const UserStatus = union(TLID) {
    UserStatusEmpty: TL.UserStatusEmpty,
    UserStatusOnline: TL.UserStatusOnline,
    UserStatusOffline: TL.UserStatusOffline,
    UserStatusRecently: TL.UserStatusRecently,
    UserStatusLastWeek: TL.UserStatusLastWeek,
    UserStatusLastMonth: TL.UserStatusLastMonth,
};
const Chat = union(TLID) {
    ChatEmpty: TL.ChatEmpty,
    Chat: TL.Chat,
    ChatForbidden: TL.ChatForbidden,
    Channel: TL.Channel,
    ChannelForbidden: TL.ChannelForbidden,
};
const ChatFull = union(TLID) {
    ChatFull: TL.ChatFull,
    ChannelFull: TL.ChannelFull,
};
const ChatParticipant = union(TLID) {
    ChatParticipant: TL.ChatParticipant,
    ChatParticipantCreator: TL.ChatParticipantCreator,
    ChatParticipantAdmin: TL.ChatParticipantAdmin,
};
const ChatParticipants = union(TLID) {
    ChatParticipantsForbidden: TL.ChatParticipantsForbidden,
    ChatParticipants: TL.ChatParticipants,
};
const ChatPhoto = union(TLID) {
    ChatPhotoEmpty: TL.ChatPhotoEmpty,
    ChatPhoto: TL.ChatPhoto,
};
const Message = union(TLID) {
    MessageEmpty: TL.MessageEmpty,
    Message: TL.Message,
    MessageService: TL.MessageService,
};
const MessageMedia = union(TLID) {
    MessageMediaEmpty: TL.MessageMediaEmpty,
    MessageMediaPhoto: TL.MessageMediaPhoto,
    MessageMediaGeo: TL.MessageMediaGeo,
    MessageMediaContact: TL.MessageMediaContact,
    MessageMediaUnsupported: TL.MessageMediaUnsupported,
    MessageMediaDocument: TL.MessageMediaDocument,
    MessageMediaWebPage: TL.MessageMediaWebPage,
    MessageMediaVenue: TL.MessageMediaVenue,
    MessageMediaGame: TL.MessageMediaGame,
    MessageMediaInvoice: TL.MessageMediaInvoice,
    MessageMediaGeoLive: TL.MessageMediaGeoLive,
    MessageMediaPoll: TL.MessageMediaPoll,
    MessageMediaDice: TL.MessageMediaDice,
    MessageMediaStory: TL.MessageMediaStory,
    MessageMediaGiveaway: TL.MessageMediaGiveaway,
    MessageMediaGiveawayResults: TL.MessageMediaGiveawayResults,
    MessageMediaPaidMedia: TL.MessageMediaPaidMedia,
};
const MessageAction = union(TLID) {
    MessageActionEmpty: TL.MessageActionEmpty,
    MessageActionChatCreate: TL.MessageActionChatCreate,
    MessageActionChatEditTitle: TL.MessageActionChatEditTitle,
    MessageActionChatEditPhoto: TL.MessageActionChatEditPhoto,
    MessageActionChatDeletePhoto: TL.MessageActionChatDeletePhoto,
    MessageActionChatAddUser: TL.MessageActionChatAddUser,
    MessageActionChatDeleteUser: TL.MessageActionChatDeleteUser,
    MessageActionChatJoinedByLink: TL.MessageActionChatJoinedByLink,
    MessageActionChannelCreate: TL.MessageActionChannelCreate,
    MessageActionChatMigrateTo: TL.MessageActionChatMigrateTo,
    MessageActionChannelMigrateFrom: TL.MessageActionChannelMigrateFrom,
    MessageActionPinMessage: TL.MessageActionPinMessage,
    MessageActionHistoryClear: TL.MessageActionHistoryClear,
    MessageActionGameScore: TL.MessageActionGameScore,
    MessageActionPaymentSentMe: TL.MessageActionPaymentSentMe,
    MessageActionPaymentSent: TL.MessageActionPaymentSent,
    MessageActionPhoneCall: TL.MessageActionPhoneCall,
    MessageActionScreenshotTaken: TL.MessageActionScreenshotTaken,
    MessageActionCustomAction: TL.MessageActionCustomAction,
    MessageActionBotAllowed: TL.MessageActionBotAllowed,
    MessageActionSecureValuesSentMe: TL.MessageActionSecureValuesSentMe,
    MessageActionSecureValuesSent: TL.MessageActionSecureValuesSent,
    MessageActionContactSignUp: TL.MessageActionContactSignUp,
    MessageActionGeoProximityReached: TL.MessageActionGeoProximityReached,
    MessageActionGroupCall: TL.MessageActionGroupCall,
    MessageActionInviteToGroupCall: TL.MessageActionInviteToGroupCall,
    MessageActionSetMessagesTTL: TL.MessageActionSetMessagesTTL,
    MessageActionGroupCallScheduled: TL.MessageActionGroupCallScheduled,
    MessageActionSetChatTheme: TL.MessageActionSetChatTheme,
    MessageActionChatJoinedByRequest: TL.MessageActionChatJoinedByRequest,
    MessageActionWebViewDataSentMe: TL.MessageActionWebViewDataSentMe,
    MessageActionWebViewDataSent: TL.MessageActionWebViewDataSent,
    MessageActionGiftPremium: TL.MessageActionGiftPremium,
    MessageActionTopicCreate: TL.MessageActionTopicCreate,
    MessageActionTopicEdit: TL.MessageActionTopicEdit,
    MessageActionSuggestProfilePhoto: TL.MessageActionSuggestProfilePhoto,
    MessageActionRequestedPeer: TL.MessageActionRequestedPeer,
    MessageActionSetChatWallPaper: TL.MessageActionSetChatWallPaper,
    MessageActionGiftCode: TL.MessageActionGiftCode,
    MessageActionGiveawayLaunch: TL.MessageActionGiveawayLaunch,
    MessageActionGiveawayResults: TL.MessageActionGiveawayResults,
    MessageActionBoostApply: TL.MessageActionBoostApply,
    MessageActionRequestedPeerSentMe: TL.MessageActionRequestedPeerSentMe,
    MessageActionPaymentRefunded: TL.MessageActionPaymentRefunded,
    MessageActionGiftStars: TL.MessageActionGiftStars,
    MessageActionPrizeStars: TL.MessageActionPrizeStars,
    MessageActionStarGift: TL.MessageActionStarGift,
};
const Dialog = union(TLID) {
    Dialog: TL.Dialog,
    DialogFolder: TL.DialogFolder,
};
const Photo = union(TLID) {
    PhotoEmpty: TL.PhotoEmpty,
    Photo: TL.Photo,
};
const PhotoSize = union(TLID) {
    PhotoSizeEmpty: TL.PhotoSizeEmpty,
    PhotoSize: TL.PhotoSize,
    PhotoCachedSize: TL.PhotoCachedSize,
    PhotoStrippedSize: TL.PhotoStrippedSize,
    PhotoSizeProgressive: TL.PhotoSizeProgressive,
    PhotoPathSize: TL.PhotoPathSize,
};
const GeoPoint = union(TLID) {
    GeoPointEmpty: TL.GeoPointEmpty,
    GeoPoint: TL.GeoPoint,
};
const AuthSentCode = union(TLID) {
    AuthSentCode: TL.AuthSentCode,
    AuthSentCodeSuccess: TL.AuthSentCodeSuccess,
};
const AuthAuthorization = union(TLID) {
    AuthAuthorization: TL.AuthAuthorization,
    AuthAuthorizationSignUpRequired: TL.AuthAuthorizationSignUpRequired,
};
const AuthExportedAuthorization = union(TLID) {
    AuthExportedAuthorization: TL.AuthExportedAuthorization,
};
const InputNotifyPeer = union(TLID) {
    InputNotifyPeer: TL.InputNotifyPeer,
    InputNotifyUsers: TL.InputNotifyUsers,
    InputNotifyChats: TL.InputNotifyChats,
    InputNotifyBroadcasts: TL.InputNotifyBroadcasts,
    InputNotifyForumTopic: TL.InputNotifyForumTopic,
};
const InputPeerNotifySettings = union(TLID) {
    InputPeerNotifySettings: TL.InputPeerNotifySettings,
};
const PeerNotifySettings = union(TLID) {
    PeerNotifySettings: TL.PeerNotifySettings,
};
const PeerSettings = union(TLID) {
    PeerSettings: TL.PeerSettings,
};
const WallPaper = union(TLID) {
    WallPaper: TL.WallPaper,
    WallPaperNoFile: TL.WallPaperNoFile,
};
const ReportReason = union(TLID) {
    InputReportReasonSpam: TL.InputReportReasonSpam,
    InputReportReasonViolence: TL.InputReportReasonViolence,
    InputReportReasonPornography: TL.InputReportReasonPornography,
    InputReportReasonChildAbuse: TL.InputReportReasonChildAbuse,
    InputReportReasonOther: TL.InputReportReasonOther,
    InputReportReasonCopyright: TL.InputReportReasonCopyright,
    InputReportReasonGeoIrrelevant: TL.InputReportReasonGeoIrrelevant,
    InputReportReasonFake: TL.InputReportReasonFake,
    InputReportReasonIllegalDrugs: TL.InputReportReasonIllegalDrugs,
    InputReportReasonPersonalDetails: TL.InputReportReasonPersonalDetails,
};
const UserFull = union(TLID) {
    UserFull: TL.UserFull,
};
const Contact = union(TLID) {
    Contact: TL.Contact,
};
const ImportedContact = union(TLID) {
    ImportedContact: TL.ImportedContact,
};
const ContactStatus = union(TLID) {
    ContactStatus: TL.ContactStatus,
};
const ContactsContacts = union(TLID) {
    ContactsContactsNotModified: TL.ContactsContactsNotModified,
    ContactsContacts: TL.ContactsContacts,
};
const ContactsImportedContacts = union(TLID) {
    ContactsImportedContacts: TL.ContactsImportedContacts,
};
const ContactsBlocked = union(TLID) {
    ContactsBlocked: TL.ContactsBlocked,
    ContactsBlockedSlice: TL.ContactsBlockedSlice,
};
const MessagesDialogs = union(TLID) {
    MessagesDialogs: TL.MessagesDialogs,
    MessagesDialogsSlice: TL.MessagesDialogsSlice,
    MessagesDialogsNotModified: TL.MessagesDialogsNotModified,
};
const MessagesMessages = union(TLID) {
    MessagesMessages: TL.MessagesMessages,
    MessagesMessagesSlice: TL.MessagesMessagesSlice,
    MessagesChannelMessages: TL.MessagesChannelMessages,
    MessagesMessagesNotModified: TL.MessagesMessagesNotModified,
};
const MessagesChats = union(TLID) {
    MessagesChats: TL.MessagesChats,
    MessagesChatsSlice: TL.MessagesChatsSlice,
};
const MessagesChatFull = union(TLID) {
    MessagesChatFull: TL.MessagesChatFull,
};
const MessagesAffectedHistory = union(TLID) {
    MessagesAffectedHistory: TL.MessagesAffectedHistory,
};
const MessagesFilter = union(TLID) {
    InputMessagesFilterEmpty: TL.InputMessagesFilterEmpty,
    InputMessagesFilterPhotos: TL.InputMessagesFilterPhotos,
    InputMessagesFilterVideo: TL.InputMessagesFilterVideo,
    InputMessagesFilterPhotoVideo: TL.InputMessagesFilterPhotoVideo,
    InputMessagesFilterDocument: TL.InputMessagesFilterDocument,
    InputMessagesFilterUrl: TL.InputMessagesFilterUrl,
    InputMessagesFilterGif: TL.InputMessagesFilterGif,
    InputMessagesFilterVoice: TL.InputMessagesFilterVoice,
    InputMessagesFilterMusic: TL.InputMessagesFilterMusic,
    InputMessagesFilterChatPhotos: TL.InputMessagesFilterChatPhotos,
    InputMessagesFilterPhoneCalls: TL.InputMessagesFilterPhoneCalls,
    InputMessagesFilterRoundVoice: TL.InputMessagesFilterRoundVoice,
    InputMessagesFilterRoundVideo: TL.InputMessagesFilterRoundVideo,
    InputMessagesFilterMyMentions: TL.InputMessagesFilterMyMentions,
    InputMessagesFilterGeo: TL.InputMessagesFilterGeo,
    InputMessagesFilterContacts: TL.InputMessagesFilterContacts,
    InputMessagesFilterPinned: TL.InputMessagesFilterPinned,
};
const Update = union(TLID) {
    UpdateNewMessage: TL.UpdateNewMessage,
    UpdateMessageID: TL.UpdateMessageID,
    UpdateDeleteMessages: TL.UpdateDeleteMessages,
    UpdateUserTyping: TL.UpdateUserTyping,
    UpdateChatUserTyping: TL.UpdateChatUserTyping,
    UpdateChatParticipants: TL.UpdateChatParticipants,
    UpdateUserStatus: TL.UpdateUserStatus,
    UpdateUserName: TL.UpdateUserName,
    UpdateNewAuthorization: TL.UpdateNewAuthorization,
    UpdateNewEncryptedMessage: TL.UpdateNewEncryptedMessage,
    UpdateEncryptedChatTyping: TL.UpdateEncryptedChatTyping,
    UpdateEncryption: TL.UpdateEncryption,
    UpdateEncryptedMessagesRead: TL.UpdateEncryptedMessagesRead,
    UpdateChatParticipantAdd: TL.UpdateChatParticipantAdd,
    UpdateChatParticipantDelete: TL.UpdateChatParticipantDelete,
    UpdateDcOptions: TL.UpdateDcOptions,
    UpdateNotifySettings: TL.UpdateNotifySettings,
    UpdateServiceNotification: TL.UpdateServiceNotification,
    UpdatePrivacy: TL.UpdatePrivacy,
    UpdateUserPhone: TL.UpdateUserPhone,
    UpdateReadHistoryInbox: TL.UpdateReadHistoryInbox,
    UpdateReadHistoryOutbox: TL.UpdateReadHistoryOutbox,
    UpdateWebPage: TL.UpdateWebPage,
    UpdateReadMessagesContents: TL.UpdateReadMessagesContents,
    UpdateChannelTooLong: TL.UpdateChannelTooLong,
    UpdateChannel: TL.UpdateChannel,
    UpdateNewChannelMessage: TL.UpdateNewChannelMessage,
    UpdateReadChannelInbox: TL.UpdateReadChannelInbox,
    UpdateDeleteChannelMessages: TL.UpdateDeleteChannelMessages,
    UpdateChannelMessageViews: TL.UpdateChannelMessageViews,
    UpdateChatParticipantAdmin: TL.UpdateChatParticipantAdmin,
    UpdateNewStickerSet: TL.UpdateNewStickerSet,
    UpdateStickerSetsOrder: TL.UpdateStickerSetsOrder,
    UpdateStickerSets: TL.UpdateStickerSets,
    UpdateSavedGifs: TL.UpdateSavedGifs,
    UpdateBotInlineQuery: TL.UpdateBotInlineQuery,
    UpdateBotInlineSend: TL.UpdateBotInlineSend,
    UpdateEditChannelMessage: TL.UpdateEditChannelMessage,
    UpdateBotCallbackQuery: TL.UpdateBotCallbackQuery,
    UpdateEditMessage: TL.UpdateEditMessage,
    UpdateInlineBotCallbackQuery: TL.UpdateInlineBotCallbackQuery,
    UpdateReadChannelOutbox: TL.UpdateReadChannelOutbox,
    UpdateDraftMessage: TL.UpdateDraftMessage,
    UpdateReadFeaturedStickers: TL.UpdateReadFeaturedStickers,
    UpdateRecentStickers: TL.UpdateRecentStickers,
    UpdateConfig: TL.UpdateConfig,
    UpdatePtsChanged: TL.UpdatePtsChanged,
    UpdateChannelWebPage: TL.UpdateChannelWebPage,
    UpdateDialogPinned: TL.UpdateDialogPinned,
    UpdatePinnedDialogs: TL.UpdatePinnedDialogs,
    UpdateBotWebhookJSON: TL.UpdateBotWebhookJSON,
    UpdateBotWebhookJSONQuery: TL.UpdateBotWebhookJSONQuery,
    UpdateBotShippingQuery: TL.UpdateBotShippingQuery,
    UpdateBotPrecheckoutQuery: TL.UpdateBotPrecheckoutQuery,
    UpdatePhoneCall: TL.UpdatePhoneCall,
    UpdateLangPackTooLong: TL.UpdateLangPackTooLong,
    UpdateLangPack: TL.UpdateLangPack,
    UpdateFavedStickers: TL.UpdateFavedStickers,
    UpdateChannelReadMessagesContents: TL.UpdateChannelReadMessagesContents,
    UpdateContactsReset: TL.UpdateContactsReset,
    UpdateChannelAvailableMessages: TL.UpdateChannelAvailableMessages,
    UpdateDialogUnreadMark: TL.UpdateDialogUnreadMark,
    UpdateMessagePoll: TL.UpdateMessagePoll,
    UpdateChatDefaultBannedRights: TL.UpdateChatDefaultBannedRights,
    UpdateFolderPeers: TL.UpdateFolderPeers,
    UpdatePeerSettings: TL.UpdatePeerSettings,
    UpdatePeerLocated: TL.UpdatePeerLocated,
    UpdateNewScheduledMessage: TL.UpdateNewScheduledMessage,
    UpdateDeleteScheduledMessages: TL.UpdateDeleteScheduledMessages,
    UpdateTheme: TL.UpdateTheme,
    UpdateGeoLiveViewed: TL.UpdateGeoLiveViewed,
    UpdateLoginToken: TL.UpdateLoginToken,
    UpdateMessagePollVote: TL.UpdateMessagePollVote,
    UpdateDialogFilter: TL.UpdateDialogFilter,
    UpdateDialogFilterOrder: TL.UpdateDialogFilterOrder,
    UpdateDialogFilters: TL.UpdateDialogFilters,
    UpdatePhoneCallSignalingData: TL.UpdatePhoneCallSignalingData,
    UpdateChannelMessageForwards: TL.UpdateChannelMessageForwards,
    UpdateReadChannelDiscussionInbox: TL.UpdateReadChannelDiscussionInbox,
    UpdateReadChannelDiscussionOutbox: TL.UpdateReadChannelDiscussionOutbox,
    UpdatePeerBlocked: TL.UpdatePeerBlocked,
    UpdateChannelUserTyping: TL.UpdateChannelUserTyping,
    UpdatePinnedMessages: TL.UpdatePinnedMessages,
    UpdatePinnedChannelMessages: TL.UpdatePinnedChannelMessages,
    UpdateChat: TL.UpdateChat,
    UpdateGroupCallParticipants: TL.UpdateGroupCallParticipants,
    UpdateGroupCall: TL.UpdateGroupCall,
    UpdatePeerHistoryTTL: TL.UpdatePeerHistoryTTL,
    UpdateChatParticipant: TL.UpdateChatParticipant,
    UpdateChannelParticipant: TL.UpdateChannelParticipant,
    UpdateBotStopped: TL.UpdateBotStopped,
    UpdateGroupCallConnection: TL.UpdateGroupCallConnection,
    UpdateBotCommands: TL.UpdateBotCommands,
    UpdatePendingJoinRequests: TL.UpdatePendingJoinRequests,
    UpdateBotChatInviteRequester: TL.UpdateBotChatInviteRequester,
    UpdateMessageReactions: TL.UpdateMessageReactions,
    UpdateAttachMenuBots: TL.UpdateAttachMenuBots,
    UpdateWebViewResultSent: TL.UpdateWebViewResultSent,
    UpdateBotMenuButton: TL.UpdateBotMenuButton,
    UpdateSavedRingtones: TL.UpdateSavedRingtones,
    UpdateTranscribedAudio: TL.UpdateTranscribedAudio,
    UpdateReadFeaturedEmojiStickers: TL.UpdateReadFeaturedEmojiStickers,
    UpdateUserEmojiStatus: TL.UpdateUserEmojiStatus,
    UpdateRecentEmojiStatuses: TL.UpdateRecentEmojiStatuses,
    UpdateRecentReactions: TL.UpdateRecentReactions,
    UpdateMoveStickerSetToTop: TL.UpdateMoveStickerSetToTop,
    UpdateMessageExtendedMedia: TL.UpdateMessageExtendedMedia,
    UpdateChannelPinnedTopic: TL.UpdateChannelPinnedTopic,
    UpdateChannelPinnedTopics: TL.UpdateChannelPinnedTopics,
    UpdateUser: TL.UpdateUser,
    UpdateAutoSaveSettings: TL.UpdateAutoSaveSettings,
    UpdateStory: TL.UpdateStory,
    UpdateReadStories: TL.UpdateReadStories,
    UpdateStoryID: TL.UpdateStoryID,
    UpdateStoriesStealthMode: TL.UpdateStoriesStealthMode,
    UpdateSentStoryReaction: TL.UpdateSentStoryReaction,
    UpdateBotChatBoost: TL.UpdateBotChatBoost,
    UpdateChannelViewForumAsMessages: TL.UpdateChannelViewForumAsMessages,
    UpdatePeerWallpaper: TL.UpdatePeerWallpaper,
    UpdateBotMessageReaction: TL.UpdateBotMessageReaction,
    UpdateBotMessageReactions: TL.UpdateBotMessageReactions,
    UpdateSavedDialogPinned: TL.UpdateSavedDialogPinned,
    UpdatePinnedSavedDialogs: TL.UpdatePinnedSavedDialogs,
    UpdateSavedReactionTags: TL.UpdateSavedReactionTags,
    UpdateSmsJob: TL.UpdateSmsJob,
    UpdateQuickReplies: TL.UpdateQuickReplies,
    UpdateNewQuickReply: TL.UpdateNewQuickReply,
    UpdateDeleteQuickReply: TL.UpdateDeleteQuickReply,
    UpdateQuickReplyMessage: TL.UpdateQuickReplyMessage,
    UpdateDeleteQuickReplyMessages: TL.UpdateDeleteQuickReplyMessages,
    UpdateBotBusinessConnect: TL.UpdateBotBusinessConnect,
    UpdateBotNewBusinessMessage: TL.UpdateBotNewBusinessMessage,
    UpdateBotEditBusinessMessage: TL.UpdateBotEditBusinessMessage,
    UpdateBotDeleteBusinessMessage: TL.UpdateBotDeleteBusinessMessage,
    UpdateNewStoryReaction: TL.UpdateNewStoryReaction,
    UpdateBroadcastRevenueTransactions: TL.UpdateBroadcastRevenueTransactions,
    UpdateStarsBalance: TL.UpdateStarsBalance,
    UpdateBusinessBotCallbackQuery: TL.UpdateBusinessBotCallbackQuery,
    UpdateStarsRevenueStatus: TL.UpdateStarsRevenueStatus,
    UpdateBotPurchasedPaidMedia: TL.UpdateBotPurchasedPaidMedia,
    UpdatePaidReactionPrivacy: TL.UpdatePaidReactionPrivacy,
};
const UpdatesState = union(TLID) {
    UpdatesState: TL.UpdatesState,
};
const UpdatesDifference = union(TLID) {
    UpdatesDifferenceEmpty: TL.UpdatesDifferenceEmpty,
    UpdatesDifference: TL.UpdatesDifference,
    UpdatesDifferenceSlice: TL.UpdatesDifferenceSlice,
    UpdatesDifferenceTooLong: TL.UpdatesDifferenceTooLong,
};
const Updates = union(TLID) {
    UpdatesTooLong: TL.UpdatesTooLong,
    UpdateShortMessage: TL.UpdateShortMessage,
    UpdateShortChatMessage: TL.UpdateShortChatMessage,
    UpdateShort: TL.UpdateShort,
    UpdatesCombined: TL.UpdatesCombined,
    Updates: TL.Updates,
    UpdateShortSentMessage: TL.UpdateShortSentMessage,
};
const PhotosPhotos = union(TLID) {
    PhotosPhotos: TL.PhotosPhotos,
    PhotosPhotosSlice: TL.PhotosPhotosSlice,
};
const PhotosPhoto = union(TLID) {
    PhotosPhoto: TL.PhotosPhoto,
};
const UploadFile = union(TLID) {
    UploadFile: TL.UploadFile,
    UploadFileCdnRedirect: TL.UploadFileCdnRedirect,
};
const DcOption = union(TLID) {
    DcOption: TL.DcOption,
};
const Config = union(TLID) {
    Config: TL.Config,
};
const NearestDc = union(TLID) {
    NearestDc: TL.NearestDc,
};
const HelpAppUpdate = union(TLID) {
    HelpAppUpdate: TL.HelpAppUpdate,
    HelpNoAppUpdate: TL.HelpNoAppUpdate,
};
const HelpInviteText = union(TLID) {
    HelpInviteText: TL.HelpInviteText,
};
const EncryptedChat = union(TLID) {
    EncryptedChatEmpty: TL.EncryptedChatEmpty,
    EncryptedChatWaiting: TL.EncryptedChatWaiting,
    EncryptedChatRequested: TL.EncryptedChatRequested,
    EncryptedChat: TL.EncryptedChat,
    EncryptedChatDiscarded: TL.EncryptedChatDiscarded,
};
const InputEncryptedChat = union(TLID) {
    InputEncryptedChat: TL.InputEncryptedChat,
};
const EncryptedFile = union(TLID) {
    EncryptedFileEmpty: TL.EncryptedFileEmpty,
    EncryptedFile: TL.EncryptedFile,
};
const InputEncryptedFile = union(TLID) {
    InputEncryptedFileEmpty: TL.InputEncryptedFileEmpty,
    InputEncryptedFileUploaded: TL.InputEncryptedFileUploaded,
    InputEncryptedFile: TL.InputEncryptedFile,
    InputEncryptedFileBigUploaded: TL.InputEncryptedFileBigUploaded,
};
const EncryptedMessage = union(TLID) {
    EncryptedMessage: TL.EncryptedMessage,
    EncryptedMessageService: TL.EncryptedMessageService,
};
const MessagesDhConfig = union(TLID) {
    MessagesDhConfigNotModified: TL.MessagesDhConfigNotModified,
    MessagesDhConfig: TL.MessagesDhConfig,
};
const MessagesSentEncryptedMessage = union(TLID) {
    MessagesSentEncryptedMessage: TL.MessagesSentEncryptedMessage,
    MessagesSentEncryptedFile: TL.MessagesSentEncryptedFile,
};
const InputDocument = union(TLID) {
    InputDocumentEmpty: TL.InputDocumentEmpty,
    InputDocument: TL.InputDocument,
};
const Document = union(TLID) {
    DocumentEmpty: TL.DocumentEmpty,
    Document: TL.Document,
};
const HelpSupport = union(TLID) {
    HelpSupport: TL.HelpSupport,
};
const NotifyPeer = union(TLID) {
    NotifyPeer: TL.NotifyPeer,
    NotifyUsers: TL.NotifyUsers,
    NotifyChats: TL.NotifyChats,
    NotifyBroadcasts: TL.NotifyBroadcasts,
    NotifyForumTopic: TL.NotifyForumTopic,
};
const SendMessageAction = union(TLID) {
    SendMessageTypingAction: TL.SendMessageTypingAction,
    SendMessageCancelAction: TL.SendMessageCancelAction,
    SendMessageRecordVideoAction: TL.SendMessageRecordVideoAction,
    SendMessageUploadVideoAction: TL.SendMessageUploadVideoAction,
    SendMessageRecordAudioAction: TL.SendMessageRecordAudioAction,
    SendMessageUploadAudioAction: TL.SendMessageUploadAudioAction,
    SendMessageUploadPhotoAction: TL.SendMessageUploadPhotoAction,
    SendMessageUploadDocumentAction: TL.SendMessageUploadDocumentAction,
    SendMessageGeoLocationAction: TL.SendMessageGeoLocationAction,
    SendMessageChooseContactAction: TL.SendMessageChooseContactAction,
    SendMessageGamePlayAction: TL.SendMessageGamePlayAction,
    SendMessageRecordRoundAction: TL.SendMessageRecordRoundAction,
    SendMessageUploadRoundAction: TL.SendMessageUploadRoundAction,
    SpeakingInGroupCallAction: TL.SpeakingInGroupCallAction,
    SendMessageHistoryImportAction: TL.SendMessageHistoryImportAction,
    SendMessageChooseStickerAction: TL.SendMessageChooseStickerAction,
    SendMessageEmojiInteraction: TL.SendMessageEmojiInteraction,
    SendMessageEmojiInteractionSeen: TL.SendMessageEmojiInteractionSeen,
};
const ContactsFound = union(TLID) {
    ContactsFound: TL.ContactsFound,
};
const InputPrivacyKey = union(TLID) {
    InputPrivacyKeyStatusTimestamp: TL.InputPrivacyKeyStatusTimestamp,
    InputPrivacyKeyChatInvite: TL.InputPrivacyKeyChatInvite,
    InputPrivacyKeyPhoneCall: TL.InputPrivacyKeyPhoneCall,
    InputPrivacyKeyPhoneP2P: TL.InputPrivacyKeyPhoneP2P,
    InputPrivacyKeyForwards: TL.InputPrivacyKeyForwards,
    InputPrivacyKeyProfilePhoto: TL.InputPrivacyKeyProfilePhoto,
    InputPrivacyKeyPhoneNumber: TL.InputPrivacyKeyPhoneNumber,
    InputPrivacyKeyAddedByPhone: TL.InputPrivacyKeyAddedByPhone,
    InputPrivacyKeyVoiceMessages: TL.InputPrivacyKeyVoiceMessages,
    InputPrivacyKeyAbout: TL.InputPrivacyKeyAbout,
    InputPrivacyKeyBirthday: TL.InputPrivacyKeyBirthday,
};
const PrivacyKey = union(TLID) {
    PrivacyKeyStatusTimestamp: TL.PrivacyKeyStatusTimestamp,
    PrivacyKeyChatInvite: TL.PrivacyKeyChatInvite,
    PrivacyKeyPhoneCall: TL.PrivacyKeyPhoneCall,
    PrivacyKeyPhoneP2P: TL.PrivacyKeyPhoneP2P,
    PrivacyKeyForwards: TL.PrivacyKeyForwards,
    PrivacyKeyProfilePhoto: TL.PrivacyKeyProfilePhoto,
    PrivacyKeyPhoneNumber: TL.PrivacyKeyPhoneNumber,
    PrivacyKeyAddedByPhone: TL.PrivacyKeyAddedByPhone,
    PrivacyKeyVoiceMessages: TL.PrivacyKeyVoiceMessages,
    PrivacyKeyAbout: TL.PrivacyKeyAbout,
    PrivacyKeyBirthday: TL.PrivacyKeyBirthday,
};
const InputPrivacyRule = union(TLID) {
    InputPrivacyValueAllowContacts: TL.InputPrivacyValueAllowContacts,
    InputPrivacyValueAllowAll: TL.InputPrivacyValueAllowAll,
    InputPrivacyValueAllowUsers: TL.InputPrivacyValueAllowUsers,
    InputPrivacyValueDisallowContacts: TL.InputPrivacyValueDisallowContacts,
    InputPrivacyValueDisallowAll: TL.InputPrivacyValueDisallowAll,
    InputPrivacyValueDisallowUsers: TL.InputPrivacyValueDisallowUsers,
    InputPrivacyValueAllowChatParticipants: TL.InputPrivacyValueAllowChatParticipants,
    InputPrivacyValueDisallowChatParticipants: TL.InputPrivacyValueDisallowChatParticipants,
    InputPrivacyValueAllowCloseFriends: TL.InputPrivacyValueAllowCloseFriends,
    InputPrivacyValueAllowPremium: TL.InputPrivacyValueAllowPremium,
};
const PrivacyRule = union(TLID) {
    PrivacyValueAllowContacts: TL.PrivacyValueAllowContacts,
    PrivacyValueAllowAll: TL.PrivacyValueAllowAll,
    PrivacyValueAllowUsers: TL.PrivacyValueAllowUsers,
    PrivacyValueDisallowContacts: TL.PrivacyValueDisallowContacts,
    PrivacyValueDisallowAll: TL.PrivacyValueDisallowAll,
    PrivacyValueDisallowUsers: TL.PrivacyValueDisallowUsers,
    PrivacyValueAllowChatParticipants: TL.PrivacyValueAllowChatParticipants,
    PrivacyValueDisallowChatParticipants: TL.PrivacyValueDisallowChatParticipants,
    PrivacyValueAllowCloseFriends: TL.PrivacyValueAllowCloseFriends,
    PrivacyValueAllowPremium: TL.PrivacyValueAllowPremium,
};
const AccountPrivacyRules = union(TLID) {
    AccountPrivacyRules: TL.AccountPrivacyRules,
};
const AccountDaysTTL = union(TLID) {
    AccountDaysTTL: TL.AccountDaysTTL,
};
const DocumentAttribute = union(TLID) {
    DocumentAttributeImageSize: TL.DocumentAttributeImageSize,
    DocumentAttributeAnimated: TL.DocumentAttributeAnimated,
    DocumentAttributeSticker: TL.DocumentAttributeSticker,
    DocumentAttributeVideo: TL.DocumentAttributeVideo,
    DocumentAttributeAudio: TL.DocumentAttributeAudio,
    DocumentAttributeFilename: TL.DocumentAttributeFilename,
    DocumentAttributeHasStickers: TL.DocumentAttributeHasStickers,
    DocumentAttributeCustomEmoji: TL.DocumentAttributeCustomEmoji,
};
const MessagesStickers = union(TLID) {
    MessagesStickersNotModified: TL.MessagesStickersNotModified,
    MessagesStickers: TL.MessagesStickers,
};
const StickerPack = union(TLID) {
    StickerPack: TL.StickerPack,
};
const MessagesAllStickers = union(TLID) {
    MessagesAllStickersNotModified: TL.MessagesAllStickersNotModified,
    MessagesAllStickers: TL.MessagesAllStickers,
};
const MessagesAffectedMessages = union(TLID) {
    MessagesAffectedMessages: TL.MessagesAffectedMessages,
};
const WebPage = union(TLID) {
    WebPageEmpty: TL.WebPageEmpty,
    WebPagePending: TL.WebPagePending,
    WebPage: TL.WebPage,
    WebPageNotModified: TL.WebPageNotModified,
};
const Authorization = union(TLID) {
    Authorization: TL.Authorization,
};
const AccountAuthorizations = union(TLID) {
    AccountAuthorizations: TL.AccountAuthorizations,
};
const AccountPassword = union(TLID) {
    AccountPassword: TL.AccountPassword,
};
const AccountPasswordSettings = union(TLID) {
    AccountPasswordSettings: TL.AccountPasswordSettings,
};
const AccountPasswordInputSettings = union(TLID) {
    AccountPasswordInputSettings: TL.AccountPasswordInputSettings,
};
const AuthPasswordRecovery = union(TLID) {
    AuthPasswordRecovery: TL.AuthPasswordRecovery,
};
const ReceivedNotifyMessage = union(TLID) {
    ReceivedNotifyMessage: TL.ReceivedNotifyMessage,
};
const ExportedChatInvite = union(TLID) {
    ChatInviteExported: TL.ChatInviteExported,
    ChatInvitePublicJoinRequests: TL.ChatInvitePublicJoinRequests,
};
const ChatInvite = union(TLID) {
    ChatInviteAlready: TL.ChatInviteAlready,
    ChatInvite: TL.ChatInvite,
    ChatInvitePeek: TL.ChatInvitePeek,
};
const InputStickerSet = union(TLID) {
    InputStickerSetEmpty: TL.InputStickerSetEmpty,
    InputStickerSetID: TL.InputStickerSetID,
    InputStickerSetShortName: TL.InputStickerSetShortName,
    InputStickerSetAnimatedEmoji: TL.InputStickerSetAnimatedEmoji,
    InputStickerSetDice: TL.InputStickerSetDice,
    InputStickerSetAnimatedEmojiAnimations: TL.InputStickerSetAnimatedEmojiAnimations,
    InputStickerSetPremiumGifts: TL.InputStickerSetPremiumGifts,
    InputStickerSetEmojiGenericAnimations: TL.InputStickerSetEmojiGenericAnimations,
    InputStickerSetEmojiDefaultStatuses: TL.InputStickerSetEmojiDefaultStatuses,
    InputStickerSetEmojiDefaultTopicIcons: TL.InputStickerSetEmojiDefaultTopicIcons,
    InputStickerSetEmojiChannelDefaultStatuses: TL.InputStickerSetEmojiChannelDefaultStatuses,
};
const StickerSet = union(TLID) {
    StickerSet: TL.StickerSet,
};
const MessagesStickerSet = union(TLID) {
    MessagesStickerSet: TL.MessagesStickerSet,
    MessagesStickerSetNotModified: TL.MessagesStickerSetNotModified,
};
const BotCommand = union(TLID) {
    BotCommand: TL.BotCommand,
};
const BotInfo = union(TLID) {
    BotInfo: TL.BotInfo,
};
const KeyboardButton = union(TLID) {
    KeyboardButton: TL.KeyboardButton,
    KeyboardButtonUrl: TL.KeyboardButtonUrl,
    KeyboardButtonCallback: TL.KeyboardButtonCallback,
    KeyboardButtonRequestPhone: TL.KeyboardButtonRequestPhone,
    KeyboardButtonRequestGeoLocation: TL.KeyboardButtonRequestGeoLocation,
    KeyboardButtonSwitchInline: TL.KeyboardButtonSwitchInline,
    KeyboardButtonGame: TL.KeyboardButtonGame,
    KeyboardButtonBuy: TL.KeyboardButtonBuy,
    KeyboardButtonUrlAuth: TL.KeyboardButtonUrlAuth,
    InputKeyboardButtonUrlAuth: TL.InputKeyboardButtonUrlAuth,
    KeyboardButtonRequestPoll: TL.KeyboardButtonRequestPoll,
    InputKeyboardButtonUserProfile: TL.InputKeyboardButtonUserProfile,
    KeyboardButtonUserProfile: TL.KeyboardButtonUserProfile,
    KeyboardButtonWebView: TL.KeyboardButtonWebView,
    KeyboardButtonSimpleWebView: TL.KeyboardButtonSimpleWebView,
    KeyboardButtonRequestPeer: TL.KeyboardButtonRequestPeer,
    InputKeyboardButtonRequestPeer: TL.InputKeyboardButtonRequestPeer,
    KeyboardButtonCopy: TL.KeyboardButtonCopy,
};
const KeyboardButtonRow = union(TLID) {
    KeyboardButtonRow: TL.KeyboardButtonRow,
};
const ReplyMarkup = union(TLID) {
    ReplyKeyboardHide: TL.ReplyKeyboardHide,
    ReplyKeyboardForceReply: TL.ReplyKeyboardForceReply,
    ReplyKeyboardMarkup: TL.ReplyKeyboardMarkup,
    ReplyInlineMarkup: TL.ReplyInlineMarkup,
};
const MessageEntity = union(TLID) {
    MessageEntityUnknown: TL.MessageEntityUnknown,
    MessageEntityMention: TL.MessageEntityMention,
    MessageEntityHashtag: TL.MessageEntityHashtag,
    MessageEntityBotCommand: TL.MessageEntityBotCommand,
    MessageEntityUrl: TL.MessageEntityUrl,
    MessageEntityEmail: TL.MessageEntityEmail,
    MessageEntityBold: TL.MessageEntityBold,
    MessageEntityItalic: TL.MessageEntityItalic,
    MessageEntityCode: TL.MessageEntityCode,
    MessageEntityPre: TL.MessageEntityPre,
    MessageEntityTextUrl: TL.MessageEntityTextUrl,
    MessageEntityMentionName: TL.MessageEntityMentionName,
    InputMessageEntityMentionName: TL.InputMessageEntityMentionName,
    MessageEntityPhone: TL.MessageEntityPhone,
    MessageEntityCashtag: TL.MessageEntityCashtag,
    MessageEntityUnderline: TL.MessageEntityUnderline,
    MessageEntityStrike: TL.MessageEntityStrike,
    MessageEntityBankCard: TL.MessageEntityBankCard,
    MessageEntitySpoiler: TL.MessageEntitySpoiler,
    MessageEntityCustomEmoji: TL.MessageEntityCustomEmoji,
    MessageEntityBlockquote: TL.MessageEntityBlockquote,
};
const InputChannel = union(TLID) {
    InputChannelEmpty: TL.InputChannelEmpty,
    InputChannel: TL.InputChannel,
    InputChannelFromMessage: TL.InputChannelFromMessage,
};
const ContactsResolvedPeer = union(TLID) {
    ContactsResolvedPeer: TL.ContactsResolvedPeer,
};
const MessageRange = union(TLID) {
    MessageRange: TL.MessageRange,
};
const UpdatesChannelDifference = union(TLID) {
    UpdatesChannelDifferenceEmpty: TL.UpdatesChannelDifferenceEmpty,
    UpdatesChannelDifferenceTooLong: TL.UpdatesChannelDifferenceTooLong,
    UpdatesChannelDifference: TL.UpdatesChannelDifference,
};
const ChannelMessagesFilter = union(TLID) {
    ChannelMessagesFilterEmpty: TL.ChannelMessagesFilterEmpty,
    ChannelMessagesFilter: TL.ChannelMessagesFilter,
};
const ChannelParticipant = union(TLID) {
    ChannelParticipant: TL.ChannelParticipant,
    ChannelParticipantSelf: TL.ChannelParticipantSelf,
    ChannelParticipantCreator: TL.ChannelParticipantCreator,
    ChannelParticipantAdmin: TL.ChannelParticipantAdmin,
    ChannelParticipantBanned: TL.ChannelParticipantBanned,
    ChannelParticipantLeft: TL.ChannelParticipantLeft,
};
const ChannelParticipantsFilter = union(TLID) {
    ChannelParticipantsRecent: TL.ChannelParticipantsRecent,
    ChannelParticipantsAdmins: TL.ChannelParticipantsAdmins,
    ChannelParticipantsKicked: TL.ChannelParticipantsKicked,
    ChannelParticipantsBots: TL.ChannelParticipantsBots,
    ChannelParticipantsBanned: TL.ChannelParticipantsBanned,
    ChannelParticipantsSearch: TL.ChannelParticipantsSearch,
    ChannelParticipantsContacts: TL.ChannelParticipantsContacts,
    ChannelParticipantsMentions: TL.ChannelParticipantsMentions,
};
const ChannelsChannelParticipants = union(TLID) {
    ChannelsChannelParticipants: TL.ChannelsChannelParticipants,
    ChannelsChannelParticipantsNotModified: TL.ChannelsChannelParticipantsNotModified,
};
const ChannelsChannelParticipant = union(TLID) {
    ChannelsChannelParticipant: TL.ChannelsChannelParticipant,
};
const HelpTermsOfService = union(TLID) {
    HelpTermsOfService: TL.HelpTermsOfService,
};
const MessagesSavedGifs = union(TLID) {
    MessagesSavedGifsNotModified: TL.MessagesSavedGifsNotModified,
    MessagesSavedGifs: TL.MessagesSavedGifs,
};
const InputBotInlineMessage = union(TLID) {
    InputBotInlineMessageMediaAuto: TL.InputBotInlineMessageMediaAuto,
    InputBotInlineMessageText: TL.InputBotInlineMessageText,
    InputBotInlineMessageMediaGeo: TL.InputBotInlineMessageMediaGeo,
    InputBotInlineMessageMediaVenue: TL.InputBotInlineMessageMediaVenue,
    InputBotInlineMessageMediaContact: TL.InputBotInlineMessageMediaContact,
    InputBotInlineMessageGame: TL.InputBotInlineMessageGame,
    InputBotInlineMessageMediaInvoice: TL.InputBotInlineMessageMediaInvoice,
    InputBotInlineMessageMediaWebPage: TL.InputBotInlineMessageMediaWebPage,
};
const InputBotInlineResult = union(TLID) {
    InputBotInlineResult: TL.InputBotInlineResult,
    InputBotInlineResultPhoto: TL.InputBotInlineResultPhoto,
    InputBotInlineResultDocument: TL.InputBotInlineResultDocument,
    InputBotInlineResultGame: TL.InputBotInlineResultGame,
};
const BotInlineMessage = union(TLID) {
    BotInlineMessageMediaAuto: TL.BotInlineMessageMediaAuto,
    BotInlineMessageText: TL.BotInlineMessageText,
    BotInlineMessageMediaGeo: TL.BotInlineMessageMediaGeo,
    BotInlineMessageMediaVenue: TL.BotInlineMessageMediaVenue,
    BotInlineMessageMediaContact: TL.BotInlineMessageMediaContact,
    BotInlineMessageMediaInvoice: TL.BotInlineMessageMediaInvoice,
    BotInlineMessageMediaWebPage: TL.BotInlineMessageMediaWebPage,
};
const BotInlineResult = union(TLID) {
    BotInlineResult: TL.BotInlineResult,
    BotInlineMediaResult: TL.BotInlineMediaResult,
};
const MessagesBotResults = union(TLID) {
    MessagesBotResults: TL.MessagesBotResults,
};
const ExportedMessageLink = union(TLID) {
    ExportedMessageLink: TL.ExportedMessageLink,
};
const MessageFwdHeader = union(TLID) {
    MessageFwdHeader: TL.MessageFwdHeader,
};
const AuthCodeType = union(TLID) {
    AuthCodeTypeSms: TL.AuthCodeTypeSms,
    AuthCodeTypeCall: TL.AuthCodeTypeCall,
    AuthCodeTypeFlashCall: TL.AuthCodeTypeFlashCall,
    AuthCodeTypeMissedCall: TL.AuthCodeTypeMissedCall,
    AuthCodeTypeFragmentSms: TL.AuthCodeTypeFragmentSms,
};
const AuthSentCodeType = union(TLID) {
    AuthSentCodeTypeApp: TL.AuthSentCodeTypeApp,
    AuthSentCodeTypeSms: TL.AuthSentCodeTypeSms,
    AuthSentCodeTypeCall: TL.AuthSentCodeTypeCall,
    AuthSentCodeTypeFlashCall: TL.AuthSentCodeTypeFlashCall,
    AuthSentCodeTypeMissedCall: TL.AuthSentCodeTypeMissedCall,
    AuthSentCodeTypeEmailCode: TL.AuthSentCodeTypeEmailCode,
    AuthSentCodeTypeSetUpEmailRequired: TL.AuthSentCodeTypeSetUpEmailRequired,
    AuthSentCodeTypeFragmentSms: TL.AuthSentCodeTypeFragmentSms,
    AuthSentCodeTypeFirebaseSms: TL.AuthSentCodeTypeFirebaseSms,
    AuthSentCodeTypeSmsWord: TL.AuthSentCodeTypeSmsWord,
    AuthSentCodeTypeSmsPhrase: TL.AuthSentCodeTypeSmsPhrase,
};
const MessagesBotCallbackAnswer = union(TLID) {
    MessagesBotCallbackAnswer: TL.MessagesBotCallbackAnswer,
};
const MessagesMessageEditData = union(TLID) {
    MessagesMessageEditData: TL.MessagesMessageEditData,
};
const InputBotInlineMessageID = union(TLID) {
    InputBotInlineMessageID: TL.InputBotInlineMessageID,
    InputBotInlineMessageID64: TL.InputBotInlineMessageID64,
};
const InlineBotSwitchPM = union(TLID) {
    InlineBotSwitchPM: TL.InlineBotSwitchPM,
};
const MessagesPeerDialogs = union(TLID) {
    MessagesPeerDialogs: TL.MessagesPeerDialogs,
};
const TopPeer = union(TLID) {
    TopPeer: TL.TopPeer,
};
const TopPeerCategory = union(TLID) {
    TopPeerCategoryBotsPM: TL.TopPeerCategoryBotsPM,
    TopPeerCategoryBotsInline: TL.TopPeerCategoryBotsInline,
    TopPeerCategoryCorrespondents: TL.TopPeerCategoryCorrespondents,
    TopPeerCategoryGroups: TL.TopPeerCategoryGroups,
    TopPeerCategoryChannels: TL.TopPeerCategoryChannels,
    TopPeerCategoryPhoneCalls: TL.TopPeerCategoryPhoneCalls,
    TopPeerCategoryForwardUsers: TL.TopPeerCategoryForwardUsers,
    TopPeerCategoryForwardChats: TL.TopPeerCategoryForwardChats,
    TopPeerCategoryBotsApp: TL.TopPeerCategoryBotsApp,
};
const TopPeerCategoryPeers = union(TLID) {
    TopPeerCategoryPeers: TL.TopPeerCategoryPeers,
};
const ContactsTopPeers = union(TLID) {
    ContactsTopPeersNotModified: TL.ContactsTopPeersNotModified,
    ContactsTopPeers: TL.ContactsTopPeers,
    ContactsTopPeersDisabled: TL.ContactsTopPeersDisabled,
};
const DraftMessage = union(TLID) {
    DraftMessageEmpty: TL.DraftMessageEmpty,
    DraftMessage: TL.DraftMessage,
};
const MessagesFeaturedStickers = union(TLID) {
    MessagesFeaturedStickersNotModified: TL.MessagesFeaturedStickersNotModified,
    MessagesFeaturedStickers: TL.MessagesFeaturedStickers,
};
const MessagesRecentStickers = union(TLID) {
    MessagesRecentStickersNotModified: TL.MessagesRecentStickersNotModified,
    MessagesRecentStickers: TL.MessagesRecentStickers,
};
const MessagesArchivedStickers = union(TLID) {
    MessagesArchivedStickers: TL.MessagesArchivedStickers,
};
const MessagesStickerSetInstallResult = union(TLID) {
    MessagesStickerSetInstallResultSuccess: TL.MessagesStickerSetInstallResultSuccess,
    MessagesStickerSetInstallResultArchive: TL.MessagesStickerSetInstallResultArchive,
};
const StickerSetCovered = union(TLID) {
    StickerSetCovered: TL.StickerSetCovered,
    StickerSetMultiCovered: TL.StickerSetMultiCovered,
    StickerSetFullCovered: TL.StickerSetFullCovered,
    StickerSetNoCovered: TL.StickerSetNoCovered,
};
const MaskCoords = union(TLID) {
    MaskCoords: TL.MaskCoords,
};
const InputStickeredMedia = union(TLID) {
    InputStickeredMediaPhoto: TL.InputStickeredMediaPhoto,
    InputStickeredMediaDocument: TL.InputStickeredMediaDocument,
};
const Game = union(TLID) {
    Game: TL.Game,
};
const InputGame = union(TLID) {
    InputGameID: TL.InputGameID,
    InputGameShortName: TL.InputGameShortName,
};
const HighScore = union(TLID) {
    HighScore: TL.HighScore,
};
const MessagesHighScores = union(TLID) {
    MessagesHighScores: TL.MessagesHighScores,
};
const RichText = union(TLID) {
    TextEmpty: TL.TextEmpty,
    TextPlain: TL.TextPlain,
    TextBold: TL.TextBold,
    TextItalic: TL.TextItalic,
    TextUnderline: TL.TextUnderline,
    TextStrike: TL.TextStrike,
    TextFixed: TL.TextFixed,
    TextUrl: TL.TextUrl,
    TextEmail: TL.TextEmail,
    TextConcat: TL.TextConcat,
    TextSubscript: TL.TextSubscript,
    TextSuperscript: TL.TextSuperscript,
    TextMarked: TL.TextMarked,
    TextPhone: TL.TextPhone,
    TextImage: TL.TextImage,
    TextAnchor: TL.TextAnchor,
};
const PageBlock = union(TLID) {
    PageBlockUnsupported: TL.PageBlockUnsupported,
    PageBlockTitle: TL.PageBlockTitle,
    PageBlockSubtitle: TL.PageBlockSubtitle,
    PageBlockAuthorDate: TL.PageBlockAuthorDate,
    PageBlockHeader: TL.PageBlockHeader,
    PageBlockSubheader: TL.PageBlockSubheader,
    PageBlockParagraph: TL.PageBlockParagraph,
    PageBlockPreformatted: TL.PageBlockPreformatted,
    PageBlockFooter: TL.PageBlockFooter,
    PageBlockDivider: TL.PageBlockDivider,
    PageBlockAnchor: TL.PageBlockAnchor,
    PageBlockList: TL.PageBlockList,
    PageBlockBlockquote: TL.PageBlockBlockquote,
    PageBlockPullquote: TL.PageBlockPullquote,
    PageBlockPhoto: TL.PageBlockPhoto,
    PageBlockVideo: TL.PageBlockVideo,
    PageBlockCover: TL.PageBlockCover,
    PageBlockEmbed: TL.PageBlockEmbed,
    PageBlockEmbedPost: TL.PageBlockEmbedPost,
    PageBlockCollage: TL.PageBlockCollage,
    PageBlockSlideshow: TL.PageBlockSlideshow,
    PageBlockChannel: TL.PageBlockChannel,
    PageBlockAudio: TL.PageBlockAudio,
    PageBlockKicker: TL.PageBlockKicker,
    PageBlockTable: TL.PageBlockTable,
    PageBlockOrderedList: TL.PageBlockOrderedList,
    PageBlockDetails: TL.PageBlockDetails,
    PageBlockRelatedArticles: TL.PageBlockRelatedArticles,
    PageBlockMap: TL.PageBlockMap,
};
const PhoneCallDiscardReason = union(TLID) {
    PhoneCallDiscardReasonMissed: TL.PhoneCallDiscardReasonMissed,
    PhoneCallDiscardReasonDisconnect: TL.PhoneCallDiscardReasonDisconnect,
    PhoneCallDiscardReasonHangup: TL.PhoneCallDiscardReasonHangup,
    PhoneCallDiscardReasonBusy: TL.PhoneCallDiscardReasonBusy,
};
const DataJSON = union(TLID) {
    DataJSON: TL.DataJSON,
};
const LabeledPrice = union(TLID) {
    LabeledPrice: TL.LabeledPrice,
};
const Invoice = union(TLID) {
    Invoice: TL.Invoice,
};
const PaymentCharge = union(TLID) {
    PaymentCharge: TL.PaymentCharge,
};
const PostAddress = union(TLID) {
    PostAddress: TL.PostAddress,
};
const PaymentRequestedInfo = union(TLID) {
    PaymentRequestedInfo: TL.PaymentRequestedInfo,
};
const PaymentSavedCredentials = union(TLID) {
    PaymentSavedCredentialsCard: TL.PaymentSavedCredentialsCard,
};
const WebDocument = union(TLID) {
    WebDocument: TL.WebDocument,
    WebDocumentNoProxy: TL.WebDocumentNoProxy,
};
const InputWebDocument = union(TLID) {
    InputWebDocument: TL.InputWebDocument,
};
const InputWebFileLocation = union(TLID) {
    InputWebFileLocation: TL.InputWebFileLocation,
    InputWebFileGeoPointLocation: TL.InputWebFileGeoPointLocation,
    InputWebFileAudioAlbumThumbLocation: TL.InputWebFileAudioAlbumThumbLocation,
};
const UploadWebFile = union(TLID) {
    UploadWebFile: TL.UploadWebFile,
};
const PaymentsPaymentForm = union(TLID) {
    PaymentsPaymentForm: TL.PaymentsPaymentForm,
    PaymentsPaymentFormStars: TL.PaymentsPaymentFormStars,
    PaymentsPaymentFormStarGift: TL.PaymentsPaymentFormStarGift,
};
const PaymentsValidatedRequestedInfo = union(TLID) {
    PaymentsValidatedRequestedInfo: TL.PaymentsValidatedRequestedInfo,
};
const PaymentsPaymentResult = union(TLID) {
    PaymentsPaymentResult: TL.PaymentsPaymentResult,
    PaymentsPaymentVerificationNeeded: TL.PaymentsPaymentVerificationNeeded,
};
const PaymentsPaymentReceipt = union(TLID) {
    PaymentsPaymentReceipt: TL.PaymentsPaymentReceipt,
    PaymentsPaymentReceiptStars: TL.PaymentsPaymentReceiptStars,
};
const PaymentsSavedInfo = union(TLID) {
    PaymentsSavedInfo: TL.PaymentsSavedInfo,
};
const InputPaymentCredentials = union(TLID) {
    InputPaymentCredentialsSaved: TL.InputPaymentCredentialsSaved,
    InputPaymentCredentials: TL.InputPaymentCredentials,
    InputPaymentCredentialsApplePay: TL.InputPaymentCredentialsApplePay,
    InputPaymentCredentialsGooglePay: TL.InputPaymentCredentialsGooglePay,
};
const AccountTmpPassword = union(TLID) {
    AccountTmpPassword: TL.AccountTmpPassword,
};
const ShippingOption = union(TLID) {
    ShippingOption: TL.ShippingOption,
};
const InputStickerSetItem = union(TLID) {
    InputStickerSetItem: TL.InputStickerSetItem,
};
const InputPhoneCall = union(TLID) {
    InputPhoneCall: TL.InputPhoneCall,
};
const PhoneCall = union(TLID) {
    PhoneCallEmpty: TL.PhoneCallEmpty,
    PhoneCallWaiting: TL.PhoneCallWaiting,
    PhoneCallRequested: TL.PhoneCallRequested,
    PhoneCallAccepted: TL.PhoneCallAccepted,
    PhoneCall: TL.PhoneCall,
    PhoneCallDiscarded: TL.PhoneCallDiscarded,
};
const PhoneConnection = union(TLID) {
    PhoneConnection: TL.PhoneConnection,
    PhoneConnectionWebrtc: TL.PhoneConnectionWebrtc,
};
const PhoneCallProtocol = union(TLID) {
    PhoneCallProtocol: TL.PhoneCallProtocol,
};
const PhonePhoneCall = union(TLID) {
    PhonePhoneCall: TL.PhonePhoneCall,
};
const UploadCdnFile = union(TLID) {
    UploadCdnFileReuploadNeeded: TL.UploadCdnFileReuploadNeeded,
    UploadCdnFile: TL.UploadCdnFile,
};
const CdnPublicKey = union(TLID) {
    CdnPublicKey: TL.CdnPublicKey,
};
const CdnConfig = union(TLID) {
    CdnConfig: TL.CdnConfig,
};
const LangPackString = union(TLID) {
    LangPackString: TL.LangPackString,
    LangPackStringPluralized: TL.LangPackStringPluralized,
    LangPackStringDeleted: TL.LangPackStringDeleted,
};
const LangPackDifference = union(TLID) {
    LangPackDifference: TL.LangPackDifference,
};
const LangPackLanguage = union(TLID) {
    LangPackLanguage: TL.LangPackLanguage,
};
const ChannelAdminLogEventAction = union(TLID) {
    ChannelAdminLogEventActionChangeTitle: TL.ChannelAdminLogEventActionChangeTitle,
    ChannelAdminLogEventActionChangeAbout: TL.ChannelAdminLogEventActionChangeAbout,
    ChannelAdminLogEventActionChangeUsername: TL.ChannelAdminLogEventActionChangeUsername,
    ChannelAdminLogEventActionChangePhoto: TL.ChannelAdminLogEventActionChangePhoto,
    ChannelAdminLogEventActionToggleInvites: TL.ChannelAdminLogEventActionToggleInvites,
    ChannelAdminLogEventActionToggleSignatures: TL.ChannelAdminLogEventActionToggleSignatures,
    ChannelAdminLogEventActionUpdatePinned: TL.ChannelAdminLogEventActionUpdatePinned,
    ChannelAdminLogEventActionEditMessage: TL.ChannelAdminLogEventActionEditMessage,
    ChannelAdminLogEventActionDeleteMessage: TL.ChannelAdminLogEventActionDeleteMessage,
    ChannelAdminLogEventActionParticipantJoin: TL.ChannelAdminLogEventActionParticipantJoin,
    ChannelAdminLogEventActionParticipantLeave: TL.ChannelAdminLogEventActionParticipantLeave,
    ChannelAdminLogEventActionParticipantInvite: TL.ChannelAdminLogEventActionParticipantInvite,
    ChannelAdminLogEventActionParticipantToggleBan: TL.ChannelAdminLogEventActionParticipantToggleBan,
    ChannelAdminLogEventActionParticipantToggleAdmin: TL.ChannelAdminLogEventActionParticipantToggleAdmin,
    ChannelAdminLogEventActionChangeStickerSet: TL.ChannelAdminLogEventActionChangeStickerSet,
    ChannelAdminLogEventActionTogglePreHistoryHidden: TL.ChannelAdminLogEventActionTogglePreHistoryHidden,
    ChannelAdminLogEventActionDefaultBannedRights: TL.ChannelAdminLogEventActionDefaultBannedRights,
    ChannelAdminLogEventActionStopPoll: TL.ChannelAdminLogEventActionStopPoll,
    ChannelAdminLogEventActionChangeLinkedChat: TL.ChannelAdminLogEventActionChangeLinkedChat,
    ChannelAdminLogEventActionChangeLocation: TL.ChannelAdminLogEventActionChangeLocation,
    ChannelAdminLogEventActionToggleSlowMode: TL.ChannelAdminLogEventActionToggleSlowMode,
    ChannelAdminLogEventActionStartGroupCall: TL.ChannelAdminLogEventActionStartGroupCall,
    ChannelAdminLogEventActionDiscardGroupCall: TL.ChannelAdminLogEventActionDiscardGroupCall,
    ChannelAdminLogEventActionParticipantMute: TL.ChannelAdminLogEventActionParticipantMute,
    ChannelAdminLogEventActionParticipantUnmute: TL.ChannelAdminLogEventActionParticipantUnmute,
    ChannelAdminLogEventActionToggleGroupCallSetting: TL.ChannelAdminLogEventActionToggleGroupCallSetting,
    ChannelAdminLogEventActionParticipantJoinByInvite: TL.ChannelAdminLogEventActionParticipantJoinByInvite,
    ChannelAdminLogEventActionExportedInviteDelete: TL.ChannelAdminLogEventActionExportedInviteDelete,
    ChannelAdminLogEventActionExportedInviteRevoke: TL.ChannelAdminLogEventActionExportedInviteRevoke,
    ChannelAdminLogEventActionExportedInviteEdit: TL.ChannelAdminLogEventActionExportedInviteEdit,
    ChannelAdminLogEventActionParticipantVolume: TL.ChannelAdminLogEventActionParticipantVolume,
    ChannelAdminLogEventActionChangeHistoryTTL: TL.ChannelAdminLogEventActionChangeHistoryTTL,
    ChannelAdminLogEventActionParticipantJoinByRequest: TL.ChannelAdminLogEventActionParticipantJoinByRequest,
    ChannelAdminLogEventActionToggleNoForwards: TL.ChannelAdminLogEventActionToggleNoForwards,
    ChannelAdminLogEventActionSendMessage: TL.ChannelAdminLogEventActionSendMessage,
    ChannelAdminLogEventActionChangeAvailableReactions: TL.ChannelAdminLogEventActionChangeAvailableReactions,
    ChannelAdminLogEventActionChangeUsernames: TL.ChannelAdminLogEventActionChangeUsernames,
    ChannelAdminLogEventActionToggleForum: TL.ChannelAdminLogEventActionToggleForum,
    ChannelAdminLogEventActionCreateTopic: TL.ChannelAdminLogEventActionCreateTopic,
    ChannelAdminLogEventActionEditTopic: TL.ChannelAdminLogEventActionEditTopic,
    ChannelAdminLogEventActionDeleteTopic: TL.ChannelAdminLogEventActionDeleteTopic,
    ChannelAdminLogEventActionPinTopic: TL.ChannelAdminLogEventActionPinTopic,
    ChannelAdminLogEventActionToggleAntiSpam: TL.ChannelAdminLogEventActionToggleAntiSpam,
    ChannelAdminLogEventActionChangePeerColor: TL.ChannelAdminLogEventActionChangePeerColor,
    ChannelAdminLogEventActionChangeProfilePeerColor: TL.ChannelAdminLogEventActionChangeProfilePeerColor,
    ChannelAdminLogEventActionChangeWallpaper: TL.ChannelAdminLogEventActionChangeWallpaper,
    ChannelAdminLogEventActionChangeEmojiStatus: TL.ChannelAdminLogEventActionChangeEmojiStatus,
    ChannelAdminLogEventActionChangeEmojiStickerSet: TL.ChannelAdminLogEventActionChangeEmojiStickerSet,
    ChannelAdminLogEventActionToggleSignatureProfiles: TL.ChannelAdminLogEventActionToggleSignatureProfiles,
    ChannelAdminLogEventActionParticipantSubExtend: TL.ChannelAdminLogEventActionParticipantSubExtend,
};
const ChannelAdminLogEvent = union(TLID) {
    ChannelAdminLogEvent: TL.ChannelAdminLogEvent,
};
const ChannelsAdminLogResults = union(TLID) {
    ChannelsAdminLogResults: TL.ChannelsAdminLogResults,
};
const ChannelAdminLogEventsFilter = union(TLID) {
    ChannelAdminLogEventsFilter: TL.ChannelAdminLogEventsFilter,
};
const PopularContact = union(TLID) {
    PopularContact: TL.PopularContact,
};
const MessagesFavedStickers = union(TLID) {
    MessagesFavedStickersNotModified: TL.MessagesFavedStickersNotModified,
    MessagesFavedStickers: TL.MessagesFavedStickers,
};
const RecentMeUrl = union(TLID) {
    RecentMeUrlUnknown: TL.RecentMeUrlUnknown,
    RecentMeUrlUser: TL.RecentMeUrlUser,
    RecentMeUrlChat: TL.RecentMeUrlChat,
    RecentMeUrlChatInvite: TL.RecentMeUrlChatInvite,
    RecentMeUrlStickerSet: TL.RecentMeUrlStickerSet,
};
const HelpRecentMeUrls = union(TLID) {
    HelpRecentMeUrls: TL.HelpRecentMeUrls,
};
const InputSingleMedia = union(TLID) {
    InputSingleMedia: TL.InputSingleMedia,
};
const WebAuthorization = union(TLID) {
    WebAuthorization: TL.WebAuthorization,
};
const AccountWebAuthorizations = union(TLID) {
    AccountWebAuthorizations: TL.AccountWebAuthorizations,
};
const InputMessage = union(TLID) {
    InputMessageID: TL.InputMessageID,
    InputMessageReplyTo: TL.InputMessageReplyTo,
    InputMessagePinned: TL.InputMessagePinned,
    InputMessageCallbackQuery: TL.InputMessageCallbackQuery,
};
const InputDialogPeer = union(TLID) {
    InputDialogPeer: TL.InputDialogPeer,
    InputDialogPeerFolder: TL.InputDialogPeerFolder,
};
const DialogPeer = union(TLID) {
    DialogPeer: TL.DialogPeer,
    DialogPeerFolder: TL.DialogPeerFolder,
};
const MessagesFoundStickerSets = union(TLID) {
    MessagesFoundStickerSetsNotModified: TL.MessagesFoundStickerSetsNotModified,
    MessagesFoundStickerSets: TL.MessagesFoundStickerSets,
};
const FileHash = union(TLID) {
    FileHash: TL.FileHash,
};
const InputClientProxy = union(TLID) {
    InputClientProxy: TL.InputClientProxy,
};
const HelpTermsOfServiceUpdate = union(TLID) {
    HelpTermsOfServiceUpdateEmpty: TL.HelpTermsOfServiceUpdateEmpty,
    HelpTermsOfServiceUpdate: TL.HelpTermsOfServiceUpdate,
};
const InputSecureFile = union(TLID) {
    InputSecureFileUploaded: TL.InputSecureFileUploaded,
    InputSecureFile: TL.InputSecureFile,
};
const SecureFile = union(TLID) {
    SecureFileEmpty: TL.SecureFileEmpty,
    SecureFile: TL.SecureFile,
};
const SecureData = union(TLID) {
    SecureData: TL.SecureData,
};
const SecurePlainData = union(TLID) {
    SecurePlainPhone: TL.SecurePlainPhone,
    SecurePlainEmail: TL.SecurePlainEmail,
};
const SecureValueType = union(TLID) {
    SecureValueTypePersonalDetails: TL.SecureValueTypePersonalDetails,
    SecureValueTypePassport: TL.SecureValueTypePassport,
    SecureValueTypeDriverLicense: TL.SecureValueTypeDriverLicense,
    SecureValueTypeIdentityCard: TL.SecureValueTypeIdentityCard,
    SecureValueTypeInternalPassport: TL.SecureValueTypeInternalPassport,
    SecureValueTypeAddress: TL.SecureValueTypeAddress,
    SecureValueTypeUtilityBill: TL.SecureValueTypeUtilityBill,
    SecureValueTypeBankStatement: TL.SecureValueTypeBankStatement,
    SecureValueTypeRentalAgreement: TL.SecureValueTypeRentalAgreement,
    SecureValueTypePassportRegistration: TL.SecureValueTypePassportRegistration,
    SecureValueTypeTemporaryRegistration: TL.SecureValueTypeTemporaryRegistration,
    SecureValueTypePhone: TL.SecureValueTypePhone,
    SecureValueTypeEmail: TL.SecureValueTypeEmail,
};
const SecureValue = union(TLID) {
    SecureValue: TL.SecureValue,
};
const InputSecureValue = union(TLID) {
    InputSecureValue: TL.InputSecureValue,
};
const SecureValueHash = union(TLID) {
    SecureValueHash: TL.SecureValueHash,
};
const SecureValueError = union(TLID) {
    SecureValueErrorData: TL.SecureValueErrorData,
    SecureValueErrorFrontSide: TL.SecureValueErrorFrontSide,
    SecureValueErrorReverseSide: TL.SecureValueErrorReverseSide,
    SecureValueErrorSelfie: TL.SecureValueErrorSelfie,
    SecureValueErrorFile: TL.SecureValueErrorFile,
    SecureValueErrorFiles: TL.SecureValueErrorFiles,
    SecureValueError: TL.SecureValueError,
    SecureValueErrorTranslationFile: TL.SecureValueErrorTranslationFile,
    SecureValueErrorTranslationFiles: TL.SecureValueErrorTranslationFiles,
};
const SecureCredentialsEncrypted = union(TLID) {
    SecureCredentialsEncrypted: TL.SecureCredentialsEncrypted,
};
const AccountAuthorizationForm = union(TLID) {
    AccountAuthorizationForm: TL.AccountAuthorizationForm,
};
const AccountSentEmailCode = union(TLID) {
    AccountSentEmailCode: TL.AccountSentEmailCode,
};
const HelpDeepLinkInfo = union(TLID) {
    HelpDeepLinkInfoEmpty: TL.HelpDeepLinkInfoEmpty,
    HelpDeepLinkInfo: TL.HelpDeepLinkInfo,
};
const SavedContact = union(TLID) {
    SavedPhoneContact: TL.SavedPhoneContact,
};
const AccountTakeout = union(TLID) {
    AccountTakeout: TL.AccountTakeout,
};
const PasswordKdfAlgo = union(TLID) {
    PasswordKdfAlgoUnknown: TL.PasswordKdfAlgoUnknown,
    PasswordKdfAlgoSHA256SHA256PBKDF2HMACSHA512iter100000SHA256ModPow: TL.PasswordKdfAlgoSHA256SHA256PBKDF2HMACSHA512iter100000SHA256ModPow,
};
const SecurePasswordKdfAlgo = union(TLID) {
    SecurePasswordKdfAlgoUnknown: TL.SecurePasswordKdfAlgoUnknown,
    SecurePasswordKdfAlgoPBKDF2HMACSHA512iter100000: TL.SecurePasswordKdfAlgoPBKDF2HMACSHA512iter100000,
    SecurePasswordKdfAlgoSHA512: TL.SecurePasswordKdfAlgoSHA512,
};
const SecureSecretSettings = union(TLID) {
    SecureSecretSettings: TL.SecureSecretSettings,
};
const InputCheckPasswordSRP = union(TLID) {
    InputCheckPasswordEmpty: TL.InputCheckPasswordEmpty,
    InputCheckPasswordSRP: TL.InputCheckPasswordSRP,
};
const SecureRequiredType = union(TLID) {
    SecureRequiredType: TL.SecureRequiredType,
    SecureRequiredTypeOneOf: TL.SecureRequiredTypeOneOf,
};
const HelpPassportConfig = union(TLID) {
    HelpPassportConfigNotModified: TL.HelpPassportConfigNotModified,
    HelpPassportConfig: TL.HelpPassportConfig,
};
const InputAppEvent = union(TLID) {
    InputAppEvent: TL.InputAppEvent,
};
const JSONObjectValue = union(TLID) {
    JsonObjectValue: TL.JsonObjectValue,
};
const JSONValue = union(TLID) {
    JsonNull: TL.JsonNull,
    JsonBool: TL.JsonBool,
    JsonNumber: TL.JsonNumber,
    JsonString: TL.JsonString,
    JsonArray: TL.JsonArray,
    JsonObject: TL.JsonObject,
};
const PageTableCell = union(TLID) {
    PageTableCell: TL.PageTableCell,
};
const PageTableRow = union(TLID) {
    PageTableRow: TL.PageTableRow,
};
const PageCaption = union(TLID) {
    PageCaption: TL.PageCaption,
};
const PageListItem = union(TLID) {
    PageListItemText: TL.PageListItemText,
    PageListItemBlocks: TL.PageListItemBlocks,
};
const PageListOrderedItem = union(TLID) {
    PageListOrderedItemText: TL.PageListOrderedItemText,
    PageListOrderedItemBlocks: TL.PageListOrderedItemBlocks,
};
const PageRelatedArticle = union(TLID) {
    PageRelatedArticle: TL.PageRelatedArticle,
};
const Page = union(TLID) {
    Page: TL.Page,
};
const HelpSupportName = union(TLID) {
    HelpSupportName: TL.HelpSupportName,
};
const HelpUserInfo = union(TLID) {
    HelpUserInfoEmpty: TL.HelpUserInfoEmpty,
    HelpUserInfo: TL.HelpUserInfo,
};
const PollAnswer = union(TLID) {
    PollAnswer: TL.PollAnswer,
};
const Poll = union(TLID) {
    Poll: TL.Poll,
};
const PollAnswerVoters = union(TLID) {
    PollAnswerVoters: TL.PollAnswerVoters,
};
const PollResults = union(TLID) {
    PollResults: TL.PollResults,
};
const ChatOnlines = union(TLID) {
    ChatOnlines: TL.ChatOnlines,
};
const StatsURL = union(TLID) {
    StatsURL: TL.StatsURL,
};
const ChatAdminRights = union(TLID) {
    ChatAdminRights: TL.ChatAdminRights,
};
const ChatBannedRights = union(TLID) {
    ChatBannedRights: TL.ChatBannedRights,
};
const InputWallPaper = union(TLID) {
    InputWallPaper: TL.InputWallPaper,
    InputWallPaperSlug: TL.InputWallPaperSlug,
    InputWallPaperNoFile: TL.InputWallPaperNoFile,
};
const AccountWallPapers = union(TLID) {
    AccountWallPapersNotModified: TL.AccountWallPapersNotModified,
    AccountWallPapers: TL.AccountWallPapers,
};
const CodeSettings = union(TLID) {
    CodeSettings: TL.CodeSettings,
};
const WallPaperSettings = union(TLID) {
    WallPaperSettings: TL.WallPaperSettings,
};
const AutoDownloadSettings = union(TLID) {
    AutoDownloadSettings: TL.AutoDownloadSettings,
};
const AccountAutoDownloadSettings = union(TLID) {
    AccountAutoDownloadSettings: TL.AccountAutoDownloadSettings,
};
const EmojiKeyword = union(TLID) {
    EmojiKeyword: TL.EmojiKeyword,
    EmojiKeywordDeleted: TL.EmojiKeywordDeleted,
};
const EmojiKeywordsDifference = union(TLID) {
    EmojiKeywordsDifference: TL.EmojiKeywordsDifference,
};
const EmojiURL = union(TLID) {
    EmojiURL: TL.EmojiURL,
};
const EmojiLanguage = union(TLID) {
    EmojiLanguage: TL.EmojiLanguage,
};
const Folder = union(TLID) {
    Folder: TL.Folder,
};
const InputFolderPeer = union(TLID) {
    InputFolderPeer: TL.InputFolderPeer,
};
const FolderPeer = union(TLID) {
    FolderPeer: TL.FolderPeer,
};
const MessagesSearchCounter = union(TLID) {
    MessagesSearchCounter: TL.MessagesSearchCounter,
};
const UrlAuthResult = union(TLID) {
    UrlAuthResultRequest: TL.UrlAuthResultRequest,
    UrlAuthResultAccepted: TL.UrlAuthResultAccepted,
    UrlAuthResultDefault: TL.UrlAuthResultDefault,
};
const ChannelLocation = union(TLID) {
    ChannelLocationEmpty: TL.ChannelLocationEmpty,
    ChannelLocation: TL.ChannelLocation,
};
const PeerLocated = union(TLID) {
    PeerLocated: TL.PeerLocated,
    PeerSelfLocated: TL.PeerSelfLocated,
};
const RestrictionReason = union(TLID) {
    RestrictionReason: TL.RestrictionReason,
};
const InputTheme = union(TLID) {
    InputTheme: TL.InputTheme,
    InputThemeSlug: TL.InputThemeSlug,
};
const Theme = union(TLID) {
    Theme: TL.Theme,
};
const AccountThemes = union(TLID) {
    AccountThemesNotModified: TL.AccountThemesNotModified,
    AccountThemes: TL.AccountThemes,
};
const AuthLoginToken = union(TLID) {
    AuthLoginToken: TL.AuthLoginToken,
    AuthLoginTokenMigrateTo: TL.AuthLoginTokenMigrateTo,
    AuthLoginTokenSuccess: TL.AuthLoginTokenSuccess,
};
const AccountContentSettings = union(TLID) {
    AccountContentSettings: TL.AccountContentSettings,
};
const MessagesInactiveChats = union(TLID) {
    MessagesInactiveChats: TL.MessagesInactiveChats,
};
const BaseTheme = union(TLID) {
    BaseThemeClassic: TL.BaseThemeClassic,
    BaseThemeDay: TL.BaseThemeDay,
    BaseThemeNight: TL.BaseThemeNight,
    BaseThemeTinted: TL.BaseThemeTinted,
    BaseThemeArctic: TL.BaseThemeArctic,
};
const InputThemeSettings = union(TLID) {
    InputThemeSettings: TL.InputThemeSettings,
};
const ThemeSettings = union(TLID) {
    ThemeSettings: TL.ThemeSettings,
};
const WebPageAttribute = union(TLID) {
    WebPageAttributeTheme: TL.WebPageAttributeTheme,
    WebPageAttributeStory: TL.WebPageAttributeStory,
    WebPageAttributeStickerSet: TL.WebPageAttributeStickerSet,
};
const MessagesVotesList = union(TLID) {
    MessagesVotesList: TL.MessagesVotesList,
};
const BankCardOpenUrl = union(TLID) {
    BankCardOpenUrl: TL.BankCardOpenUrl,
};
const PaymentsBankCardData = union(TLID) {
    PaymentsBankCardData: TL.PaymentsBankCardData,
};
const DialogFilter = union(TLID) {
    DialogFilter: TL.DialogFilter,
    DialogFilterDefault: TL.DialogFilterDefault,
    DialogFilterChatlist: TL.DialogFilterChatlist,
};
const DialogFilterSuggested = union(TLID) {
    DialogFilterSuggested: TL.DialogFilterSuggested,
};
const StatsDateRangeDays = union(TLID) {
    StatsDateRangeDays: TL.StatsDateRangeDays,
};
const StatsAbsValueAndPrev = union(TLID) {
    StatsAbsValueAndPrev: TL.StatsAbsValueAndPrev,
};
const StatsPercentValue = union(TLID) {
    StatsPercentValue: TL.StatsPercentValue,
};
const StatsGraph = union(TLID) {
    StatsGraphAsync: TL.StatsGraphAsync,
    StatsGraphError: TL.StatsGraphError,
    StatsGraph: TL.StatsGraph,
};
const StatsBroadcastStats = union(TLID) {
    StatsBroadcastStats: TL.StatsBroadcastStats,
};
const HelpPromoData = union(TLID) {
    HelpPromoDataEmpty: TL.HelpPromoDataEmpty,
    HelpPromoData: TL.HelpPromoData,
};
const VideoSize = union(TLID) {
    VideoSize: TL.VideoSize,
    VideoSizeEmojiMarkup: TL.VideoSizeEmojiMarkup,
    VideoSizeStickerMarkup: TL.VideoSizeStickerMarkup,
};
const StatsGroupTopPoster = union(TLID) {
    StatsGroupTopPoster: TL.StatsGroupTopPoster,
};
const StatsGroupTopAdmin = union(TLID) {
    StatsGroupTopAdmin: TL.StatsGroupTopAdmin,
};
const StatsGroupTopInviter = union(TLID) {
    StatsGroupTopInviter: TL.StatsGroupTopInviter,
};
const StatsMegagroupStats = union(TLID) {
    StatsMegagroupStats: TL.StatsMegagroupStats,
};
const GlobalPrivacySettings = union(TLID) {
    GlobalPrivacySettings: TL.GlobalPrivacySettings,
};
const HelpCountryCode = union(TLID) {
    HelpCountryCode: TL.HelpCountryCode,
};
const HelpCountry = union(TLID) {
    HelpCountry: TL.HelpCountry,
};
const HelpCountriesList = union(TLID) {
    HelpCountriesListNotModified: TL.HelpCountriesListNotModified,
    HelpCountriesList: TL.HelpCountriesList,
};
const MessageViews = union(TLID) {
    MessageViews: TL.MessageViews,
};
const MessagesMessageViews = union(TLID) {
    MessagesMessageViews: TL.MessagesMessageViews,
};
const MessagesDiscussionMessage = union(TLID) {
    MessagesDiscussionMessage: TL.MessagesDiscussionMessage,
};
const MessageReplyHeader = union(TLID) {
    MessageReplyHeader: TL.MessageReplyHeader,
    MessageReplyStoryHeader: TL.MessageReplyStoryHeader,
};
const MessageReplies = union(TLID) {
    MessageReplies: TL.MessageReplies,
};
const PeerBlocked = union(TLID) {
    PeerBlocked: TL.PeerBlocked,
};
const StatsMessageStats = union(TLID) {
    StatsMessageStats: TL.StatsMessageStats,
};
const GroupCall = union(TLID) {
    GroupCallDiscarded: TL.GroupCallDiscarded,
    GroupCall: TL.GroupCall,
};
const InputGroupCall = union(TLID) {
    InputGroupCall: TL.InputGroupCall,
};
const GroupCallParticipant = union(TLID) {
    GroupCallParticipant: TL.GroupCallParticipant,
};
const PhoneGroupCall = union(TLID) {
    PhoneGroupCall: TL.PhoneGroupCall,
};
const PhoneGroupParticipants = union(TLID) {
    PhoneGroupParticipants: TL.PhoneGroupParticipants,
};
const InlineQueryPeerType = union(TLID) {
    InlineQueryPeerTypeSameBotPM: TL.InlineQueryPeerTypeSameBotPM,
    InlineQueryPeerTypePM: TL.InlineQueryPeerTypePM,
    InlineQueryPeerTypeChat: TL.InlineQueryPeerTypeChat,
    InlineQueryPeerTypeMegagroup: TL.InlineQueryPeerTypeMegagroup,
    InlineQueryPeerTypeBroadcast: TL.InlineQueryPeerTypeBroadcast,
    InlineQueryPeerTypeBotPM: TL.InlineQueryPeerTypeBotPM,
};
const MessagesHistoryImport = union(TLID) {
    MessagesHistoryImport: TL.MessagesHistoryImport,
};
const MessagesHistoryImportParsed = union(TLID) {
    MessagesHistoryImportParsed: TL.MessagesHistoryImportParsed,
};
const MessagesAffectedFoundMessages = union(TLID) {
    MessagesAffectedFoundMessages: TL.MessagesAffectedFoundMessages,
};
const ChatInviteImporter = union(TLID) {
    ChatInviteImporter: TL.ChatInviteImporter,
};
const MessagesExportedChatInvites = union(TLID) {
    MessagesExportedChatInvites: TL.MessagesExportedChatInvites,
};
const MessagesExportedChatInvite = union(TLID) {
    MessagesExportedChatInvite: TL.MessagesExportedChatInvite,
    MessagesExportedChatInviteReplaced: TL.MessagesExportedChatInviteReplaced,
};
const MessagesChatInviteImporters = union(TLID) {
    MessagesChatInviteImporters: TL.MessagesChatInviteImporters,
};
const ChatAdminWithInvites = union(TLID) {
    ChatAdminWithInvites: TL.ChatAdminWithInvites,
};
const MessagesChatAdminsWithInvites = union(TLID) {
    MessagesChatAdminsWithInvites: TL.MessagesChatAdminsWithInvites,
};
const MessagesCheckedHistoryImportPeer = union(TLID) {
    MessagesCheckedHistoryImportPeer: TL.MessagesCheckedHistoryImportPeer,
};
const PhoneJoinAsPeers = union(TLID) {
    PhoneJoinAsPeers: TL.PhoneJoinAsPeers,
};
const PhoneExportedGroupCallInvite = union(TLID) {
    PhoneExportedGroupCallInvite: TL.PhoneExportedGroupCallInvite,
};
const GroupCallParticipantVideoSourceGroup = union(TLID) {
    GroupCallParticipantVideoSourceGroup: TL.GroupCallParticipantVideoSourceGroup,
};
const GroupCallParticipantVideo = union(TLID) {
    GroupCallParticipantVideo: TL.GroupCallParticipantVideo,
};
const StickersSuggestedShortName = union(TLID) {
    StickersSuggestedShortName: TL.StickersSuggestedShortName,
};
const BotCommandScope = union(TLID) {
    BotCommandScopeDefault: TL.BotCommandScopeDefault,
    BotCommandScopeUsers: TL.BotCommandScopeUsers,
    BotCommandScopeChats: TL.BotCommandScopeChats,
    BotCommandScopeChatAdmins: TL.BotCommandScopeChatAdmins,
    BotCommandScopePeer: TL.BotCommandScopePeer,
    BotCommandScopePeerAdmins: TL.BotCommandScopePeerAdmins,
    BotCommandScopePeerUser: TL.BotCommandScopePeerUser,
};
const AccountResetPasswordResult = union(TLID) {
    AccountResetPasswordFailedWait: TL.AccountResetPasswordFailedWait,
    AccountResetPasswordRequestedWait: TL.AccountResetPasswordRequestedWait,
    AccountResetPasswordOk: TL.AccountResetPasswordOk,
};
const SponsoredMessage = union(TLID) {
    SponsoredMessage: TL.SponsoredMessage,
};
const MessagesSponsoredMessages = union(TLID) {
    MessagesSponsoredMessages: TL.MessagesSponsoredMessages,
    MessagesSponsoredMessagesEmpty: TL.MessagesSponsoredMessagesEmpty,
};
const SearchResultsCalendarPeriod = union(TLID) {
    SearchResultsCalendarPeriod: TL.SearchResultsCalendarPeriod,
};
const MessagesSearchResultsCalendar = union(TLID) {
    MessagesSearchResultsCalendar: TL.MessagesSearchResultsCalendar,
};
const SearchResultsPosition = union(TLID) {
    SearchResultPosition: TL.SearchResultPosition,
};
const MessagesSearchResultsPositions = union(TLID) {
    MessagesSearchResultsPositions: TL.MessagesSearchResultsPositions,
};
const ChannelsSendAsPeers = union(TLID) {
    ChannelsSendAsPeers: TL.ChannelsSendAsPeers,
};
const UsersUserFull = union(TLID) {
    UsersUserFull: TL.UsersUserFull,
};
const MessagesPeerSettings = union(TLID) {
    MessagesPeerSettings: TL.MessagesPeerSettings,
};
const AuthLoggedOut = union(TLID) {
    AuthLoggedOut: TL.AuthLoggedOut,
};
const ReactionCount = union(TLID) {
    ReactionCount: TL.ReactionCount,
};
const MessageReactions = union(TLID) {
    MessageReactions: TL.MessageReactions,
};
const MessagesMessageReactionsList = union(TLID) {
    MessagesMessageReactionsList: TL.MessagesMessageReactionsList,
};
const AvailableReaction = union(TLID) {
    AvailableReaction: TL.AvailableReaction,
};
const MessagesAvailableReactions = union(TLID) {
    MessagesAvailableReactionsNotModified: TL.MessagesAvailableReactionsNotModified,
    MessagesAvailableReactions: TL.MessagesAvailableReactions,
};
const MessagePeerReaction = union(TLID) {
    MessagePeerReaction: TL.MessagePeerReaction,
};
const GroupCallStreamChannel = union(TLID) {
    GroupCallStreamChannel: TL.GroupCallStreamChannel,
};
const PhoneGroupCallStreamChannels = union(TLID) {
    PhoneGroupCallStreamChannels: TL.PhoneGroupCallStreamChannels,
};
const PhoneGroupCallStreamRtmpUrl = union(TLID) {
    PhoneGroupCallStreamRtmpUrl: TL.PhoneGroupCallStreamRtmpUrl,
};
const AttachMenuBotIconColor = union(TLID) {
    AttachMenuBotIconColor: TL.AttachMenuBotIconColor,
};
const AttachMenuBotIcon = union(TLID) {
    AttachMenuBotIcon: TL.AttachMenuBotIcon,
};
const AttachMenuBot = union(TLID) {
    AttachMenuBot: TL.AttachMenuBot,
};
const AttachMenuBots = union(TLID) {
    AttachMenuBotsNotModified: TL.AttachMenuBotsNotModified,
    AttachMenuBots: TL.AttachMenuBots,
};
const AttachMenuBotsBot = union(TLID) {
    AttachMenuBotsBot: TL.AttachMenuBotsBot,
};
const WebViewResult = union(TLID) {
    WebViewResultUrl: TL.WebViewResultUrl,
};
const WebViewMessageSent = union(TLID) {
    WebViewMessageSent: TL.WebViewMessageSent,
};
const BotMenuButton = union(TLID) {
    BotMenuButtonDefault: TL.BotMenuButtonDefault,
    BotMenuButtonCommands: TL.BotMenuButtonCommands,
    BotMenuButton: TL.BotMenuButton,
};
const AccountSavedRingtones = union(TLID) {
    AccountSavedRingtonesNotModified: TL.AccountSavedRingtonesNotModified,
    AccountSavedRingtones: TL.AccountSavedRingtones,
};
const NotificationSound = union(TLID) {
    NotificationSoundDefault: TL.NotificationSoundDefault,
    NotificationSoundNone: TL.NotificationSoundNone,
    NotificationSoundLocal: TL.NotificationSoundLocal,
    NotificationSoundRingtone: TL.NotificationSoundRingtone,
};
const AccountSavedRingtone = union(TLID) {
    AccountSavedRingtone: TL.AccountSavedRingtone,
    AccountSavedRingtoneConverted: TL.AccountSavedRingtoneConverted,
};
const AttachMenuPeerType = union(TLID) {
    AttachMenuPeerTypeSameBotPM: TL.AttachMenuPeerTypeSameBotPM,
    AttachMenuPeerTypeBotPM: TL.AttachMenuPeerTypeBotPM,
    AttachMenuPeerTypePM: TL.AttachMenuPeerTypePM,
    AttachMenuPeerTypeChat: TL.AttachMenuPeerTypeChat,
    AttachMenuPeerTypeBroadcast: TL.AttachMenuPeerTypeBroadcast,
};
const InputInvoice = union(TLID) {
    InputInvoiceMessage: TL.InputInvoiceMessage,
    InputInvoiceSlug: TL.InputInvoiceSlug,
    InputInvoicePremiumGiftCode: TL.InputInvoicePremiumGiftCode,
    InputInvoiceStars: TL.InputInvoiceStars,
    InputInvoiceChatInviteSubscription: TL.InputInvoiceChatInviteSubscription,
    InputInvoiceStarGift: TL.InputInvoiceStarGift,
};
const PaymentsExportedInvoice = union(TLID) {
    PaymentsExportedInvoice: TL.PaymentsExportedInvoice,
};
const MessagesTranscribedAudio = union(TLID) {
    MessagesTranscribedAudio: TL.MessagesTranscribedAudio,
};
const HelpPremiumPromo = union(TLID) {
    HelpPremiumPromo: TL.HelpPremiumPromo,
};
const InputStorePaymentPurpose = union(TLID) {
    InputStorePaymentPremiumSubscription: TL.InputStorePaymentPremiumSubscription,
    InputStorePaymentGiftPremium: TL.InputStorePaymentGiftPremium,
    InputStorePaymentPremiumGiftCode: TL.InputStorePaymentPremiumGiftCode,
    InputStorePaymentPremiumGiveaway: TL.InputStorePaymentPremiumGiveaway,
    InputStorePaymentStarsTopup: TL.InputStorePaymentStarsTopup,
    InputStorePaymentStarsGift: TL.InputStorePaymentStarsGift,
    InputStorePaymentStarsGiveaway: TL.InputStorePaymentStarsGiveaway,
};
const PremiumGiftOption = union(TLID) {
    PremiumGiftOption: TL.PremiumGiftOption,
};
const PaymentFormMethod = union(TLID) {
    PaymentFormMethod: TL.PaymentFormMethod,
};
const EmojiStatus = union(TLID) {
    EmojiStatusEmpty: TL.EmojiStatusEmpty,
    EmojiStatus: TL.EmojiStatus,
    EmojiStatusUntil: TL.EmojiStatusUntil,
};
const AccountEmojiStatuses = union(TLID) {
    AccountEmojiStatusesNotModified: TL.AccountEmojiStatusesNotModified,
    AccountEmojiStatuses: TL.AccountEmojiStatuses,
};
const Reaction = union(TLID) {
    ReactionEmpty: TL.ReactionEmpty,
    ReactionEmoji: TL.ReactionEmoji,
    ReactionCustomEmoji: TL.ReactionCustomEmoji,
    ReactionPaid: TL.ReactionPaid,
};
const ChatReactions = union(TLID) {
    ChatReactionsNone: TL.ChatReactionsNone,
    ChatReactionsAll: TL.ChatReactionsAll,
    ChatReactionsSome: TL.ChatReactionsSome,
};
const MessagesReactions = union(TLID) {
    MessagesReactionsNotModified: TL.MessagesReactionsNotModified,
    MessagesReactions: TL.MessagesReactions,
};
const EmailVerifyPurpose = union(TLID) {
    EmailVerifyPurposeLoginSetup: TL.EmailVerifyPurposeLoginSetup,
    EmailVerifyPurposeLoginChange: TL.EmailVerifyPurposeLoginChange,
    EmailVerifyPurposePassport: TL.EmailVerifyPurposePassport,
};
const EmailVerification = union(TLID) {
    EmailVerificationCode: TL.EmailVerificationCode,
    EmailVerificationGoogle: TL.EmailVerificationGoogle,
    EmailVerificationApple: TL.EmailVerificationApple,
};
const AccountEmailVerified = union(TLID) {
    AccountEmailVerified: TL.AccountEmailVerified,
    AccountEmailVerifiedLogin: TL.AccountEmailVerifiedLogin,
};
const PremiumSubscriptionOption = union(TLID) {
    PremiumSubscriptionOption: TL.PremiumSubscriptionOption,
};
const SendAsPeer = union(TLID) {
    SendAsPeer: TL.SendAsPeer,
};
const MessageExtendedMedia = union(TLID) {
    MessageExtendedMediaPreview: TL.MessageExtendedMediaPreview,
    MessageExtendedMedia: TL.MessageExtendedMedia,
};
const StickerKeyword = union(TLID) {
    StickerKeyword: TL.StickerKeyword,
};
const Username = union(TLID) {
    Username: TL.Username,
};
const ForumTopic = union(TLID) {
    ForumTopicDeleted: TL.ForumTopicDeleted,
    ForumTopic: TL.ForumTopic,
};
const MessagesForumTopics = union(TLID) {
    MessagesForumTopics: TL.MessagesForumTopics,
};
const DefaultHistoryTTL = union(TLID) {
    DefaultHistoryTTL: TL.DefaultHistoryTTL,
};
const ExportedContactToken = union(TLID) {
    ExportedContactToken: TL.ExportedContactToken,
};
const RequestPeerType = union(TLID) {
    RequestPeerTypeUser: TL.RequestPeerTypeUser,
    RequestPeerTypeChat: TL.RequestPeerTypeChat,
    RequestPeerTypeBroadcast: TL.RequestPeerTypeBroadcast,
};
const EmojiList = union(TLID) {
    EmojiListNotModified: TL.EmojiListNotModified,
    EmojiList: TL.EmojiList,
};
const EmojiGroup = union(TLID) {
    EmojiGroup: TL.EmojiGroup,
    EmojiGroupGreeting: TL.EmojiGroupGreeting,
    EmojiGroupPremium: TL.EmojiGroupPremium,
};
const MessagesEmojiGroups = union(TLID) {
    MessagesEmojiGroupsNotModified: TL.MessagesEmojiGroupsNotModified,
    MessagesEmojiGroups: TL.MessagesEmojiGroups,
};
const TextWithEntities = union(TLID) {
    TextWithEntities: TL.TextWithEntities,
};
const MessagesTranslatedText = union(TLID) {
    MessagesTranslateResult: TL.MessagesTranslateResult,
};
const AutoSaveSettings = union(TLID) {
    AutoSaveSettings: TL.AutoSaveSettings,
};
const AutoSaveException = union(TLID) {
    AutoSaveException: TL.AutoSaveException,
};
const AccountAutoSaveSettings = union(TLID) {
    AccountAutoSaveSettings: TL.AccountAutoSaveSettings,
};
const HelpAppConfig = union(TLID) {
    HelpAppConfigNotModified: TL.HelpAppConfigNotModified,
    HelpAppConfig: TL.HelpAppConfig,
};
const InputBotApp = union(TLID) {
    InputBotAppID: TL.InputBotAppID,
    InputBotAppShortName: TL.InputBotAppShortName,
};
const BotApp = union(TLID) {
    BotAppNotModified: TL.BotAppNotModified,
    BotApp: TL.BotApp,
};
const MessagesBotApp = union(TLID) {
    MessagesBotApp: TL.MessagesBotApp,
};
const InlineBotWebView = union(TLID) {
    InlineBotWebView: TL.InlineBotWebView,
};
const ReadParticipantDate = union(TLID) {
    ReadParticipantDate: TL.ReadParticipantDate,
};
const InputChatlist = union(TLID) {
    InputChatlistDialogFilter: TL.InputChatlistDialogFilter,
};
const ExportedChatlistInvite = union(TLID) {
    ExportedChatlistInvite: TL.ExportedChatlistInvite,
};
const ChatlistsExportedChatlistInvite = union(TLID) {
    ChatlistsExportedChatlistInvite: TL.ChatlistsExportedChatlistInvite,
};
const ChatlistsExportedInvites = union(TLID) {
    ChatlistsExportedInvites: TL.ChatlistsExportedInvites,
};
const ChatlistsChatlistInvite = union(TLID) {
    ChatlistsChatlistInviteAlready: TL.ChatlistsChatlistInviteAlready,
    ChatlistsChatlistInvite: TL.ChatlistsChatlistInvite,
};
const ChatlistsChatlistUpdates = union(TLID) {
    ChatlistsChatlistUpdates: TL.ChatlistsChatlistUpdates,
};
const BotsBotInfo = union(TLID) {
    BotsBotInfo: TL.BotsBotInfo,
};
const MessagePeerVote = union(TLID) {
    MessagePeerVote: TL.MessagePeerVote,
    MessagePeerVoteInputOption: TL.MessagePeerVoteInputOption,
    MessagePeerVoteMultiple: TL.MessagePeerVoteMultiple,
};
const StoryViews = union(TLID) {
    StoryViews: TL.StoryViews,
};
const StoryItem = union(TLID) {
    StoryItemDeleted: TL.StoryItemDeleted,
    StoryItemSkipped: TL.StoryItemSkipped,
    StoryItem: TL.StoryItem,
};
const StoriesAllStories = union(TLID) {
    StoriesAllStoriesNotModified: TL.StoriesAllStoriesNotModified,
    StoriesAllStories: TL.StoriesAllStories,
};
const StoriesStories = union(TLID) {
    StoriesStories: TL.StoriesStories,
};
const StoryView = union(TLID) {
    StoryView: TL.StoryView,
    StoryViewPublicForward: TL.StoryViewPublicForward,
    StoryViewPublicRepost: TL.StoryViewPublicRepost,
};
const StoriesStoryViewsList = union(TLID) {
    StoriesStoryViewsList: TL.StoriesStoryViewsList,
};
const StoriesStoryViews = union(TLID) {
    StoriesStoryViews: TL.StoriesStoryViews,
};
const InputReplyTo = union(TLID) {
    InputReplyToMessage: TL.InputReplyToMessage,
    InputReplyToStory: TL.InputReplyToStory,
};
const ExportedStoryLink = union(TLID) {
    ExportedStoryLink: TL.ExportedStoryLink,
};
const StoriesStealthMode = union(TLID) {
    StoriesStealthMode: TL.StoriesStealthMode,
};
const MediaAreaCoordinates = union(TLID) {
    MediaAreaCoordinates: TL.MediaAreaCoordinates,
};
const MediaArea = union(TLID) {
    MediaAreaVenue: TL.MediaAreaVenue,
    InputMediaAreaVenue: TL.InputMediaAreaVenue,
    MediaAreaGeoPoint: TL.MediaAreaGeoPoint,
    MediaAreaSuggestedReaction: TL.MediaAreaSuggestedReaction,
    MediaAreaChannelPost: TL.MediaAreaChannelPost,
    InputMediaAreaChannelPost: TL.InputMediaAreaChannelPost,
    MediaAreaUrl: TL.MediaAreaUrl,
    MediaAreaWeather: TL.MediaAreaWeather,
};
const PeerStories = union(TLID) {
    PeerStories: TL.PeerStories,
};
const StoriesPeerStories = union(TLID) {
    StoriesPeerStories: TL.StoriesPeerStories,
};
const MessagesWebPage = union(TLID) {
    MessagesWebPage: TL.MessagesWebPage,
};
const PremiumGiftCodeOption = union(TLID) {
    PremiumGiftCodeOption: TL.PremiumGiftCodeOption,
};
const PaymentsCheckedGiftCode = union(TLID) {
    PaymentsCheckedGiftCode: TL.PaymentsCheckedGiftCode,
};
const PaymentsGiveawayInfo = union(TLID) {
    PaymentsGiveawayInfo: TL.PaymentsGiveawayInfo,
    PaymentsGiveawayInfoResults: TL.PaymentsGiveawayInfoResults,
};
const PrepaidGiveaway = union(TLID) {
    PrepaidGiveaway: TL.PrepaidGiveaway,
    PrepaidStarsGiveaway: TL.PrepaidStarsGiveaway,
};
const Boost = union(TLID) {
    Boost: TL.Boost,
};
const PremiumBoostsList = union(TLID) {
    PremiumBoostsList: TL.PremiumBoostsList,
};
const MyBoost = union(TLID) {
    MyBoost: TL.MyBoost,
};
const PremiumMyBoosts = union(TLID) {
    PremiumMyBoosts: TL.PremiumMyBoosts,
};
const PremiumBoostsStatus = union(TLID) {
    PremiumBoostsStatus: TL.PremiumBoostsStatus,
};
const StoryFwdHeader = union(TLID) {
    StoryFwdHeader: TL.StoryFwdHeader,
};
const PostInteractionCounters = union(TLID) {
    PostInteractionCountersMessage: TL.PostInteractionCountersMessage,
    PostInteractionCountersStory: TL.PostInteractionCountersStory,
};
const StatsStoryStats = union(TLID) {
    StatsStoryStats: TL.StatsStoryStats,
};
const PublicForward = union(TLID) {
    PublicForwardMessage: TL.PublicForwardMessage,
    PublicForwardStory: TL.PublicForwardStory,
};
const StatsPublicForwards = union(TLID) {
    StatsPublicForwards: TL.StatsPublicForwards,
};
const PeerColor = union(TLID) {
    PeerColor: TL.PeerColor,
};
const HelpPeerColorSet = union(TLID) {
    HelpPeerColorSet: TL.HelpPeerColorSet,
    HelpPeerColorProfileSet: TL.HelpPeerColorProfileSet,
};
const HelpPeerColorOption = union(TLID) {
    HelpPeerColorOption: TL.HelpPeerColorOption,
};
const HelpPeerColors = union(TLID) {
    HelpPeerColorsNotModified: TL.HelpPeerColorsNotModified,
    HelpPeerColors: TL.HelpPeerColors,
};
const StoryReaction = union(TLID) {
    StoryReaction: TL.StoryReaction,
    StoryReactionPublicForward: TL.StoryReactionPublicForward,
    StoryReactionPublicRepost: TL.StoryReactionPublicRepost,
};
const StoriesStoryReactionsList = union(TLID) {
    StoriesStoryReactionsList: TL.StoriesStoryReactionsList,
};
const SavedDialog = union(TLID) {
    SavedDialog: TL.SavedDialog,
};
const MessagesSavedDialogs = union(TLID) {
    MessagesSavedDialogs: TL.MessagesSavedDialogs,
    MessagesSavedDialogsSlice: TL.MessagesSavedDialogsSlice,
    MessagesSavedDialogsNotModified: TL.MessagesSavedDialogsNotModified,
};
const SavedReactionTag = union(TLID) {
    SavedReactionTag: TL.SavedReactionTag,
};
const MessagesSavedReactionTags = union(TLID) {
    MessagesSavedReactionTagsNotModified: TL.MessagesSavedReactionTagsNotModified,
    MessagesSavedReactionTags: TL.MessagesSavedReactionTags,
};
const OutboxReadDate = union(TLID) {
    OutboxReadDate: TL.OutboxReadDate,
};
const SmsjobsEligibilityToJoin = union(TLID) {
    SmsjobsEligibleToJoin: TL.SmsjobsEligibleToJoin,
};
const SmsjobsStatus = union(TLID) {
    SmsjobsStatus: TL.SmsjobsStatus,
};
const SmsJob = union(TLID) {
    SmsJob: TL.SmsJob,
};
const BusinessWeeklyOpen = union(TLID) {
    BusinessWeeklyOpen: TL.BusinessWeeklyOpen,
};
const BusinessWorkHours = union(TLID) {
    BusinessWorkHours: TL.BusinessWorkHours,
};
const BusinessLocation = union(TLID) {
    BusinessLocation: TL.BusinessLocation,
};
const InputBusinessRecipients = union(TLID) {
    InputBusinessRecipients: TL.InputBusinessRecipients,
};
const BusinessRecipients = union(TLID) {
    BusinessRecipients: TL.BusinessRecipients,
};
const BusinessAwayMessageSchedule = union(TLID) {
    BusinessAwayMessageScheduleAlways: TL.BusinessAwayMessageScheduleAlways,
    BusinessAwayMessageScheduleOutsideWorkHours: TL.BusinessAwayMessageScheduleOutsideWorkHours,
    BusinessAwayMessageScheduleCustom: TL.BusinessAwayMessageScheduleCustom,
};
const InputBusinessGreetingMessage = union(TLID) {
    InputBusinessGreetingMessage: TL.InputBusinessGreetingMessage,
};
const BusinessGreetingMessage = union(TLID) {
    BusinessGreetingMessage: TL.BusinessGreetingMessage,
};
const InputBusinessAwayMessage = union(TLID) {
    InputBusinessAwayMessage: TL.InputBusinessAwayMessage,
};
const BusinessAwayMessage = union(TLID) {
    BusinessAwayMessage: TL.BusinessAwayMessage,
};
const Timezone = union(TLID) {
    Timezone: TL.Timezone,
};
const HelpTimezonesList = union(TLID) {
    HelpTimezonesListNotModified: TL.HelpTimezonesListNotModified,
    HelpTimezonesList: TL.HelpTimezonesList,
};
const QuickReply = union(TLID) {
    QuickReply: TL.QuickReply,
};
const InputQuickReplyShortcut = union(TLID) {
    InputQuickReplyShortcut: TL.InputQuickReplyShortcut,
    InputQuickReplyShortcutId: TL.InputQuickReplyShortcutId,
};
const MessagesQuickReplies = union(TLID) {
    MessagesQuickReplies: TL.MessagesQuickReplies,
    MessagesQuickRepliesNotModified: TL.MessagesQuickRepliesNotModified,
};
const ConnectedBot = union(TLID) {
    ConnectedBot: TL.ConnectedBot,
};
const AccountConnectedBots = union(TLID) {
    AccountConnectedBots: TL.AccountConnectedBots,
};
const MessagesDialogFilters = union(TLID) {
    MessagesDialogFilters: TL.MessagesDialogFilters,
};
const Birthday = union(TLID) {
    Birthday: TL.Birthday,
};
const BotBusinessConnection = union(TLID) {
    BotBusinessConnection: TL.BotBusinessConnection,
};
const InputBusinessIntro = union(TLID) {
    InputBusinessIntro: TL.InputBusinessIntro,
};
const BusinessIntro = union(TLID) {
    BusinessIntro: TL.BusinessIntro,
};
const MessagesMyStickers = union(TLID) {
    MessagesMyStickers: TL.MessagesMyStickers,
};
const InputCollectible = union(TLID) {
    InputCollectibleUsername: TL.InputCollectibleUsername,
    InputCollectiblePhone: TL.InputCollectiblePhone,
};
const FragmentCollectibleInfo = union(TLID) {
    FragmentCollectibleInfo: TL.FragmentCollectibleInfo,
};
const InputBusinessBotRecipients = union(TLID) {
    InputBusinessBotRecipients: TL.InputBusinessBotRecipients,
};
const BusinessBotRecipients = union(TLID) {
    BusinessBotRecipients: TL.BusinessBotRecipients,
};
const ContactBirthday = union(TLID) {
    ContactBirthday: TL.ContactBirthday,
};
const ContactsContactBirthdays = union(TLID) {
    ContactsContactBirthdays: TL.ContactsContactBirthdays,
};
const MissingInvitee = union(TLID) {
    MissingInvitee: TL.MissingInvitee,
};
const MessagesInvitedUsers = union(TLID) {
    MessagesInvitedUsers: TL.MessagesInvitedUsers,
};
const InputBusinessChatLink = union(TLID) {
    InputBusinessChatLink: TL.InputBusinessChatLink,
};
const BusinessChatLink = union(TLID) {
    BusinessChatLink: TL.BusinessChatLink,
};
const AccountBusinessChatLinks = union(TLID) {
    AccountBusinessChatLinks: TL.AccountBusinessChatLinks,
};
const AccountResolvedBusinessChatLinks = union(TLID) {
    AccountResolvedBusinessChatLinks: TL.AccountResolvedBusinessChatLinks,
};
const RequestedPeer = union(TLID) {
    RequestedPeerUser: TL.RequestedPeerUser,
    RequestedPeerChat: TL.RequestedPeerChat,
    RequestedPeerChannel: TL.RequestedPeerChannel,
};
const SponsoredMessageReportOption = union(TLID) {
    SponsoredMessageReportOption: TL.SponsoredMessageReportOption,
};
const ChannelsSponsoredMessageReportResult = union(TLID) {
    ChannelsSponsoredMessageReportResultChooseOption: TL.ChannelsSponsoredMessageReportResultChooseOption,
    ChannelsSponsoredMessageReportResultAdsHidden: TL.ChannelsSponsoredMessageReportResultAdsHidden,
    ChannelsSponsoredMessageReportResultReported: TL.ChannelsSponsoredMessageReportResultReported,
};
const StatsBroadcastRevenueStats = union(TLID) {
    StatsBroadcastRevenueStats: TL.StatsBroadcastRevenueStats,
};
const StatsBroadcastRevenueWithdrawalUrl = union(TLID) {
    StatsBroadcastRevenueWithdrawalUrl: TL.StatsBroadcastRevenueWithdrawalUrl,
};
const BroadcastRevenueTransaction = union(TLID) {
    BroadcastRevenueTransactionProceeds: TL.BroadcastRevenueTransactionProceeds,
    BroadcastRevenueTransactionWithdrawal: TL.BroadcastRevenueTransactionWithdrawal,
    BroadcastRevenueTransactionRefund: TL.BroadcastRevenueTransactionRefund,
};
const StatsBroadcastRevenueTransactions = union(TLID) {
    StatsBroadcastRevenueTransactions: TL.StatsBroadcastRevenueTransactions,
};
const ReactionNotificationsFrom = union(TLID) {
    ReactionNotificationsFromContacts: TL.ReactionNotificationsFromContacts,
    ReactionNotificationsFromAll: TL.ReactionNotificationsFromAll,
};
const ReactionsNotifySettings = union(TLID) {
    ReactionsNotifySettings: TL.ReactionsNotifySettings,
};
const BroadcastRevenueBalances = union(TLID) {
    BroadcastRevenueBalances: TL.BroadcastRevenueBalances,
};
const AvailableEffect = union(TLID) {
    AvailableEffect: TL.AvailableEffect,
};
const MessagesAvailableEffects = union(TLID) {
    MessagesAvailableEffectsNotModified: TL.MessagesAvailableEffectsNotModified,
    MessagesAvailableEffects: TL.MessagesAvailableEffects,
};
const FactCheck = union(TLID) {
    FactCheck: TL.FactCheck,
};
const StarsTransactionPeer = union(TLID) {
    StarsTransactionPeerUnsupported: TL.StarsTransactionPeerUnsupported,
    StarsTransactionPeerAppStore: TL.StarsTransactionPeerAppStore,
    StarsTransactionPeerPlayMarket: TL.StarsTransactionPeerPlayMarket,
    StarsTransactionPeerPremiumBot: TL.StarsTransactionPeerPremiumBot,
    StarsTransactionPeerFragment: TL.StarsTransactionPeerFragment,
    StarsTransactionPeer: TL.StarsTransactionPeer,
    StarsTransactionPeerAds: TL.StarsTransactionPeerAds,
};
const StarsTopupOption = union(TLID) {
    StarsTopupOption: TL.StarsTopupOption,
};
const StarsTransaction = union(TLID) {
    StarsTransaction: TL.StarsTransaction,
};
const PaymentsStarsStatus = union(TLID) {
    PaymentsStarsStatus: TL.PaymentsStarsStatus,
};
const FoundStory = union(TLID) {
    FoundStory: TL.FoundStory,
};
const StoriesFoundStories = union(TLID) {
    StoriesFoundStories: TL.StoriesFoundStories,
};
const GeoPointAddress = union(TLID) {
    GeoPointAddress: TL.GeoPointAddress,
};
const StarsRevenueStatus = union(TLID) {
    StarsRevenueStatus: TL.StarsRevenueStatus,
};
const PaymentsStarsRevenueStats = union(TLID) {
    PaymentsStarsRevenueStats: TL.PaymentsStarsRevenueStats,
};
const PaymentsStarsRevenueWithdrawalUrl = union(TLID) {
    PaymentsStarsRevenueWithdrawalUrl: TL.PaymentsStarsRevenueWithdrawalUrl,
};
const PaymentsStarsRevenueAdsAccountUrl = union(TLID) {
    PaymentsStarsRevenueAdsAccountUrl: TL.PaymentsStarsRevenueAdsAccountUrl,
};
const InputStarsTransaction = union(TLID) {
    InputStarsTransaction: TL.InputStarsTransaction,
};
const StarsGiftOption = union(TLID) {
    StarsGiftOption: TL.StarsGiftOption,
};
const BotsPopularAppBots = union(TLID) {
    BotsPopularAppBots: TL.BotsPopularAppBots,
};
const BotPreviewMedia = union(TLID) {
    BotPreviewMedia: TL.BotPreviewMedia,
};
const BotsPreviewInfo = union(TLID) {
    BotsPreviewInfo: TL.BotsPreviewInfo,
};
const StarsSubscriptionPricing = union(TLID) {
    StarsSubscriptionPricing: TL.StarsSubscriptionPricing,
};
const StarsSubscription = union(TLID) {
    StarsSubscription: TL.StarsSubscription,
};
const MessageReactor = union(TLID) {
    MessageReactor: TL.MessageReactor,
};
const StarsGiveawayOption = union(TLID) {
    StarsGiveawayOption: TL.StarsGiveawayOption,
};
const StarsGiveawayWinnersOption = union(TLID) {
    StarsGiveawayWinnersOption: TL.StarsGiveawayWinnersOption,
};
const StarGift = union(TLID) {
    StarGift: TL.StarGift,
};
const PaymentsStarGifts = union(TLID) {
    PaymentsStarGiftsNotModified: TL.PaymentsStarGiftsNotModified,
    PaymentsStarGifts: TL.PaymentsStarGifts,
};
const UserStarGift = union(TLID) {
    UserStarGift: TL.UserStarGift,
};
const PaymentsUserStarGifts = union(TLID) {
    PaymentsUserStarGifts: TL.PaymentsUserStarGifts,
};
const MessageReportOption = union(TLID) {
    MessageReportOption: TL.MessageReportOption,
};
const ReportResult = union(TLID) {
    ReportResultChooseOption: TL.ReportResultChooseOption,
    ReportResultAddComment: TL.ReportResultAddComment,
    ReportResultReported: TL.ReportResultReported,
};
