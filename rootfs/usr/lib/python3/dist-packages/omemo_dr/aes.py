from __future__ import annotations

from typing import NamedTuple

import logging
import os

from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives.ciphers import algorithms
from cryptography.hazmat.primitives.ciphers import Cipher
from cryptography.hazmat.primitives.ciphers.modes import GCM

log = logging.getLogger(__name__)

IV_SIZE = 12


class EncryptionResult(NamedTuple):
    payload: bytes
    key: bytes
    iv: bytes


def _decrypt(key: bytes, iv: bytes, tag: bytes, data: bytes) -> bytes:
    decryptor = Cipher(
        algorithms.AES(key), GCM(iv, tag=tag), backend=default_backend()
    ).decryptor()
    return decryptor.update(data) + decryptor.finalize()


def aes_decrypt(_key: bytes, iv: bytes, payload: bytes) -> str:
    if len(_key) >= 32:
        # XEP-0384
        log.debug("XEP Compliant Key/Tag")
        data = payload
        key = _key[:16]
        tag = _key[16:]
    else:
        # Legacy
        log.debug("Legacy Key/Tag")
        data = payload[:-16]
        key = _key
        tag = payload[-16:]

    return _decrypt(key, iv, tag, data).decode()


def aes_decrypt_file(key: bytes, iv: bytes, payload: bytes) -> bytes:
    data = payload[:-16]
    tag = payload[-16:]
    return _decrypt(key, iv, tag, data)


def _encrypt(
    data: str | bytes, key_size: int, iv_size: int = IV_SIZE
) -> tuple[bytes, bytes, bytes, bytes]:
    if isinstance(data, str):
        data = data.encode()
    key = os.urandom(key_size)
    iv = os.urandom(iv_size)
    encryptor = Cipher(
        algorithms.AES(key), GCM(iv), backend=default_backend()
    ).encryptor()

    payload = encryptor.update(data) + encryptor.finalize()
    return key, iv, encryptor.tag, payload


def aes_encrypt(plaintext: str) -> EncryptionResult:
    key, iv, tag, payload = _encrypt(plaintext, 16)
    key += tag
    return EncryptionResult(payload=payload, key=key, iv=iv)


def aes_encrypt_file(data: bytes) -> EncryptionResult:
    (
        key,
        iv,
        tag,
        payload,
    ) = _encrypt(data, 32)
    payload += tag
    return EncryptionResult(payload=payload, key=key, iv=iv)


def get_new_key() -> bytes:
    return os.urandom(16)


def get_new_iv() -> bytes:
    return os.urandom(IV_SIZE)
