#ifndef CHRONO_UTILITIES_PERIOD_H
#define CHRONO_UTILITIES_PERIOD_H

#include "./datetime.h"

namespace ChronoUtilities {

class CPP_UTILITIES_EXPORT Period
{
public:
    Period(const DateTime &beg, const DateTime &end);
    int years() const;
    int months() const;
    int days() const;
private:
    int m_years;
    int m_months;
    int m_days;
};

/*!
 * \brief Gets the years component of the period represented by the current instance.
 */
inline int Period::years() const
{
    return m_years;
}

/*!
 * \brief Gets the months component of the period represented by the current instance.
 */
inline int Period::months() const
{
    return m_months;
}

/*!
 * \brief Gets the days component of the period represented by the current instance.
 */
inline int Period::days() const
{
    return m_days;
}

}

#endif // CHRONO_UTILITIES_PERIOD_H
