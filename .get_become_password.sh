#!/bin/sh
exec op read "op://ServiceAccountAccess/Fleet ansible become_pass/$(hostname)"
