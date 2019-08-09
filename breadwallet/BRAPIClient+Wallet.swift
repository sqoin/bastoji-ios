//
//  BRAPIClient+Wallet.swift
//  breadwallet
//
//  Created by Samuel Sutch on 4/2/17.
//  Copyright © 2017 breadwallet LLC. All rights reserved.
//

import Foundation

private let fallbackRatesURL = "https://bitpay.com/api/rates"

enum RatesResult {
    case success([Rate])
    case error(String)
}

extension BRAPIClient {

    func me() {
        let req = URLRequest(url: url("/me"))
        let task = dataTaskWithRequest(req, authenticated: true, handler: { data, response, err in
            if let data = data {
                print("me: \(String(describing: String(data: data, encoding: .utf8)))")
            }
        })
        task.resume()
    }

    func feePerKb(code: String, _ handler: @escaping (_ fees: Fees, _ error: String?) -> Void) {
        let param = false ? "?currency=bch" : ""
        let req = URLRequest(url: url("/fee-per-kb\(param)"))
        let task = self.dataTaskWithRequest(req) { (data, response, err) -> Void in
            var regularFeePerKb: uint_fast64_t = 0
            var economyFeePerKb: uint_fast64_t = 0
            var errStr: String? = nil
            if err == nil {
                do {
                    let parsedObject: Any? = try JSONSerialization.jsonObject(
                        with: data!, options: JSONSerialization.ReadingOptions.allowFragments)
                    if let top = parsedObject as? NSDictionary, let regular = top["fee_per_kb"] as? NSNumber, let economy = top["fee_per_kb_economy"] as? NSNumber {
                        regularFeePerKb = regular.uint64Value
                        economyFeePerKb = economy.uint64Value
                    }
                } catch (let e) {
                    self.log("fee-per-kb: error parsing json \(e)")
                }
                if regularFeePerKb == 0 || economyFeePerKb == 0 {
                    errStr = "invalid json"
                }
            } else {
                self.log("fee-per-kb network error: \(String(describing: err))")
                errStr = "bad network connection"
            }
            handler(Fees(regular: regularFeePerKb, economy: economyFeePerKb, timestamp: Date().timeIntervalSince1970), errStr)
        }
        task.resume()
    }
    
    /// Fetches Bitcoin exchange rates in all available fiat currencies
    func exchangeRates(currencyCode code: String, isFallback: Bool = false, _ handler: @escaping (RatesResult) -> Void) {
        
        let rates: [Rate] = [Rate(code: "USD",
                                  name: "USD",
                                  rate: 1.5,
                                  reciprocalCode: "USD")]
        handler(.success(rates))
        
       
    }

    /// Fetches all token exchange rates in BTC from CoinMarketCap
    func tokenExchangeRates(_ handler: @escaping (RatesResult) -> Void) {
        
        let rates: [Rate] = [Rate(code: Currencies.btc.code,
                                  name: Currencies.btc.name,
                                  rate: 1.5,
                                  reciprocalCode: Currencies.btc.code)]
        handler(.success(rates))
        
    
    }
    
    func savePushNotificationToken(_ token: Data) {
        var req = URLRequest(url: url("/me/push-devices"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        let reqJson = [
            "token": token.hexString,
            "service": "apns",
            "data": [   "e": pushNotificationEnvironment(),
                        "b": Bundle.main.bundleIdentifier!]
            ] as [String : Any]
        do {
            let dat = try JSONSerialization.data(withJSONObject: reqJson, options: .prettyPrinted)
            req.httpBody = dat
        } catch (let e) {
            log("JSON Serialization error \(e)")
            return
        }
        dataTaskWithRequest(req as URLRequest, authenticated: true, retryCount: 0) { (dat, resp, er) in
            print("[PUSH] registered device token: \(reqJson)")
            let datString = String(data: dat ?? Data(), encoding: .utf8)
            self.log("save push token resp: \(resp?.statusCode ?? 0) data: \(String(describing: datString))")
        }.resume()
    }

    func deletePushNotificationToken(_ token: Data) {
        var req = URLRequest(url: url("/me/push-devices/apns/\(token.hexString)"))
        req.httpMethod = "DELETE"
        dataTaskWithRequest(req as URLRequest, authenticated: true, retryCount: 0) { (dat, resp, er) in
            self.log("delete push token resp: \(String(describing: resp))")
            if let statusCode = resp?.statusCode {
                if statusCode >= 200 && statusCode < 300 {
                    UserDefaults.pushToken = nil
                    self.log("deleted old token")
                }
            }
        }.resume()
    }

    func fetchUTXOS(address: String, currency: CurrencyDef, completion: @escaping ([[String: Any]]?)->Void) {
        let path = currency.matches(Currencies.btc) ? "/q/addrs/utxo" : "/q/addrs/utxo?currency=bch"
        var req = URLRequest(url: url(path))
        req.httpMethod = "POST"
        req.httpBody = "addrs=\(address)".data(using: .utf8)
        dataTaskWithRequest(req, handler: { data, resp, error in
            guard error == nil else { completion(nil); return }
            guard let data = data,
                let jsonData = try? JSONSerialization.jsonObject(with: data, options: []),
                let json = jsonData as? [[String: Any]] else { completion(nil); return }
                completion(json)
        }).resume()
    }
}

struct BTCRateResponse : Codable {
    let body: [BTCRate]
    
    struct BTCRate : Codable {
        let code: String
        let name: String
        let rate: Double
    }
}

struct Ticker: Codable {
    let symbol: String
    let name: String
    let usdRate: String?
    let btcRate: String?
    
    enum CodingKeys: String, CodingKey {
        case symbol
        case name
        case usdRate = "price_usd"
        case btcRate = "price_btc"
    }
}

private func pushNotificationEnvironment() -> String {
    return E.isDebug ? "d" : "p" //development or production
}
