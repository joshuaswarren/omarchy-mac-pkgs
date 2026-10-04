---
title: Moving an existing Mac
description: How Macs installed from earlier Apple Silicon projects move to this stack.
section: Using it
---

Macs already running Omarchy from an earlier Apple Silicon project (Omarchy MX Mac, the earlier omarchy-mac project, or test builds of this stack) move to official Omarchy and these packages in place, without a reinstall. Nothing moves yet.

The move is not part of `omarchy-mac` or `omarchy-mac-boot`. It is a standalone migration script, documented with the script in [omacom/omarchy-mac](https://github.com/omacom/omarchy-mac):

- Macs on the omarchy-mac fork get it from its `quattro` branch, through their normal update.
- Omarchy MX Mac Macs get it from that project's final release.
- Macs on test builds of this stack get a one-line command.

It is switched on only after the official Mac packages are signed, published and promoted, and the move has been accepted for each kind of install.

Encrypting an unencrypted Mac is not part of the move. It may come later as a separate, opt-in step.
