from __future__ import annotations

from ..const import MAX_INT
from ..const import NS_OMEMO_2
from ..const import NS_OMEMO_TMP
from ..ecc.djbec import CurvePublicKey
from ..ecc.djbec import EdPublicKey
from ..exceptions import BundleValidationError
from ..identitykey import IdentityKey
from ..structs import OMEMOBundleProto


class PreKeyBundle:
    def __init__(
        self,
        remote_device_id: int,
        namespace: str,
        pre_key_id: int,
        ec_public_key_pre_key_public: CurvePublicKey,
        signed_pre_key_id: int,
        ec_public_key_signed_pre_key_public: CurvePublicKey,
        signed_pre_key_signature: bytes,
        identity_key: IdentityKey,
    ) -> None:
        self._remote_device_id = remote_device_id
        self._namespace = namespace
        self._pre_key_id = pre_key_id
        self._pre_key_public = ec_public_key_pre_key_public
        self._signed_pre_key_id = signed_pre_key_id
        self._signed_pre_key_public = ec_public_key_signed_pre_key_public
        self._signed_pre_key_signature = signed_pre_key_signature
        self._identity_key = identity_key

    @classmethod
    def from_proto(cls, bundle: OMEMOBundleProto) -> PreKeyBundle:
        prekey = bundle.pick_prekey()
        otpk = CurvePublicKey.from_bytes(prekey["key"])
        spk = CurvePublicKey.from_bytes(bundle.spk["key"])

        ns = bundle.namespace
        if ns == NS_OMEMO_TMP:
            ik_pub = CurvePublicKey.from_bytes(bundle.ik)
        elif ns == NS_OMEMO_2:
            ik_pub = EdPublicKey.from_bytes(bundle.ik).to_curve()
        else:
            raise BundleValidationError("Unknown namespace on bundle: %s", ns)

        ik = IdentityKey(ik_pub)

        if not 1 <= bundle.device_id <= MAX_INT:
            raise BundleValidationError("Device id out of range")

        if not 1 <= prekey["id"] <= MAX_INT:
            raise BundleValidationError("Prekey id out of range")

        if not 0 <= bundle.spk["id"] <= MAX_INT:
            # Allow 0 to stay backwards compatible
            raise BundleValidationError("Signed pre key id out of range")

        return cls(
            bundle.device_id,
            bundle.namespace,
            prekey["id"],
            otpk,
            bundle.spk["id"],
            spk,
            bundle.spk_signature,
            ik,
        )

    def get_remote_device_id(self) -> int:
        return self._remote_device_id

    def get_namespace(self) -> str:
        return self._namespace

    def get_pre_key_id(self) -> int:
        return self._pre_key_id

    def get_pre_key(self) -> CurvePublicKey:
        return self._pre_key_public

    def get_signed_pre_key_id(self) -> int:
        return self._signed_pre_key_id

    def get_signed_pre_key(self) -> CurvePublicKey:
        return self._signed_pre_key_public

    def get_signed_pre_key_signature(self) -> bytes:
        return self._signed_pre_key_signature

    def get_identity_key(self) -> IdentityKey:
        return self._identity_key

    def get_session_version(self) -> int:
        if self._namespace == NS_OMEMO_TMP:
            return 3

        elif self._namespace == NS_OMEMO_2:
            return 4

        else:
            raise AssertionError("Unknown session version")
