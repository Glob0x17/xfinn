//
//  ServerDiscoveryService.swift
//  xfinn
//
//  Created by Dorian Galiana on 11/01/2026.
//  Based on UDPBroadcastConnection approach (BSD sockets)
//

import Foundation
import Combine

/// Service de découverte des serveurs Jellyfin sur le réseau local via UDP broadcast
/// Utilise les sockets BSD pour une compatibilité maximale
final class ServerDiscoveryService: ObservableObject {

    // MARK: - Published Properties

    /// Serveurs découverts sur le réseau
    @Published private(set) var discoveredServers: [ServerItem] = []

    /// Indique si une recherche est en cours
    @Published private(set) var isSearching = false

    // MARK: - Private Properties

    private var socket: Int32 = -1
    private var responseSource: DispatchSourceRead?
    private let queue = DispatchQueue(label: "com.xfinn.serverDiscovery", qos: .userInitiated)

    private let jellyfinPort: UInt16 = 7359
    private let broadcastMessage = "Who is JellyfinServer?"

    private var discoveryTimer: Timer?

    // MARK: - Initialization

    init() {}

    deinit {
        stopDiscovery()
    }

    // MARK: - Public API

    /// Démarre la découverte des serveurs (avec rafraîchissement périodique)
    func startDiscovery() {
        guard !isSearching else { return }

        DispatchQueue.main.async {
            self.isSearching = true
            self.discoveredServers = []
        }

        // Créer le socket
        guard setupSocket() else {
            #if DEBUG
            print("[ServerDiscovery] Failed to setup socket")
            #endif
            DispatchQueue.main.async {
                self.isSearching = false
            }
            return
        }

        // Démarrer l'écoute des réponses
        startListening()

        // Envoyer le premier broadcast
        sendBroadcast()

        // Rafraîchir toutes les 10 secondes
        DispatchQueue.main.async {
            self.discoveryTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
                self?.sendBroadcast()
            }
        }
    }

    /// Arrête la découverte
    func stopDiscovery() {
        // Capturer le timer directement : depuis deinit, un [weak self] serait
        // déjà nil et le timer ne serait jamais invalidé
        let timer = discoveryTimer
        discoveryTimer = nil
        DispatchQueue.main.async { [weak self] in
            timer?.invalidate()
            self?.isSearching = false
        }

        let socketToClose = socket
        socket = -1

        // Annuler la source AVANT de fermer le fd (règle Apple) : le fd est
        // fermé dans le cancelHandler de la source, une fois qu'elle garantit
        // ne plus le surveiller. Fermer d'abord risquerait qu'un fd recyclé
        // soit surveillé/fermé par erreur.
        if let source = responseSource {
            source.cancel()
            responseSource = nil
        } else if socketToClose >= 0 {
            // Aucune source créée : fermer directement
            close(socketToClose)
        }
    }

    // MARK: - Private Methods - Socket Setup

    private func setupSocket() -> Bool {
        // Créer un socket UDP
        socket = Darwin.socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
        guard socket >= 0 else {
            #if DEBUG
            print("[ServerDiscovery] Failed to create socket: \(errno)")
            #endif
            return false
        }

        // Activer le broadcast
        var broadcastEnable: Int32 = 1
        let result = setsockopt(socket, SOL_SOCKET, SO_BROADCAST, &broadcastEnable, socklen_t(MemoryLayout<Int32>.size))
        guard result >= 0 else {
            #if DEBUG
            print("[ServerDiscovery] Failed to enable broadcast: \(errno)")
            #endif
            close(socket)
            socket = -1
            return false
        }

        // Permettre la réutilisation de l'adresse
        var reuseEnable: Int32 = 1
        setsockopt(socket, SOL_SOCKET, SO_REUSEADDR, &reuseEnable, socklen_t(MemoryLayout<Int32>.size))
        setsockopt(socket, SOL_SOCKET, SO_REUSEPORT, &reuseEnable, socklen_t(MemoryLayout<Int32>.size))

        // Bind sur le port pour recevoir les réponses
        var bindAddr = sockaddr_in()
        bindAddr.sin_family = sa_family_t(AF_INET)
        bindAddr.sin_port = jellyfinPort.bigEndian
        bindAddr.sin_addr.s_addr = INADDR_ANY.bigEndian

        let bindResult = withUnsafePointer(to: &bindAddr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPtr in
                bind(socket, sockaddrPtr, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }

        if bindResult < 0 {
            #if DEBUG
            print("[ServerDiscovery] Failed to bind socket (errno \(errno)), trying without bind...")
            #endif
            // Continuer sans bind - on peut quand même envoyer des broadcasts
        }

        #if DEBUG
        print("[ServerDiscovery] Socket created successfully")
        #endif

        return true
    }

    // MARK: - Private Methods - Listening

    private func startListening() {
        // Capturer le fd par valeur : les handlers ne dépendent ainsi pas de
        // la propriété `socket`, mutée depuis un autre thread par stopDiscovery()
        let fd = socket
        responseSource = DispatchSource.makeReadSource(fileDescriptor: fd, queue: queue)

        responseSource?.setEventHandler { [weak self] in
            self?.handleIncomingData(on: fd)
        }

        responseSource?.setCancelHandler {
            #if DEBUG
            print("[ServerDiscovery] Response source cancelled, closing socket")
            #endif
            // Fermer le fd ici, une fois la source annulée : elle garantit
            // qu'elle ne le surveille plus (pattern recommandé par Apple)
            if fd >= 0 {
                close(fd)
            }
        }

        responseSource?.resume()

        #if DEBUG
        print("[ServerDiscovery] Started listening for responses")
        #endif
    }

    private func handleIncomingData(on fd: Int32) {
        var buffer = [UInt8](repeating: 0, count: 4096)
        var senderAddr = sockaddr_in()
        var senderAddrLen = socklen_t(MemoryLayout<sockaddr_in>.size)

        let bytesRead = withUnsafeMutablePointer(to: &senderAddr) { addrPtr in
            addrPtr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPtr in
                recvfrom(fd, &buffer, buffer.count, 0, sockaddrPtr, &senderAddrLen)
            }
        }

        guard bytesRead > 0 else {
            #if DEBUG
            print("[ServerDiscovery] recvfrom failed or no data: \(errno)")
            #endif
            return
        }

        let data = Data(bytes: buffer, count: bytesRead)

        // Extraire l'IP de l'expéditeur
        var hostBuffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
        inet_ntop(AF_INET, &senderAddr.sin_addr, &hostBuffer, socklen_t(INET_ADDRSTRLEN))
        let senderIP = String(cString: hostBuffer)

        #if DEBUG
        if let responseString = String(data: data, encoding: .utf8) {
            print("[ServerDiscovery] Received from \(senderIP): \(responseString)")
        }
        #endif

        // Ignorer notre propre broadcast
        if let responseString = String(data: data, encoding: .utf8),
           responseString == broadcastMessage {
            #if DEBUG
            print("[ServerDiscovery] Ignoring own broadcast")
            #endif
            return
        }

        // Décoder la réponse JSON
        do {
            let response = try JSONDecoder().decode(JellyfinDiscoveryResponse.self, from: data)
            let server = response.asServerItem

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                // Éviter les doublons
                if !self.discoveredServers.contains(where: { $0.id == server.id }) {
                    self.discoveredServers.append(server)
                    #if DEBUG
                    print("[ServerDiscovery] Found server: \(server.name) at \(server.url)")
                    #endif
                }
            }
        } catch {
            #if DEBUG
            print("[ServerDiscovery] Failed to decode response: \(error)")
            #endif
        }
    }

    // MARK: - Private Methods - Broadcast

    private func sendBroadcast() {
        guard socket >= 0 else {
            #if DEBUG
            print("[ServerDiscovery] Cannot send broadcast: socket not initialized")
            #endif
            return
        }

        #if DEBUG
        print("[ServerDiscovery] Sending broadcast...")
        #endif

        // Préparer l'adresse de broadcast
        var broadcastAddr = sockaddr_in()
        broadcastAddr.sin_family = sa_family_t(AF_INET)
        broadcastAddr.sin_port = jellyfinPort.bigEndian
        broadcastAddr.sin_addr.s_addr = INADDR_BROADCAST

        // Envoyer le message
        guard let messageData = broadcastMessage.data(using: .utf8) else { return }

        let bytesSent = messageData.withUnsafeBytes { bufferPtr in
            withUnsafePointer(to: &broadcastAddr) { addrPtr in
                addrPtr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPtr in
                    sendto(socket, bufferPtr.baseAddress, messageData.count, 0, sockaddrPtr, socklen_t(MemoryLayout<sockaddr_in>.size))
                }
            }
        }

        #if DEBUG
        if bytesSent > 0 {
            print("[ServerDiscovery] Broadcast sent (\(bytesSent) bytes)")
        } else {
            print("[ServerDiscovery] Failed to send broadcast: \(errno)")
        }
        #endif
    }
}
