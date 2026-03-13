import Shared
import EndpointSecurity
import Foundation
import Shared

enum AnalysisResult {
    case noChange
    case newHeur
    case shouldKill
    case ignore
}

class HeuristicsPipeline {
    static let shared = HeuristicsPipeline()
    
    private init() {}
    
    func heurResponds(_ heur: Heuristic, to message: es_message_t) -> Bool {
        heur.match.map {
            switch $0 {
            case let .event(event):
                ExtendedEventInfo.byHeurNameExtended(event.name)?.esValue == message.event_type
            case .heuristic:
                true
            }
        }.allSatisfy { $0 }
    }
    
    func restrictionApplies(_ restriction: Heuristic.MatchItem.Restriction, to message: es_message_t) -> Bool {
        switch restriction {
        case let .allOf(restrictions):
            return restrictions.map { self.restrictionApplies($0, to: message) }.allSatisfy { $0 }
        case let .anyOf(restrictions):
            return restrictions.map { self.restrictionApplies($0, to: message) }.contains(true)
        case let .notAllOf(restrictions):
            return !restrictions.map { self.restrictionApplies($0, to: message) }.allSatisfy { $0 }
        case let .notAnyOf(restrictions):
            return !restrictions.map { self.restrictionApplies($0, to: message) }.contains(true)
        case let .node(key, value):
            let tokens = key.split(separator: "+").map { String($0) }
            let attr = tokens[0]
            let op = tokens[1]
            guard let info = ExtendedEventInfo.byEsValueExtended(message.event_type.rawValue) else {
                SharedLog.fatal("Cannot find event \(message.event_type)")
            }
            guard let comparator = info.attrs[attr] else {
                SharedLog.fatal("Cannot find comparator \(attr)")
            }
            return comparator[op, message](value)
        }
    }
    
    func heurApplies(_ heur: Heuristic, to message: es_message_t) -> Bool {
        heur.match.map {
            switch $0 {
            case let .event(event):
                restrictionApplies(event.restrict, to: message)
            case .heuristic:
                true
            }
        }.allSatisfy { $0 }
    }
    
    func thresholdReached(_ heur: Heuristic, to message: es_message_t, processData: ProcessData) -> Bool {
        let currentTimestamp = Int(Date.now.timeIntervalSince1970)
        for match in heur.match {
            switch match {
            case let .event(event):
                switch event.threshold {
                case let .total(total):
                    if processData.private.messages.filter({ message in
                        guard let info = ExtendedEventInfo.byHeurNameExtended(event.name) else {
                            SharedLog.fatal("Cannot find event for \(event.name)")
                        }
                        return info.esValue == message.pointee.event_type
                    }).filter({ message in
                        self.restrictionApplies(event.restrict, to: message.pointee)
                    }).filter({ message in
                        guard let interval = total.interval else {
                            return true
                        }
                        return message.pointee.time.tv_sec >= currentTimestamp - interval
                    }).count < total.amount {
                        return false
                    }
                }
            case let .heuristic(heuristic):
                switch heuristic.threshold {
                case let .total(total):
                    if processData.public.heurs.filter({ heur in
                        heur == heuristic.name
                    }).count < total.amount {
                        return false
                    }
                }
            }
        }
        return true
    }
    
    func pipe(message: es_message_t, processData: ProcessData) -> AnalysisResult {
        if processData.public.killedByEdr {
            return .ignore
        }
        
        let heurs = Globals.shared.endpointSecurity.heurs
        let validHeurs = heurs
            .map(\.value)
            .filter { self.heurResponds($0, to: message) }
            .filter { self.heurApplies($0, to: message) }
        
        let eventHeurs = validHeurs.filter { $0.match.contains {
            if case .event = $0 {
                true
            } else {
                false
            }
        }}
        
        let heurHeurs = validHeurs.filter { $0.match.contains {
            if case .heuristic = $0 {
                true
            } else {
                false
            }
        }}

        if validHeurs.isEmpty {
            return .noChange
        }
        
        for heur in eventHeurs {
            if !self.thresholdReached(heur, to: message, processData: processData) {
                continue
            }
            self.applyChanges(process: processData, heur: heur)
        }
        
        var lastChanged = 0
        while true {
            let changed = heurHeurs.filter { self.thresholdReached($0, to: message, processData: processData) }
            if changed.count == lastChanged {
                for heur in changed {
                    if self.thresholdReached(heur, to: message, processData: processData) {
                        self.applyChanges(process: processData, heur: heur)
                    }
                }
                break
            }
            lastChanged = changed.count
        }

        if processData.public.points > PublicProcessData.maxPoints {
            return .shouldKill
        } else {
            return .newHeur
        }
    }
    
    func applyChanges(process: ProcessData, heur: Heuristic) {
        let exists = process.public.heurs.contains(heur.name)
        if exists && heur.onDuplicate == .ignore {
            return
        }
        process.public.heurs.append(heur.name)
        if exists && heur.onDuplicate == .ignorePoints {
            return
        }
        process.public.points += heur.points
    }
}
