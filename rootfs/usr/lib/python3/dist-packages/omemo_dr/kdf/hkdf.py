from __future__ import annotations

from typing import Optional

import hashlib
import hmac
import math


class HKDF:
    HASH_OUTPUT_SIZE = 32

    def __init__(self, session_version: int) -> None:
        if session_version not in (3, 4):
            raise AssertionError("Unknown version: %s " % session_version)

        self._session_version = session_version

    def get_session_version(self) -> int:
        return self._session_version

    def derive_secrets(
        self,
        input_key_material: bytes,
        info: bytes,
        output_length: int,
        salt: Optional[bytes] = None,
    ) -> bytes:
        salt = salt or bytes(self.HASH_OUTPUT_SIZE)
        prk = self._extract(salt, input_key_material)
        return self._expand(prk, info, output_length)

    def _extract(self, salt: bytes, input_key_material: bytes) -> bytes:
        mac = hmac.new(bytes(salt), digestmod=hashlib.sha256)
        mac.update(bytes(input_key_material))
        return mac.digest()

    def _expand(self, prk: bytes, info: bytes, output_size: int) -> bytes:
        iterations = int(math.ceil(float(output_size) / float(self.HASH_OUTPUT_SIZE)))
        mixin = b""
        results = bytearray()
        remaining_bytes = output_size

        for i in range(1, iterations + 1):
            mac = hmac.new(prk, digestmod=hashlib.sha256)
            mac.update(mixin)
            mac.update(info)
            updateChr = chr(i % 256)
            mac.update(updateChr.encode())

            stepResult = mac.digest()
            stepSize = min(remaining_bytes, len(stepResult))
            results.extend(stepResult[:stepSize])
            mixin = stepResult
            remaining_bytes -= stepSize

        return bytes(results)
