from enum import IntEnum

NS_OMEMO_TMP = "eu.siacs.conversations.axolotl"
NS_OMEMO_2 = "urn:xmpp:omemo:2"

LEGACY_ENCODED_KEY_LENGTH = 33
ENCODED_KEY_LENGTH = 32
MAX_INT = 2**31 - 1


class OMEMOTrust(IntEnum):
    UNTRUSTED = 0
    VERIFIED = 1
    UNDECIDED = 2
    BLIND = 3
