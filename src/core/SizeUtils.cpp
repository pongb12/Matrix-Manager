#include "SizeUtils.h"

namespace SizeUtils
{

QString formatBytes(quint64 bytes)
{
    const quint64 unit = 1024ull;
    if (bytes < unit)
        return QString::number(bytes) + QLatin1String(" B");

    double value = static_cast<double>(bytes);
    static const char16_t *units[] = {
        u"KiB", u"MiB", u"GiB", u"TiB", u"PiB", u"EiB"
    };
    for (const char16_t *u : units) {
        value /= static_cast<double>(unit);
        if (value < static_cast<double>(unit) || u == units[5])
            return QString::number(value, 'f', 1) + QLatin1Char(' ') + QString::fromUtf16(u);
    }
    // Unreachable.
    return QString::number(bytes) + QLatin1String(" B");
}

QString formatKib(quint64 kib)
{
    return formatBytes(kibToBytes(kib));
}

} // namespace SizeUtils
