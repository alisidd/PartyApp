//
//  MultipeerManager.swift
//  WeJ
//
//  Created by Matthew Paletta on 2017-01-20.
//  Copyright © 2017 Mohammad Ali Siddiqui. All rights reserved.
//

import Foundation
import MultipeerConnectivity

struct Host {
    var hostID: MCPeerID
    var partyName: String
}

class MultipeerManager: NSObject {
    
    weak var delegate : NetworkManagerDelegate?
    weak var partiesListerDelegate: PartiesListerDelegate?
    private let serviceType = "localParty"
    var partyName: String
    fileprivate static var myPeerID: MCPeerID!
    private var serviceAdvertiser: MCNearbyServiceAdvertiser!
    fileprivate var serviceBrowser: MCNearbyServiceBrowser!
    
    fileprivate var isHost: Bool
    var sessions = [MCPeerID : (partyName: String, session: MCSession)]() {
        didSet {
            partiesListerDelegate?.reloadList()
        }
    }
    var allHosts: [Host] {
        return sessions.map { Host(hostID: $0.key, partyName: $0.value.partyName) }.sorted(by: { $0.partyName < $1.partyName })
    }
    
    private var latestPosition = TimeInterval()
    private var latestRequest = [Track]()
    static var tracksFailedToSend = [Track]()
    
    // MARK: - Lifecycle
    
    init(isHost: Bool, partyName: String = NSLocalizedString("Party", comment: "")) {
        self.isHost = isHost
        self.partyName = partyName
        
        let deviceIdentifier = UIDevice.current.identifierForVendor!.uuidString
        MultipeerManager.myPeerID = MultipeerManager.myPeerID ?? MCPeerID(displayName: deviceIdentifier)
        
        if isHost {
            serviceAdvertiser = MCNearbyServiceAdvertiser(peer: MultipeerManager.myPeerID, discoveryInfo: ["partyName": partyName], serviceType: serviceType)
        } else {
            serviceBrowser = MCNearbyServiceBrowser(peer: MultipeerManager.myPeerID, serviceType: serviceType)
        }
        
        super.init()
        
        setDelegates()
        advertise()
    }
    
    deinit {
        if isHost {
            serviceAdvertiser?.stopAdvertisingPeer()
        } else {
            serviceBrowser?.stopBrowsingForPeers()
        }
    }
    
    private func setDelegates() {
        if isHost {
            serviceAdvertiser.delegate = self
        } else {
            serviceBrowser.delegate = self
        }
    }
    
    func advertise() {
        DispatchQueue.global(qos: .background).async {
            if self.isHost {
                self.serviceAdvertiser.startAdvertisingPeer()
            } else {
                self.serviceBrowser.startBrowsingForPeers()
            }
        }
    }
    
    // MARK: - Functions
    
    func advertise(position: TimeInterval) {
        if !sessions.isEmpty {
            latestPosition = position
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard self != nil && position == self!.latestPosition else { return }
                
                let positionData = NSKeyedArchiver.archivedData(withRootObject: position)
                self?.sessions.values.forEach {
                    try? $0.session.send(positionData, toPeers: $0.session.connectedPeers, with: .reliable)
                }
            }
        }
    }
    
    func send(tracks: [Track], toRemove isRemoval: Bool = false) {
        if !sessions.isEmpty {
            if !isRemoval {
                latestRequest = tracks
            }
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard self != nil && (isRemoval || tracks == self!.latestRequest) else { return }
                
                let tracksListData = NSKeyedArchiver.archivedData(withRootObject: tracks)
                self?.sessions.values.forEach {
                    guard self != nil else { return }
                    if (try? $0.session.send(tracksListData, toPeers: $0.session.connectedPeers, with: .reliable)) == nil && !self!.isHost {
                        MultipeerManager.tracksFailedToSend = tracks
                    } else {
                        MultipeerManager.tracksFailedToSend.forEach {
                            if !Party.tracksQueue(hasTrack: $0) {
                                Party.tracksQueue.append($0)
                            }
                        }
                        MultipeerManager.tracksFailedToSend = []
                    }
                }
            }
        } else if !isHost {
            MultipeerManager.tracksFailedToSend = tracks
        }
    }
    
    func sendPartyInfo(toSession session: MCSession) {
        if !sessions.isEmpty && delegate != nil {
            let partyData = NSKeyedArchiver.archivedData(withRootObject: Party())
            try? session.send(partyData, toPeers: session.connectedPeers, with: .reliable)
        }
    }
    
}

extension MCSessionState {
    
    var stringValue: String {
        switch self {
        case .notConnected: return NSLocalizedString("Not Connected", comment: "")
        case .connecting: return NSLocalizedString("Connecting", comment: "")
        case .connected: return NSLocalizedString("Connected", comment: "")
        }
    }
    
}

// MARK: - Invitation

extension MultipeerManager: MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping ((Bool, MCSession?) -> Void)) {
        if !sessions.contains(where: { $0.0.displayName == peerID.displayName }) {
            let newSession = MCSession(peer: MultipeerManager.myPeerID, securityIdentity: nil, encryptionPreference: .none)
            newSession.delegate = self
            sessions[peerID] = ("", newSession)
            invitationHandler(true, newSession)
        } else {
            for (_, session) in sessions.values where session.connectedPeers.isEmpty {
                invitationHandler(true, session)
            }
        }
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("didNotStartAdvertisingPeer: \(error)")
    }
    
}

// MARK: - Peer Discovery Callbacks

extension MultipeerManager: MCNearbyServiceBrowserDelegate {
    
    public func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        guard peerID.displayName != MultipeerManager.myPeerID.displayName && (delegate?.connectionStatus ?? .notConnected) == .notConnected else { return }
        let newSession = MCSession(peer: MultipeerManager.myPeerID, securityIdentity: nil, encryptionPreference: .none)
        newSession.delegate = self
        sessions[peerID] = (info!["partyName"] ?? NSLocalizedString("Party", comment: ""), newSession)
        
        invite(peerID: peerID, forFirstTime: false, withPartyName: info!["partyName"] ?? NSLocalizedString("Party", comment: ""))
    }
    
    func invite(peerID: MCPeerID, forFirstTime firstTime: Bool, withPartyName partyName: String? = nil) {
        let alreadyConnected = sessions.values.contains(where: { !$0.session.connectedPeers.isEmpty && $0.session.connectedPeers[0].displayName == peerID.displayName })
        
        if let (_, session) = sessions[peerID], !alreadyConnected && (firstTime || Party.name == partyName) {
            serviceBrowser.invitePeer(peerID, to: session, withContext: nil, timeout: 2)
            sessions.forEach { if $0.key.displayName != peerID.displayName { sessions.removeValue(forKey: $0.key) }}
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        sessions[peerID]?.session.disconnect()
        sessions.removeValue(forKey: peerID)
        
        if sessions.isEmpty {
            delegate?.updateStatus(withState: .notConnected)
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("didNotStartBrowsingForPeers: \(error)")
    }
    
}

// MARK: - Session Callbacks

extension MultipeerManager: MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        if state == .connected {
            if isHost {
                sendPartyInfo(toSession: session)
                send(tracks: Party.tracksQueue)
            }
            delegate?.updateStatus(withState: state)
        } else if state == .notConnected {
            sessions.removeValue(forKey: peerID)
            if !sessions.contains(where: { !$0.value.session.connectedPeers.isEmpty }) {
                delegate?.updateStatus(withState: state)
                delegate?.resetManager()
            }
        } else {
            delegate?.updateStatus(withState: state)
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        let unarchivedData = NSKeyedUnarchiver.unarchiveObject(with: data)
        
        if let party = unarchivedData as? Party {
            delegate?.setup(withParty: party)
        } else if let tracks = unarchivedData as? [Track] {
            if !tracks.isEmpty, case .removal = Track.typeOf(track: tracks[0]) {
                delegate?.remove(track: tracks[0])
            } else {
                delegate?.add(tracksReceived: tracks)
            }
        } else if let position = unarchivedData as? TimeInterval {
            delegate?.update(usingPosition: position)
        }
    }
    
    func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
        print("Certificate receive")
        certificateHandler(true)
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("didReceiveStream")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        print("didFinishReceivingResourceWithName")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print("didStartReceivingResourceWithName")
    }
    
}
