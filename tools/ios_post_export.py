#!/usr/bin/env python3
"""Post-process the Godot iOS export for the Long Note.

Godot's export does not expose every Info.plist key we need. This script is
idempotent and only touches orientation, file sharing, and encryption metadata.
Signing and iCloud entitlements still require a real Apple Developer team.

Usage:
    python3 tools/ios_post_export.py build/ios/LongNote/LongNote-Info.plist
    python3 tools/ios_post_export.py build/ios/LongNote/LongNote-Info.plist --icloud iCloud.com.leksarodic.longnote
"""

from __future__ import annotations

import plistlib
import sys
from pathlib import Path

if len(sys.argv) < 2:
    print("usage: ios_post_export.py <Info.plist> [--icloud <container>]")
    raise SystemExit(2)

path = Path(sys.argv[1])
if not path.exists():
    print(f"not found: {path}")
    raise SystemExit(1)

with path.open("rb") as fh:
    data = plistlib.load(fh)

data["UIFileSharingEnabled"] = True
data["LSSupportsOpeningDocumentsInPlace"] = True
data["UIRequiresFullScreen"] = True
data["UIStatusBarHidden"] = True
data["UIViewControllerBasedStatusBarAppearance"] = False
data["ITSAppUsesNonExemptEncryption"] = False
data["UISupportedInterfaceOrientations"] = [
    "UIInterfaceOrientationLandscapeLeft",
    "UIInterfaceOrientationLandscapeRight",
]
data["UISupportedInterfaceOrientations~ipad"] = [
    "UIInterfaceOrientationLandscapeLeft",
    "UIInterfaceOrientationLandscapeRight",
]

if "--icloud" in sys.argv:
    idx = sys.argv.index("--icloud")
    if idx + 1 < len(sys.argv):
        container = sys.argv[idx + 1]
        data["NSUbiquitousContainers"] = {
            container: {
                "NSUbiquitousContainerIsDocumentScopePublic": True,
                "NSUbiquitousContainerName": "The Long Note",
                "NSUbiquitousContainerSupportedFolderLevels": "Any",
            }
        }

with path.open("wb") as fh:
    plistlib.dump(data, fh, fmt=plistlib.FMT_XML)

print(f"updated {path}")
print("  file sharing, landscape orientation, encryption metadata")
if "--icloud" in sys.argv:
    print("  iCloud container declared; add the matching entitlement in Xcode")
print("  signing/team/provisioning still required")
