from __future__ import annotations

from ..ecc.curve import Curve
from ..ecc.djbec import CurvePublicKey
from ..ecc.eckeypair import ECKeyPair
from ..kdf.derivedrootsecrets import DerivedRootSecrets
from ..kdf.hkdf import HKDF
from .chainkey import ChainKey


class RootKey:
    def __init__(self, kdf: HKDF, key: bytes) -> None:
        self._kdf = kdf
        self._key = key

    def get_key_bytes(self) -> bytes:
        return self._key

    def create_chain(
        self,
        ec_public_key_their_ratchet_key: CurvePublicKey,
        ec_key_pair_our_ratchet_key: ECKeyPair,
    ) -> tuple[RootKey, ChainKey]:
        if self._kdf.get_session_version() <= 3:
            domain_separator = "WhisperRatchet"
        else:
            domain_separator = "OMEMO Root Chain"

        shared_secret = Curve.calculate_agreement(
            ec_public_key_their_ratchet_key,
            ec_key_pair_our_ratchet_key.get_private_key(),
        )

        derived_secret_bytes = self._kdf.derive_secrets(
            shared_secret,
            domain_separator.encode(),
            DerivedRootSecrets.SIZE,
            salt=self._key,
        )

        derived_secrets = DerivedRootSecrets(derived_secret_bytes)
        new_root_key = RootKey(self._kdf, derived_secrets.get_root_key())
        new_chain_key = ChainKey(self._kdf, derived_secrets.get_chain_key(), 0)
        return (new_root_key, new_chain_key)
