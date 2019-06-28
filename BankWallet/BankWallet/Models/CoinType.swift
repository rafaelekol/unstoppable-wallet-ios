import Foundation

enum CoinType {
    case bitcoin
    case bitcoinCash
    case dash
    case ethereum
    case erc20(address: String, decimal: Int, fee: Decimal)
    case eos(token: String, symbol: String)

    func canSupport(accountType: AccountType) -> Bool {
        switch self {
        case .bitcoin, .bitcoinCash, .dash:
            if case .mnemonic = accountType { return true }
            if case .hdMasterKey = accountType { return true }
            return false
        case .ethereum, .erc20:
            if case .mnemonic = accountType { return true }
            if case .privateKey = accountType { return true }
            return false
        case .eos:
            if case .eos = accountType { return true }
            return false
        }
    }
}

extension CoinType: Equatable {

    public static func ==(lhs: CoinType, rhs: CoinType) -> Bool {
        switch (lhs, rhs) {
        case (.bitcoin, .bitcoin): return true
        case (.bitcoinCash, .bitcoinCash): return true
        case (.dash, .dash): return true
        case (.ethereum, .ethereum): return true
        case (.erc20(let lhsAddress, let lhsDecimal, let lhsFee), .erc20(let rhsAddress, let rhsDecimal, let rhsFee)):
            return lhsAddress == rhsAddress && lhsDecimal == rhsDecimal && lhsFee == rhsFee
        case (.eos(let lhsToken, let lhsSymbol), .eos(let rhsToken, let rhsSymbol)):
            return lhsToken == rhsToken && lhsSymbol == rhsSymbol
        default: return false
        }
    }

}
