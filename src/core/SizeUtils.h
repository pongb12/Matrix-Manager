/*
 * SizeUtils.h — consistent human-readable size formatting.
 *
 * DOC.md rule 7: use binary units (B, KiB, MiB, GiB, TiB) with one fixed
 * convention everywhere in the application. Never mix decimal "MB" with
 * binary "MiB" presentation.
 */
#pragma once

#include <QtGlobal>
#include <QString>

namespace SizeUtils
{
// Formats a byte count using binary units, e.g. "512 B", "1.0 KiB",
// "42.7 MiB", "1.8 GiB". Byte values are shown as integers, everything
// larger with exactly one decimal digit.
QString formatBytes(quint64 bytes);

// Formats a byte count that is known to be an installed-size value coming
// from dpkg, which reports sizes in KiB.
QString formatKib(quint64 kib);

// Converts a dpkg Installed-Size value (KiB) to bytes.
constexpr quint64 kibToBytes(quint64 kib) { return kib * 1024ull; }
}
