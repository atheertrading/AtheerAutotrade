import CryptoKit
import Foundation

/// Encrypts sensitive native-to-backend payloads for one supervised child-process session.
/// A new ephemeral Curve25519 key pair is created whenever the backend is launched.
final class IPCSecretChannel {
    private let privateKey = Curve25519.KeyAgreement.PrivateKey()
    private var symmetricKey: SymmetricKey?

    var clientPublicKey: String {
        privateKey.publicKey.rawRepresentation.base64EncodedString()
    }

    func establish(serverPublicKey: String, salt: String) throws {
        guard
            let publicData = Data(base64Encoded: serverPublicKey),
            let saltData = Data(base64Encoded: salt),
            publicData.count == 32,
            saltData.count == 32
        else {
            throw LocalIPCError.handshakeRejected
        }

        let peerKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: publicData)
        let sharedSecret = try privateKey.sharedSecretFromKeyAgreement(with: peerKey)
        symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: saltData,
            sharedInfo: Data("atheer.local-ipc.capitalcom.credentials.v1".utf8),
            outputByteCount: 32
        )
    }

    func encrypt(_ plaintext: Data) throws -> [String: String] {
        guard let symmetricKey else {
            throw LocalIPCError.handshakeRejected
        }

        let sealed = try AES.GCM.seal(plaintext, using: symmetricKey)
        let nonce = sealed.nonce.withUnsafeBytes { Data($0) }

        return [
            "algorithm": "AES-256-GCM",
            "nonce": nonce.base64EncodedString(),
            "ciphertext": sealed.ciphertext.base64EncodedString(),
            "tag": sealed.tag.base64EncodedString()
        ]
    }

    func reset() {
        symmetricKey = nil
    }
}
