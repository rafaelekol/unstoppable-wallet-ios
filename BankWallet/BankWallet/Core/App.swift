class App {
    static let shared = App()

    let localStorage: ILocalStorage & IChartTypeStorage
    let secureStorage: ISecureStorage
    let storage: IEnabledWalletStorage & IAccountRecordStorage & IPriceAlertRecordStorage

    let themeManager: IThemeManager
    let appConfigProvider: IAppConfigProvider
    let systemInfoManager: ISystemInfoManager
    let biometryManager: IBiometryManager

    let pasteboardManager: IPasteboardManager
    let reachabilityManager: IReachabilityManager

    let languageManager: LanguageManager

    let pinManager: IPinManager
    let wordsManager: IWordsManager

    let accountManager: IAccountManager
    let backupManager: IBackupManager

    let walletFactory: IWalletFactory
    let walletManager: IWalletManager

    let accountCreator: IAccountCreator
    let predefinedAccountTypeManager: IPredefinedAccountTypeManager

    let currencyManager: ICurrencyManager

    let rateManager: IRateManager

    let feeCoinProvider: IFeeCoinProvider
    let feeRateProviderFactory: FeeRateProviderFactory

    let adapterManager: IAdapterManager

    let lockRouter: LockRouter

    let passcodeLockManager: IPasscodeLockManager

    let dataProviderManager: IFullTransactionDataProviderManager
    let fullTransactionInfoProviderFactory: IFullTransactionInfoProviderFactory

    private let testModeIndicator: TestModeIndicator
    private let walletRemover: WalletRemover

    let priceAlertManager: IPriceAlertManager
    let backgroundPriceAlertManager: IBackgroundPriceAlertManager
    let notificationManager: INotificationManager
    var debugLogger: IDebugLogger?

    let appStatusManager: IAppStatusManager
    let appVersionManager: IAppVersionManager

    let appManager: AppManager

    init() {
        let networkManager = NetworkManager()

        localStorage = UserDefaultsStorage()
        secureStorage = KeychainStorage()
        storage = GrdbStorage()

        themeManager = ThemeManager(localStorage: localStorage)
        appConfigProvider = AppConfigProvider()
        systemInfoManager = SystemInfoManager()
        biometryManager = BiometryManager(systemInfoManager: systemInfoManager)
        if appConfigProvider.officeMode {
            debugLogger = DebugLogger(localStorage: localStorage, dateProvider: CurrentDateProvider())
        }

        pasteboardManager = PasteboardManager()
        reachabilityManager = ReachabilityManager(appConfigProvider: appConfigProvider)

        languageManager = LanguageManager(localStorage: localStorage)

        pinManager = PinManager(secureStorage: secureStorage, localStorage: localStorage)
        wordsManager = WordsManager()

        let accountStorage: IAccountStorage = AccountStorage(secureStorage: secureStorage, storage: storage)
        accountManager = AccountManager(storage: accountStorage)
        backupManager = BackupManager(accountManager: accountManager)

        walletFactory = WalletFactory()
        let walletStorage: IWalletStorage = WalletStorage(appConfigProvider: appConfigProvider, walletFactory: walletFactory, storage: storage)
        walletManager = WalletManager(accountManager: accountManager, walletFactory: walletFactory, storage: walletStorage)

        let defaultWalletCreator: IDefaultWalletCreator = DefaultWalletCreator(walletManager: walletManager, appConfigProvider: appConfigProvider, walletFactory: walletFactory)
        accountCreator = AccountCreator(accountManager: accountManager, accountFactory: AccountFactory(), wordsManager: wordsManager, defaultWalletCreator: defaultWalletCreator)
        predefinedAccountTypeManager = PredefinedAccountTypeManager(appConfigProvider: appConfigProvider, accountManager: accountManager, accountCreator: accountCreator)

        currencyManager = CurrencyManager(localStorage: localStorage, appConfigProvider: appConfigProvider)

        rateManager = RateManager(walletManager: walletManager, currencyManager: currencyManager)

        feeCoinProvider = FeeCoinProvider(appConfigProvider: appConfigProvider)
        feeRateProviderFactory = FeeRateProviderFactory(appConfigProvider: appConfigProvider)

        let ethereumKitManager = EthereumKitManager(appConfigProvider: appConfigProvider)
        let eosKitManager = EosKitManager(appConfigProvider: appConfigProvider)
        let binanceKitManager = BinanceKitManager(appConfigProvider: appConfigProvider)

        let adapterFactory: IAdapterFactory = AdapterFactory(appConfigProvider: appConfigProvider, ethereumKitManager: ethereumKitManager, eosKitManager: eosKitManager, binanceKitManager: binanceKitManager)
        adapterManager = AdapterManager(adapterFactory: adapterFactory, ethereumKitManager: ethereumKitManager, eosKitManager: eosKitManager, binanceKitManager: binanceKitManager, walletManager: walletManager)

        lockRouter = LockRouter()
        let lockManager: ILockManager = LockManager(pinManager: pinManager, localStorage: localStorage, lockRouter: lockRouter)
        let blurManager: IBlurManager = BlurManager(lockManager: lockManager)

        let passcodeLockRouter: IPasscodeLockRouter = PasscodeLockRouter()
        passcodeLockManager = PasscodeLockManager(systemInfoManager: systemInfoManager, accountManager: accountManager, walletManager: walletManager, router: passcodeLockRouter)

        dataProviderManager = FullTransactionDataProviderManager(localStorage: localStorage, appConfigProvider: appConfigProvider)

        let jsonApiProvider: IJsonApiProvider = JsonApiProvider(networkManager: networkManager)
        fullTransactionInfoProviderFactory = FullTransactionInfoProviderFactory(apiProvider: jsonApiProvider, dataProviderManager: dataProviderManager)

        testModeIndicator = TestModeIndicator(appConfigProvider: appConfigProvider)
        walletRemover = WalletRemover(accountManager: accountManager, walletManager: walletManager)

        let priceAlertStorage: IPriceAlertStorage = PriceAlertStorage(appConfigProvider: appConfigProvider, storage: storage)
        priceAlertManager = PriceAlertManager(walletManager: walletManager, storage: priceAlertStorage)
        notificationManager = NotificationManager()

        let notificationFactory = NotificationFactory(emojiHelper: EmojiHelper())
        let priceAlertHandler = PriceAlertHandler(priceAlertStorage: priceAlertStorage, notificationManager: notificationManager, notificationFactory: notificationFactory)

        backgroundPriceAlertManager = BackgroundPriceAlertManager(rateManager: rateManager, currencyManager: currencyManager, priceAlertStorage: priceAlertStorage, priceAlertHandler: priceAlertHandler, debugBackgroundLogger: debugLogger)

        appStatusManager = AppStatusManager(systemInfoManager: systemInfoManager, localStorage: localStorage, predefinedAccountTypeManager: predefinedAccountTypeManager, walletManager: walletManager, adapterManager: adapterManager, ethereumKitManager: ethereumKitManager, eosKitManager: eosKitManager, binanceKitManager: binanceKitManager)
        appVersionManager = AppVersionManager(systemInfoManager: systemInfoManager, localStorage: localStorage)

        let kitCleaner = KitCleaner(accountManager: accountManager)
        appManager = AppManager(
                accountManager: accountManager,
                walletManager: walletManager,
                adapterManager: adapterManager,
                lockManager: lockManager,
                passcodeLockManager: passcodeLockManager,
                biometryManager: biometryManager,
                blurManager: blurManager,
                notificationManager: notificationManager,
                backgroundPriceAlertManager: backgroundPriceAlertManager,
                localStorage: localStorage,
                secureStorage: secureStorage,
                kitCleaner: kitCleaner,
                debugLogger: debugLogger,
                appVersionManager: appVersionManager
        )
    }

}

extension App {

    static var theme: ITheme {
        App.shared.themeManager.currentTheme
    }

}
