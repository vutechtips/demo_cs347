#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
need_root
require_lab
python3 "$ROOT/scripts/verify_capture.py"
