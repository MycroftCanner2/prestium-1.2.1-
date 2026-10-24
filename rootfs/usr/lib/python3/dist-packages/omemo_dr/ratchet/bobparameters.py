from __future__ import annotations

from ..ecc.djbec import CurvePublicKey
from ..ecc.eckeypair import ECKeyPair
from ..identitykey import IdentityKey
from ..identitykeypair import IdentityKeyPair


class BobParameters:
    def __init__(
        self,
        our_identity_key: IdentityKeyPair,
        our_signed_pre_key: ECKeyPair,
        our_ratchet_key: ECKeyPair,
        our_one_time_pre_key: ECKeyPair,
        their_identity_key: IdentityKey,
        their_base_key: CurvePublicKey,
    ) -> None:
        self._our_identity_key = our_identity_key
        self._our_signed_pre_key = our_signed_pre_key
        self._our_ratchet_key = our_ratchet_key
        self._our_one_time_pre_key = our_one_time_pre_key
        self._their_identity_key = their_identity_key
        self._their_base_key = their_base_key

    def get_our_identity_key(self) -> IdentityKeyPair:
        return self._our_identity_key

    def get_our_signed_pre_key(self) -> ECKeyPair:
        return self._our_signed_pre_key

    def get_our_one_time_pre_key(self) -> ECKeyPair:
        return self._our_one_time_pre_key

    def get_their_identity_key(self) -> IdentityKey:
        return self._their_identity_key

    def get_their_base_key(self) -> CurvePublicKey:
        return self._their_base_key

    def get_our_ratchet_key(self) -> ECKeyPair:
        return self._our_ratchet_key
