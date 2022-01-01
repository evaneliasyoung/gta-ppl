/**
 *  @file      Threading.cs
 *  @brief     Threading namespace with helpers.
 *
 *  @author    Evan Elias Young
 *  @date      2022-01-01
 *  @date      2022-01-01
 *  @copyright Copyright 2022 Evan Elias Young. All rights reserved.
 */

namespace GTAPPL.Threading;

interface IPausable
{
    bool Suspend();
    bool Resume();
}

class Threading
{
    public static bool SuspendAll<T>(List<T> list) where T : IPausable
    {
        return !list.Any(delegate (T pause) { return !pause.Suspend(); });
    }
    public static bool ResumeAll<T>(List<T> list) where T : IPausable
    {
        return !list.Any(delegate (T pause) { return !pause.Resume(); });
    }
}
